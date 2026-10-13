const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || process.env.JWT_SECRET || 'zm_access_secret_super_secure_2026';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'zm_refresh_secret_super_secure_2026';

/**
 * 1. E.164 Phone Normalization & Validation
 * Regex: ^\+[1-9]\d{9,14}$
 */
const E164_REGEX = /^\+[1-9]\d{9,14}$/;

function normalizePhone(rawPhone) {
  if (!rawPhone) return '';
  let cleaned = String(rawPhone).trim().replace(/[^\d+]/g, '');
  if (cleaned.startsWith('+')) {
    return cleaned;
  }
  // Strip leading 0 if 11 digits (e.g. 08534088666 -> 8534088666)
  if (cleaned.startsWith('0') && cleaned.length === 11) {
    cleaned = cleaned.slice(1);
  }
  // Default to +91 (India) if 10-digit number is passed
  if (cleaned.length === 10) {
    return `+91${cleaned}`;
  }
  // If 12 digits starting with 91 (e.g. 918534088666)
  if (cleaned.length === 12 && cleaned.startsWith('91')) {
    return `+${cleaned}`;
  }
  return `+${cleaned}`;
}

function isValidPhone(phone) {
  const normalized = normalizePhone(phone);
  return E164_REGEX.test(normalized);
}

function findUserByIdentifier(db, identifier) {
  if (!identifier || !db) return null;
  const raw = String(identifier).trim();
  const lower = raw.toLowerCase();
  const digits = raw.replace(/\D/g, '');
  const last10 = digits.length >= 10 ? digits.slice(-10) : null;

  return (db.users || []).find(u => {
    // 1. Phone matching (exact or last 10 digits)
    if (u.phone) {
      const uDigits = String(u.phone).replace(/\D/g, '');
      if (last10 && uDigits.slice(-10) === last10) return true;
      if (normalizePhone(u.phone) === normalizePhone(raw)) return true;
    }
    // 2. Email matching (case-insensitive)
    if (u.email && u.email.toLowerCase() === lower) return true;
    // Cross-link user variations for Zoya/Admin
    if ((lower === 'business437@gmail.com' || lower === 'businesszm437@gmail.com') &&
        (u.email === 'business437@gmail.com' || u.email === 'businesszm437@gmail.com')) {
      return true;
    }
    if ((lower === 'qureshizoya63@gmail.com' || lower === 'zoyaqureshi63@gmail.com') && 
        (u.email === 'qureshizoya63@gmail.com' || u.email === 'zoyaqureshi63@gmail.com')) {
      return true;
    }
    // 3. Roll Number matching
    if (u.rollNo && String(u.rollNo).trim().toLowerCase() === lower) return true;
    // 4. Name matching
    if (u.name && u.name.trim().toLowerCase() === lower) return true;
    if (u.full_name && u.full_name.trim().toLowerCase() === lower) return true;

    return false;
  });
}

/**
 * 2. Strong Password Policy Validator
 * Policy: Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special character
 */
function validatePassword(password) {
  if (!password || typeof password !== 'string') {
    return { valid: false, message: 'Password is required.' };
  }
  if (password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters long.' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least 1 uppercase letter.' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least 1 lowercase letter.' };
  }
  if (!/\d/.test(password)) {
    return { valid: false, message: 'Password must contain at least 1 digit (0-9).' };
  }
  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~]/.test(password)) {
    return { valid: false, message: 'Password must contain at least 1 special character (e.g. @, #, $, !).' };
  }
  return { valid: true };
}

/**
 * 3. Cryptographically Secure 6-digit OTP Generation
 * Uses crypto.randomInt(100000, 1000000)
 */
function generateSecureOtp() {
  return crypto.randomInt(100000, 1000000).toString();
}

/**
 * 4. Password Hashing with bcrypt (Salt rounds 12)
 */
async function hashPassword(plainText) {
  const salt = await bcrypt.genSalt(12);
  return bcrypt.hash(plainText, salt);
}

async function comparePassword(plainText, hash) {
  if (!hash) return false;
  return bcrypt.compare(plainText, hash);
}

/**
 * 5. Hash Token using SHA-256 for secure session storage
 */
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

/**
 * 6. JWT Token Generation (Access 15m, Refresh 7d)
 */
function generateTokens(user) {
  const sessionId = crypto.randomUUID();

  const payload = {
    id: user.id,
    full_name: user.full_name || user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    adminType: user.adminType,
    department: user.department,
    batch: user.batch,
    sid: sessionId,
  };

  const accessToken = jwt.sign(payload, JWT_ACCESS_SECRET, {
    expiresIn: '15m', // 15 minutes
  });

  const refreshToken = jwt.sign(
    { id: user.id, sid: sessionId },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' } // 7 days
  );

  return {
    accessToken,
    refreshToken,
    sessionId,
    expiresIn: 900, // 15 mins in seconds
  };
}

function verifyAccessToken(token) {
  return jwt.verify(token, JWT_ACCESS_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, JWT_REFRESH_SECRET);
}

module.exports = {
  normalizePhone,
  isValidPhone,
  findUserByIdentifier,
  validatePassword,
  generateSecureOtp,
  hashPassword,
  comparePassword,
  hashToken,
  generateTokens,
  verifyAccessToken,
  verifyRefreshToken,
  JWT_ACCESS_SECRET,
  JWT_REFRESH_SECRET,
};
