import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import '../auth/login_screen.dart';
import 'live_test_screen.dart';
import '../admin/upload_notes_screen.dart';
import '../admin/all_students_screen.dart';
import '../common/notices_screen.dart';
import '../common/notifications_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  final AppData _appData = AppData();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _appData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _appData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final student = _appData.currentUser;
    final isDark = _appData.isDarkMode;

    final studentNotes = _appData.notes.where((n) => n.className == student?.assignedClass || n.className == 'All').toList();
    final filteredNotes = studentNotes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.subject.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final studentAttendance = _appData.attendanceRecords.where((r) => r.studentId == student?.id).toList();
    final presentCount = studentAttendance.where((r) => r.status == 'Present').length;
    final totalAttendanceCount = studentAttendance.length;
    final attendancePercentage = totalAttendanceCount > 0 ? ((presentCount / totalAttendanceCount) * 100).toStringAsFixed(0) : '85';

    final studentFees = _appData.fees.where((f) => f.studentId == student?.id).toList();
    final studentTests = _appData.testSeriesList.where((t) => t.className == student?.assignedClass || t.className == 'All').toList();

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ZM Tuition Management App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Learn  •  Attend  •  Pay  •  Grow', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFA5B4FC) : Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${_appData.notifications.length}'),
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              _appData.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),

      // Navigation Drawer (PRD Screen 18 Alignment)
      drawer: Drawer(
        backgroundColor: cardColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
              ),
              accountName: Text(student?.name ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text(student?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF4F46E5), size: 36),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Dashboard', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF4F46E5)),
                    title: Text('My Profile', style: TextStyle(color: textColor)),
                    onTap: () { setState(() => _currentIndex = 4); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Attendance', style: TextStyle(color: textColor)),
                    onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Fees', style: TextStyle(color: textColor)),
                    onTap: () { setState(() => _currentIndex = 3); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Notes & Study Material', style: TextStyle(color: textColor)),
                    onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.campaign_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Notices', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.quiz_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Live Tests', style: TextStyle(color: textColor)),
                    onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
                  ),
                  const Divider(),
                  // System Dark Mode Switch
                  SwitchListTile(
                    title: Text('SYSTEM DARK MODE', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: const Color(0xFF4F46E5)),
                    value: isDark,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => _appData.toggleDarkMode(val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Body with Smooth Scrolling
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: const Color(0xFF4F46E5), size: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${student?.name ?? "Ayesha"} 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${student?.assignedClass ?? "Class 10th"} • Roll No: ${student?.rollNo ?? "01"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Performance Insights (PRD Chart Visualizer)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('STUDENT PERFORMANCE INSIGHTS', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Attendance', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Attendance Trend Chart Graphic
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: AttendanceTrendPainter(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Aug', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('Sep', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('Oct', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('Nov', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Feature Navigation Cards Grid (PRD Screen 5)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildDashboardCard('My Profile', Icons.person_outline, const Color(0xFF3B82F6), () {
                    _showProfileDialog(context, student, cardColor, textColor);
                  }, cardColor, textColor),
                  _buildDashboardCard('My Attendance', Icons.calendar_today_outlined, const Color(0xFF10B981), () {
                    _showAttendanceDialog(context, studentAttendance, attendancePercentage, cardColor, textColor);
                  }, cardColor, textColor),
                  _buildDashboardCard('My Fees', Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B), () {
                    _showFeesDialog(context, studentFees, cardColor, textColor);
                  }, cardColor, textColor),
                  _buildDashboardCard('Notes & Study', Icons.menu_book_outlined, const Color(0xFFEC4899), () {
                    _showNotesDialog(context, filteredNotes, cardColor, textColor);
                  }, cardColor, textColor),
                  _buildDashboardCard('Notices', Icons.campaign_outlined, const Color(0xFF8B5CF6), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen()));
                  }, cardColor, textColor),
                  _buildDashboardCard('Live Tests', Icons.quiz_outlined, const Color(0xFFEF4444), () {
                    _showLiveTestsDialog(context, studentTests, cardColor, textColor);
                  }, cardColor, textColor),
                ],
              ),
              const SizedBox(height: 20),

              // System Dark Mode Toggle Widget Bar (PRD Screen 5)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isDark ? Icons.dark_mode : Icons.wb_sunny_outlined, color: const Color(0xFF4F46E5)),
                        const SizedBox(width: 12),
                        Text('SYSTEM DARK MODE', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) => _appData.toggleDarkMode(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, Color color, VoidCallback onTap, Color cardColor, Color textColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, dynamic student, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Student Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${student?.name}', style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Class: ${student?.assignedClass}', style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Roll Number: ${student?.rollNo}', style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Email: ${student?.email}', style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Phone: ${student?.phone}', style: TextStyle(color: textColor, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAttendanceDialog(BuildContext context, List studentAttendance, String rate, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Attendance Overview ($rate%)', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: studentAttendance.isEmpty
              ? const Text('No attendance logs found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: studentAttendance.length,
                  itemBuilder: (context, idx) {
                    final rec = studentAttendance[idx];
                    return ListTile(
                      leading: Icon(rec.status == 'Present' ? Icons.check_circle : Icons.cancel, color: rec.status == 'Present' ? Colors.green : Colors.red),
                      title: Text('Date: ${rec.date.toLocal().toString().split(' ')[0]}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: ${rec.status}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFeesDialog(BuildContext context, List studentFees, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Fees Ledger', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: studentFees.isEmpty
              ? const Text('No fee records found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: studentFees.length,
                  itemBuilder: (context, idx) {
                    final fee = studentFees[idx];
                    return ListTile(
                      title: Text(fee.month, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text('Amount: ₹${fee.amount.toStringAsFixed(0)} • Date: ${fee.date}'),
                      trailing: Chip(
                        label: Text(fee.isPaid ? 'PAID' : 'PENDING'),
                        backgroundColor: fee.isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                        labelStyle: TextStyle(color: fee.isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showNotesDialog(BuildContext context, List notes, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Notes & Study Material', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: notes.isEmpty
              ? const Text('No notes published yet')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notes.length,
                  itemBuilder: (context, idx) {
                    final n = notes[idx];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(n.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('File: ${n.fileName} (${n.fileSize})'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLiveTestsDialog(BuildContext context, List tests, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Live Proctored Tests', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: tests.isEmpty
              ? const Text('No active test series')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tests.length,
                  itemBuilder: (context, idx) {
                    final t = tests[idx];
                    return ListTile(
                      title: Text(t.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Duration: ${t.durationMinutes} mins • Marks: ${t.totalMarks}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LiveTestScreen(testSeries: t)),
                          );
                        },
                        child: const Text('Start Test'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

// Attendance Trend Line Painter for Chart
class AttendanceTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.65, size.height * 0.55),
      Offset(size.width, size.height * 0.15),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    for (var p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
