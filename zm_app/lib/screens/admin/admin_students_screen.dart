import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminStudentsScreen extends StatefulWidget {
  final UserModel user;
  const AdminStudentsScreen({super.key, required this.user});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _students = [];
  List<dynamic> _requests = [];
  String _searchQuery = '';

  // Add student form controllers
  final _addNameCtrl = TextEditingController();
  final _addPhoneCtrl = TextEditingController();
  final _addEmailCtrl = TextEditingController();
  final _addRollCtrl = TextEditingController();
  String _selectedBatch = 'Class 11 & 12 (Commerce)';
  bool _isSubmitting = false;

  bool get isZoya {
    final type = widget.user.adminType?.toLowerCase();
    final name = widget.user.name.toLowerCase();
    return type == 'zoya' || name.contains('zoya');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!isZoya) {
      _selectedBatch = 'Class 10 (Maths & Science)';
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addNameCtrl.dispose();
    _addPhoneCtrl.dispose();
    _addEmailCtrl.dispose();
    _addRollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final studentsList = await ApiService.getStudents();
    final reqsList = await ApiService.getRegistrationRequests();

    if (!mounted) return;
    setState(() {
      _students = studentsList;
      _requests = reqsList;
      _isLoading = false;
    });
  }

  Future<void> _handleAddStudent() async {
    final name = _addNameCtrl.text.trim();
    final phone = _addPhoneCtrl.text.trim();
    final email = _addEmailCtrl.text.trim();
    final roll = _addRollCtrl.text.trim();

    if (name.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.dangerRed,
          content: Text('Please enter valid Student Name and 10-digit Phone Number.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await ApiService.addStudent(
      name: name,
      phone: phone,
      email: email.isNotEmpty ? email : null,
      batch: _selectedBatch,
      rollNo: roll.isNotEmpty ? roll : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      _addNameCtrl.clear();
      _addPhoneCtrl.clear();
      _addEmailCtrl.clear();
      _addRollCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text(res['message'] ?? 'Student added successfully!'),
        ),
      );
      _loadData();
      _tabController.animateTo(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.dangerRed,
          content: Text(res['message'] ?? 'Failed to add student.'),
        ),
      );
    }
  }

  void _showSetPasswordDialog(dynamic student) {
    final name = student['name'] ?? 'Student';
    final studentId = student['id']?.toString() ?? '';
    final passCtrl = TextEditingController(text: 'ZM@2026');
    bool obscure = false;
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
                      color: AppTheme.brandBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.key_rounded, color: AppTheme.brandBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('For $name', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                      ],
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
                      'Admin can directly assign a new login password for this student (no OTP required):',
                      style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
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
                          avatar: const Icon(Icons.refresh, size: 14, color: AppTheme.brandBlue),
                          label: const Text('Default: ZM@2026', style: TextStyle(fontSize: 11)),
                          onPressed: () => setDialogState(() => passCtrl.text = 'ZM@2026'),
                        ),
                        if (student['phone'] != null)
                          ActionChip(
                            avatar: const Icon(Icons.phone_android, size: 14, color: AppTheme.brandBlue),
                            label: const Text('Phone as Pass', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              final phone = student['phone'].toString().replaceAll(RegExp(r'\D'), '');
                              final last6 = phone.length >= 6 ? phone.substring(phone.length - 6) : '123456';
                              setDialogState(() => passCtrl.text = 'zm$last6');
                            },
                          ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(errorText!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    backgroundColor: AppTheme.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPass = passCtrl.text.trim();
                          if (newPass.length < 6) {
                            setDialogState(() => errorText = 'Password must be at least 6 characters.');
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          final res = await ApiService.setStudentPassword(
                            studentId: studentId,
                            newPassword: newPass,
                          );

                          if (!dialogCtx.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.successGreen,
                                content: Text('New password set for $name: "$newPass"'),
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

  Future<void> _confirmRemoveStudent(dynamic student) async {
    final name = student['name'] ?? 'Student';
    final studentId = student['id']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('Permanent Removal')),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$name"?\n\n'
          '⚠️ Warning: This will permanently erase ALL upcoming and past records '
          '(attendance history, fee payments, and login access) as per center policy.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Student & Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && studentId.isNotEmpty) {
      setState(() => _isLoading = true);
      final ok = await ApiService.removeStudent(studentId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
          content: Text(
            ok
                ? 'Student "$name" and all related data removed successfully.'
                : 'Failed to remove student.',
          ),
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleApproveStudent(dynamic req) async {
    final studentId = req['id']?.toString() ?? '';
    final name = req['name'] ?? 'Student';

    setState(() => _isLoading = true);
    final ok = await ApiService.approveStudent(studentId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
        content: Text(
          ok ? 'Registration for "$name" approved! Roll number assigned.' : 'Approval failed.',
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final phone = (s['phone'] ?? '').toString().toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentYellow,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Enrolled (${filteredStudents.length})'),
            const Tab(text: '+ Add Student'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_requests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_requests.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveStudentsTab(filteredStudents),
                _buildAddStudentTab(),
                _buildRequestsTab(),
              ],
            ),
    );
  }

  Widget _buildActiveStudentsTab(List<dynamic> list) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search student by name, phone or email...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.brandBlue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Student List
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? 'No student matching "$_searchQuery"' : 'No students found.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final s = list[idx];
                    final name = s['name'] ?? 'Unknown';
                    final phone = s['phone'] ?? '';
                    final email = s['email'] ?? '';
                    final batch = s['batch'] ?? 'General';
                    final rollNo = s['rollNo'] ?? 'ZM-${100 + idx}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.line),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.brandBlue.withAlpha(25),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: const TextStyle(color: AppTheme.brandBlue, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.inkPrimary),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandBlue,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          rollNo,
                                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    batch,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.brandBlue, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: AppTheme.inkSecondary),
                                      const SizedBox(width: 4),
                                      Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                      const SizedBox(width: 14),
                                      const Icon(Icons.email_outlined, size: 14, color: AppTheme.inkSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.key_rounded, color: AppTheme.brandBlue),
                              tooltip: 'Set New Password',
                              onPressed: () => _showSetPasswordDialog(s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed),
                              tooltip: 'Remove Student',
                              onPressed: () => _confirmRemoveStudent(s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAddStudentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.brandBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_alt_1, color: AppTheme.brandBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add New Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Admin enrollment with auto-batching', style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addNameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Zaid Khan',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '10-digit mobile number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Email Address (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'student@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Roll Number (Optional, auto-generated if blank)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addRollCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ZM-105',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Assign Class / Batch *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBatch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Class 9 (Maths & Science)',
                        child: Text('Class 9 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 10 (Maths & Science)',
                        child: Text('Class 10 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 11 (Maths & Science)',
                        child: Text('Class 11 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 12 (Maths & Science)',
                        child: Text('Class 12 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 11 & 12 (Commerce)',
                        child: Text('Class 11 & 12 (Commerce) - Zoya'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedBatch = v);
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleAddStudent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enroll Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 12),
            const Text(
              'No pending registration requests!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'All students are verified and enrolled.',
              style: TextStyle(color: AppTheme.inkSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, idx) {
        final req = _requests[idx];
        final name = req['name'] ?? 'Applicant';
        final phone = req['phone'] ?? '';
        final batch = req['batch'] ?? 'General';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentYellow.withAlpha(50),
                  child: const Icon(Icons.person_outline, color: AppTheme.inkPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Batch: $batch', style: const TextStyle(fontSize: 12, color: AppTheme.brandBlue)),
                      Text('Phone: $phone', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleApproveStudent(req),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
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
