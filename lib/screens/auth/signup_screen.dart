import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import 'pending_approval_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _rollController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedClass = AppData.allClasses.first;
  final AppData _appData = AppData();

  void _signup() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*)')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text && _confirmPasswordController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    final success = _appData.signupStudent(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      rollNo: _rollController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success) {
      _appData.users.last.assignedClass = _selectedClass;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already registered. Try logging in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1, size: 40, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(height: 12),
                    const Text('Student Registration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    const Text('Create an account for ZM Tuition Portal', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4F46E5))),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(labelText: 'Email Address *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF4F46E5))),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF4F46E5))),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Class / Course *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF4F46E5)),
                      ),
                      items: AppData.allClasses.map((cls) => DropdownMenuItem(value: cls, child: Text(cls))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClass = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _signup,
                        child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
