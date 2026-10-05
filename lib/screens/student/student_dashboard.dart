import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/app_data.dart';
import '../auth/login_screen.dart';
import 'live_test_screen.dart';
import '../common/notices_screen.dart';
import '../common/notifications_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AppData _appData = AppData();
  String _notesSearchQuery = '';

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    // Filtered Notes
    final studentNotes = _appData.notes.where((n) {
      if (n.className != student?.assignedClass && n.className != 'All') return false;
      final q = _notesSearchQuery.toLowerCase();
      return n.title.toLowerCase().contains(q) || n.subject.toLowerCase().contains(q);
    }).toList();

    // Attendance Calculations for Selected Month
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    int presentDays = 0;
    int absentDays = 0;
    int leaveDays = 0;
    int lateDays = 0;
    int holidayDays = 0;

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
      if (rec.status == 'Holiday') holidayDays++;
    }

    final totalTracked = presentDays + absentDays + leaveDays + lateDays;
    final attendancePercent = totalTracked > 0 ? ((presentDays + (lateDays * 0.5)) / totalTracked * 100) : 85.0;
    final isLowAttendance = attendancePercent < 75.0;

    // Fees Ledger for Student
    final studentFees = _appData.fees.where((f) => f.studentId == student?.id).toList();

    // Test Series & Results
    final studentTests = _appData.testSeriesList.where((t) => t.className == student?.assignedClass || t.className == 'All').toList();
    final studentResults = _appData.testResults.where((r) => r.studentId == student?.id).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_appData.tr('Student Portal'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('${student?.name ?? "Student"} • ${AppData.instituteName}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_appData.isHindi ? Icons.language : Icons.translate, color: Colors.white),
            tooltip: 'Language Toggle',
            onPressed: () => _appData.toggleLanguage(),
          ),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Card
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
                            'Hello, ${student?.name ?? "Student"} 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${student?.assignedClass ?? "Class 10th"} • Roll No: ${student?.rollNo ?? "01"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'Phone: ${student?.phone} | PIN: ${student?.studentPin}',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 1: Monthly Attendance Grid Calendar
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_appData.tr('Attendance Monthly Grid'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
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
                              Text('$_selectedMonth/$_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      const SizedBox(height: 10),

                      // Attendance Summary Strip with Red Alert Badge if < 75%
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLowAttendance ? Colors.red.shade50 : const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isLowAttendance ? Colors.red : const Color(0xFF4F46E5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Monthly Rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  '${attendancePercent.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isLowAttendance ? Colors.red : const Color(0xFF4F46E5)),
                                ),
                              ],
                            ),
                            if (isLowAttendance)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                child: const Text('LOW ATTENDANCE < 75%', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            Text('P: $presentDays | A: $absentDays | L: $leaveDays | LT: $lateDays', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Calendar Day Cells Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: daysInMonth,
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final dateStr = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                          final rec = _appData.attendanceRecords.firstWhere(
                            (r) => r.studentId == student?.id && AppData.formatLocalDate(r.date) == dateStr,
                            orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: 'Off', markedBy: ''),
                          );

                          Color cellBg = Colors.grey.shade200;
                          Color cellText = Colors.black87;

                          if (rec.status == 'Present') { cellBg = Colors.green; cellText = Colors.white; }
                          else if (rec.status == 'Absent') { cellBg = Colors.red; cellText = Colors.white; }
                          else if (rec.status == 'Leave') { cellBg = Colors.blue; cellText = Colors.white; }
                          else if (rec.status == 'Late') { cellBg = Colors.orange; cellText = Colors.white; }
                          else if (rec.status == 'Holiday') { cellBg = Colors.grey.shade400; cellText = Colors.white; }

                          return Container(
                            decoration: BoxDecoration(color: cellBg, borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cellText)),
                                if (rec.status != 'Off')
                                  Text(rec.status.substring(0, 1), style: TextStyle(fontSize: 8, color: cellText, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 2: Fee Status & Receipts
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_appData.tr('Fee Ledger & Receipts'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 10),

                      studentFees.isEmpty
                          ? const Text('No fee records found', style: TextStyle(color: Colors.grey, fontSize: 12))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: studentFees.length,
                              itemBuilder: (context, idx) {
                                final fee = studentFees[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(fee.month, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                  subtitle: Text(
                                    'Paid: ₹${fee.paidAmount.toStringAsFixed(0)} / ₹${fee.amount.toStringAsFixed(0)}\n'
                                    'Receipt No: ${fee.receiptNo.isNotEmpty ? fee.receiptNo : "Pending"} • Mode: ${fee.paymentMode}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  isThreeLine: true,
                                  trailing: Chip(
                                    label: Text(fee.isPaid ? 'PAID' : (fee.isPartial ? 'PARTIAL' : 'PENDING')),
                                    backgroundColor: fee.isPaid ? Colors.green.shade50 : (fee.isPartial ? Colors.orange.shade50 : Colors.red.shade50),
                                    side: BorderSide.none,
                                    labelStyle: TextStyle(
                                      color: fee.isPaid ? Colors.green : (fee.isPartial ? Colors.orange : Colors.red),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 3: Performance & Live Tests
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_appData.tr('Live Tests & Marks'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                          const Icon(Icons.show_chart, color: Color(0xFF4F46E5)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Trend Line Graphic
                      SizedBox(
                        height: 80,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: StudentTrendPainter(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      studentTests.isEmpty
                          ? const Text('No active test series', style: TextStyle(color: Colors.grey, fontSize: 12))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: studentTests.length,
                              itemBuilder: (context, idx) {
                                final test = studentTests[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(test.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                  subtitle: Text('Duration: ${test.durationMinutes} mins • Marks: ${test.totalMarks}'),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTestScreen(testSeries: test)));
                                    },
                                    child: const Text('Start Test', style: TextStyle(fontSize: 11)),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SECTION 4: Notes & Homework List
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_appData.tr('Study Notes & Materials'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 10),

                      TextField(
                        decoration: InputDecoration(
                          hintText: _appData.tr('Search Student'),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) => setState(() => _notesSearchQuery = val),
                      ),
                      const SizedBox(height: 10),

                      studentNotes.isEmpty
                          ? const Text('No study notes available', style: TextStyle(color: Colors.grey, fontSize: 12))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: studentNotes.length,
                              itemBuilder: (context, idx) {
                                final note = studentNotes[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                  subtitle: Text('Subject: ${note.subject} • ${note.fileName} (${note.fileSize})', style: const TextStyle(fontSize: 11)),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
