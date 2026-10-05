import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEC4899), // Pink Background
      body: SafeArea(
        child: Column(
          children: [
            // Top Pink Banner with Yellow & White Multi-Device Illustration
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Multi-Device Illustration (White, Yellow, Pink)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Laptop Graphic
                        Container(
                          width: 240,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 18,
                                color: const Color(0xFFEC4899), // Pink top bar
                                child: const Row(
                                  children: [
                                    SizedBox(width: 8),
                                    CircleAvatar(radius: 3, backgroundColor: Color(0xFFF59E0B)), // Yellow dot
                                    SizedBox(width: 4),
                                    CircleAvatar(radius: 3, backgroundColor: Colors.white),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(width: 90, height: 8, color: const Color(0xFFF59E0B)), // Yellow accent
                                      const SizedBox(height: 6),
                                      Container(width: 140, height: 6, color: Colors.grey.shade300),
                                      const SizedBox(height: 4),
                                      Container(width: 110, height: 6, color: Colors.grey.shade300),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tablet Graphic (Yellow Border)
                        Positioned(
                          right: 10,
                          bottom: 0,
                          child: Container(
                            width: 110,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(height: 12, color: const Color(0xFFF59E0B)), // Yellow header
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(width: 50, height: 6, color: const Color(0xFFEC4899)),
                                      const SizedBox(height: 4),
                                      Container(width: 70, height: 6, color: Colors.grey.shade300),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Smartphone Graphic
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            width: 75,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEC4899), width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(height: 10, color: const Color(0xFFEC4899)),
                                const SizedBox(height: 8),
                                Container(width: 40, height: 5, color: const Color(0xFFF59E0B)),
                                const SizedBox(height: 4),
                                Container(width: 50, height: 5, color: Colors.grey.shade300),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom White & Yellow Card Section
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Welcome to zm Portal',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tuition communication and collaboration made easy',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7), // Light Yellow
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: const Text(
                            'Managed by Zoya & Muskan • v1.0.62',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Page Dots Indicator (Yellow & Pink)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 12, height: 10, decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: const Color(0xFFEC4899))),
                            const SizedBox(width: 6),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF59E0B))),
                            const SizedBox(width: 6),
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300)),
                            const SizedBox(width: 6),
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300)),
                          ],
                        ),
                      ],
                    ),

                    // SIGN IN & REGISTER Buttons (Pink & Yellow)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC4899), // Pink Button
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            },
                            child: const Text('SIGN IN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706), // Yellow / Amber Text
                              side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                            },
                            child: const Text('NEW STUDENT REGISTRATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
