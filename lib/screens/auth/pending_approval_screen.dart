import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import '../student/student_dashboard.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData();
    final user = appData.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB), // Soft Yellow Tint
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC4899), // Pink
        title: const Text('Approval Status - zm Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              appData.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7), // Light Yellow
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, size: 60, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Account Pending Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Text(
                    'Hello ${user?.name ?? "Student"}, your account is currently pending review by Admin teachers (Zoya / Muskan). Once approved, you will get access to live test series, study notes, and attendance.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        if (user?.status == 'approved') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Status is still Pending. Please wait for Zoya / Muskan to approve.')),
                          );
                        }
                      },
                      child: const Text('Check Approval Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      appData.logout();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Back to Login', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
