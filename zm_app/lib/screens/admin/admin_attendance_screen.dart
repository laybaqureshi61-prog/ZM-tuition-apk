import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final UserModel user;
  const AdminAttendanceScreen({super.key, required this.user});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  List<dynamic> _students = [];
  Map<String, String> _attendanceMap = {};
  String _batchFilter = 'All';

  bool get isZoya {
    final type = widget.user.adminType?.toLowerCase();
    final name = widget.user.name.toLowerCase();
    return type == 'zoya' || name.contains('zoya');
  }

  @override
  void initState() {
    super.initState();
    _batchFilter = isZoya ? 'Commerce' : 'Science';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final studentsList = await ApiService.getStudents();
    final attData = await ApiService.getAttendance(dateStr);

    if (!mounted) return;
    setState(() {
      _students = studentsList;
      _attendanceMap = {};
      attData.forEach((k, v) {
        _attendanceMap[k.toString()] = v.toString();
      });

      // Default 'P' for unrecorded students
      for (var s in _students) {
        final id = (s['id'] ?? s['name']).toString();
        if (!_attendanceMap.containsKey(id)) {
          _attendanceMap[id] = 'P';
        }
      }

      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var s in _students) {
        final id = (s['id'] ?? s['name']).toString();
        _attendanceMap[id] = status;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final ok = await ApiService.markAttendance(dateStr, _attendanceMap);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
        content: Text(
          ok ? 'Attendance for $dateStr saved successfully!' : 'Failed to save attendance.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) {
      final batch = (s['batch'] ?? '').toString();
      if (_batchFilter == 'Commerce') return batch.contains('Commerce');
      if (_batchFilter == 'Science') return !batch.contains('Commerce');
      return true;
    }).toList();

    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;

    for (var s in filteredStudents) {
      final id = (s['id'] ?? s['name']).toString();
      final status = _attendanceMap[id] ?? 'P';
      if (status == 'P') presentCount++;
      if (status == 'A') absentCount++;
      if (status == 'L') lateCount++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with Date Picker & Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.brandBlue.withAlpha(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: AppTheme.brandBlue, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_drop_down, color: AppTheme.inkSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _markAll('P'),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('All Present'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Attendance Metric Pills
                      Row(
                        children: [
                          _buildStatBadge('Total', '${filteredStudents.length}', AppTheme.inkPrimary),
                          const SizedBox(width: 8),
                          _buildStatBadge('Present', '$presentCount', AppTheme.successGreen),
                          const SizedBox(width: 8),
                          _buildStatBadge('Absent', '$absentCount', AppTheme.dangerRed),
                          const SizedBox(width: 8),
                          _buildStatBadge('Late', '$lateCount', Colors.orange.shade700),
                        ],
                      ),
                    ],
                  ),
                ),

                // Batch Selection Filter
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Text('Batch: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Commerce (11-12)'),
                        selected: _batchFilter == 'Commerce',
                        onSelected: (sel) => setState(() => _batchFilter = 'Commerce'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Science & Maths (9-10)'),
                        selected: _batchFilter == 'Science',
                        onSelected: (sel) => setState(() => _batchFilter = 'Science'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _batchFilter == 'All',
                        onSelected: (sel) => setState(() => _batchFilter = 'All'),
                      ),
                    ],
                  ),
                ),

                // Swipe Tutorial Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.brandBlue.withAlpha(40)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swipe_rounded, color: AppTheme.brandBlue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 Swipe Right ➡️ to mark Present (Green) | Swipe Left ⬅️ to mark Absent (Red)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.brandBlue),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student Attendance List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? const Center(child: Text('No students in selected batch.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, idx) {
                            final s = filteredStudents[idx];
                            final id = (s['id'] ?? s['name']).toString();
                            final name = s['name'] ?? 'Unknown';
                            final rollNo = s['rollNo'] ?? 'ZM-${100 + idx}';
                            final currentStatus = _attendanceMap[id] ?? 'P';

                            return Dismissible(
                              key: ValueKey('att_${id}_$idx'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // Swiped Right -> Present
                                  setState(() => _attendanceMap[id] = 'P');
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(milliseconds: 900),
                                      backgroundColor: AppTheme.successGreen,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('$name marked PRESENT 🟢', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (direction == DismissDirection.endToStart) {
                                  // Swiped Left -> Absent
                                  setState(() => _attendanceMap[id] = 'A');
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(milliseconds: 900),
                                      backgroundColor: AppTheme.dangerRed,
                                      content: Row(
                                        children: [
                                          const Icon(Icons.cancel, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('$name marked ABSENT 🔴', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return false; // Keeps card in list
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                                    SizedBox(width: 8),
                                    Text('PRESENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerRed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('ABSENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                    SizedBox(width: 8),
                                    Icon(Icons.cancel_rounded, color: Colors.white, size: 24),
                                  ],
                                ),
                              ),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: currentStatus == 'A'
                                        ? AppTheme.dangerRed.withAlpha(70)
                                        : currentStatus == 'L'
                                            ? Colors.orange.withAlpha(70)
                                            : AppTheme.line,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: currentStatus == 'P'
                                            ? AppTheme.successGreen.withAlpha(25)
                                            : currentStatus == 'A'
                                                ? AppTheme.dangerRed.withAlpha(25)
                                                : Colors.orange.withAlpha(25),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                          style: TextStyle(
                                            color: currentStatus == 'P'
                                                ? AppTheme.successGreen
                                                : currentStatus == 'A'
                                                    ? AppTheme.dangerRed
                                                    : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Text(
                                              'Roll: $rollNo',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status Selector Chips: P, A, L
                                      _buildStatusButton(id, 'P', 'Present', AppTheme.successGreen, currentStatus == 'P'),
                                      const SizedBox(width: 6),
                                      _buildStatusButton(id, 'A', 'Absent', AppTheme.dangerRed, currentStatus == 'A'),
                                      const SizedBox(width: 6),
                                      _buildStatusButton(id, 'L', 'Late', Colors.orange.shade700, currentStatus == 'L'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Save Attendance Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAttendance,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Attendance for ${DateFormat('dd MMM').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.inkSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String studentId, String code, String label, Color color, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _attendanceMap[studentId] = code;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
