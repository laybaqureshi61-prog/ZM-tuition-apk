import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/app_data.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import '../common/pdf_document_viewer.dart';
import '../common/classroom_hub_screen.dart';
import 'live_test_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AppData _appData = AppData();
  int _selectedNavTab =
      0; // 0: Overview, 1: Attendance, 2: Notes/E-Books, 3: Fees, 4: Security
  String _notesSearchQuery = '';

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _appData.addListener(_onDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowNoticePopup();
    });
  }

  void _checkAndShowNoticePopup() {
    if (_appData.notices.isNotEmpty && mounted) {
      final notice = _appData.notices.first;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.campaign, color: Color(0xFF4F46E5), size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Notice Announcement',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                      'Category: ${notice.category} • Date: ${notice.date}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5))),
                ),
                const SizedBox(height: 12),
                Text(notice.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(notice.description,
                    style: const TextStyle(
                        fontSize: 13, height: 1.4, color: Colors.black87)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got It!'),
              ),
            ],
          );
        },
      );
    }
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

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    // Filtered Notes
    final studentNotes = _appData.notes.where((n) {
      if (n.className != student?.assignedClass && n.className != 'All')
        return false;
      final q = _notesSearchQuery.toLowerCase();
      return n.title.toLowerCase().contains(q) ||
          n.subject.toLowerCase().contains(q);
    }).toList();

    // Attendance Calculations for Selected Month
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    int presentDays = 0;
    int absentDays = 0;
    int leaveDays = 0;
    int lateDays = 0;
    int holidayDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final rec = _appData.attendanceRecords.firstWhere(
        (r) =>
            r.studentId == student?.id &&
            AppData.formatLocalDate(r.date) == dateStr,
        orElse: () => AttendanceRecord(
          studentId: '',
          studentName: '',
          className: '',
          date: DateTime.now(),
          status: '',
          markedBy: '',
        ),
      );

      if (rec.status == 'Present') presentDays++;
      if (rec.status == 'Absent') absentDays++;
      if (rec.status == 'Leave') leaveDays++;
      if (rec.status == 'Late') lateDays++;
      if (rec.status == 'Holiday') holidayDays++;
    }

    final totalTracked = presentDays + absentDays + leaveDays + lateDays;
    final attendancePercent = totalTracked > 0
        ? ((presentDays + (lateDays * 0.5)) / totalTracked * 100)
        : 92.5;

    // Fees Ledger for Student
    final studentFees =
        _appData.fees.where((f) => f.studentId == student?.id).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5), // Indigo Header
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.school, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student?.name ?? "Student Portal"}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  '${student?.assignedClass ?? "Class 10th"} • ${AppData.instituteName}',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_appData.isHindi ? Icons.language : Icons.translate,
                color: Colors.white),
            onPressed: () => _appData.toggleLanguage(),
          ),
          IconButton(
            icon: Badge(
              label: Text('${_appData.notifications.length}'),
              child:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _appData.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),

      // Drawer Sidebar Navigation matching Edu-Care Layout
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF4F46E5), size: 36),
              ),
              accountName: Text(student?.name ?? 'Student Name',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(
                  '${student?.assignedClass} • Roll No: ${student?.rollNo}'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF4F46E5)),
              title: const Text('Dashboard Overview',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedNavTab == 0,
              onTap: () {
                setState(() => _selectedNavTab = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
              title: const Text('Day-by-Day Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedNavTab == 1,
              onTap: () {
                setState(() => _selectedNavTab = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.import_contacts, color: Color(0xFFF59E0B)),
              title: const Text('Study Notes & E-Books',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedNavTab == 2,
              onTap: () {
                setState(() => _selectedNavTab = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Color(0xFFE11D48)),
              title: const Text('ZM Classroom Portal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClassroomHubScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet,
                  color: Color(0xFF8B5CF6)),
              title: const Text('Fees & Receipts',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedNavTab == 3,
              onTap: () {
                setState(() => _selectedNavTab = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Color(0xFFEC4899)),
              title: const Text('Security & Password',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _selectedNavTab == 4,
              onTap: () {
                setState(() => _selectedNavTab = 4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Segment Pills
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildNavPill(0, 'Dashboard', Icons.dashboard),
                    _buildNavPill(
                        1, 'Attendance & Daily Logs', Icons.calendar_month),
                    _buildNavPill(2, 'Notes & Downloads', Icons.menu_book),
                    _buildNavPill(3, 'Fees Ledger', Icons.receipt_long),
                    _buildNavPill(4, 'Password Settings', Icons.lock),
                  ],
                ),
              ),
            ),

            // Main Dashboard Body Based on Selected Tab
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedNavTab == 0)
                      _buildOverviewTab(
                          student,
                          attendancePercent,
                          presentDays,
                          absentDays,
                          leaveDays,
                          studentNotes,
                          studentFees,
                          cardColor,
                          textColor),
                    if (_selectedNavTab == 1)
                      _buildAttendanceCalendarTab(
                          student,
                          daysInMonth,
                          presentDays,
                          absentDays,
                          leaveDays,
                          lateDays,
                          attendancePercent,
                          cardColor,
                          textColor),
                    if (_selectedNavTab == 2)
                      _buildStudyNotesCardsTab(
                          studentNotes, cardColor, textColor),
                    if (_selectedNavTab == 3)
                      _buildFeesLedgerTab(studentFees, cardColor, textColor),
                    if (_selectedNavTab == 4)
                      _buildSecuritySettingsTab(cardColor, textColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavPill(int index, String label, IconData icon) {
    final isSel = _selectedNavTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        selected: isSel,
        showCheckmark: false,
        avatar: Icon(icon,
            size: 16, color: isSel ? Colors.white : const Color(0xFF4F46E5)),
        label: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSel ? Colors.white : const Color(0xFF1E293B))),
        selectedColor: const Color(0xFF4F46E5),
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => setState(() => _selectedNavTab = index),
      ),
    );
  }

  // ================= TAB 0: OVERVIEW =================
  Widget _buildOverviewTab(
      UserModel? student,
      double attendancePercent,
      int present,
      int absent,
      int leave,
      List<NoteModel> notes,
      List<FeeModel> fees,
      Color cardColor,
      Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Greeting Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF4F46E5), size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${student?.name ?? "Student"}! 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student?.assignedClass} • Roll No: ${student?.rollNo}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Text(
                      AppData.instituteName,
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Latest Notice Announcement Banner
        if (_appData.notices.isNotEmpty) ...[
          Card(
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.indigo.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.campaign, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text('Latest Notice from Admin',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF4F46E5))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_appData.notices.first.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(_appData.notices.first.description,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Attendance Donut Chart & Progress Cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: CircularProgressIndicator(
                              value: attendancePercent / 100,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade200,
                              color: attendancePercent >= 75
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          Text('${attendancePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('Total Attendance %',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          attendancePercent >= 75 ? '92.5% Good' : 'Low (<75%)',
                          style: TextStyle(
                              color: attendancePercent >= 75
                                  ? const Color(0xFF10B981)
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _buildStatCard(
                      'Present Days',
                      '$present Days',
                      Icons.check_circle,
                      const Color(0xFF10B981),
                      cardColor,
                      textColor),
                  const SizedBox(height: 8),
                  _buildStatCard('Absent Days', '$absent Days', Icons.cancel,
                      const Color(0xFFEF4444), cardColor, textColor),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Quick Access ZM Classroom Portal Card
        InkWell(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ClassroomHubScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFE11D48).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Open ZM Classroom Portal',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                          'Course Work, Resources, Homework, Results & Quizzes',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Study Notes Quick Preview Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Notes & Materials',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            TextButton(
              onPressed: () => setState(() => _selectedNavTab = 2),
              child: const Text('View All Notes'),
            ),
          ],
        ),
        ...notes.take(2).map((n) => _buildNoteCard(n, cardColor, textColor)),
      ],
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color col,
      Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: col, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(val,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: DAY-BY-DAY ATTENDANCE & COMPACT DAILY ROWS =================
  Widget _buildAttendanceCalendarTab(
      UserModel? student,
      int daysInMonth,
      int present,
      int absent,
      int leave,
      int lateDays,
      double pct,
      Color cardColor,
      Color textColor) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Attendance % Summary Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pct >= 75 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: pct >= 75
                        ? Colors.green.shade300
                        : Colors.red.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Attendance Percentage',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                      Text('${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: pct >= 75
                                  ? Colors.green.shade900
                                  : Colors.red.shade900)),
                    ],
                  ),
                  Chip(
                    label: Text(pct >= 75 ? 'GOOD (≥75%)' : 'WARNING (<75%)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                    backgroundColor: pct >= 75
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Attendance Logs',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 14),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 1) {
                            _selectedMonth = 12;
                            _selectedYear--;
                          } else {
                            _selectedMonth--;
                          }
                        });
                      },
                    ),
                    Text('$_selectedMonth/$_selectedYear',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: () {
                        setState(() {
                          if (_selectedMonth == 12) {
                            _selectedMonth = 1;
                            _selectedYear++;
                          } else {
                            _selectedMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttendanceBadge('Present', '$present', Colors.green),
                _buildAttendanceBadge('Absent', '$absent', Colors.red),
                _buildAttendanceBadge('Leave', '$leave', Colors.blue),
                _buildAttendanceBadge('Late', '$lateDays', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),

            // Compact Daily Rows (Small Font Crisp Design)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth,
              itemBuilder: (context, idx) {
                final day = daysInMonth - idx; // Newest dates first
                final dateStr =
                    '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final rec = _appData.attendanceRecords.firstWhere(
                  (r) =>
                      r.studentId == student?.id &&
                      AppData.formatLocalDate(r.date) == dateStr,
                  orElse: () => AttendanceRecord(
                      studentId: '',
                      studentName: '',
                      className: '',
                      date: DateTime.now(),
                      status: 'Not Marked',
                      markedBy: 'System'),
                );

                Color statusColor = Colors.grey;
                if (rec.status == 'Present') statusColor = Colors.green;
                if (rec.status == 'Absent') statusColor = Colors.red;
                if (rec.status == 'Leave') statusColor = Colors.blue;
                if (rec.status == 'Late') statusColor = Colors.orange;
                if (rec.status == 'Holiday') statusColor = Colors.purple;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, size: 14, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            '$day-${_selectedMonth.toString().padLeft(2, '0')}-$_selectedYear',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: textColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'By ${rec.markedBy}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              rec.status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBadge(String label, String val, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: col.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: col)),
          Text(label, style: TextStyle(fontSize: 10, color: col)),
        ],
      ),
    );
  }

  // ================= TAB 2: STUDY NOTES CARDS =================
  Widget _buildStudyNotesCardsTab(
      List<NoteModel> notes, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Study Notes & E-Books',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search Note Title, Subject...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (val) => setState(() => _notesSearchQuery = val),
        ),
        const SizedBox(height: 14),
        notes.isEmpty
            ? const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No study notes found.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                itemBuilder: (context, idx) {
                  final note = notes[idx];
                  return _buildNoteCard(note, cardColor, textColor);
                },
              ),
      ],
    );
  }

  Widget _buildNoteCard(NoteModel note, Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          PdfDocumentViewerModal.open(context, note);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor)),
                        Text('Subject: ${note.subject} • ${note.fileName}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Size: ${note.fileSize} • By ${note.uploadedBy}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        onPressed: () {
                          PdfDocumentViewerModal.open(context, note);
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Read PDF',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        onPressed: () {
                          PdfDocumentViewerModal.open(context, note);
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TAB 3: FEES LEDGER =================
  Widget _buildFeesLedgerTab(
      List<FeeModel> fees, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fees & Receipts Ledger',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        ...fees.map((f) {
          final isPaid = f.isPaid;
          return Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? const Color(0xFF10B981) : Colors.red,
              ),
              title: Text('${f.month}: ₹${f.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor)),
              subtitle: Text('Receipt: ${f.receiptNo} • Date: ${f.date}',
                  style: const TextStyle(fontSize: 11)),
              trailing: Chip(
                label: Text(isPaid ? 'PAID' : 'UNPAID',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
                backgroundColor: isPaid ? const Color(0xFF10B981) : Colors.red,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= TAB 4: SECURITY & PASSWORD SETTINGS =================
  Widget _buildSecuritySettingsTab(Color cardColor, Color textColor) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_reset, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Text('Change Student Password / PIN',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: oldPassController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current Password / PIN *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setModalState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPassController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password / PIN *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white),
                    onPressed: () {
                      final oldP = oldPassController.text.trim();
                      final newP = newPassController.text.trim();
                      if (oldP.isEmpty || newP.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter both passwords')));
                        return;
                      }
                      final ok = _appData.changeCurrentUserPassword(oldP, newP);
                      if (ok) {
                        oldPassController.clear();
                        newPassController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Password updated successfully!')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Incorrect current password / PIN')));
                      }
                    },
                    child: const Text('Update Password',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
