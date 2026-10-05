import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';
import 'signup_screen.dart';
import 'pending_approval_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;

  const LoginScreen({super.key, this.initialRole = 'student'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _selectedRole;
  final AppData _appData = AppData();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _setCredentialsForRole(_selectedRole);
  }

  void _setCredentialsForRole(String role) {
    if (role == 'admin') {
      _emailController.text = 'zm@124'; // Zoya (Admin 1) or muskan@zm.com for Muskan
      _passwordController.text = '12345678';
    } else {
      _emailController.text = 'student@123';
      _passwordController.text = '123456789';
    }
  }

  void _executeLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final success = _appData.login(email, password, _selectedRole);
    if (success) {
      final user = _appData.currentUser;
      if (user?.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        if (user?.status == 'approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials or role selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Login (Zoya & Muskan)' : 'Student Login'),
        backgroundColor: const Color(0xFF4F46E5),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.school,
                        size: 40,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAdmin ? 'Admin Portal Login' : 'Student Login',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdmin ? 'Zoya (Admin 1) or Muskan (Admin 2)' : 'Enter your registered student credentials',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Role Segmented Toggle
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.person)),
                        ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings)),
                      ],
                      selected: {_selectedRole},
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected) ? const Color(0xFF4F46E5) : Colors.grey.shade100,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black87,
                        ),
                      ),
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                          _setCredentialsForRole(_selectedRole);
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Admin Quick Switcher hint
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _emailController.text = 'zm@124';
                                  _passwordController.text = '12345678';
                                });
                              },
                              child: const Text('Zoya (Admin 1)', style: TextStyle(fontSize: 11)),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _emailController.text = 'muskan@zm.com';
                                  _passwordController.text = '12345678';
                                });
                              },
                              child: const Text('Muskan (Admin 2)', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Email / User ID',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4F46E5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _executeLogin,
                        child: const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                          },
                          child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        if (_selectedRole == 'student')
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                            },
                            child: const Text('Register Here', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
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
