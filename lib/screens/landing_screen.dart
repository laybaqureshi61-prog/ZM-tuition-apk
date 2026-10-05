import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import '../services/app_data.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'tag': 'WELCOME TO ZM TUITION',
      'title': 'Welcome! Apni coaching ko banao smart',
      'subtitle': 'Students, attendance aur fees ka poora hisaab, ZM Tuition app me.',
      'bgColor': const Color(0xFF4F46E5),
      'icon': Icons.school,
      'badge': 'ZM Tuition • Class 9th-12th',
    },
    {
      'tag': 'ATTENDANCE & FEES',
      'title': 'Ek tap me poori class attendance',
      'subtitle': 'Day-by-day attendance lagao aur pending fees reminder WhatsApp par bhejo.',
      'bgColor': const Color(0xFF10B981),
      'icon': Icons.checklist,
      'badge': '1-Tap Daily Attendance',
    },
    {
      'tag': 'NOTES & DOWNLOADS',
      'title': 'Notes & PDF Materials without hassle',
      'subtitle': 'Upload karte hi student portal me notes live, mobile me view aur download karein.',
      'bgColor': const Color(0xFFF59E0B),
      'icon': Icons.file_present,
      'badge': 'PDF View & Download',
    },
  ];

  void _showRoleSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Aap kaun hain? / Select Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              const Text(AppData.instituteName, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),

              // Teacher / Admin Login Button
              Card(
                color: const Color(0xFFEEEDFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  title: const Text('Teacher / Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF26215C))),
                  subtitle: const Text('Zoya & Muskan • Class, Attendance & Fees', style: TextStyle(fontSize: 11, color: Color(0xFF534AB7))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4F46E5)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'admin')));
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Student / Parent Login Button
              Card(
                color: const Color(0xFFE1F5EE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0F6E56), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: const Text('Student / Parent Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF04342C))),
                  subtitle: const Text('Day-by-Day Attendance, Notes Download & Receipts', style: TextStyle(fontSize: 11, color: Color(0xFF0F6E56))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0F6E56)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'student')));
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Register Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New Student? ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                    child: const Text('Register Here', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ZM Tuition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5))),
                  TextButton(
                    onPressed: _showRoleSelectionSheet,
                    child: const Text('Skip', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Swipable Onboarding Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final item = _slides[index];
                  final Color bg = item['bgColor'] as Color;

                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Circle
                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: Icon(item['icon'] as IconData, size: 64, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['tag'] as String,
                            style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.25),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Dots & Next/Get Started Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Dots
                  Row(
                    children: List.generate(_slides.length, (idx) {
                      final isSel = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: isSel ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isSel ? slide['bgColor'] as Color : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Shuru Karein Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slide['bgColor'] as Color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _showRoleSelectionSheet();
                      }
                    },
                    icon: Icon(_currentPage == _slides.length - 1 ? Icons.login : Icons.arrow_forward),
                    label: Text(
                      _currentPage == _slides.length - 1 ? 'Shuru Karein' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
