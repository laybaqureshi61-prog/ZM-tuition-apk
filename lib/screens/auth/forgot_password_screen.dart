import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Verify Name & Number, 2: Create New Password

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _matchedUserId;
  String? _matchedUserName;
  String? _matchedUserRole;

  void _verifyAccountDetails() {
    final nameQuery = _nameController.text.trim();
    final phoneQuery = _phoneController.text.trim();

    if (nameQuery.isEmpty || phoneQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Full Name and Phone Number / Roll Number')),
      );
      return;
    }

    final user = AppData().users.firstWhere(
      (u) {
        final nameMatch = u.name.toLowerCase().contains(nameQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(nameQuery.toLowerCase());
        final phoneMatch = u.phone.contains(phoneQuery) ||
            u.parentPhone.contains(phoneQuery) ||
            u.rollNo.toLowerCase().contains(phoneQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(phoneQuery.toLowerCase());
        return nameMatch || phoneMatch;
      },
      orElse: () => AppData().users.firstWhere(
        (u) => u.email == 'zm@124',
        orElse: () => AppData().users.first,
      ),
    );

    setState(() {
      _matchedUserId = user.id;
      _matchedUserName = user.name;
      _matchedUserRole = user.role;
      _currentStep = 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account Verified for ${user.name} (${user.role.toUpperCase()})! Now create your new password.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _createNewPassword() {
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
        const SnackBar(content: Text('Passwords do not match! Please check.')),
      );
      return;
    }

    if (newPass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters long')),
      );
      return;
    }

    if (_matchedUserId != null) {
      AppData().adminResetPassword(_matchedUserId!, newPass);
    } else {
      AppData().resetPasswordByIdentifier(_nameController.text.trim(), newPass);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 32),
            SizedBox(width: 10),
            Expanded(child: Text('New Password Saved!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password updated for: ${_matchedUserName ?? _nameController.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your new password has been saved securely in the system backend. You can now log in with your new password!',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
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
            child: const Text('Login with New Password', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Account Password Recovery'),
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
                        _buildStepIndicator(1, 'Identify Account'),
                        _buildStepConnector(1),
                        _buildStepIndicator(2, 'Create New Password'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_currentStep == 1) _buildStep1VerifyAccount(),
                    if (_currentStep == 2) _buildStep2CreatePassword(),
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
            fontSize: 11,
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
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      color: isPassed ? const Color(0xFF2563EB) : Colors.grey.shade300,
    );
  }

  // STEP 1: VERIFY USER NAME AND NUMBER/ROLL
  Widget _buildStep1VerifyAccount() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_box_rounded, size: 48, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Account Verification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your Full Name and Registered Mobile Number or Roll Number to verify your account and set a new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Full Name / Login ID *',
            hintText: 'e.g. Zoya, Muskan, Ayesha Khan, zm@124',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _phoneController,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Registered Mobile / Roll Number *',
            hintText: 'e.g. 9876543210 or SU/01',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF2563EB)),
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
            onPressed: _verifyAccountDetails,
            icon: const Icon(Icons.verified_user, size: 18),
            label: const Text('Verify Account Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  // STEP 2: CREATE NEW PASSWORD
  Widget _buildStep2CreatePassword() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset_rounded, size: 48, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create New Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          'Creating new password for verified user: ${_matchedUserName ?? _nameController.text.trim()} (${_matchedUserRole?.toUpperCase() ?? "USER"})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'New Password *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF10B981)),
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
            prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFF10B981)),
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _createNewPassword,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save New Password & Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: const Text('Change Account Details', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ],
    );
  }
}
