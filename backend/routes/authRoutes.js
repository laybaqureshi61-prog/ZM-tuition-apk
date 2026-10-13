const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Public OTP & Registration Endpoints
router.post('/send-otp', authController.sendOtp);
router.post('/verify-otp', authController.verifyOtp);
router.post('/register', authController.register);
router.post('/reset-password', authController.resetPassword);
router.post('/login', authController.login);

module.exports = router;
