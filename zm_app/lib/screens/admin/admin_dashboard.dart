import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../common/settings_screen.dart';
import '../common/pdf_preview_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_students_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_notes_screen.dart';
import 'admin_notices_screen.dart';
import 'admin_fees_screen.dart';
import 'admin_classroom_screen.dart';
import 'admin_live_tests_screen.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  // Active Admin View: 'zoya' (Commerce 11/12) vs 'muskan' (Science 9th to 12th)
  late String _activeAdmin;

  List<dynamic> _students = [];
  List<dynamic> _requests = [];
  List<dynamic> _notes = [];
  List<dynamic> _fees = [];
  List<dynamic> _notices = [];
  List<dynamic> _batches = [];
  int _todayPresentCount = 0;

  // Search & Filters
  String _searchQuery = '';
  String _departmentFilter = 'my_dept'; // 'my_dept' or 'all'

  // Inline Notice form
  final _noticeTitleCtrl = TextEditingController();
  final _noticeContentCtrl = TextEditingController();
  bool _isPostingNotice = false;

  bool get isZoyaView => _activeAdmin == 'zoya';

  String get activeTeacherName => isZoyaView ? 'Zoya Mam' : 'Muskan Mam';
  String get activeDepartmentName =>
      isZoyaView ? 'Commerce Department (Class 11 & 12)' : 'Science & Maths Department (Class 9th to 12th)';
  String get activeSubjects => isZoyaView
      ? 'Commerce: Accounts • Economics • Business Studies'
      : 'Science & Maths: Mathematics & Science (Classes 9, 10, 11 & 12)';
  Color get activeBrandColor => isZoyaView ? const Color(0xFF1E3A8A) : AppTheme.brandTeal;
  Color get activeAccentColor => isZoyaView ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
  String get activeFeeRange => isZoyaView ? '₹1,000/mo' : 'Class 9 & 10: ₹600/mo • Class 11 & 12: ₹1,000/mo';

  @override
  void initState() {
    super.initState();
    final type = widget.user.adminType?.toLowerCase();
    final name = widget.user.name.toLowerCase();
    _activeAdmin = (type == 'muskan' || name.contains('muskan')) ? 'muskan' : 'zoya';
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noticeTitleCtrl.dispose();
    _noticeContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final studentsList = await ApiService.getStudents();
    final requestsList = await ApiService.getRegistrationRequests();
    final notesList = await ApiService.getNotes();
    final feesList = await ApiService.getFees();
    final noticesList = await ApiService.getNotices();
    final batchesList = await ApiService.getBatches();
    final attData = await ApiService.getAttendance(todayStr);

    int present = 0;
    attData.forEach((k, v) {
      if (v == 'P') present++;
    });

    if (!mounted) return;
    setState(() {
      _students = studentsList;
      _requests = requestsList;
      _notes = notesList;
      _fees = feesList;
      _notices = noticesList;
      _batches = batchesList;
      _todayPresentCount = present;
      _isLoading = false;
    });
  }

  bool _isCommerceStudent(dynamic s) {
    final batch = (s['batch'] ?? '').toString().toLowerCase();
    return batch.contains('commerce') || batch.contains('accounts');
  }

  bool _isScienceStudent(dynamic s) {
    final batch = (s['batch'] ?? '').toString().toLowerCase();
    return batch.contains('science') ||
        batch.contains('math') ||
        batch.contains('physics') ||
        batch.contains('9') ||
        batch.contains('10') ||
        (batch.contains('11') && !batch.contains('commerce')) ||
        (batch.contains('12') && !batch.contains('commerce'));
  }

  List<dynamic> get _myDepartmentStudents {
    if (isZoyaView) {
      return _students.where(_isCommerceStudent).toList();
    } else {
      return _students.where(_isScienceStudent).toList();
    }
  }

  List<dynamic> get _myDepartmentRequests {
    if (isZoyaView) {
      return _requests.where((r) => _isCommerceStudent(r)).toList();
    } else {
      return _requests.where((r) => _isScienceStudent(r)).toList();
    }
  }

  List<dynamic> get _myDepartmentBatches {
    if (isZoyaView) {
      return _batches.where((b) => (b['teacher'] ?? '').toString().toLowerCase().contains('zoya') || (b['name'] ?? '').toString().contains('Commerce')).toList();
    } else {
      return _batches.where((b) => (b['teacher'] ?? '').toString().toLowerCase().contains('muskan') || !(b['name'] ?? '').toString().contains('Commerce')).toList();
    }
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to log out of the admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
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

  void _showChangeAdminPasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeBrandColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock_reset_rounded, color: activeBrandColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Change Admin Password',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a new login password for $activeTeacherName (min 6 characters):',
                      style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        hintText: 'Re-enter new password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeBrandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPass = newPassCtrl.text.trim();
                          final confirmPass = confirmPassCtrl.text.trim();

                          if (newPass.length < 6) {
                            setDialogState(() => errorText = 'Password must be at least 6 characters.');
                            return;
                          }
                          if (newPass != confirmPass) {
                            setDialogState(() => errorText = 'Passwords do not match.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          final res = await ApiService.changePassword(newPassword: newPass);

                          if (!dialogCtx.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.successGreen,
                                content: Text(res['message'] ?? 'Admin password changed successfully!'),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              errorText = res['message'] ?? 'Failed to update password.';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangeAdminPasskeyDialog() {
    final passkeyCtrl = TextEditingController();
    bool obscure = false;
    bool isSaving = false;
    String? currentKey;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (currentKey == null) {
              ApiService.getAdminPasskey().then((k) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    currentKey = k;
                    passkeyCtrl.text = k;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: Colors.orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Faculty Portal Passkey',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This security passkey is required to unlock the Admin / Teacher portal:',
                      style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passkeyCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Faculty Passkey',
                        hintText: 'e.g. ZM@2026',
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.refresh, size: 14),
                          label: const Text('Reset to ZM@2026', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => passkeyCtrl.text = 'ZM@2026'),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newKey = passkeyCtrl.text.trim();
                          if (newKey.length < 4) {
                            setDialogState(() => errorText = 'Passkey must be at least 4 characters.');
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          final res = await ApiService.updateAdminPasskey(newKey);

                          if (!dialogCtx.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.successGreen,
                                content: Text('Faculty Passkey updated to "$newKey"!'),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              errorText = res['message'] ?? 'Failed to update passkey.';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Passkey'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProctoringLogsDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return FutureBuilder<List<dynamic>>(
            future: ApiService.getProctoringLogs(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Live Proctoring & Cheating Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Real-time audit of student test violations', style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 600,
                  height: 400,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : logs.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 48, color: Colors.green),
                                  SizedBox(height: 10),
                                  Text('Clean Record: No cheating or proctoring violations recorded yet.', style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: logs.length,
                              itemBuilder: (context, i) {
                                final log = logs[i];
                                final isDisqualified = log['status'] == 'DISQUALIFIED';
                                final warnings = log['warningsCount'] ?? 0;
                                final student = log['studentName'] ?? 'Student';
                                final reason = log['violationReason'] ?? 'Normal Submission';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: isDisqualified ? Colors.red.shade300 : AppTheme.line),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isDisqualified ? Colors.red.shade100 : Colors.green.shade100,
                                      child: Icon(
                                        isDisqualified ? Icons.block_rounded : Icons.check_circle_outline,
                                        color: isDisqualified ? Colors.red.shade900 : Colors.green.shade900,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(student, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDisqualified ? Colors.red : Colors.green,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isDisqualified ? 'DISQUALIFIED' : 'PASSED',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Score: ${log['obtainedMarks']} / ${log['totalMarks']} • Warnings: $warnings', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        if (reason.isNotEmpty)
                                          Text('Details: $reason', style: TextStyle(fontSize: 11, color: isDisqualified ? Colors.red.shade700 : AppTheme.inkSecondary)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- MODAL 1: ADD STUDENT ---
  void _showAddStudentModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    String selectedBatch = isZoyaView ? 'Class 11 & 12 (Commerce)' : 'Class 10 (Science & Maths)';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activeBrandColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_add_rounded, color: activeBrandColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Student (${isZoyaView ? "Commerce" : "Science 9-12"})',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.ink),
                            ),
                            Text(
                              'Managed by $activeTeacherName',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.inkSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Student Full Name *', hintText: 'Enter student name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: '10-Digit Phone Number *', hintText: 'e.g. 9876543210'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address (Optional)', hintText: 'e.g. student@gmail.com'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBatch,
                  decoration: const InputDecoration(labelText: 'Class / Batch'),
                  items: const [
                    DropdownMenuItem(value: 'Class 9 (Maths & Science)', child: Text('Class 9 (Maths & Science) - Muskan (₹600/mo)')),
                    DropdownMenuItem(value: 'Class 10 (Maths & Science)', child: Text('Class 10 (Maths & Science) - Muskan (₹600/mo)')),
                    DropdownMenuItem(value: 'Class 11 (Maths & Science)', child: Text('Class 11 (Maths & Science) - Muskan (₹1000/mo)')),
                    DropdownMenuItem(value: 'Class 12 (Maths & Science)', child: Text('Class 12 (Maths & Science) - Muskan (₹1000/mo)')),
                    DropdownMenuItem(value: 'Class 11 & 12 (Commerce)', child: Text('Class 11 & 12 (Commerce: Accounts/Eco) - Zoya (₹1000/mo)')),
                  ],
                  onChanged: (v) => setModalState(() => selectedBatch = v ?? selectedBatch),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rollCtrl,
                  decoration: const InputDecoration(labelText: 'Roll Number (Optional - Auto assigned if blank)', hintText: 'e.g. ZM-105'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeBrandColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(isSubmitting ? 'Adding...' : 'Enroll Student with $activeTeacherName', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final roll = rollCtrl.text.trim();

                            if (name.isEmpty || phone.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: AppTheme.dangerRed, content: Text('Please enter valid Student Name and 10-digit Phone Number.')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            final res = await ApiService.addStudent(
                              name: name,
                              phone: phone,
                              email: email.isNotEmpty ? email : null,
                              batch: selectedBatch,
                              rollNo: roll.isNotEmpty ? roll : null,
                            );

                            if (!mounted) return;
                            setModalState(() => isSubmitting = false);

                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(backgroundColor: AppTheme.successGreen, content: Text(res['message'] ?? 'Student added successfully!')),
                              );
                              _loadDashboardData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(backgroundColor: AppTheme.dangerRed, content: Text(res['message'] ?? 'Failed to add student.')),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL 2: ADD / EDIT BATCH & TIMING ---
  void _showAddBatchModal([dynamic existingBatch]) {
    final nameCtrl = TextEditingController(text: existingBatch?['name'] ?? '');
    final timeCtrl = TextEditingController(text: existingBatch?['time'] ?? '');
    final subjectCtrl = TextEditingController(text: existingBatch?['subject'] ?? '');
    final daysCtrl = TextEditingController(text: existingBatch?['days'] ?? 'Mon - Sat');
    final feeCtrl = TextEditingController(text: (existingBatch?['fee'] ?? (isZoyaView ? 1000 : 500)).toString());
    final meetCtrl = TextEditingController(text: existingBatch?['meetLink'] ?? 'https://meet.google.com/new');
    String teacher = existingBatch?['teacher'] ?? (isZoyaView ? 'Zoya' : 'Muskan');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activeBrandColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.schedule_rounded, color: activeBrandColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          existingBatch != null ? 'Edit Batch Timing' : 'Add New Batch & Time Slot',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.ink),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name *',
                    hintText: 'e.g. Class 12 Science (Physics & Chemistry)',
                    prefixIcon: Icon(Icons.school_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 460;
                    if (isNarrow) {
                      return Column(
                        children: [
                          TextField(
                            controller: timeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Time Slot *',
                              hintText: 'e.g. 6:15 PM - 7:30 PM',
                              prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: daysCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Class Days',
                              hintText: 'e.g. Mon - Sat',
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Time Slot *',
                              hintText: 'e.g. 6:15 PM - 7:30 PM',
                              prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: daysCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Class Days',
                              hintText: 'e.g. Mon - Sat',
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subjects Covered',
                    hintText: 'e.g. Physics, Chemistry, Maths & Biology',
                    prefixIcon: Icon(Icons.menu_book_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 460;
                    if (isNarrow) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: teacher,
                            decoration: const InputDecoration(labelText: 'Assigned Teacher'),
                            items: const [
                              DropdownMenuItem(value: 'Muskan', child: Text('Muskan Mam (Maths & Science 9-12)')),
                              DropdownMenuItem(value: 'Zoya', child: Text('Zoya Mam (Commerce 11-12)')),
                            ],
                            onChanged: (v) => setModalState(() => teacher = v ?? teacher),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: feeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Monthly Fee (₹)', hintText: '500 or 1000', prefixIcon: Icon(Icons.currency_rupee, size: 20)),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: teacher,
                            decoration: const InputDecoration(labelText: 'Assigned Teacher'),
                            items: const [
                              DropdownMenuItem(value: 'Muskan', child: Text('Muskan Mam (Maths & Science 9-12)')),
                              DropdownMenuItem(value: 'Zoya', child: Text('Zoya Mam (Commerce 11-12)')),
                            ],
                            onChanged: (v) => setModalState(() => teacher = v ?? teacher),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: feeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Monthly Fee (₹)', hintText: '500 or 1000', prefixIcon: Icon(Icons.currency_rupee, size: 20)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: meetCtrl,
                  decoration: const InputDecoration(labelText: 'Google Meet / Live Link', hintText: 'https://meet.google.com/xyz', prefixIcon: Icon(Icons.video_call_outlined, size: 20)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: activeBrandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                    icon: isSaving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(existingBatch != null ? 'Update Batch Schedule' : 'Create Batch & Set Timing', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final time = timeCtrl.text.trim();
                            if (name.isEmpty || time.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.dangerRed, content: Text('Please enter Batch Name and Time Slot.')));
                              return;
                            }
                            setModalState(() => isSaving = true);
                            bool ok = false;
                            if (existingBatch != null) {
                              ok = await ApiService.updateBatch(existingBatch['id'], {
                                'name': name,
                                'time': time,
                                'subject': subjectCtrl.text.trim(),
                                'days': daysCtrl.text.trim(),
                                'teacher': teacher,
                                'fee': int.tryParse(feeCtrl.text.trim()) ?? 500,
                                'meetLink': meetCtrl.text.trim(),
                              });
                            } else {
                              ok = await ApiService.addBatch(
                                name: name,
                                time: time,
                                subject: subjectCtrl.text.trim(),
                                days: daysCtrl.text.trim(),
                                teacher: teacher,
                                fee: int.tryParse(feeCtrl.text.trim()) ?? 500,
                                meetLink: meetCtrl.text.trim(),
                              );
                            }
                            if (!mounted) return;
                            setModalState(() => isSaving = false);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed, content: Text(ok ? 'Batch schedule saved successfully!' : 'Failed to save batch.')),
                            );
                            _loadDashboardData();
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL 3: UPLOAD NOTE / STUDY MATERIAL (WITH REAL PDF & CAMERA PICKER) ---
  void _showUploadNoteModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String subject = isZoyaView ? 'Accountancy' : 'Physics';
    String batch = isZoyaView ? 'Class 11 & 12 (Commerce)' : 'Class 10 (Science & Maths)';
    String? selectedFileName;
    String? selectedFileSize;
    String? selectedFileType;
    bool isUploading = false;

    final scienceSubs = ['Physics', 'Chemistry', 'Biology', 'Mathematics', 'General Science'];
    final commerceSubs = ['Accountancy', 'Economics', 'Business Studies', 'Applied Maths'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPdfFile() async {
            try {
              final result = await FilePickerPlatform.instance.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result.isNotEmpty) {
                final file = result.first;
                setModalState(() {
                  selectedFileName = file.name;
                  selectedFileSize = '2.4 MB';
                  selectedFileType = 'PDF Document';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = file.name.replaceAll('.pdf', '').replaceAll('_', ' ');
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File selection notice: $e')));
              }
            }
          }

          Future<void> pickFromCamera() async {
            try {
              final picker = ImagePicker();
              final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
              if (photo != null) {
                setModalState(() {
                  selectedFileName = 'Camera_Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
                  selectedFileSize = '1.8 MB';
                  selectedFileType = 'Camera Scanned Document';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = 'Scanned Notes ${DateFormat('dd MMM').format(DateTime.now())}';
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera notice: $e')));
              }
            }
          }

          Future<void> pickFromGallery() async {
            try {
              final picker = ImagePicker();
              final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (photo != null) {
                setModalState(() {
                  selectedFileName = photo.name.isNotEmpty ? photo.name : 'Gallery_Document_${DateTime.now().millisecondsSinceEpoch}.pdf';
                  selectedFileSize = '2.1 MB';
                  selectedFileType = 'Device Gallery Image';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = 'Document ${DateFormat('dd MMM').format(DateTime.now())}';
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gallery notice: $e')));
              }
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.deepOrange.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.upload_file_rounded, color: Colors.deepOrange, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Upload Notes & PDF Material', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                              Text('Uploaded by $activeTeacherName', style: const TextStyle(fontSize: 11.5, color: AppTheme.inkSecondary)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Choose Upload Source (PDF / Camera / Gallery)
                  const Text('Select Document Source *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.deepOrange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: pickPdfFile,
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange, size: 18),
                          label: const Text('PDF File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: activeBrandColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: pickFromCamera,
                          icon: Icon(Icons.camera_alt, color: activeBrandColor, size: 18),
                          label: Text('Camera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: activeBrandColor)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: pickFromGallery,
                          icon: const Icon(Icons.photo_library, color: Colors.purple, size: 18),
                          label: const Text('Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selected File Badge / Status
                  if (selectedFileName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade400, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedFileName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('$selectedFileType • $selectedFileSize (Ready to Publish)', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            tooltip: 'Clear File',
                            onPressed: () {
                              setModalState(() {
                                selectedFileName = null;
                                selectedFileSize = null;
                                selectedFileType = null;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please tap PDF File, Camera, or Gallery above to select notes.',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Chapter / Note Title *', hintText: 'e.g. Chapter 4: Carbon & Its Compounds / Partnership'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: subject,
                          decoration: const InputDecoration(labelText: 'Subject'),
                          items: (isZoyaView ? commerceSubs : scienceSubs).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setModalState(() => subject = v ?? subject),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: batch,
                          decoration: const InputDecoration(labelText: 'Target Batch'),
                          items: const [
                            DropdownMenuItem(value: 'Class 9 (Maths & Science)', child: Text('Class 9 Maths & Science')),
                            DropdownMenuItem(value: 'Class 10 (Maths & Science)', child: Text('Class 10 Maths & Science')),
                            DropdownMenuItem(value: 'Class 11 (Maths & Science)', child: Text('Class 11 Maths & Science')),
                            DropdownMenuItem(value: 'Class 12 (Maths & Science)', child: Text('Class 12 Maths & Science')),
                            DropdownMenuItem(value: 'Class 11 & 12 (Commerce)', child: Text('Commerce 11 & 12')),
                          ],
                          onChanged: (v) => setModalState(() => batch = v ?? batch),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description / Topics Covered', hintText: 'Important formulas, exercise solutions and practice problems'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: activeBrandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                      icon: isUploading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(isUploading ? 'Uploading...' : 'Publish PDF Material to Students', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: isUploading
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.dangerRed, content: Text('Please enter Note Title.')));
                                return;
                              }
                              setModalState(() => isUploading = true);
                              final ok = await ApiService.addNote({
                                'title': title,
                                'subject': subject,
                                'batch': batch,
                                'description': descCtrl.text.trim(),
                                'fileName': selectedFileName ?? '${title.replaceAll(' ', '_')}.pdf',
                                'fileSize': selectedFileSize ?? '2.4 MB',
                                'fileType': selectedFileType ?? 'PDF Document',
                                'pdfUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                              });
                              if (!mounted) return;
                              setModalState(() => isUploading = false);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed, content: Text(ok ? 'Note uploaded & broadcasted to students!' : 'Upload failed.')),
                              );
                              _loadDashboardData();
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRemoveStudent(dynamic student) async {
    final name = student['name'] ?? 'Student';
    final studentId = student['id']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 26),
            SizedBox(width: 8),
            Text('Confirm Removal'),
          ],
        ),
        content: Text('Are you sure you want to permanently remove "$name"?\nAll attendance, fees, and access will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Student'),
          ),
        ],
      ),
    );

    if (confirmed == true && studentId.isNotEmpty) {
      setState(() => _isLoading = true);
      final ok = await ApiService.removeStudent(studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed, content: Text(ok ? 'Student "$name" removed.' : 'Failed to remove.')),
      );
      _loadDashboardData();
    }
  }

  Future<void> _handleApproveStudent(dynamic req) async {
    final studentId = req['id']?.toString() ?? '';
    final name = req['name'] ?? 'Student';

    setState(() => _isLoading = true);
    final ok = await ApiService.approveStudent(studentId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed, content: Text(ok ? 'Student "$name" approved! Roll number assigned.' : 'Approval failed.')),
    );
    _loadDashboardData();
  }

  Future<void> _handleRejectStudent(dynamic req) async {
    final studentId = req['id']?.toString() ?? '';
    final name = req['name'] ?? 'Student';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reject Registration'),
        content: Text('Are you sure you want to reject request for "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && studentId.isNotEmpty) {
      setState(() => _isLoading = true);
      final ok = await ApiService.rejectStudent(studentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.inkSecondary, content: Text('Request for "$name" rejected.')));
      _loadDashboardData();
    }
  }

  Future<void> _handlePostNotice() async {
    final title = _noticeTitleCtrl.text.trim();
    final content = _noticeContentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.dangerRed, content: Text('Please fill title and message.')));
      return;
    }
    setState(() => _isPostingNotice = true);
    final formattedTitle = '[$activeTeacherName] $title';
    final ok = await ApiService.addNotice(formattedTitle, content);
    if (!mounted) return;
    setState(() => _isPostingNotice = false);
    if (ok) {
      _noticeTitleCtrl.clear();
      _noticeContentCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.successGreen, content: Text('Notice broadcasted to all students!')));
      _loadDashboardData();
    }
  }

  void _launchMeet() async {
    final uri = Uri.parse('https://meet.google.com/new');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Google Meet session...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsToDisplay = _departmentFilter == 'my_dept' ? _myDepartmentStudents : _students;
    final requestsToDisplay = _departmentFilter == 'my_dept' ? _myDepartmentRequests : _requests;
    final batchesToDisplay = _departmentFilter == 'my_dept' ? _myDepartmentBatches : _batches;

    final filteredStudents = studentsToDisplay.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final phone = (s['phone'] ?? '').toString().toLowerCase();
      final roll = (s['rollNo'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || phone.contains(q) || roll.contains(q);
    }).toList();

    int pendingFeesCount = _fees.where((f) => (f['status'] ?? 'Due') != 'Paid').length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: activeBrandColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.school, size: 20, color: AppTheme.brandTeal),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'ZM Tuition',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3, fontSize: 18),
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
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppTheme.brandTeal),
                tooltip: 'Toggle Theme',
                onPressed: () => AppTheme.toggleTheme(),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.brandTeal), tooltip: 'Refresh All', onPressed: _loadDashboardData),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.brandTeal),
            tooltip: 'More Options',
            onSelected: (val) {
              if (val == 'settings') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)));
              } else if (val == 'change_password') {
                _showChangeAdminPasswordDialog();
              } else if (val == 'change_passkey') {
                _showChangeAdminPasskeyDialog();
              } else if (val == 'manage_live_tests') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminLiveTestsScreen(user: widget.user)));
              } else if (val == 'proctoring_logs') {
                _showProctoringLogsDialog();
              } else if (val == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_live_tests',
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Manage Live Tests (Create & Schedule)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'proctoring_logs',
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Live Test Logs & Violations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 18, color: AppTheme.brandTeal),
                    SizedBox(width: 10),
                    Text('Change Admin Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_passkey',
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_rounded, size: 18, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Change Faculty Passkey'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: AppTheme.brandTeal),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppTheme.dangerRed),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: AppTheme.dangerRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Dual-Admin Switcher (Zoya Commerce vs Muskan Science 9th-12th)
                        _buildAdminRoleSelector(),
                        const SizedBox(height: 14),

                        // 2. Department Brand Greeting Banner
                        _buildDepartmentBanner(),
                        const SizedBox(height: 16),

                        // 3. Circular Quick Menu Row (Inspired by Reference Image 1)
                        _buildQuickActionMenu(),
                        const SizedBox(height: 16),

                        // 4. Department KPI Stats
                        _buildDepartmentKpis(pendingFeesCount),
                        const SizedBox(height: 16),

                        // 5. Approvals Alert Banner (if pending)
                        if (requestsToDisplay.isNotEmpty) ...[
                          _buildApprovalsAlertCard(requestsToDisplay),
                          const SizedBox(height: 16),
                        ],

                        // 6. Main Integrated Tabs (Students, Batches & Timings, Notes & Materials, Modules, Notices)
                        _buildIntegratedTabsContainer(filteredStudents, batchesToDisplay),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // --- 1. DUAL ADMIN ROLE SWITCHER ---
  Widget _buildAdminRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Zoya (Commerce 11 & 12)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeAdmin = 'zoya'),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: isZoyaView ? const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_rounded, size: 20, color: isZoyaView ? Colors.white : const Color(0xFF1E3A8A)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Zoya Mam (Commerce)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isZoyaView ? Colors.white : AppTheme.ink), overflow: TextOverflow.ellipsis),
                          Text('Class 11 & 12 • ₹1,000/mo', style: TextStyle(fontSize: 11, color: isZoyaView ? Colors.white70 : AppTheme.inkSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Muskan (Science 9th to 12th)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeAdmin = 'muskan'),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: !isZoyaView ? const LinearGradient(colors: [Color(0xFF0C4D4A), Color(0xFF14B8A6)]) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.science_rounded, size: 20, color: !isZoyaView ? Colors.white : AppTheme.brandTeal),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Muskan Mam (Maths & Science)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !isZoyaView ? Colors.white : AppTheme.ink), overflow: TextOverflow.ellipsis),
                          Text('Class 9th to 12th • ₹600 - ₹1,000', style: TextStyle(fontSize: 11, color: !isZoyaView ? Colors.white70 : AppTheme.inkSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. DEPARTMENT BANNER ---
  Widget _buildDepartmentBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 680;

        final avatarAndText = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isMobile ? 26 : 34,
              backgroundColor: Colors.white,
              child: Text(
                isZoyaView ? 'Z' : 'M',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: activeBrandColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$activeTeacherName Head View',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeAccentColor.withAlpha(50),
                          border: Border.all(color: activeAccentColor, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isZoyaView ? 'Commerce Head (11-12)' : 'Science & Maths Head (9th-12th)',
                          style: TextStyle(color: activeAccentColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeSubjects,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fees: $activeFeeRange • ${DateFormat("EEEE, dd MMMM yyyy").format(DateTime.now())}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeAccentColor,
                foregroundColor: isZoyaView ? AppTheme.ink : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('+ Add Student', style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: _showAddStudentModal,
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.video_call_rounded, size: 18),
              label: const Text('Start Meet', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _launchMeet,
            ),
          ],
        );

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isZoyaView
                  ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                  : [const Color(0xFF0C4D4A), const Color(0xFF073836)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: activeBrandColor.withAlpha(50), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    avatarAndText,
                    const SizedBox(height: 14),
                    actionButtons,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: avatarAndText),
                    const SizedBox(width: 16),
                    actionButtons,
                  ],
                ),
        );
      },
    );
  }

  // --- 3. CIRCULAR QUICK ACTION MENU (Inspired by Reference Image 1) ---
  Widget _buildQuickActionMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access Menu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCircleMenuItem(
                  label: '+ Upload Note',
                  icon: Icons.upload_file_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: _showUploadNoteModal,
                ),
                _buildCircleMenuItem(
                  label: '+ Add Batch',
                  icon: Icons.more_time_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => _showAddBatchModal(),
                ),
                _buildCircleMenuItem(
                  label: 'Attendance',
                  icon: Icons.how_to_reg_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAttendanceScreen(user: widget.user))),
                ),
                _buildCircleMenuItem(
                  label: 'Fees & Dues',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFeesScreen(user: widget.user))),
                ),
                _buildCircleMenuItem(
                  label: 'PDF Library',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _tabController.animateTo(2),
                ),
                _buildCircleMenuItem(
                  label: 'Broadcast Notice',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF06B6D4),
                  onTap: () => _tabController.animateTo(4),
                ),
                _buildCircleMenuItem(
                  label: 'Live Tests',
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminLiveTestsScreen(user: widget.user))),
                ),
                _buildCircleMenuItem(
                  label: 'Live Test Logs',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFDC2626),
                  onTap: _showProctoringLogsDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleMenuItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(60), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.ink)),
          ],
        ),
      ),
    );
  }

  // --- 4. DEPARTMENT KPI STATS ---
  Widget _buildDepartmentKpis(int pendingFees) {
    final myStudentsCount = _myDepartmentStudents.length;
    final myRequestsCount = _myDepartmentRequests.length;
    final myBatchesCount = _myDepartmentBatches.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.45 : 1.35,
          children: [
            _buildKpiCard(
              label: '${isZoyaView ? "Commerce" : "Science"} Students',
              value: '$myStudentsCount',
              subtext: 'Total Center: ${_students.length}',
              icon: Icons.people_alt_rounded,
              color: activeBrandColor,
              onTap: () => _tabController.animateTo(0),
            ),
            _buildKpiCard(
              label: 'Active Batches',
              value: '$myBatchesCount Batches',
              subtext: 'Timetable & Schedule',
              icon: Icons.schedule_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () => _tabController.animateTo(1),
            ),
            _buildKpiCard(
              label: 'Study Materials',
              value: '${_notes.length} PDFs',
              subtext: '+ Upload New Notes',
              icon: Icons.upload_file_rounded,
              color: Colors.deepOrange,
              onTap: () => _tabController.animateTo(2),
            ),
            _buildKpiCard(
              label: 'Pending Approvals',
              value: '$myRequestsCount',
              subtext: myRequestsCount > 0 ? 'Action Needed' : 'All Approved',
              icon: Icons.verified_user_outlined,
              color: myRequestsCount > 0 ? Colors.orange.shade800 : AppTheme.successGreen,
              isAlert: myRequestsCount > 0,
              onTap: () => _tabController.animateTo(0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isAlert = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAlert ? color : AppTheme.line, width: isAlert ? 2 : 1),
          boxShadow: [BoxShadow(color: isAlert ? color.withAlpha(25) : Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(subtext, style: TextStyle(fontSize: 11, color: isAlert ? color : AppTheme.inkSecondary, fontWeight: isAlert ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. APPROVALS ALERT CARD ---
  Widget _buildApprovalsAlertCard(List<dynamic> reqs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.amber.shade200.withAlpha(100), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.notification_important_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action Required: ${reqs.length} Student Approval Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.amber.shade900)),
                    Text('Assigned to $activeTeacherName for verification & roll number allocation.', style: const TextStyle(fontSize: 12, color: AppTheme.ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final req = reqs[idx];
              final name = req['name'] ?? 'Student';
              final phone = req['phone'] ?? '';
              final batch = req['batch'] ?? 'Class 10';

              return LayoutBuilder(
                builder: (context, cardConstraints) {
                  final isCompact = cardConstraints.maxWidth < 500;
                  final avatarAndDetails = Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: activeBrandColor.withAlpha(25),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: TextStyle(fontWeight: FontWeight.bold, color: activeBrandColor)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Phone: $phone • $batch', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                          ],
                        ),
                      ),
                    ],
                  );

                  final buttons = [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleApproveStudent(req),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRed,
                        side: const BorderSide(color: AppTheme.dangerRed),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject', style: TextStyle(fontSize: 12)),
                      onPressed: () => _handleRejectStudent(req),
                    ),
                  ];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade300)),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              avatarAndDetails,
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: buttons[0]),
                                  const SizedBox(width: 8),
                                  Expanded(child: buttons[2]),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: avatarAndDetails),
                              const SizedBox(width: 12),
                              ...buttons,
                            ],
                          ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 6. MAIN INTEGRATED TABS CONTAINER ---
  Widget _buildIntegratedTabsContainer(List<dynamic> filteredList, List<dynamic> batchesList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Header
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: activeBrandColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: activeBrandColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: activeBrandColor.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.ink,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(icon: const Icon(Icons.people_alt_rounded, size: 17), text: 'Students (${filteredList.length})'),
                Tab(icon: const Icon(Icons.schedule_rounded, size: 17), text: 'Batches & Timing (${batchesList.length})'),
                Tab(icon: const Icon(Icons.picture_as_pdf_rounded, size: 17), text: 'Notes & Materials (${_notes.length})'),
                const Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 17), text: 'All Modules'),
                Tab(icon: const Icon(Icons.campaign_rounded, size: 17), text: 'Notice Board (${_notices.length})'),
              ],
            ),
          ),

          // Tab Body
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildStudentsTab(filteredList);
              } else if (_tabController.index == 1) {
                return _buildBatchesTab(batchesList);
              } else if (_tabController.index == 2) {
                return _buildNotesTab();
              } else if (_tabController.index == 3) {
                return _buildModulesTab();
              } else {
                return _buildNoticesTab();
              }
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 0: STUDENTS ---
  Widget _buildStudentsTab(List<dynamic> filteredList) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search student name, phone, roll...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'my_dept',
                                label: Text(isZoyaView ? 'Commerce' : 'Science 9-12', style: const TextStyle(fontSize: 11.5)),
                              ),
                              const ButtonSegment(
                                value: 'all',
                                label: Text('All', style: TextStyle(fontSize: 11.5)),
                              ),
                            ],
                            selected: {_departmentFilter},
                            onSelectionChanged: (val) => setState(() => _departmentFilter = val.first),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeBrandColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('Add Student', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: _showAddStudentModal,
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by student name, phone or roll number...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                            : null,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'my_dept', label: Text(isZoyaView ? 'Commerce' : 'Science 9-12')),
                      const ButtonSegment(value: 'all', label: Text('All')),
                    ],
                    selected: {_departmentFilter},
                    onSelectionChanged: (val) => setState(() => _departmentFilter = val.first),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: activeBrandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Student'),
                    onPressed: _showAddStudentModal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Showing ${filteredList.length} students (${_departmentFilter == "my_dept" ? "$activeTeacherName Roster" : "All Coaching"})',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSecondary, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('Full Roster Screen', style: TextStyle(fontSize: 12)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminStudentsScreen(user: widget.user))).then((_) => _loadDashboardData()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: AppTheme.inkSecondary),
                  SizedBox(height: 10),
                  Text('No students match your query.', style: TextStyle(color: AppTheme.inkSecondary, fontSize: 14)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final st = filteredList[idx];
                final name = st['name'] ?? 'Student';
                final phone = st['phone'] ?? '';
                final email = st['email'] ?? '';
                final batch = st['batch'] ?? 'Class 10';
                final rollNo = st['rollNo'] ?? 'ZM-${100 + idx}';
                final isComm = _isCommerceStudent(st);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.line)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (isComm ? const Color(0xFF1E3A8A) : AppTheme.brandTeal).withAlpha(20),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isComm ? const Color(0xFF1E3A8A) : AppTheme.brandTeal)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.ink)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: activeBrandColor.withAlpha(18), borderRadius: BorderRadius.circular(6)),
                                  child: Text(rollNo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: activeBrandColor)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: isComm ? Colors.blue.shade100 : Colors.teal.shade100, borderRadius: BorderRadius.circular(6)),
                                  child: Text(isComm ? 'Commerce (₹1000)' : 'Science (₹500-₹1000)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isComm ? Colors.blue.shade900 : Colors.teal.shade900)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Phone: $phone ${email.isNotEmpty ? "• $email" : ""}', style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSecondary)),
                            const SizedBox(height: 2),
                            Text(batch, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeBrandColor)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed), tooltip: 'Remove Student', onPressed: () => _handleRemoveStudent(st)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- TAB 1: BATCHES & TIMETABLE (NEW! Inspired by Reference Image 1 "Upcoming Classes") ---
  Widget _buildBatchesTab(List<dynamic> batchesList) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Class Batches & Daily Timetable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                  Text('Classes handled by $activeTeacherName', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                ],
              );
              final btn = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: activeBrandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                icon: const Icon(Icons.more_time_rounded, size: 18),
                label: const Text('+ Add / Change Batch Time'),
                onPressed: () => _showAddBatchModal(),
              );
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleCol,
                    const SizedBox(height: 10),
                    btn,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleCol,
                  btn,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (batchesList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.inkSecondary),
                  const SizedBox(height: 8),
                  const Text('No batches listed for this department yet.', style: TextStyle(color: AppTheme.inkSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => _showAddBatchModal(), child: const Text('+ Add First Batch Slot')),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: batchesList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final b = batchesList[idx];
                final name = b['name'] ?? 'Class Batch';
                final time = b['time'] ?? '4:00 PM - 5:00 PM';
                final subject = b['subject'] ?? 'Science / Commerce';
                final days = b['days'] ?? 'Mon - Sat';
                final teacher = b['teacher'] ?? 'Teacher';
                final fee = b['fee'] ?? 500;
                final meetLink = b['meetLink'] ?? 'https://meet.google.com/new';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.line),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      // Calendar / Time pill (Reference Image 1 style)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: activeBrandColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: activeBrandColor.withAlpha(40)),
                        ),
                        child: Column(
                          children: [
                            Text(days.split(' ').first, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeBrandColor)),
                            const SizedBox(height: 2),
                            Text('LIVE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: activeBrandColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.ink)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                  child: Text('₹$fee/mo', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(subject, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.brandTeal),
                                Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.brandTeal)),
                                Text('• $days • by $teacher Mam', style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.video_call_rounded, color: Colors.indigo, size: 24),
                        tooltip: 'Join Live Meet',
                        onPressed: () async {
                          final uri = Uri.parse(meetLink);
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting live class meeting...')));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.inkSecondary, size: 20),
                        tooltip: 'Edit Batch Timing',
                        onPressed: () => _showAddBatchModal(b),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                        tooltip: 'Delete Batch',
                        onPressed: () async {
                          final ok = await ApiService.deleteBatch(b['id']);
                          if (ok) _loadDashboardData();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- TAB 2: NOTES & PDF UPLOADS (NEW! Dedicated upload & in-app viewer) ---
  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Study Materials & Uploaded PDFs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                  Text('Upload notes for $activeDepartmentName', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                ],
              );
              final btn = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: activeBrandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('+ Upload PDF Note'),
                onPressed: _showUploadNoteModal,
              );
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleCol,
                    const SizedBox(height: 10),
                    btn,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleCol,
                  btn,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_notes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 48, color: AppTheme.inkSecondary),
                  const SizedBox(height: 8),
                  const Text('No study materials uploaded yet.', style: TextStyle(color: AppTheme.inkSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _showUploadNoteModal, child: const Text('+ Upload First Note')),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final nt = _notes[idx];
                final title = nt['title'] ?? 'Note';
                final subject = nt['subject'] ?? 'Subject';
                final batch = nt['batch'] ?? 'Class Batch';
                final desc = nt['description'] ?? '';
                final addedBy = nt['addedBy'] ?? 'Teacher';
                final date = nt['date'] ?? '';
                final id = nt['id']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.deepOrange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: activeBrandColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                                      child: Text(subject, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeBrandColor)),
                                    ),
                                    Text('For $batch', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppTheme.inkSecondary)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.line),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'by $addedBy • $date',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.inkSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeBrandColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                icon: const Icon(Icons.visibility_rounded, size: 14),
                                label: const Text('View PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => PdfPreviewDialog.show(context, title: title, subject: subject, batch: batch, description: desc),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                                tooltip: 'Delete Note',
                                onPressed: () async {
                                  final ok = await ApiService.deleteNote(id);
                                  if (ok) _loadDashboardData();
                                },
                              ),
                            ],
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
    );
  }

  // --- TAB 3: ALL MODULES ---
  Widget _buildModulesTab() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return GridView.count(
            crossAxisCount: isWide ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 1.2 : 1.1,
            children: [
              _buildModuleCard(
                title: 'Student Roster',
                subtitle: 'Add, Remove & Approval Requests',
                icon: Icons.people_alt_rounded,
                color: activeBrandColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminStudentsScreen(user: widget.user))).then((_) => _loadDashboardData()),
              ),
              _buildModuleCard(
                title: 'Batches & Timing',
                subtitle: 'Manage Schedules, Slots & Live Classes',
                icon: Icons.schedule_rounded,
                color: const Color(0xFF3B82F6),
                badge: '${_batches.length} Slots',
                onTap: () => _tabController.animateTo(1),
              ),
              _buildModuleCard(
                title: 'Attendance Register',
                subtitle: 'Mark Present, Absent & Late Records',
                icon: Icons.calendar_month_rounded,
                color: AppTheme.successGreen,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAttendanceScreen(user: widget.user))).then((_) => _loadDashboardData()),
              ),
              _buildModuleCard(
                title: 'Study Materials',
                subtitle: 'Upload PDFs & In-App Reader',
                icon: Icons.picture_as_pdf_rounded,
                color: Colors.deepOrange,
                badge: '${_notes.length} PDFs',
                onTap: () => _tabController.animateTo(2),
              ),
              _buildModuleCard(
                title: 'Fee Collection',
                subtitle: isZoyaView ? 'Commerce: ₹1,000/mo Fees' : 'Science 9-12: ₹500-₹1,000/mo',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFeesScreen(user: widget.user))).then((_) => _loadDashboardData()),
              ),
              _buildModuleCard(
                title: 'Live Meet Classroom',
                subtitle: 'Google Meet Sessions & Schedule',
                icon: Icons.video_call_rounded,
                color: Colors.indigo,
                onTap: _launchMeet,
              ),
            ],
          );
        },
      ),
    );
  }

  // --- TAB 4: NOTICE BOARD ---
  Widget _buildNoticesTab() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: activeBrandColor.withAlpha(15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_alert_rounded, color: activeBrandColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Broadcast Notice as $activeTeacherName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _noticeTitleCtrl, decoration: const InputDecoration(labelText: 'Notice Title', hintText: 'e.g. Science Revision Test on Thursday', isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: _noticeContentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Announcement Message', hintText: 'Type message to broadcast to all students...', isDense: true)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: activeBrandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    icon: _isPostingNotice ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_isPostingNotice ? 'Posting...' : 'Broadcast Notice'),
                    onPressed: _isPostingNotice ? null : _handlePostNotice,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Active Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink)),
          const SizedBox(height: 10),
          if (_notices.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No announcements posted yet.', style: TextStyle(color: AppTheme.inkSecondary))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final nt = _notices[idx];
                final title = nt['title'] ?? 'Notice';
                final content = nt['content'] ?? '';
                final date = nt['date'] ?? '';
                final id = nt['id']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.line)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: activeBrandColor.withAlpha(20), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.campaign, color: activeBrandColor, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary, height: 1.3)),
                          ],
                        ),
                      ),
                      if (id.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                          tooltip: 'Delete Notice',
                          onPressed: () async {
                            final ok = await ApiService.deleteNotice(id);
                            if (ok) _loadDashboardData();
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(45)),
          boxShadow: [BoxShadow(color: color.withAlpha(12), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.dangerRed, borderRadius: BorderRadius.circular(10)),
                    child: Text(badge, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.inkSecondary),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppTheme.inkSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
