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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AppData _appData = AppData();

  @override
  void initState() {
    super.initState();
    _appData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _appData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _scrollToRolePortals() {
    _scrollController.animateTo(
      380,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showRoleSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Role / Access Portal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              const Text(AppData.instituteName, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),

              // Student Login
              _buildRolePortalCard(
                context,
                title: 'Student Learning Portal',
                subtitle: 'Attendance, Study Notes, PDF Downloads & Live Tests',
                icon: Icons.school_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'student')));
                },
              ),
              const SizedBox(height: 12),

              // Teacher Portal
              _buildRolePortalCard(
                context,
                title: 'Teacher Portal (Zoya & Muskan)',
                subtitle: 'Class Notes Uploader, Attendance & Fee Receipts',
                icon: Icons.psychology_rounded,
                color: const Color(0xFF5B5FC7),
                bgColor: const Color(0xFFEEEDFE),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'admin')));
                },
              ),
              const SizedBox(height: 12),

              // Admin Console
              _buildRolePortalCard(
                context,
                title: 'Admin Control Console',
                subtitle: 'System Health, Credentials Assignment & Security Audit Logs',
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFE1F5EE),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'admin')));
                },
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New Student? ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                    child: const Text('Register Here', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRolePortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ZM Tuition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                Text(AppData.instituteName, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_appData.isHindi ? Icons.language : Icons.translate, color: const Color(0xFF2563EB)),
            onPressed: () => _appData.toggleLanguage(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _showRoleSelectionSheet(context),
            child: const Text('Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // HERO HEADER SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF5B5FC7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ZM Tuition Portal • Old Bus Stand, Nakur',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Empowering Next-Gen Commerce & Science Learners',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.25),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'Smart Tuition Management App for Class 9th–12th. Automated attendance, instant PDF study notes, fee receipts, and proctored online test series.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search courses, formula sheets, notes, or fee status...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB)),
                          onPressed: () {
                            if (_searchController.text.trim().isNotEmpty) {
                              _showRoleSelectionSheet(context);
                            }
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _showRoleSelectionSheet(context),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Direct CTAs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _scrollToRolePortals,
                        icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                        label: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () => _showRoleSelectionSheet(context),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Login Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ROLE PORTAL SELECTORS
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.widgets_rounded, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Role Portal Selectors',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Select your user role to access personalized portal dashboards.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),

                  // Cards Grid / Column
                  _buildRolePortalCard(
                    context,
                    title: '1. Student Learning Portal',
                    subtitle: 'Day-by-day attendance tracking, study PDF downloads, homework submission & live tests.',
                    icon: Icons.school_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: Colors.white,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'student'))),
                  ),
                  const SizedBox(height: 12),

                  _buildRolePortalCard(
                    context,
                    title: '2. Teacher Portal (Zoya & Muskan)',
                    subtitle: 'Classroom uploader, broadcast notices, daily attendance register & WhatsApp fee reminders.',
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFF5B5FC7),
                    bgColor: Colors.white,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'admin'))),
                  ),
                  const SizedBox(height: 12),

                  _buildRolePortalCard(
                    context,
                    title: '3. Admin Control Console',
                    subtitle: 'System health metrics, role management table, credentials assignment & security audit logs.',
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFF10B981),
                    bgColor: Colors.white,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRole: 'admin'))),
                  ),
                ],
              ),
            ),

            // KEY OFFERINGS GRID & INSTITUTIONAL METRICS
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFF5B5FC7)),
                      SizedBox(width: 8),
                      Text(
                        'Key Offerings & Catalog',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Offerings Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildOfferingCard('Commerce Stream', 'Class 11th & 12th Commerce\nAccountancy & Economics by Zoya', Icons.menu_book, const Color(0xFF2563EB)),
                      _buildOfferingCard('Science & Math', 'Class 9th to 12th Science\nPhysics, Chem & Math by Muskan', Icons.science, const Color(0xFF5B5FC7)),
                      _buildOfferingCard('Proctored Tests', 'Unit tests, mock exams & auto scorecards', Icons.quiz, const Color(0xFF10B981)),
                      _buildOfferingCard('PDF Notes Vault', 'High resolution notes & formula sheets', Icons.picture_as_pdf, const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Institutional Metrics Header
                  const Text('Institutional Metrics & Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _buildMetricTile('500+', 'Active Students', Icons.groups_rounded, const Color(0xFF2563EB))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricTile('98%', 'Board Pass Rate', Icons.verified_rounded, const Color(0xFF10B981))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricTile('10+ Yrs', 'Coaching Excellence', Icons.emoji_events_rounded, const Color(0xFF5B5FC7))),
                    ],
                  ),
                ],
              ),
            ),

            // FOOTER
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF0F172A),
              width: double.infinity,
              child: const Column(
                children: [
                  Text('ZM Tuition Management Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Old Bus Stand, Nakur • Zoya & Muskan Coaching', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  SizedBox(height: 10),
                  Text('© 2026 ZM Tuition. All rights reserved.', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
