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
  int _selectedNavTab = 0; // 0: Learning Portal / Overview, 1: Attendance, 2: Notes & Downloads, 3: Deadlines & Schedule, 4: Fees Ledger
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.campaign_rounded, color: Color(0xFF2563EB), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Notice Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Category: ${notice.category} • Date: ${notice.date}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
                const SizedBox(height: 12),
                Text(notice.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(notice.description, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
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

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    // Filtered Notes
    final studentNotes = _appData.notes.where((n) {
      if (n.className != student?.assignedClass && n.className != 'All') return false;
      final q = _notesSearchQuery.toLowerCase();
      return n.title.toLowerCase().contains(q) || n.subject.toLowerCase().contains(q);
    }).toList();

    // Attendance Calculations
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    int presentDays = 0;
    int absentDays = 0;
    int leaveDays = 0;
    int lateDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final rec = _appData.attendanceRecords.firstWhere(
        (r) => r.studentId == student?.id && AppData.formatLocalDate(r.date) == dateStr,
        orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: '', markedBy: ''),
      );

      if (rec.status == 'Present') presentDays++;
      if (rec.status == 'Absent') absentDays++;
      if (rec.status == 'Leave') leaveDays++;
      if (rec.status == 'Late') lateDays++;
    }

    final totalTracked = presentDays + absentDays + leaveDays + lateDays;
    final attendancePercent = totalTracked > 0 ? ((presentDays + (lateDays * 0.5)) / totalTracked * 100) : 92.5;

    // Fees Ledger
    final studentFees = _appData.fees.where((f) => f.studentId == student?.id).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB), // Royal Blue Header
        elevation: 0,
        title: Row(
          children: [
            // Student Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                student?.name.isNotEmpty == true ? student!.name[0].toUpperCase() : 'S',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student?.name ?? 'Student Portal',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // DAILY STREAK BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥 ', style: TextStyle(fontSize: 10)),
                            Text('5 Day Streak', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${student?.assignedClass ?? "Class 10th"} • ${AppData.instituteName}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_appData.isHindi ? Icons.language : Icons.translate, color: Colors.white),
            onPressed: () => _appData.toggleLanguage(),
          ),
          // Notification Center
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
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _appData.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
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
                    _buildNavPill(0, 'Learning Portal', Icons.dashboard_rounded),
                    _buildNavPill(1, 'Attendance Logs', Icons.calendar_month_rounded),
                    _buildNavPill(2, 'PDF Notes Vault', Icons.menu_book_rounded),
                    _buildNavPill(3, 'Deadlines & Schedule', Icons.event_note_rounded),
                    _buildNavPill(4, 'Fees & Receipts', Icons.receipt_long_rounded),
                  ],
                ),
              ),
            ),

            // Main Body Based on Selected Tab
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedNavTab == 0)
                      _buildLearningPortalOverview(student, attendancePercent, presentDays, absentDays, studentNotes, studentFees, cardColor, textColor),
                    if (_selectedNavTab == 1)
                      _buildAttendanceCalendarTab(student, daysInMonth, presentDays, absentDays, leaveDays, lateDays, attendancePercent, cardColor, textColor),
                    if (_selectedNavTab == 2)
                      _buildStudyNotesTab(studentNotes, cardColor, textColor),
                    if (_selectedNavTab == 3)
                      _buildDeadlinesAndScheduleTab(cardColor, textColor),
                    if (_selectedNavTab == 4)
                      _buildFeesLedgerTab(studentFees, cardColor, textColor),
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
        avatar: Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFF2563EB)),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isSel ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => setState(() => _selectedNavTab = index),
      ),
    );
  }

  // ================= TAB 0: LEARNING PORTAL & OVERVIEW =================
  Widget _buildLearningPortalOverview(
    UserModel? student,
    double attendancePercent,
    int present,
    int absent,
    List<NoteModel> notes,
    List<FeeModel> fees,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header & Daily Streak Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF5B5FC7)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  student?.name.isNotEmpty == true ? student!.name[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Welcome back, ${student?.name ?? "Student"}!',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(12)),
                          child: const Text('🔥 5 Day Streak', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${student?.assignedClass} • Roll No: ${student?.rollNo}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text(AppData.instituteName, style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Jetpack Compose M3 Style Attendance KPI Card
        Card(
          color: const Color(0xFFE0E7FF), // primaryContainer
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3730A3))),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: attendancePercent / 100,
                    minHeight: 8,
                    backgroundColor: Colors.indigo.shade100,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(attendancePercent).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B))),
                    Text(attendancePercent >= 75 ? '92% Good' : 'Low (<75%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: attendancePercent >= 75 ? const Color(0xFF059669) : Colors.red)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Enrolled Subjects Section (Jetpack Compose M3 Style)
        Text('Enrolled Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),

        ...List.generate(3, (index) {
          final moduleNames = ['Mathematics & Algebra', 'Science & Magnetism', 'Accountancy & Ledger'];
          return Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subject Module ${index + 1}: ${moduleNames[index]}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                        const Text('Status: Active', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (notes.length > index) {
                        PdfDocumentViewerModal.open(context, notes[index]);
                      } else if (notes.isNotEmpty) {
                        PdfDocumentViewerModal.open(context, notes.first);
                      }
                    },
                    child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // LESSON RESUME POINT CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resume Point', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    Text('Math Quadratic Equations Ex 4.2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    const Text('Last read 2 hours ago • Step-by-step solution notes', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  if (notes.isNotEmpty) {
                    PdfDocumentViewerModal.open(context, notes.first);
                  }
                },
                child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // QUICK LAUNCH CLASSROOM HUB PORTAL
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassroomHubScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF5B5FC7), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFF5B5FC7).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.cast_for_education_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Open ZM Classroom Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Live Classroom Resources, Homework & Quiz Arena', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // RECENT NOTES PREVIEW
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent PDF Notes & Study Vault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
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

  Widget _buildCourseProgressCard(String title, String subtitle, double progress, String label, Color accentColor, Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor))),
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accentColor)),
              ],
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: ATTENDANCE CALENDAR =================
  Widget _buildAttendanceCalendarTab(
    UserModel? student,
    int daysInMonth,
    int present,
    int absent,
    int leave,
    int lateDays,
    double pct,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pct >= 75 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pct >= 75 ? Colors.green.shade300 : Colors.red.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Attendance Percentage', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: pct >= 75 ? Colors.green.shade900 : Colors.red.shade900)),
                    ],
                  ),
                  Chip(
                    label: Text(pct >= 75 ? 'GOOD (≥75%)' : 'WARNING (<75%)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    backgroundColor: pct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Attendance Logs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
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
                    Text('$_selectedMonth/$_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth,
              itemBuilder: (context, idx) {
                final day = daysInMonth - idx;
                final dateStr = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final rec = _appData.attendanceRecords.firstWhere(
                  (r) => r.studentId == student?.id && AppData.formatLocalDate(r.date) == dateStr,
                  orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: 'Not Marked', markedBy: 'System'),
                );

                Color statusColor = Colors.grey;
                if (rec.status == 'Present') statusColor = const Color(0xFF10B981);
                if (rec.status == 'Absent') statusColor = const Color(0xFFEF4444);
                if (rec.status == 'Leave') statusColor = const Color(0xFF2563EB);
                if (rec.status == 'Late') statusColor = Colors.orange;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_available, size: 14, color: statusColor),
                          const SizedBox(width: 8),
                          Text('$day-${_selectedMonth.toString().padLeft(2, '0')}-$_selectedYear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(rec.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
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

  // ================= TAB 2: STUDY NOTES & PDF VAULT =================
  Widget _buildStudyNotesTab(List<NoteModel> notes, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PDF Study Notes & Downloads', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search note title, chapter or subject...',
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF2563EB)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (val) => setState(() => _notesSearchQuery = val),
        ),
        const SizedBox(height: 14),
        notes.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No study notes found in this stream.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                itemBuilder: (context, idx) {
                  return _buildNoteCard(notes[idx], cardColor, textColor);
                },
              ),
      ],
    );
  }

  Widget _buildNoteCard(NoteModel note, Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      Text('Subject: ${note.subject} • ${note.fileName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Size: ${note.fileSize} • By ${note.uploadedBy}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        PdfDocumentViewerModal.open(context, note);
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Read PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        PdfDocumentViewerModal.open(context, note);
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 3: DEADLINES & SCHEDULE =================
  Widget _buildDeadlinesAndScheduleTab(Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upcoming Assignments Section
        Row(
          children: [
            const Icon(Icons.assignment_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('Upcoming Homework Assignments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 10),
        ..._appData.homeworkList.map((hw) {
          return Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(hw.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
              subtitle: Text('${hw.subject} • Due Date: ${hw.dueDate}\n${hw.description}', style: const TextStyle(fontSize: 11)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Homework "${hw.title}" marked completed!')));
                },
                child: const Text('Submit', style: TextStyle(fontSize: 11)),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Upcoming Quizzes & Live Tests
        Row(
          children: [
            const Icon(Icons.quiz_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('Proctored Tests & Quizzes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 10),
        ..._appData.testSeriesList.map((test) {
          return Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(test.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
              subtitle: Text('Subject: ${test.subject} • Duration: ${test.durationMinutes} mins | Total: ${test.totalMarks} Marks', style: const TextStyle(fontSize: 11)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTestScreen(testSeries: test)));
                },
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Take Test', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Live Class Schedule Calendar
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF5B5FC7)),
            const SizedBox(width: 8),
            Text('Live Class Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 10),

        Card(
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: const Padding(
            padding: EdgeInsets.all(14.0),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Color(0xFF2563EB), child: Icon(Icons.video_call, color: Colors.white)),
                  title: Text('Batch Class 10th Math & Science', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Everyday: 04:00 PM – 05:30 PM • Teacher: Muskan', style: TextStyle(fontSize: 11)),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Color(0xFF5B5FC7), child: Icon(Icons.video_call, color: Colors.white)),
                  title: Text('Class 12th Commerce Accountancy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Everyday: 05:30 PM – 07:00 PM • Teacher: Zoya', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 4: FEES LEDGER =================
  Widget _buildFeesLedgerTab(List<FeeModel> fees, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fees & Receipts Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        ...fees.map((f) {
          final isPaid = f.isPaid;
          return Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(
                isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              title: Text('${f.month}: ₹${f.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              subtitle: Text('Receipt: ${f.receiptNo.isNotEmpty ? f.receiptNo : "Pending"} • Date: ${f.date}', style: const TextStyle(fontSize: 11)),
              trailing: Chip(
                label: Text(isPaid ? 'PAID' : 'UNPAID', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                backgroundColor: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          );
        }),
      ],
    );
  }
}
