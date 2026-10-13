import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../common/settings_screen.dart';
import 'student_attendance_screen.dart';
import 'student_notes_screen.dart';
import 'student_notices_screen.dart';
import 'student_fees_screen.dart';
import 'student_classroom_screen.dart';
import 'student_live_tests_screen.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _feeData;
  List<dynamic> _notes = [];
  List<dynamic> _notices = [];
  List<dynamic> _tests = [];

  @override
  void initState() {
    super.initState();
    _loadStudentDashboardData();
  }

  Future<void> _loadStudentDashboardData() async {
    setState(() => _isLoading = true);
    final att = await ApiService.getMyAttendance();
    final fee = await ApiService.getMyFees();
    final notesList = await ApiService.getNotes();
    final noticesList = await ApiService.getNotices();
    final testsList = await ApiService.getTests();

    if (!mounted) return;
    setState(() {
      _attendanceData = att;
      _feeData = fee;
      _notes = notesList;
      _notices = noticesList;
      _tests = testsList;
      _isLoading = false;
    });
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out of your student portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.user.name.isNotEmpty ? widget.user.name : 'Student';
    final rollNo = widget.user.rollNo ?? 'ZM-101';
    final batch = widget.user.batch ?? 'Class 10 (Maths & Science)';
    final email = widget.user.email;
    final phone = widget.user.phone;

    final attPct = (_attendanceData?['percentage'] ?? 95) as int;
    final feeStatus = _feeData?['status'] ?? 'Due';
    final isFeePaid = feeStatus == 'Paid';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'ZM Tuition',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => AppTheme.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudentDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Student Profile Header Card (Inspired by Reference UI)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.brandTeal, Color(0xFF073836)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandTeal.withAlpha(50),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.brandBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello, $studentName! 👋',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentYellow,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Roll: $rollNo',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.inkPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                batch,
                                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 28, color: Colors.white24),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.phone_outlined, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline, size: 12, color: Colors.white),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Strict Read-Only Mode (Managed by Admin)',
                                        style: TextStyle(fontSize: 11, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Prominent Live Test Alert & Action Banner
                        if (_tests.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withAlpha(80),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => StudentLiveTestsScreen(user: widget.user)),
                                ).then((_) => _loadStudentDashboardData()),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(40),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.timer_sharp, color: Colors.white, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    '🔴 LIVE TEST AVAILABLE',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBF360C)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${_tests.length} Scheduled',
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _tests.first['title'] ?? 'Live Proctored Examination',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_tests.first['durationMinutes'] ?? 15} Mins • ${_tests.first['totalMarks'] ?? 20} Marks • Anti-Cheat AI Protected',
                                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFFBF360C),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => StudentLiveTestsScreen(user: widget.user)),
                                        ).then((_) => _loadStudentDashboardData()),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                        label: const Text('Join Test', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Quick KPI Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 650;
                            return GridView.count(
                              crossAxisCount: isWide ? 4 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: isWide ? 1.4 : 1.3,
                              children: [
                                _buildMetricCard(
                                  'My Attendance',
                                  '$attPct%',
                                  Icons.pie_chart_outline,
                                  attPct >= 85 ? AppTheme.successGreen : Colors.orange.shade700,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(user: widget.user))),
                                ),
                                _buildMetricCard(
                                  'Tuition Fee',
                                  feeStatus.toUpperCase(),
                                  isFeePaid ? Icons.check_circle_outline : Icons.error_outline,
                                  isFeePaid ? AppTheme.successGreen : AppTheme.dangerRed,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFeesScreen(user: widget.user))),
                                ),
                                _buildMetricCard(
                                  'Study Materials',
                                  '${_notes.length} PDFs',
                                  Icons.menu_book,
                                  Colors.purple.shade700,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentNotesScreen(user: widget.user))),
                                ),
                                _buildMetricCard(
                                  'Notices',
                                  '${_notices.length} Alerts',
                                  Icons.campaign_outlined,
                                  Colors.indigo,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentNoticesScreen(user: widget.user))),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // Separate Pages Navigation
                        const Text(
                          'Student Portal Modules & Pages',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.inkPrimary),
                        ),
                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;
                            return GridView.count(
                              crossAxisCount: isWide ? 3 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isWide ? 1.25 : 0.88,
                              children: [
                                _buildNavCard(
                                  title: 'My Attendance',
                                  subtitle: 'Ratio, Present & Absent history',
                                  icon: Icons.calendar_today_rounded,
                                  color: AppTheme.successGreen,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentAttendanceScreen(user: widget.user)),
                                  ),
                                ),
                                _buildNavCard(
                                  title: 'Notes & Materials',
                                  subtitle: 'Class PDFs with direct download',
                                  icon: Icons.picture_as_pdf_rounded,
                                  color: AppTheme.dangerRed,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentNotesScreen(user: widget.user)),
                                  ),
                                ),
                                _buildNavCard(
                                  title: 'Notice Board',
                                  subtitle: 'Important tuition announcements',
                                  icon: Icons.campaign_rounded,
                                  color: Colors.indigo,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentNoticesScreen(user: widget.user)),
                                  ),
                                ),
                                _buildNavCard(
                                  title: 'My Tuition Fees',
                                  subtitle: 'View monthly fee amount & status',
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: Colors.teal,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentFeesScreen(user: widget.user)),
                                  ),
                                ),
                                _buildNavCard(
                                  title: 'Live Proctored Tests',
                                  subtitle: 'AI Camera & Anti-Cheat live exams',
                                  icon: Icons.assignment_late_rounded,
                                  color: Colors.deepOrange,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentLiveTestsScreen(user: widget.user)),
                                  ),
                                ),
                                _buildNavCard(
                                  title: 'Classroom & Batch',
                                  subtitle: 'Schedule, syllabus & faculty',
                                  icon: Icons.school_rounded,
                                  color: AppTheme.brandBlue,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentClassroomScreen(user: widget.user)),
                                  ),
                                ),
                                _buildNavCard(
                                  title: 'Settings & Profile',
                                  subtitle: 'Account info & sign out',
                                  icon: Icons.settings_rounded,
                                  color: Colors.blueGrey,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // Latest Notices Snippet
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.line),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.notifications_active, color: AppTheme.brandBlue, size: 20),
                                        SizedBox(width: 8),
                                        Text('Notice Board Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => StudentNoticesScreen(user: widget.user)),
                                      ),
                                      child: const Text('View All'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                if (_notices.isEmpty)
                                  const Text('No announcements posted yet.', style: TextStyle(color: AppTheme.inkSecondary))
                                else
                                  ..._notices.take(3).map((nt) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(fontSize: 18, color: AppTheme.brandBlue)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nt['title'] ?? 'Notice',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                nt['content'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          nt['date'] ?? '',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary),
                                        ),
                                      ],
                                    ),
                                  )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.inkSecondary),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.inkPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
