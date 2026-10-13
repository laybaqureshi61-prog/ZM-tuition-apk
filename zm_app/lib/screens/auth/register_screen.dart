import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../common/custom_password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'student'; // 'student' or 'admin'
  String _selectedAdmin =
      'zoya'; // 'zoya' (Commerce) or 'muskan' (Maths & Science)
  String _selectedBatch =
      'Class 10 (Maths & Science) - Muskan Mam'; // For students

  final List<String> _studentBatches = [
    'Class 9 (Maths & Science) - Muskan Mam',
    'Class 10 (Maths & Science) - Muskan Mam',
    'Class 11 (Maths & Science) - Muskan Mam',
    'Class 12 (Maths & Science) - Muskan Mam',
    'Class 11 & 12 (Commerce) - Zoya Mam',
  ];

  bool _otpSent = false;
  bool _otpVerified = false;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 1. Register Account & Send Phone OTP (PRD 3.1)
  Future<void> _handleRegisterAndSendOtp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter Name, Email, and Phone Number.',
      );
      return;
    }

    if (password.length < 8) {
      setState(
        () => _errorMessage = 'Password must be at least 8 characters long.',
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: _selectedRole,
      adminType: _selectedRole == 'admin' ? _selectedAdmin : null,
      batch: _selectedRole == 'student' ? _selectedBatch : null,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _otpController.clear();
      setState(() {
        _otpSent = true;
        _successMessage =
            'Verification code sent to $email! Please check your Inbox and Spam folder, and enter the 6-digit OTP manually.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.brandTeal,
          content: Text('OTP sent to $email. Please enter it below.'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Registration failed.');
    }
  }

  // 2. Verify Phone via OTP (PRD 3.2)
  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.verifyPhone(phone: phone, otp: otp);

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _otpVerified = true;
        _successMessage = 'Account verified successfully! Activated.';
      });

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen),
              SizedBox(width: 8),
              Text('Account Verified!'),
            ],
          ),
          content: Text(
            'Your phone ($phone) is verified and account is active. You can now log in.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandTeal,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to Login
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Invalid OTP code.');
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

                  // TOP HERO CARD (Inspired by Image 1 Sign Up Header)
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
                        // Decorative organic curves
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
                            // Back to login button (Exact Image 1 Style)
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Back to login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join ZM Tuition center online learning hub',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // MAIN WHITE CARD SHEET (Pill inputs - Exact Image 1 Style)
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
                        // "Sign Up" Title (Deep Teal)
                        const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandTeal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Selector Pills
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.cardDarkElevated
                                : const Color(0xFFEEF5F3),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _otpSent
                                      ? null
                                      : () => setState(
                                          () => _selectedRole = 'student',
                                        ),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'student'
                                          ? (isDark
                                                ? AppTheme.cardDark
                                                : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: _selectedRole == 'student'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  15,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Student',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: _selectedRole == 'student'
                                              ? AppTheme.brandTeal
                                              : AppTheme.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _otpSent
                                      ? null
                                      : () => setState(
                                          () => _selectedRole = 'admin',
                                        ),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'admin'
                                          ? (isDark
                                                ? AppTheme.cardDark
                                                : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: _selectedRole == 'admin'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  15,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Teacher / Admin',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: _selectedRole == 'admin'
                                              ? AppTheme.brandTeal
                                              : AppTheme.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // If Admin: Choose Department
                        if (_selectedRole == 'admin') ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _selectedAdmin == 'zoya'
                                        ? const Color(0xFFE0F2EF)
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color: _selectedAdmin == 'zoya'
                                          ? AppTheme.brandTeal
                                          : const Color(0xFFD0E0DC),
                                      width: _selectedAdmin == 'zoya' ? 2 : 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: _otpSent
                                      ? null
                                      : () => setState(
                                          () => _selectedAdmin = 'zoya',
                                        ),
                                  child: const Text(
                                    'Zoya (Commerce)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _selectedAdmin == 'muskan'
                                        ? const Color(0xFFE0F2EF)
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color: _selectedAdmin == 'muskan'
                                          ? AppTheme.brandTeal
                                          : const Color(0xFFD0E0DC),
                                      width: _selectedAdmin == 'muskan' ? 2 : 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: _otpSent
                                      ? null
                                      : () => setState(
                                          () => _selectedAdmin = 'muskan',
                                        ),
                                  child: const Text(
                                    'Muskan (Maths & Science)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        // If Student: Choose Batch
                        if (_selectedRole == 'student') ...[
                          DropdownButtonFormField<String>(
                            initialValue:
                                _studentBatches.contains(_selectedBatch)
                                ? _selectedBatch
                                : _studentBatches.first,
                            decoration: InputDecoration(
                              labelText: 'Class / Batch',
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                size: 20,
                                color: Color(0xFF6B8A87),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppTheme.cardDarkElevated
                                  : const Color(0xFFF3F7F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _studentBatches
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      b,
                                      style: const TextStyle(fontSize: 13.5),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _otpSent
                                ? null
                                : (v) => setState(() => _selectedBatch = v!),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Pill Input 1: Full Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              size: 20,
                              color: Color(0xFF6B8A87),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.cardDarkElevated
                                : const Color(0xFFF3F7F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pill Input 2: Email (Exact Image 1 field)
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: Color(0xFF6B8A87),
                            ),
                            suffixIcon: _emailController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B8A87)),
                                    tooltip: 'Clear email',
                                    splashRadius: 18,
                                    onPressed: () {
                                      _emailController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.cardDarkElevated
                                : const Color(0xFFF3F7F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pill Input 3: Password (Exact Image 1 field)
                        CustomPasswordField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Pill Input 4: Confirm Password (Exact Image 1 field)
                        CustomPasswordField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Enter your confirm password',
                          prefixIcon: Icons.lock_outline_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Pill Input 5: Phone (Exact Image 1 field)
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            hintText: 'Enter your phone number',
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 20,
                              color: Color(0xFF6B8A87),
                            ),
                            suffixIcon: _phoneController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B8A87)),
                                    tooltip: 'Clear phone',
                                    splashRadius: 18,
                                    onPressed: () {
                                      _phoneController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.cardDarkElevated
                                : const Color(0xFFF3F7F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRedSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.dangerRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Pill Primary Button: Sign Up (Exact Image 1 Style)
                        if (!_otpSent)
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _handleRegisterAndSendOtp,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                        // OTP Section if sent
                        if (_otpSent && !_otpVerified) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.brandTealLight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Enter Phone Verification Code',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.brandTeal,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    hintText: '------',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandTeal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : _handleVerifyOtp,
                                  child: const Text(
                                    'Verify & Activate Account',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Footer Back to Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.inkSecondaryDark
                                    : const Color(0xFF6A8784),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandTeal,
                                ),
                              ),
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
