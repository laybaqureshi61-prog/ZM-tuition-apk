import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';
import '../common/custom_password_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;
  final bool isPortalLocked;

  const LoginScreen({
    super.key,
    this.initialRole = 'student',
    this.isPortalLocked = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  late String _selectedRole;
  String _loginType = 'password'; // 'password' or 'otp'
  bool _phoneOtpSent = false;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    setState(() => _cooldownSeconds = seconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_cooldownSeconds <= 1) {
        setState(() => _cooldownSeconds = 0);
        return false;
      }
      setState(() => _cooldownSeconds--);
      return true;
    });
  }

  void _navigateToDashboard(UserModel user) {
    if (!mounted) return;
    if (user.role == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentDashboard(user: user)),
      );
    }
  }

  // 1. Password Login (PRD Option A)
  Future<void> _handlePasswordLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email/phone and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.login(
      email: identifier,
      password: password,
      portal: _selectedRole,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _navigateToDashboard(res['user']);
    } else if (res['code'] == 'PHONE_NOT_VERIFIED') {
      _showPhoneVerificationModal(res['phone'] ?? identifier);
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Invalid credentials.');
    }
  }

  // 2. Passwordless Phone OTP Login (PRD Option B: Send OTP)
  Future<void> _handleSendPhoneOtp() async {
    final phone = _emailController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.sendPhoneLoginOtp(
      phone: phone,
      portal: _selectedRole,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _otpController.clear();
      setState(() {
        _phoneOtpSent = true;
      });
      _startCooldown();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.brandTeal,
          content: Text('Login OTP dispatched! Please check your email / phone.'),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      final retryAfter = res['retryAfter'];
      if (retryAfter != null && retryAfter is int) {
        _startCooldown(retryAfter);
      }
      setState(() => _errorMessage = res['message'] ?? 'Failed to send OTP.');
    }
  }

  // 3. Passwordless Phone OTP Login (PRD Option B: Verify & Login)
  Future<void> _handleVerifyPhoneOtp() async {
    final phone = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (phone.isEmpty || otp.length < 4) {
      setState(() => _errorMessage = 'Please enter phone and 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.verifyPhoneLoginOtp(
      phone: phone,
      otp: otp,
      portal: _selectedRole,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _navigateToDashboard(res['user']);
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Invalid or expired OTP.');
    }
  }

  void _showPhoneVerificationModal(String phone) {
    final verifyOtpCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.phonelink_lock, color: AppTheme.brandTeal),
            SizedBox(width: 8),
            Text('Verify Phone Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your phone ($phone) is not verified yet. Enter the OTP sent:'),
            const SizedBox(height: 14),
            TextField(
              controller: verifyOtpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
              decoration: const InputDecoration(hintText: '------', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final otp = verifyOtpCtrl.text.trim();
              if (otp.length < 4) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final res = await ApiService.verifyPhone(phone: phone, otp: otp);
              setState(() => _isLoading = false);
              if (res['success'] == true) {
                _navigateToDashboard(res['user']);
              } else {
                setState(() => _errorMessage = res['message'] ?? 'OTP verification failed');
              }
            },
            child: const Text('Verify & Activate'),
          ),
        ],
      ),
    );
  }

  void _promptAdminPasskeyBeforeSwitch() {
    final keyCtrl = TextEditingController();
    bool obscurePasskey = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Faculty Access Gate', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Only authorized teachers (Muskan & Zoya Mam) can access this section. Enter passkey:',
                style: TextStyle(fontSize: 12.5, color: AppTheme.inkSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                obscureText: obscurePasskey,
                decoration: InputDecoration(
                  hintText: 'Enter Admin Passkey (e.g. ZM@2026)',
                  prefixIcon: const Icon(Icons.key, color: AppTheme.brandTeal),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePasskey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.brandTeal,
                    ),
                    tooltip: obscurePasskey ? 'Show passkey' : 'Hide passkey',
                    splashRadius: 20,
                    onPressed: () => setDialogState(() => obscurePasskey = !obscurePasskey),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandTeal, foregroundColor: Colors.white),
              onPressed: () async {
                final key = keyCtrl.text.trim();
                final isValid = await ApiService.verifyAdminPasskey(key);
                if (isValid) {
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  setState(() => _selectedRole = 'admin');
                } else {
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('⛔ Access Denied! Invalid faculty security passkey.'),
                    ),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerSettings() {
    final urlController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Backend API URL', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify your backend address (e.g. for Wi-Fi use local PC IP):',
              style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'http://192.168.1.3:5000/api'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ApiService.updateBaseUrl(urlController.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server URL updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.paperDark : AppTheme.mintBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // TOP APP HEADER BAR (Settings + Theme Toggle)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.brandTeal.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ZM TUITION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppTheme.brandTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: AppTheme.themeModeNotifier,
                              builder: (context, mode, _) {
                                final isCurrentlyDark = mode == ThemeMode.dark;
                                return IconButton(
                                  icon: Icon(
                                    isCurrentlyDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    color: AppTheme.brandTeal,
                                    size: 20,
                                  ),
                                  tooltip: 'Toggle Theme',
                                  onPressed: () => AppTheme.toggleTheme(),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppTheme.brandTeal, size: 20),
                              tooltip: 'Server Settings',
                              onPressed: _showServerSettings,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // TOP HERO CARD (Inspired by Image 1 Header & Plant Illustration)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
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
                        // Decorative organic curves (Image 1 style)
                        Positioned(
                          top: -30,
                          left: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFF136864).withAlpha(140),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 40,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF26A69A).withAlpha(90),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Right Side Education / Study Hub Emblem (matching plant pot from Image 1)
                        Positioned(
                          right: 18,
                          bottom: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stylized 3D pot / graduation badge
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(40),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 38,
                                    color: AppTheme.brandTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Zoya & Muskan',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Left Side Greeting (Exact Image 1 layout)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 42, 110, 42),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hello!',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome to ZM Tuition',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Colors.white.withAlpha(220),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // MAIN WHITE CARD SHEET (Pill Inputs & Login Form - Exact Image 1 Style)
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
                        // "Login" Title (Deep Teal)
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandTeal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Role / Portal Badge or Guarded Selector
                        if (widget.isPortalLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'admin'
                                  ? const Color(0xFFFEF2F2)
                                  : (isDark ? AppTheme.cardDarkElevated : const Color(0xFFEEF5F3)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedRole == 'admin'
                                    ? const Color(0xFFFCA5A5)
                                    : AppTheme.brandTeal.withAlpha(50),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedRole == 'admin' ? Icons.security_rounded : Icons.person_rounded,
                                  color: _selectedRole == 'admin' ? const Color(0xFFDC2626) : AppTheme.brandTeal,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedRole == 'admin'
                                        ? 'Faculty Portal (Muskan & Zoya Mam)'
                                        : 'Student Portal (Class 9th-12th)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: _selectedRole == 'admin' ? const Color(0xFF991B1B) : AppTheme.brandTeal,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          )
                        else
                          // Role Selector (Pill Styled with Admin Passkey Protection)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFEEF5F3),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedRole = 'student'),
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == 'student'
                                            ? (isDark ? AppTheme.cardDark : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: _selectedRole == 'student'
                                            ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4)]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Student',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _selectedRole == 'student' ? AppTheme.brandTeal : AppTheme.inkSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _promptAdminPasskeyBeforeSwitch();
                                    },
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == 'admin'
                                            ? (isDark ? AppTheme.cardDark : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: _selectedRole == 'admin'
                                            ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4)]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock_rounded,
                                              size: 13,
                                              color: _selectedRole == 'admin' ? AppTheme.brandTeal : AppTheme.inkSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Faculty / Admin',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: _selectedRole == 'admin' ? AppTheme.brandTeal : AppTheme.inkSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 18),

                        // Pill Field 1: Email or Phone
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Enter your email or phone number',
                            labelText: 'Email or Phone',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF6B8A87)),
                            suffixIcon: _emailController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B8A87)),
                                    tooltip: 'Clear input',
                                    splashRadius: 18,
                                    onPressed: () {
                                      _emailController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Pill Field 2: Password
                        CustomPasswordField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          onSubmitted: (_) => _handlePasswordLogin(),
                        ),

                        // Forgot Password Link (Right Aligned in Teal)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.brandTeal,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),

                        if (_errorMessage != null) ...[
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
                          const SizedBox(height: 10),
                        ],

                        const SizedBox(height: 6),

                        // Pill Primary Button: Login (Deep Teal Solid - Exact Image 1 Style)
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
                            onPressed: _isLoading ? null : _handlePasswordLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider: "Or login with" (Exact Image 1 Style)
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? AppTheme.lineDark : const Color(0xFFDCE8E5))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Or login with',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? AppTheme.inkSecondaryDark : const Color(0xFF88A5A2),
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDark ? AppTheme.lineDark : const Color(0xFFDCE8E5))),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Social / Fast Login Circular Buttons (Image 1 Style)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Phone OTP fast login button
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _loginType = _loginType == 'password' ? 'otp' : 'password';
                                });
                                if (_loginType == 'otp') {
                                  _handleSendPhoneOtp();
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE0EBE8)),
                                ),
                                child: const Icon(Icons.sms_outlined, color: AppTheme.brandTeal, size: 22),
                              ),
                            ),
                            const SizedBox(width: 18),

                            // 2. Google Icon Pill
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Google Sign-in available for verified tuition emails.')),
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE0EBE8)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFEA4335),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),

                            // 3. Apple / Center ID Icon Pill
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Center ID authentication active.')),
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F7F6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE0EBE8)),
                                ),
                                child: const Icon(Icons.apple, color: Colors.black, size: 24),
                              ),
                            ),
                          ],
                        ),

                        // Inline OTP verification card if OTP mode is active
                        if (_phoneOtpSent) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.brandTealLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Enter 6-Digit Code',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.brandTeal),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 8),
                                  decoration: const InputDecoration(counterText: '', hintText: '------'),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandTeal,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: _isLoading ? null : _handleVerifyPhoneOtp,
                                  child: const Text('Verify & Login'),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Footer: "Don't have account? Sign Up" (Exact Image 1 Style)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have account? ",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? AppTheme.inkSecondaryDark : const Color(0xFF6A8784),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 13.5,
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
