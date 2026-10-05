import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../services/app_data.dart';
import '../auth/login_screen.dart';
import 'add_edit_student_screen.dart';
import 'upload_notes_screen.dart';
import '../common/notices_screen.dart';
import '../common/notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late PageController _pageController;
  final AppData _appData = AppData();

  // Attendance Tab State
  late String _selectedAttendanceClass;
  DateTime _selectedAttendanceDate = DateTime.now();
  final Map<String, String> _dailyStatusMap = {};

  // Monthly Calendar State
  int _calendarMonth = DateTime.now().month;
  int _calendarYear = DateTime.now().year;
  String? _selectedCalendarStudentId;

  // Students Tab State
  String _studentSearchQuery = '';
  String _studentClassFilter = 'All';
  bool _showArchivedStudents = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _appData.addListener(_onDataChanged);

    final allowed = _appData.classesForCurrentAdmin;
    _selectedAttendanceClass = allowed.isNotEmpty ? allowed.first : AppData.allClasses.first;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _appData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentTab = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Launch WhatsApp with pre-filled fee reminder
  Future<void> _sendWhatsAppReminder(UserModel student, FeeModel fee) async {
    final phone = student.parentPhone.isNotEmpty ? student.parentPhone : student.phone;
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final msg = Uri.encodeComponent(
      'Dear Parent, this is a friendly fee reminder from ZM Tuition (${AppData.instituteName}).\n'
      'Student Name: ${student.name}\n'
      'Class: ${student.assignedClass}\n'
      'Month: ${fee.month}\n'
      'Pending Amount: ₹${(fee.amount - fee.paidAmount).toStringAsFixed(0)}\n'
      'Kindly submit at your earliest convenience. Thank you!',
    );

    final url = Uri.parse('https://wa.me/91$cleanPhone?text=$msg');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please check if WhatsApp is installed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _appData.currentUser;
    final isDark = _appData.isDarkMode;
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
            Text(
              _appData.tr('ZM Tuition Admin'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${admin?.name ?? "Admin"} • ${AppData.instituteName}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
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

      // Animated Page View Body
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        children: [
          _buildHomeTab(cardColor, textColor),
          _buildAttendanceTab(cardColor, textColor),
          _buildStudentsTab(cardColor, textColor),
          _buildFeesTab(cardColor, textColor),
          _buildMoreTab(cardColor, textColor),
        ],
      ),

      // Animated 5-Tab Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: _onTabTapped,
          backgroundColor: cardColor,
          indicatorColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: Color(0xFF4F46E5)),
              label: _appData.tr('Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_today_outlined),
              selectedIcon: const Icon(Icons.calendar_today, color: Color(0xFF4F46E5)),
              label: _appData.tr('Attendance'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outlined),
              selectedIcon: const Icon(Icons.people, color: Color(0xFF4F46E5)),
              label: _appData.tr('Students'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF4F46E5)),
              label: _appData.tr('Fees'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view, color: Color(0xFF4F46E5)),
              label: _appData.tr('More'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: HOME ====================
  Widget _buildHomeTab(Color cardColor, Color textColor) {
    final admin = _appData.currentUser;
    final isZoya = admin?.name.toLowerCase().contains('zoya') == true || admin?.email == 'zm@124';

    final activeStudents = _appData.users.where((u) {
      if (u.role != 'student' || u.status != 'approved' || u.isArchived) return false;
      return isZoya ? u.assignedClass.contains('Commerce') : !u.assignedClass.contains('Commerce');
    }).toList();

    final pendingStudents = _appData.users.where((u) => u.role == 'student' && u.status == 'pending').toList();

    final totalCollected = _appData.fees.where((f) => f.isPaid || f.isPartial).fold(0.0, (sum, f) => sum + f.paidAmount);
    final totalPending = _appData.fees.fold(0.0, (sum, f) => sum + (f.amount - f.paidAmount));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card with Dynamic Greeting
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school, color: Color(0xFF4F46E5), size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateTime.now().hour < 12 ? "Good Morning 👋" : DateTime.now().hour < 17 ? "Good Afternoon 👋" : "Good Evening 👋"}, ${admin?.name ?? "Admin"}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        AppData.instituteName,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overview Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatTile('Total Students', '${activeStudents.length}', Icons.group, const Color(0xFF3B82F6), cardColor, textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile('Active Batches', '${_appData.classesForCurrentAdmin.length}', Icons.class_, const Color(0xFF10B981), cardColor, textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile('Collected Fees', '₹${totalCollected.toStringAsFixed(0)}', Icons.currency_rupee, const Color(0xFF22C55E), cardColor, textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile('Pending Fees', '₹${totalPending.toStringAsFixed(0)}', Icons.pending_actions, const Color(0xFFEF4444), cardColor, textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pending Approvals Card (if any)
          if (pendingStudents.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Student Approvals (${pendingStudents.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...pendingStudents.map((student) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      subtitle: Text('Email: ${student.email} • Class: ${student.assignedClass}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              _appData.approveStudent(student.id, student.assignedClass);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Approved ${student.name}!')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              _appData.rejectStudent(student.id);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Action Shortcuts
          Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildQuickActionTile('Mark Attendance', Icons.calendar_today, const Color(0xFF4F46E5), () {
                _onTabTapped(1);
              }, cardColor, textColor),
              _buildQuickActionTile('Add New Student', Icons.person_add, const Color(0xFF10B981), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditStudentScreen()));
              }, cardColor, textColor),
              _buildQuickActionTile('Record Fee Payment', Icons.receipt_long, const Color(0xFFF59E0B), () {
                _onTabTapped(3);
              }, cardColor, textColor),
              _buildQuickActionTile('Upload Notes', Icons.upload_file, const Color(0xFFEC4899), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen()));
              }, cardColor, textColor),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Notices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Notices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
                child: const Text('View All'),
              ),
            ],
          ),
          ..._appData.notices.take(2).map((notice) {
            return Card(
              color: cardColor,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Color(0xFF4F46E5)),
                title: Text(notice.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                subtitle: Text(notice.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11))),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(String title, IconData icon, Color color, VoidCallback onTap, Color cardColor, Color textColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 2: ATTENDANCE ====================
  Widget _buildAttendanceTab(Color cardColor, Color textColor) {
    final allowedClasses = _appData.classesForCurrentAdmin;
    if (!allowedClasses.contains(_selectedAttendanceClass) && allowedClasses.isNotEmpty) {
      _selectedAttendanceClass = allowedClasses.first;
    }

    final studentsInBatch = _appData.users
        .where((u) => u.role == 'student' && u.status == 'approved' && !u.isArchived && u.assignedClass == _selectedAttendanceClass)
        .toList();

    final localFormattedDate = AppData.formatLocalDate(_selectedAttendanceDate);

    // Populate daily map from existing records
    for (var student in studentsInBatch) {
      _dailyStatusMap.putIfAbsent(student.id, () {
        final existing = _appData.attendanceRecords.firstWhere(
          (r) => r.studentId == student.id && AppData.formatLocalDate(r.date) == localFormattedDate,
          orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: 'Present', markedBy: ''),
        );
        return existing.studentId.isNotEmpty ? existing.status : 'Present';
      });
    }

    int presentCount = 0;
    int absentCount = 0;
    int leaveCount = 0;
    int lateCount = 0;
    int holidayCount = 0;

    for (var student in studentsInBatch) {
      final st = _dailyStatusMap[student.id] ?? 'Present';
      if (st == 'Present') presentCount++;
      if (st == 'Absent') absentCount++;
      if (st == 'Leave') leaveCount++;
      if (st == 'Late') lateCount++;
      if (st == 'Holiday') holidayCount++;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_appData.tr('Daily Attendance Marking'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () => _showMonthlyCalendarDialog(context, cardColor, textColor),
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Monthly View', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Batch & Date Selector Card
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAttendanceClass,
                          decoration: const InputDecoration(
                            labelText: 'Select Batch / Class',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: allowedClasses.map((cls) => DropdownMenuItem(value: cls, child: Text(cls, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedAttendanceClass = val;
                                _dailyStatusMap.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedAttendanceDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedAttendanceDate = picked;
                              _dailyStatusMap.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(
                          localFormattedDate,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live Counter Summary Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('$presentCount Present', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('$absentCount Absent', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('$leaveCount Leave', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('$lateCount Late', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mark All Present Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                        onPressed: () {
                          setState(() {
                            for (var s in studentsInBatch) {
                              _dailyStatusMap[s.id] = 'Present';
                            }
                          });
                        },
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text(_appData.tr('Mark All Present'), style: const TextStyle(fontSize: 12)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                        onPressed: () {
                          final admin = _appData.currentUser;
                          for (var s in studentsInBatch) {
                            _appData.markAttendance(
                              studentId: s.id,
                              studentName: s.name,
                              className: _selectedAttendanceClass,
                              date: _selectedAttendanceDate,
                              status: _dailyStatusMap[s.id] ?? 'Present',
                              markedBy: admin?.name ?? 'Admin',
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Attendance saved for ${studentsInBatch.length} students on $localFormattedDate!')),
                          );
                        },
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save Daily Attendance', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Students Attendance List
          studentsInBatch.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No active students found in this batch')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentsInBatch.length,
                  itemBuilder: (context, index) {
                    final student = studentsInBatch[index];
                    final currentStatus = _dailyStatusMap[student.id] ?? 'Present';

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                Text('Roll: ${student.rollNo}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Status Buttons: P, A, L, LT, Holiday
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusChoiceChip(student.id, 'P', 'Present', currentStatus, Colors.green),
                                _buildStatusChoiceChip(student.id, 'A', 'Absent', currentStatus, Colors.red),
                                _buildStatusChoiceChip(student.id, 'L', 'Leave', currentStatus, Colors.blue),
                                _buildStatusChoiceChip(student.id, 'LT', 'Late', currentStatus, Colors.orange),
                                _buildStatusChoiceChip(student.id, 'H', 'Holiday', currentStatus, Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatusChoiceChip(String studentId, String code, String statusName, String currentStatus, Color color) {
    final isSelected = currentStatus == statusName;
    return InkWell(
      onTap: () {
        setState(() {
          _dailyStatusMap[studentId] = statusName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(
          '$code ($statusName)',
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // Monthly Attendance Calendar View Sheet
  void _showMonthlyCalendarDialog(BuildContext context, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final studentsInBatch = _appData.users
                .where((u) => u.role == 'student' && u.status == 'approved' && !u.isArchived && u.assignedClass == _selectedAttendanceClass)
                .toList();

            _selectedCalendarStudentId ??= studentsInBatch.isNotEmpty ? studentsInBatch.first.id : null;
            final selectedStudent = _appData.users.firstWhere((u) => u.id == _selectedCalendarStudentId, orElse: () => studentsInBatch.first);

            final daysInMonth = DateTime(_calendarYear, _calendarMonth + 1, 0).day;

            // Compute student stats for this month
            int studentPresent = 0;
            int studentAbsent = 0;
            int studentLeave = 0;
            int studentLate = 0;
            int studentHoliday = 0;

            for (int day = 1; day <= daysInMonth; day++) {
              final dateStr = '$_calendarYear-${_calendarMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final rec = _appData.attendanceRecords.firstWhere(
                (r) => r.studentId == selectedStudent.id && AppData.formatLocalDate(r.date) == dateStr,
                orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: '', markedBy: ''),
              );

              if (rec.status == 'Present') studentPresent++;
              if (rec.status == 'Absent') studentAbsent++;
              if (rec.status == 'Leave') studentLeave++;
              if (rec.status == 'Late') studentLate++;
              if (rec.status == 'Holiday') studentHoliday++;
            }

            final totalTrackedDays = studentPresent + studentAbsent + studentLeave + studentLate;
            final attendancePercent = totalTrackedDays > 0 ? ((studentPresent + (studentLate * 0.5)) / totalTrackedDays * 100) : 100.0;
            final isLowAttendance = attendancePercent < 75.0;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Calendar Grid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),

                  // Month Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: () {
                          setModalState(() {
                            if (_calendarMonth == 1) {
                              _calendarMonth = 12;
                              _calendarYear--;
                            } else {
                              _calendarMonth--;
                            }
                          });
                        },
                      ),
                      Text(
                        'Month: $_calendarMonth / $_calendarYear',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: () {
                          setModalState(() {
                            if (_calendarMonth == 12) {
                              _calendarMonth = 1;
                              _calendarYear++;
                            } else {
                              _calendarMonth++;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Student Selector Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCalendarStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Select Student for Individual Grid',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: studentsInBatch.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.rollNo})'))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          _selectedCalendarStudentId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Summary Strip with Low Attendance Red Alert
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
                            const Text('Attendance %', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                            child: const Text('ALERT < 75%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        Column(
                          children: [
                            const Text('P / A / L / LT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('$studentPresent / $studentAbsent / $studentLeave / $studentLate', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calendar Days Grid (30 Day cells)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: daysInMonth,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final dateStr = '$_calendarYear-${_calendarMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                        final rec = _appData.attendanceRecords.firstWhere(
                          (r) => r.studentId == selectedStudent.id && AppData.formatLocalDate(r.date) == dateStr,
                          orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: 'Unmarked', markedBy: ''),
                        );

                        Color cellColor = Colors.grey.shade200;
                        Color textCol = Colors.black87;

                        if (rec.status == 'Present') { cellColor = Colors.green; textCol = Colors.white; }
                        else if (rec.status == 'Absent') { cellColor = Colors.red; textCol = Colors.white; }
                        else if (rec.status == 'Leave') { cellColor = Colors.blue; textCol = Colors.white; }
                        else if (rec.status == 'Late') { cellColor = Colors.orange; textCol = Colors.white; }
                        else if (rec.status == 'Holiday') { cellColor = Colors.grey.shade400; textCol = Colors.white; }

                        return InkWell(
                          onTap: () {
                            // Tap day cell opens detail editor sheet
                            _showDayStatusEditDialog(context, selectedStudent, DateTime(_calendarYear, _calendarMonth, day), rec.status, setModalState);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 13)),
                                if (rec.status != 'Unmarked')
                                  Text(rec.status.substring(0, 1), style: TextStyle(color: textCol, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDayStatusEditDialog(BuildContext context, UserModel student, DateTime date, String currentStatus, StateSetter parentSetState) {
    String newStatus = currentStatus.isEmpty ? 'Present' : currentStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Status: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${AppData.formatLocalDate(date)}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: ['Present', 'Absent', 'Leave', 'Late', 'Holiday'].contains(newStatus) ? newStatus : 'Present',
              items: ['Present', 'Absent', 'Leave', 'Late', 'Holiday']
                  .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                  .toList(),
              onChanged: (val) {
                if (val != null) newStatus = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _appData.markAttendance(
                studentId: student.id,
                studentName: student.name,
                className: student.assignedClass,
                date: date,
                status: newStatus,
                markedBy: _appData.currentUser?.name ?? 'Admin',
              );
              parentSetState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: STUDENTS ====================
  Widget _buildStudentsTab(Color cardColor, Color textColor) {
    final admin = _appData.currentUser;
    final isZoya = admin?.name.toLowerCase().contains('zoya') == true || admin?.email == 'zm@124';

    final studentsList = _appData.users.where((u) {
      if (u.role != 'student' || u.status != 'approved') return false;
      if (_showArchivedStudents) {
        if (!u.isArchived) return false;
      } else {
        if (u.isArchived) return false;
      }
      if (isZoya && !u.assignedClass.contains('Commerce')) return false;
      if (!isZoya && u.assignedClass.contains('Commerce')) return false;

      if (_studentClassFilter != 'All' && u.assignedClass != _studentClassFilter) return false;

      final q = _studentSearchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) || u.rollNo.toLowerCase().contains(q) || u.phone.contains(q);
    }).toList();

    final allowedClasses = ['All', ..._appData.classesForCurrentAdmin];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Student
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_appData.tr('Students Directory'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditStudentScreen())),
                icon: const Icon(Icons.person_add, size: 16),
                label: Text(_appData.tr('Add Student'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: _appData.tr('Search Student'),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4F46E5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: cardColor,
            ),
            onChanged: (val) => setState(() => _studentSearchQuery = val),
          ),
          const SizedBox(height: 12),

          // Filters & Soft Archive Toggle
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _studentClassFilter,
                  decoration: const InputDecoration(
                    labelText: 'Batch Filter',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  items: allowedClasses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _studentClassFilter = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_showArchivedStudents ? 'Archived' : 'Active', style: const TextStyle(fontSize: 11)),
                selected: _showArchivedStudents,
                onSelected: (val) => setState(() => _showArchivedStudents = val),
                selectedColor: Colors.orange.shade100,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student Cards List
          studentsList.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No students found matching filter')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentsList.length,
                  itemBuilder: (context, index) {
                    final student = studentsList[index];

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                  child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                      Text('${student.assignedClass} • Roll No: ${student.rollNo}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text('Phone: ${student.phone} | PIN: ${student.studentPin}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),

                            // Action buttons: Edit, Archive / Unarchive, Reset PIN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showResetPinDialog(context, student),
                                  icon: const Icon(Icons.lock_reset, size: 14, color: Colors.orange),
                                  label: const Text('Reset PIN', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    if (student.isArchived) {
                                      _appData.unarchiveStudent(student.id);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unarchived ${student.name}')));
                                    } else {
                                      _appData.archiveStudent(student.id);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archived ${student.name}')));
                                    }
                                  },
                                  icon: Icon(student.isArchived ? Icons.unarchive : Icons.archive, size: 14, color: Colors.grey),
                                  label: Text(student.isArchived ? 'Restore' : 'Archive', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditStudentScreen(studentToEdit: student)));
                                  },
                                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFF4F46E5)),
                                  label: const Text('Edit', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showResetPinDialog(BuildContext context, UserModel student) {
    final pinController = TextEditingController(text: student.studentPin);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset PIN for ${student.name}'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'New 4-Digit Student PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.trim().isNotEmpty) {
                _appData.resetStudentPin(student.id, pinController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN updated for ${student.name}')));
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: FEES ====================
  Widget _buildFeesTab(Color cardColor, Color textColor) {
    final totalCollected = _appData.fees.where((f) => f.isPaid || f.isPartial).fold(0.0, (sum, f) => sum + f.paidAmount);
    final totalPending = _appData.fees.fold(0.0, (sum, f) => sum + (f.amount - f.paidAmount));
    final fullyPaidCount = _appData.fees.where((f) => f.isPaid).length;
    final partialCount = _appData.fees.where((f) => f.isPartial).length;
    final pendingCount = _appData.fees.where((f) => !f.isPaid && !f.isPartial).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_appData.tr('Tuition Fee Management'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () => _showRecordPaymentDialog(context, cardColor, textColor),
                icon: const Icon(Icons.add, size: 16),
                label: Text(_appData.tr('Record Payment'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Monthly Counters Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Collected', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('₹${totalCollected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Total Pending', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('₹${totalPending.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('$fullyPaidCount Fully Paid', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('$partialCount Partial', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('$pendingCount Pending', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fees Ledger Cards
          Text('Student Receipts & Ledger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appData.fees.length,
            itemBuilder: (context, index) {
              final fee = _appData.fees[index];
              final student = _appData.users.firstWhere(
                (u) => u.id == fee.studentId,
                orElse: () => UserModel(id: '', name: fee.studentName, email: '', password: '', role: 'student', phone: '9876543210', parentPhone: '9876543210'),
              );

              final pending = fee.amount - fee.paidAmount;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fee.studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      Chip(
                        label: Text(
                          fee.isPaid ? 'PAID' : (fee.isPartial ? 'PARTIAL' : 'PENDING'),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: fee.isPaid ? Colors.green.shade50 : (fee.isPartial ? Colors.orange.shade50 : Colors.red.shade50),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${fee.className} • Month: ${fee.month}', style: const TextStyle(fontSize: 11)),
                      Text(
                        'Paid: ₹${fee.paidAmount.toStringAsFixed(0)} / Total: ₹${fee.amount.toStringAsFixed(0)} '
                        '${fee.receiptNo.isNotEmpty ? "• Rec: " + fee.receiptNo : ""}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (fee.paymentMode.isNotEmpty) Text('Mode: ${fee.paymentMode} ${fee.note.isNotEmpty ? "(" + fee.note + ")" : ""}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  trailing: pending > 0
                      ? IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          tooltip: 'Send WhatsApp Fee Reminder',
                          onPressed: () => _sendWhatsAppReminder(student, fee),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, Color cardColor, Color textColor) {
    final activeStudents = _appData.users.where((u) => u.role == 'student' && u.status == 'approved' && !u.isArchived).toList();
    if (activeStudents.isEmpty) return;

    String selectedStudentId = activeStudents.first.id;
    final amountController = TextEditingController(text: '2500');
    final noteController = TextEditingController();
    String paymentMode = 'Cash';
    String selectedMonth = 'September 2026';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final student = activeStudents.firstWhere((s) => s.id == selectedStudentId);

          return AlertDialog(
            backgroundColor: cardColor,
            title: Text('Record Fee Payment', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    decoration: const InputDecoration(labelText: 'Student'),
                    items: activeStudents.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStudentId = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount Paid (₹)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode'),
                    items: ['Cash', 'UPI'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => paymentMode = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note / Ref Number (Optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () {
                  final paidAmt = double.tryParse(amountController.text.trim()) ?? 2500.0;
                  final fee = _appData.fees.firstWhere(
                    (f) => f.studentId == student.id && f.month == selectedMonth,
                    orElse: () {
                      final newFee = FeeModel(
                        id: 'fee_${DateTime.now().millisecondsSinceEpoch}',
                        studentId: student.id,
                        studentName: student.name,
                        className: student.assignedClass,
                        month: selectedMonth,
                        amount: 2500,
                        paidAmount: 0,
                        isPaid: false,
                        date: 'Pending',
                      );
                      _appData.fees.add(newFee);
                      return newFee;
                    },
                  );

                  _appData.recordFeePayment(
                    feeId: fee.id,
                    paidAmount: paidAmt,
                    totalAmount: 2500,
                    paymentMode: paymentMode,
                    note: noteController.text.trim(),
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recorded payment of ₹$paidAmt for ${student.name}! Receipt: ${fee.receiptNo}')),
                  );
                },
                child: const Text('Save & Issue Receipt'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== TAB 5: MORE ====================
  Widget _buildMoreTab(Color cardColor, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_appData.tr('More Management Tools'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),

          // Tools List Cards
          _buildMoreListTile('Upload Notes & Homework', Icons.upload_file, const Color(0xFF4F46E5), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen()));
          }, cardColor, textColor),

          _buildMoreListTile('JSON Backup & Restore', Icons.backup, const Color(0xFF10B981), () {
            _showBackupRestoreDialog(context, cardColor, textColor);
          }, cardColor, textColor),

          _buildMoreListTile('Language (Hindi / English)', Icons.language, const Color(0xFFF59E0B), () {
            _appData.toggleLanguage();
          }, cardColor, textColor, trailingText: _appData.isHindi ? 'हिंदी' : 'English'),

          _buildMoreListTile('System Dark Mode', Icons.dark_mode, const Color(0xFF8B5CF6), () {
            _appData.toggleDarkMode();
          }, cardColor, textColor, trailingWidget: Switch(
            value: _appData.isDarkMode,
            onChanged: (val) => _appData.toggleDarkMode(val),
          )),

          _buildMoreListTile('Batch Soft Archive Manager', Icons.folder_delete, const Color(0xFFEC4899), () {
            _showBatchArchiveDialog(context, cardColor, textColor);
          }, cardColor, textColor),

          _buildMoreListTile('About Coaching App', Icons.info_outline, const Color(0xFF3B82F6), () {
            _showAboutDialog(context, cardColor, textColor);
          }, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildMoreListTile(String title, IconData icon, Color color, VoidCallback onTap, Color cardColor, Color textColor, {String? trailingText, Widget? trailingWidget}) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
        trailing: trailingWidget ?? (trailingText != null ? Text(trailingText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))) : const Icon(Icons.arrow_forward_ios, size: 14)),
        onTap: onTap,
      ),
    );
  }

  void _showBackupRestoreDialog(BuildContext context, Color cardColor, Color textColor) {
    final jsonTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Backup & Restore JSON', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export current database or paste JSON to restore data.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: jsonTextController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON data here to restore...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final exported = _appData.exportToJson();
              jsonTextController.text = exported;
              Clipboard.setData(ClipboardData(text: exported));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup JSON copied to Clipboard!')));
            },
            child: const Text('Export JSON'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            onPressed: () {
              if (jsonTextController.text.trim().isNotEmpty) {
                final success = _appData.importFromJson(jsonTextController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Database restored successfully!' : 'Invalid JSON format!')),
                );
              }
            },
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
  }

  void _showBatchArchiveDialog(BuildContext context, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Soft Archive Batches', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppData.allClasses.length,
            itemBuilder: (context, idx) {
              final cls = AppData.allClasses[idx];
              final isArchived = _appData.archivedBatches.contains(cls);

              return ListTile(
                title: Text(cls, style: TextStyle(color: textColor, fontSize: 13)),
                trailing: Switch(
                  value: isArchived,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    if (val) {
                      _appData.archiveBatch(cls);
                    } else {
                      _appData.unarchiveBatch(cls);
                    }
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('About ZM Tuition', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppData.instituteName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4F46E5))),
            SizedBox(height: 6),
            Text('App Version: 2.0.0 (build 20000)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 10),
            Text('Features included: Automated Attendance, Live Proctored Test Series, Fee Receipts & Reminders, Soft Archiving, and Multi-language support.', style: TextStyle(fontSize: 12, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
