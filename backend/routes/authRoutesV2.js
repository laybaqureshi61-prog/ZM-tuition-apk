const express = require('express');
const router = express.Router();
const authController = require('../controllers/authControllerV2');
const { checkSmsRateLimit } = require('../middlewares/rateLimiter');

// 3.1 Account Registration
router.post('/register', authController.register);

// 3.2 Phone Verification via OTP
router.post('/verify-phone', authController.verifyPhone);

// 3.3 Multi-Channel Login: Option A - Password Login
router.post('/login/password', authController.loginPassword);

// 3.3 Multi-Channel Login: Option B - Passwordless Phone OTP Login
router.post('/login/phone/send-otp', checkSmsRateLimit, authController.sendPhoneLoginOtp);
router.post('/login/phone/verify-otp', authController.verifyPhoneLoginOtp);

// 3.4 Password Recovery & Reset Flow
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-reset-otp', authController.verifyResetOtp);
router.post('/reset-password', authController.resetPassword);

// 3.5 Token Refresh & Revocation
router.post('/refresh-token', authController.refreshToken);
router.post('/logout', authController.logout);
router.post('/logout-all', authController.requireAuth, authController.logoutAll);

// Current User Profile & Password
router.get('/me', authController.requireAuth, authController.getMe);
router.post('/change-password', authController.requireAuth, authController.changePassword);

// Verify Faculty Passkey (Public for gateway check)
const tuitionController = require('../controllers/tuitionController');
router.post('/verify-passkey', tuitionController.verifyAdminPasskey);

module.exports = router;
