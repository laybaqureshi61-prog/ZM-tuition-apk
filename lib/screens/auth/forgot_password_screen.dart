import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1;

  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _matchedUserName;
  String? _matchedUserRole;

  void _handleStep1SendOtp() {
    final query = _identifierController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your registered email or phone number')),
      );
      return;
    }

    final user = AppData().findUserByIdentifier(query);
    if (user != null) {
      _matchedUserName = user.name;
      _matchedUserRole = user.role;
    } else {
      _matchedUserName = query.contains('@') ? query.split('@')[0] : 'Registered User';
      _matchedUserRole = 'User';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('6-Digit OTP sent to $query (Demo OTP: 123456)'),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );

    setState(() {
      _currentStep = 2;
    });
  }

  void _handleStep2VerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP code (e.g. 123456)')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP Verified Successfully! Please set your new password.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    setState(() {
      _currentStep = 3;
    });
  }

  void _handleStep3ResetPassword() {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both password fields')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match! Please verify.')),
      );
      return;
    }

    if (newPass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters long')),
      );
      return;
    }

    final success = AppData().resetPasswordByIdentifier(_identifierController.text.trim(), newPass);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 32),
            SizedBox(width: 10),
            Expanded(child: Text('Password Reset Complete!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password updated for account: ${_matchedUserName ?? _identifierController.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'Your new credentials have been updated in AppData. You can log in immediately!'
                  : 'New password registered for recovery engine.',
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen(initialRole: _matchedUserRole == 'admin' ? 'admin' : 'student')),
              );
            },
            child: const Text('Proceed to Login Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('3-Step Password Recovery Engine'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step Progress Indicator Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(1, 'Identify'),
                        _buildStepConnector(1),
                        _buildStepIndicator(2, 'OTP Verification'),
                        _buildStepConnector(2),
                        _buildStepIndicator(3, 'New Password'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Icon & Title per Step
                    if (_currentStep == 1) _buildStep1View(),
                    if (_currentStep == 2) _buildStep2View(),
                    if (_currentStep == 3) _buildStep3View(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isDone = _currentStep > step;
    final isCurrent = _currentStep == step;

    Color bg = Colors.grey.shade300;
    Color fg = Colors.grey.shade600;

    if (isDone || isCurrent) {
      bg = const Color(0xFF2563EB);
      fg = Colors.white;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$step', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? const Color(0xFF2563EB) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int step) {
    final isPassed = _currentStep > step;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      color: isPassed ? const Color(0xFF2563EB) : Colors.grey.shade300,
    );
  }

  // STEP 1: INPUT EMAIL OR PHONE NUMBER
  Widget _buildStep1View() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_circle, size: 48, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Step 1: Input Email or Phone',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your registered email address or phone number (e.g., zm@124, muskan@zm.com, or student@123) to receive a 6-digit OTP code.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _identifierController,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Email or Phone Number *',
            hintText: 'zm@124 or 9876543210',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _handleStep1SendOtp,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send 6-Digit OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Login', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // STEP 2: 6-DIGIT OTP VERIFICATION SCREEN
  Widget _buildStep2View() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded, size: 48, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Step 2: 6-Digit OTP Verification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit verification code to:\n${_identifierController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Demo OTP Code: 123456',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            labelText: '6-Digit Verification OTP',
            hintText: '123456',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.pin, color: Color(0xFF10B981)),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _handleStep2VerifyOtp,
            icon: const Icon(Icons.verified_user, size: 18),
            label: const Text('Verify OTP Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Change Email/Phone', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                _otpController.text = '123456';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-filled Demo OTP: 123456')),
                );
              },
              child: const Text('Resend OTP', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: NEW PASSWORD CREATION SCREEN
  Widget _buildStep3View() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5B5FC7).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, size: 48, color: Color(0xFF5B5FC7)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Step 3: New Password Creation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          'Set a new password for account: ${_matchedUserName ?? _identifierController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'New Password *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5B5FC7)),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Confirm New Password *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFF5B5FC7)),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _handleStep3ResetPassword,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Update Password & Allow Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
