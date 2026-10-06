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
import '../common/classroom_hub_screen.dart';

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

  // ANNOUNCEMENT BROADCASTER DIALOG
  void _showBroadcastAnnouncementDialog(Color cardColor, Color textColor) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text('Announcement Broadcaster', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'Announcement Title *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: ['General', 'Holiday', 'Exam', 'Academics', 'Fees']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'Message Body *', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () {
                final title = titleController.text.trim();
                final desc = descController.text.trim();
                if (title.isEmpty || desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }

                _appData.notices.insert(
                  0,
                  NoticeModel(
                    id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    date: AppData.formatLocalDate(DateTime.now()),
                    description: desc,
                    category: category,
                  ),
                );

                _appData.addAuditLog(
                  event: 'Announcement Broadcasted',
                  userIdentifier: _appData.currentUser?.name ?? 'Admin',
                  ipAddress: '192.168.1.1',
                  details: 'Broadcasted "$title" to all students',
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Announcement "$title" broadcasted successfully!')),
                );
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Broadcast Now'),
            ),
          ],
        ),
      ),
    );
  }

  // LIVE CLASS INITIALIZER DIALOG
  void _showLiveClassInitializerDialog(Color cardColor, Color textColor) {
    final topicController = TextEditingController();
    final linkController = TextEditingController(text: 'https://meet.google.com/zm-tuition-live');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.live_tv_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text('Live Class Initializer', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topicController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'Topic / Chapter Title *', hintText: 'e.g. Accountancy Balance Sheet Live Q&A', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(labelText: 'Meeting Link *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              final topic = topicController.text.trim();
              if (topic.isEmpty) return;

              _appData.notices.insert(
                0,
                NoticeModel(
                  id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
                  title: '🔴 LIVE CLASS STARTED: $topic',
                  date: AppData.formatLocalDate(DateTime.now()),
                  description: 'Live session is now active! Join link: ${linkController.text.trim()}',
                  category: 'Exam',
                ),
              );

              _appData.addAuditLog(
                event: 'Live Class Session Initialized',
                userIdentifier: _appData.currentUser?.name ?? 'Admin',
                ipAddress: '192.168.1.1',
                details: 'Started live class for "$topic"',
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Live class for "$topic" launched! Notifications sent.')),
              );
            },
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: const Text('Start Live Session'),
          ),
        ],
      ),
    );
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
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
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

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        children: [
          _buildHomeKpiAndAnalyticsTab(cardColor, textColor),
          _buildAttendanceTab(cardColor, textColor),
          _buildStudentsDirectoryTab(cardColor, textColor),
          _buildFeesTab(cardColor, textColor),
          _buildAdminControlPanelTab(cardColor, textColor),
        ],
      ),

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
          indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: Color(0xFF2563EB)),
              label: 'KPI Hub',
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_today_outlined),
              selectedIcon: const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
              label: _appData.tr('Attendance'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outlined),
              selectedIcon: const Icon(Icons.people, color: Color(0xFF2563EB)),
              label: _appData.tr('Students'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF2563EB)),
              label: _appData.tr('Fees'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings, color: Color(0xFF2563EB)),
              label: 'Admin Control',
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: KPI OVERVIEW & CLASSROOM HUB ====================
  Widget _buildHomeKpiAndAnalyticsTab(Color cardColor, Color textColor) {
    final admin = _appData.currentUser;
    final isZoya = admin?.name.toLowerCase().contains('zoya') == true || admin?.email == 'zm@124';

    final activeStudents = _appData.users.where((u) {
      if (u.role != 'student' || u.status != 'approved' || u.isArchived) return false;
      return isZoya ? u.assignedClass.contains('Commerce') : !u.assignedClass.contains('Commerce');
    }).toList();

    final pendingStudents = _appData.users.where((u) => u.role == 'student' && u.status == 'pending').toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF5B5FC7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school, color: Color(0xFF2563EB), size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${admin?.name ?? "Admin"} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(AppData.instituteName, style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI OVERVIEW SECTION
          Text('KPI Performance Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildKpiCard('Total Active Students', '${activeStudents.length}', 'Active enrolled', Icons.groups_rounded, const Color(0xFF2563EB), cardColor, textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard('Class Average Grade', '88.5%', 'B+ Performance', Icons.grade_rounded, const Color(0xFF10B981), cardColor, textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildKpiCard('Pending Submissions', '${_appData.homeworkList.length}', 'Homeworks & Tests', Icons.pending_actions_rounded, const Color(0xFFEF4444), cardColor, textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard('Active Batches', '${_appData.classesForCurrentAdmin.length}', 'Commerce & Science', Icons.class_rounded, const Color(0xFF5B5FC7), cardColor, textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // CLASSROOM HUB & ANALYTICS PANEL
          Text('Classroom Hub & Control Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),

          // Launcher Card for Classroom Hub
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
                  Icon(Icons.hub_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Launch Classroom Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Course Work, Homework Management, Quiz Arena & Live Stream', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Toolbar: Content Uploader, Announcement Broadcaster, Live Class Initializer
          Row(
            children: [
              Expanded(
                child: _buildActionButtonTile(
                  title: 'Content Uploader',
                  icon: Icons.upload_file_rounded,
                  color: const Color(0xFF2563EB),
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButtonTile(
                  title: 'Announcement Broadcaster',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF10B981),
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => _showBroadcastAnnouncementDialog(cardColor, textColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButtonTile(
                  title: 'Live Class Initializer',
                  icon: Icons.live_tv_rounded,
                  color: const Color(0xFFEF4444),
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => _showLiveClassInitializerDialog(cardColor, textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pending Approvals Banner
          if (pendingStudents.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Pending Student Approvals (${pendingStudents.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
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
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved ${student.name}!')));
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

          // Recent Notices Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Broadcaster Notices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
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
                leading: const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB)),
                title: Text(notice.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                subtitle: Text(notice.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String val, String subtitle, IconData icon, Color color, Color cardColor, Color textColor) {
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
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionButtonTile({
    required String title,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center, maxLines: 2),
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

    for (var student in studentsInBatch) {
      _dailyStatusMap.putIfAbsent(student.id, () {
        final existing = _appData.attendanceRecords.firstWhere(
          (r) => r.studentId == student.id && AppData.formatLocalDate(r.date) == localFormattedDate,
          orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: 'Present', markedBy: ''),
        );
        return existing.studentId.isNotEmpty ? existing.status : 'Present';
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_appData.tr('Daily Attendance Marking'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () => _showMonthlyCalendarDialog(context, cardColor, textColor),
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Monthly View', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                          decoration: const InputDecoration(labelText: 'Select Batch / Class', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
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
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFF2563EB),
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
                        label: Text(localFormattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
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
                        label: const Text('Save Attendance', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusChoiceChip(student.id, 'P', 'Present', currentStatus, const Color(0xFF10B981)),
                                _buildStatusChoiceChip(student.id, 'A', 'Absent', currentStatus, const Color(0xFFEF4444)),
                                _buildStatusChoiceChip(student.id, 'L', 'Leave', currentStatus, const Color(0xFF2563EB)),
                                _buildStatusChoiceChip(student.id, 'LT', 'Late', currentStatus, Colors.orange),
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

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Attendance Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _selectedCalendarStudentId,
                    decoration: const InputDecoration(labelText: 'Select Student', border: OutlineInputBorder()),
                    items: studentsInBatch.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.rollNo})'))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => _selectedCalendarStudentId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
                      itemCount: daysInMonth,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final dateStr = '$_calendarYear-${_calendarMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                        final rec = _appData.attendanceRecords.firstWhere(
                          (r) => r.studentId == selectedStudent.id && AppData.formatLocalDate(r.date) == dateStr,
                          orElse: () => AttendanceRecord(studentId: '', studentName: '', className: '', date: DateTime.now(), status: 'Unmarked', markedBy: ''),
                        );

                        Color cellColor = Colors.grey.shade200;
                        if (rec.status == 'Present') cellColor = const Color(0xFF10B981);
                        if (rec.status == 'Absent') cellColor = const Color(0xFFEF4444);
                        if (rec.status == 'Leave') cellColor = const Color(0xFF2563EB);

                        return Container(
                          decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: rec.status == 'Unmarked' ? Colors.black : Colors.white)),
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

  // ==================== TAB 3: STUDENTS DIRECTORY ====================
  Widget _buildStudentsDirectoryTab(Color cardColor, Color textColor) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_appData.tr('Students Directory'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditStudentScreen())),
                icon: const Icon(Icons.person_add, size: 16),
                label: Text(_appData.tr('Add Student'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            decoration: InputDecoration(
              hintText: _appData.tr('Search Student'),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: cardColor,
            ),
            onChanged: (val) => setState(() => _studentSearchQuery = val),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: studentsList.length,
            itemBuilder: (context, index) {
              final student = studentsList[index];

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: Color(0xFF2563EB)),
                  ),
                  title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  subtitle: Text('${student.assignedClass} • Roll: ${student.rollNo}\nPhone: ${student.phone} | PIN: ${student.studentPin}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditStudentScreen(studentToEdit: student)));
                        },
                      ),
                      IconButton(
                        icon: Icon(student.isArchived ? Icons.unarchive : Icons.archive, color: Colors.grey),
                        onPressed: () {
                          if (student.isArchived) {
                            _appData.unarchiveStudent(student.id);
                          } else {
                            _appData.archiveStudent(student.id);
                          }
                        },
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

  // ==================== TAB 4: FEES MANAGEMENT ====================
  Widget _buildFeesTab(Color cardColor, Color textColor) {
    final totalCollected = _appData.fees.where((f) => f.isPaid || f.isPartial).fold(0.0, (sum, f) => sum + f.paidAmount);
    final totalPending = _appData.fees.fold(0.0, (sum, f) => sum + (f.amount - f.paidAmount));

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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () => _showRecordPaymentDialog(context, cardColor, textColor),
                icon: const Icon(Icons.add, size: 16),
                label: Text(_appData.tr('Record Payment'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Collected', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('₹${totalCollected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
                Column(
                  children: [
                    const Text('Total Pending', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('₹${totalPending.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appData.fees.length,
            itemBuilder: (context, index) {
              final fee = _appData.fees[index];
              final student = _appData.users.firstWhere((u) => u.id == fee.studentId, orElse: () => UserModel(id: '', name: fee.studentName, email: '', password: '', role: 'student', phone: '9876543210'));

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(fee.studentName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: Text('${fee.className} • ${fee.month}\nPaid: ₹${fee.paidAmount.toStringAsFixed(0)} / ₹${fee.amount.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFF10B981)),
                    onPressed: () => _sendWhatsAppReminder(student, fee),
                  ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Record Fee Payment', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStudentId,
              decoration: const InputDecoration(labelText: 'Student'),
              items: activeStudents.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (val) {
                if (val != null) selectedStudentId = val;
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              final student = activeStudents.firstWhere((s) => s.id == selectedStudentId);
              final paidAmt = double.tryParse(amountController.text.trim()) ?? 2500.0;
              final fee = _appData.fees.firstWhere((f) => f.studentId == student.id, orElse: () {
                final newFee = FeeModel(id: 'fee_${DateTime.now().millisecondsSinceEpoch}', studentId: student.id, studentName: student.name, className: student.assignedClass, month: 'September 2026', amount: 2500, paidAmount: 0, isPaid: false, date: 'Pending');
                _appData.fees.add(newFee);
                return newFee;
              });

              _appData.recordFeePayment(feeId: fee.id, paidAmount: paidAmt, totalAmount: 2500, paymentMode: 'Cash', note: 'Recorded by Admin');
              Navigator.pop(context);
            },
            child: const Text('Save Payment'),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 5: ADMIN CONTROL PANEL (SYSTEM HEALTH, ROLE TABLE, SECURITY AUDIT LOGS) ====================
  Widget _buildAdminControlPanelTab(Color cardColor, Color textColor) {
    final totalUsers = _appData.users.length;
    final activeSessions = 18; // Simulated active sessions count
    final systemLoad = '99.9% Uptime (24ms)';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2563EB), size: 28),
              const SizedBox(width: 8),
              Text('Admin Control Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),

          // 1. SYSTEM HEALTH CARDS
          Text('System Health & Infrastructure', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: _buildHealthCard('Total Accounts', '$totalUsers Users', Icons.group_work_rounded, const Color(0xFF2563EB), cardColor, textColor)),
              const SizedBox(width: 10),
              Expanded(child: _buildHealthCard('Active Sessions', '$activeSessions Online', Icons.online_prediction_rounded, const Color(0xFF10B981), cardColor, textColor)),
              const SizedBox(width: 10),
              Expanded(child: _buildHealthCard('System Health', systemLoad, Icons.speed_rounded, const Color(0xFF5B5FC7), cardColor, textColor)),
            ],
          ),
          const SizedBox(height: 20),

          // 2. ROLE MANAGEMENT TABLE & ACCOUNT STATUS TOGGLES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Role Management & Credentials Table', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditStudentScreen())),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add User', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _appData.users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final user = _appData.users[idx];
                final isSuspended = user.status == 'suspended';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'admin' ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                    child: Icon(user.role == 'admin' ? Icons.security : Icons.person, color: Colors.white, size: 18),
                  ),
                  title: Row(
                    children: [
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        backgroundColor: user.role == 'admin' ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Email: ${user.email} • Assigned: ${user.assignedClass}\n'
                    'Status: ${user.status.toUpperCase()}',
                    style: TextStyle(fontSize: 11, color: isSuspended ? Colors.red : Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reset Password Button
                      IconButton(
                        icon: const Icon(Icons.lock_reset, color: Color(0xFF2563EB), size: 20),
                        tooltip: 'Reset User Password',
                        onPressed: () => _showAdminResetPasswordDialog(context, user, cardColor, textColor),
                      ),
                      // Suspend / Activate Account Status Toggle
                      Switch(
                        value: !isSuspended,
                        activeColor: const Color(0xFF10B981),
                        inactiveThumbColor: Colors.red,
                        onChanged: (val) {
                          final newStatus = val ? 'approved' : 'suspended';
                          _appData.toggleUserAccountStatus(user.id, newStatus);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Account for ${user.name} set to ${newStatus.toUpperCase()}')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. SECURITY AUDIT LOGS
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text('Security Audit Logs & Triggers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),

          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _appData.auditLogs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final log = _appData.auditLogs[idx];
                  Color eventColor = const Color(0xFF2563EB);
                  if (log.event.contains('Failed') || log.event.contains('Suspended')) eventColor = const Color(0xFFEF4444);
                  if (log.event.contains('Reset') || log.event.contains('Success')) eventColor = const Color(0xFF10B981);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: eventColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.security_rounded, color: eventColor, size: 20),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(log.event, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: eventColor)),
                        Text(log.timestamp, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    subtitle: Text(
                      'User: ${log.userIdentifier} • IP: ${log.ipAddress}\n'
                      '${log.details}',
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SYSTEM TOOLS LIST (Backup, Language, Dark Mode)
          Text('System Governance & Backups', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),

          _buildControlTile('JSON Backup & Restore Engine', Icons.backup_rounded, const Color(0xFF10B981), () {
            _showBackupRestoreDialog(context, cardColor, textColor);
          }, cardColor, textColor),

          _buildControlTile('Language Toggle (Hindi / English)', Icons.language_rounded, const Color(0xFF2563EB), () {
            _appData.toggleLanguage();
          }, cardColor, textColor, trailingText: _appData.isHindi ? 'हिंदी' : 'English'),

          _buildControlTile('System Dark Mode', Icons.dark_mode_rounded, const Color(0xFF5B5FC7), () {
            _appData.toggleDarkMode();
          }, cardColor, textColor, trailingWidget: Switch(value: _appData.isDarkMode, onChanged: (val) => _appData.toggleDarkMode(val))),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, IconData icon, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildControlTile(String title, IconData icon, Color color, VoidCallback onTap, Color cardColor, Color textColor, {String? trailingText, Widget? trailingWidget}) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
        trailing: trailingWidget ?? (trailingText != null ? Text(trailingText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))) : const Icon(Icons.arrow_forward_ios, size: 14)),
        onTap: onTap,
      ),
    );
  }

  void _showAdminResetPasswordDialog(BuildContext context, UserModel user, Color cardColor, Color textColor) {
    final newPassController = TextEditingController(text: '12345678');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Reset Password: ${user.name}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(labelText: 'New Password *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              if (newPassController.text.trim().isNotEmpty) {
                _appData.resetPasswordByIdentifier(user.email, newPassController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated for ${user.name}!')));
              }
            },
            child: const Text('Save New Password'),
          ),
        ],
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
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
}
