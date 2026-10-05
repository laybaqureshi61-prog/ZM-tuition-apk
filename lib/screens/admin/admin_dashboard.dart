import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import '../auth/login_screen.dart';
import 'all_students_screen.dart';
import 'add_edit_student_screen.dart';
import 'upload_notes_screen.dart';
import 'manage_fees_screen.dart';
import 'second_admin_view.dart';
import '../common/notices_screen.dart';
import '../common/notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AppData _appData = AppData();

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

  void _showMarkAttendanceDialog(BuildContext context) {
    final allowedClasses = _appData.classesForCurrentAdmin;
    String selectedClass = allowedClasses.isNotEmpty ? allowedClasses.first : 'Class 10th (Science & Math)';
    DateTime selectedDate = DateTime.now();
    final Map<String, String> statusMap = {};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final studentsInClass = _appData.users
              .where((u) => u.role == 'student' && u.status == 'approved' && u.assignedClass == selectedClass)
              .toList();

          for (var s in studentsInClass) {
            statusMap.putIfAbsent(s.id, () => 'Present');
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mark Daily Attendance', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedClass,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: allowedClasses.map((cls) => DropdownMenuItem(value: cls, child: Text(cls, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedClass = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF4F46E5)),
                          label: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
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
                            setDialogState(() {
                              for (var s in studentsInClass) {
                                statusMap[s.id] = 'Present';
                              }
                            });
                          },
                          icon: const Icon(Icons.done_all, size: 14),
                          label: const Text('All Present', style: TextStyle(fontSize: 11)),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          onPressed: () {
                            setDialogState(() {
                              for (var s in studentsInClass) {
                                statusMap[s.id] = 'Absent';
                              }
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 14),
                          label: const Text('All Absent', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: studentsInClass.isEmpty
                          ? const Center(child: Text('No approved students in this class', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: studentsInClass.length,
                              itemBuilder: (context, index) {
                                final student = studentsInClass[index];
                                final currentStatus = statusMap[student.id] ?? 'Present';

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('Roll: ${student.rollNo}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: ['Present', 'Absent', 'Late', 'Leave'].map((st) {
                                          final isSelected = currentStatus == st;
                                          Color chipColor = st == 'Present' ? Colors.green : (st == 'Absent' ? Colors.red : Colors.orange);

                                          return InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                statusMap[student.id] = st;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isSelected ? chipColor : Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: chipColor),
                                              ),
                                              child: Text(
                                                st,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : chipColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () {
                  final admin = _appData.currentUser;
                  for (var student in studentsInClass) {
                    _appData.markAttendance(
                      studentId: student.id,
                      studentName: student.name,
                      className: selectedClass,
                      date: selectedDate,
                      status: statusMap[student.id] ?? 'Present',
                      markedBy: admin?.name ?? 'Zoya / Muskan',
                    );
                  }
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Attendance recorded for ${studentsInClass.length} students!')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Save Attendance'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = _appData.currentUser;
    final isZoya = admin?.name.toLowerCase().contains('zoya') == true || admin?.email == 'zm@124';

    final pendingStudents = _appData.users.where((u) => u.role == 'student' && u.status == 'pending').toList();

    final approvedStudents = _appData.users.where((u) {
      if (u.role != 'student' || u.status != 'approved') return false;
      if (isZoya) {
        return u.assignedClass.contains('Commerce');
      } else {
        return !u.assignedClass.contains('Commerce');
      }
    }).toList();

    final isDark = _appData.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final streamLabel = isZoya ? '12th & 11th Commerce Stream' : '9th to 12th Science & Math Stream';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ZM Admin Dashboard', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Logged in: ${admin?.name ?? "Zoya / Muskan"}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _appData.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),

      // Admin Navigation Drawer (PRD Screen 18 Alignment)
      drawer: Drawer(
        backgroundColor: cardColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
              ),
              accountName: Text(admin?.name ?? 'Admin 1 (Zoya)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text(admin?.email ?? 'zm@124'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Color(0xFF4F46E5), size: 36),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Dashboard', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_outlined, color: Color(0xFF4F46E5)),
                    title: Text('All Students', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AllStudentsScreen())); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Manage Fees', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFeesScreen())); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Attendance', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); _showMarkAttendanceDialog(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: Color(0xFF4F46E5)),
                    title: Text('Upload Notes', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen())); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.campaign_outlined, color: Color(0xFF4F46E5)),
                    title: Text('Notices & Announcements', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz, color: Color(0xFF4F46E5)),
                    title: Text('Second Admin View', style: TextStyle(color: textColor)),
                    onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SecondAdminViewScreen())); },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('SYSTEM DARK MODE', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
              // Admin Header Card (PRD Screen 9)
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
                      child: Icon(Icons.admin_panel_settings, color: const Color(0xFF4F46E5), size: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${admin?.name ?? "Admin"} 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Managing: $streamLabel',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stat Counter Row (PRD Screen 9)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Students', '${approvedStudents.length}', Icons.group, const Color(0xFF3B82F6), cardColor, textColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Total Classes', '${_appData.classesForCurrentAdmin.length}', Icons.class_outlined, const Color(0xFF10B981), cardColor, textColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Cards Grid (PRD Screen 9 Alignment)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildAdminCard('All Students', Icons.group_outlined, const Color(0xFF3B82F6), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllStudentsScreen()));
                  }, cardColor, textColor),
                  _buildAdminCard('Add Student', Icons.person_add_outlined, const Color(0xFF10B981), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditStudentScreen()));
                  }, cardColor, textColor),
                  _buildAdminCard('Manage Fees', Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFeesScreen()));
                  }, cardColor, textColor),
                  _buildAdminCard('Attendance', Icons.calendar_today_outlined, const Color(0xFFEC4899), () {
                    _showMarkAttendanceDialog(context);
                  }, cardColor, textColor),
                  _buildAdminCard('Payment Records', Icons.receipt_long_outlined, const Color(0xFF8B5CF6), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFeesScreen()));
                  }, cardColor, textColor),
                  _buildAdminCard('Upload Notes', Icons.cloud_upload_outlined, const Color(0xFFEF4444), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen()));
                  }, cardColor, textColor),
                ],
              ),
              const SizedBox(height: 20),

              // System Dark Mode Toggle Bar
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(String title, IconData icon, Color color, VoidCallback onTap, Color cardColor, Color textColor) {
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
}
