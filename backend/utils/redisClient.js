/**
 * Redis Client & In-Memory TTL Key-Value Engine
 * 
 * Supports Redis commands: get, set, setex, del, incr, expire, ttl, flushall
 * Implements PRD Section 7 Key Specifications:
 * - otp:reg:<phone>        (TTL 300s)
 * - otp:login:<phone>      (TTL 300s)
 * - otp:pwd_reset:<phone>  (TTL 600s)
 * - otp_attempts:<phone>   (TTL 600s)
 * - rate:sms:<phone>       (TTL 60s)
 * - rate:sms_hourly:<phone>(TTL 3600s)
 * - rate:sms_ip:<ip>       (TTL 3600s)
 */

class MemoryRedisStore {
  constructor() {
    this.store = new Map();
    this.expiries = new Map();

    // Periodic sweep for expired keys every 10 seconds
    this.cleanupInterval = setInterval(() => {
      this._purgeExpired();
    }, 10000);

    if (this.cleanupInterval.unref) {
      this.cleanupInterval.unref();
    }
  }

  _purgeExpired() {
    const now = Date.now();
    for (const [key, expireAt] of this.expiries.entries()) {
      if (expireAt <= now) {
        this.store.delete(key);
        this.expiries.delete(key);
      }
    }
  }

  _isExpired(key) {
    const expireAt = this.expiries.get(key);
    if (!expireAt) return false;
    if (Date.now() >= expireAt) {
      this.store.delete(key);
      this.expiries.delete(key);
      return true;
    }
    return false;
  }

  async get(key) {
    if (this._isExpired(key)) return null;
    const val = this.store.get(key);
    return val !== undefined ? String(val) : null;
  }

  async set(key, value, mode, duration) {
    this.store.set(key, String(value));
    if (mode === 'EX' && typeof duration === 'number') {
      this.expiries.set(key, Date.now() + duration * 1000);
    } else {
      this.expiries.delete(key);
    }
    return 'OK';
  }

  async setex(key, seconds, value) {
    return this.set(key, value, 'EX', parseInt(seconds, 10));
  }

  async del(key) {
    const existed = this.store.has(key);
    this.store.delete(key);
    this.expiries.delete(key);
    return existed ? 1 : 0;
  }

  async incr(key) {
    if (this._isExpired(key)) {
      this.store.set(key, '0');
    }
    const current = parseInt(this.store.get(key) || '0', 10);
    const nextVal = current + 1;
    this.store.set(key, String(nextVal));
    return nextVal;
  }

  async expire(key, seconds) {
    if (!this.store.has(key) || this._isExpired(key)) return 0;
    this.expiries.set(key, Date.now() + parseInt(seconds, 10) * 1000);
    return 1;
  }

  async ttl(key) {
    if (!this.store.has(key) || this._isExpired(key)) return -2;
    const expireAt = this.expiries.get(key);
    if (!expireAt) return -1;
    const remainingMs = expireAt - Date.now();
    return Math.max(0, Math.ceil(remainingMs / 1000));
  }

  async keys(pattern) {
    this._purgeExpired();
    const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    const result = [];
    for (const key of this.store.keys()) {
      if (!this._isExpired(key) && regex.test(key)) {
        result.push(key);
      }
    }
    return result;
  }

  async flushall() {
    this.store.clear();
    this.expiries.clear();
    return 'OK';
  }
}

// Singleton Redis instance
const redisClient = new MemoryRedisStore();

module.exports = redisClient;
