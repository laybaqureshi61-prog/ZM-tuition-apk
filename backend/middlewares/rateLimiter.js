const redisClient = require('../utils/redisClient');
const { normalizePhone } = require('../utils/authUtils');

/**
 * PRD Section 5: SMS Toll-Fraud Defense Middleware
 * 1. Per-Phone Cooldown : 60s minimum between 2 OTPs
 * 2. Per-Phone Hourly   : Max 4 SMS requests per hour
 * 3. Per-IP Hourly      : Max 10 SMS requests per hour
 */
async function checkSmsRateLimit(req, res, next) {
  try {
    const rawPhone = req.body.phone || req.body.identifier;
    if (!rawPhone) {
      return res.status(400).json({ message: 'Phone number is required.' });
    }

    const phone = normalizePhone(rawPhone);
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';

    // 1. Check Per-Phone Cooldown (60s)
    const cooldownKey = `rate:sms:${phone}`;
    const inCooldown = await redisClient.get(cooldownKey);
    if (inCooldown) {
      const remainingTtl = await redisClient.ttl(cooldownKey);
      return res.status(429).json({
        message: `Please wait ${remainingTtl > 0 ? remainingTtl : 60} seconds before requesting another OTP.`,
        retryAfter: remainingTtl > 0 ? remainingTtl : 60,
      });
    }

    // 2. Check Per-Phone Hourly Limit (Max 4 per hour)
    const phoneHourlyKey = `rate:sms_hourly:${phone}`;
    const phoneRequests = parseInt(await redisClient.get(phoneHourlyKey) || '0', 10);
    if (phoneRequests >= 4) {
      return res.status(429).json({
        message: 'Hourly SMS limit reached for this phone number (Max 4 OTPs per hour). Please try again later.',
        retryAfter: 3600,
      });
    }

    // 3. Check Per-IP Hourly Limit (Max 10 per hour)
    const ipHourlyKey = `rate:sms_ip:${clientIp}`;
    const ipRequests = parseInt(await redisClient.get(ipHourlyKey) || '0', 10);
    if (ipRequests >= 10) {
      return res.status(429).json({
        message: 'Too many OTP requests from this IP address. Please try again after an hour.',
        retryAfter: 3600,
      });
    }

    // Attach verified phone to request
    req.normalizedPhone = phone;
    req.clientIp = clientIp;
    next();
  } catch (err) {
    console.error('Rate limit middleware error:', err);
    next();
  }
}

/**
 * Commit Rate Limit Counters after OTP is successfully dispatched
 */
async function recordSmsSent(phone, clientIp) {
  try {
    // 1. Set 60s cooldown
    await redisClient.setex(`rate:sms:${phone}`, 60, '1');

    // 2. Increment Hourly Phone Count (TTL 3600s)
    const phoneHourlyKey = `rate:sms_hourly:${phone}`;
    const phoneCount = await redisClient.incr(phoneHourlyKey);
    if (phoneCount === 1) {
      await redisClient.expire(phoneHourlyKey, 3600);
    }

    // 3. Increment Hourly IP Count (TTL 3600s)
    if (clientIp) {
      const ipHourlyKey = `rate:sms_ip:${clientIp}`;
      const ipCount = await redisClient.incr(ipHourlyKey);
      if (ipCount === 1) {
        await redisClient.expire(ipHourlyKey, 3600);
      }
    }
  } catch (err) {
    console.error('Error recording SMS sent rate limits:', err);
  }
}

/**
 * Check Brute-Force OTP Lockout
 * Max 3 invalid attempts -> Lock for 15 minutes (900s)
 */
async function checkOtpAttempts(phone) {
  const attemptsKey = `otp_attempts:${phone}`;
  const attempts = parseInt(await redisClient.get(attemptsKey) || '0', 10);
  if (attempts >= 3) {
    const ttl = await redisClient.ttl(attemptsKey);
    return {
      locked: true,
      remainingMinutes: Math.max(1, Math.ceil(ttl / 60)),
    };
  }
  return { locked: false, attempts };
}

async function recordOtpFailure(phone) {
  const attemptsKey = `otp_attempts:${phone}`;
  const nextAttempts = await redisClient.incr(attemptsKey);
  if (nextAttempts >= 3) {
    await redisClient.expire(attemptsKey, 900); // 15 minutes lockout
  } else {
    await redisClient.expire(attemptsKey, 600); // 10 minutes tracking
  }
  return nextAttempts;
}

async function clearOtpAttempts(phone) {
  await redisClient.del(`otp_attempts:${phone}`);
}

module.exports = {
  checkSmsRateLimit,
  recordSmsSent,
  checkOtpAttempts,
  recordOtpFailure,
  clearOtpAttempts,
};
