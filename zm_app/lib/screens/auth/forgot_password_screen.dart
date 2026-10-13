import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../common/custom_password_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _otpVerified = false;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 1. Send OTP (PRD 3.4 Step 1)
  Future<void> _handleSendOtp() async {
    final identifier = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : _emailController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered Phone Number or Email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.forgotPassword(identifier: identifier, channel: 'SMS');

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _otpController.clear();
      setState(() {
        _otpSent = true;
        _successMessage = 'A 6-digit verification code has been dispatched. Please check your Inbox and Spam folder, and enter the OTP below.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.brandTeal,
          content: Text('Verification OTP dispatched! Please check your email / phone.'),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Failed to send reset code.');
    }
  }

  // 2. Verify OTP (PRD 3.4 Step 1.5)
  Future<void> _handleVerifyOtp() async {
    final identifier = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.verifyResetOtp(identifier: identifier, otp: otp);

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _otpVerified = true;
        _errorMessage = null;
        _successMessage = 'Code verified! Now choose a new secure password.';
      });
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Invalid or expired OTP.');
    }
  }

  // 3. Reset Password (PRD 3.4 Step 2)
  Future<void> _handleResetPassword() async {
    final identifier = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.resetPassword(
      identifier: identifier,
      otp: otp,
      newPassword: newPassword,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen),
              SizedBox(width: 8),
              Text('Password Reset Done'),
            ],
          ),
          content: const Text(
            'Your password has been updated successfully. You can now login with your new password.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandTeal),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to Login
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Password reset failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.paperDark : AppTheme.mintBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // TOP HERO CARD (Inspired by Image 1 Header)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                    decoration: BoxDecoration(
                      color: AppTheme.brandTeal,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandTeal.withAlpha(50),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFF136864).withAlpha(140),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Back to login',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recover access to your ZM Tuition account',
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // MAIN WHITE CARD SHEET
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandTeal.withAlpha(25),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step 1: Identifier Input
                        if (!_otpSent) ...[
                          const Text(
                            'Enter your registered phone or email to receive a recovery code:',
                            style: TextStyle(fontSize: 13.5, color: AppTheme.inkSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'Enter your 10-digit phone number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF6B8A87)),
                              filled: true,
                              fillColor: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text('— OR —', style: TextStyle(color: Color(0xFF88A5A2), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'Enter your registered email address',
                              prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF6B8A87)),
                              filled: true,
                              fillColor: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              onPressed: _isLoading ? null : _handleSendOtp,
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Send Recovery Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],

                        // Step 2: OTP Verification
                        if (_otpSent && !_otpVerified) ...[
                          if (_successMessage != null)
                            Text(_successMessage!, style: const TextStyle(fontSize: 13, color: AppTheme.brandTeal, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 8),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '------',
                              filled: true,
                              fillColor: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              onPressed: _isLoading ? null : _handleVerifyOtp,
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Verify Recovery Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],

                        // Step 3: Set New Password
                        if (_otpVerified) ...[
                          const Text(
                            'Create a new secure password for your account:',
                            style: TextStyle(fontSize: 13.5, color: AppTheme.inkSecondary),
                          ),
                          const SizedBox(height: 16),
                          CustomPasswordField(
                            controller: _newPasswordController,
                            labelText: 'New Password',
                            hintText: 'Enter your new password',
                            prefixIcon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          CustomPasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm New Password',
                            hintText: 'Confirm your new password',
                            prefixIcon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              onPressed: _isLoading ? null : _handleResetPassword,
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Update Password & Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRedSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Back to login footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Remember your password? ', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.inkSecondaryDark : const Color(0xFF6A8784))),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text('Login', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.brandTeal)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
