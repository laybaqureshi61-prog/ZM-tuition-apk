import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final UserModel user;
  const StudentAttendanceScreen({super.key, required this.user});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _attendanceData;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getMyAttendance();
    if (!mounted) return;
    setState(() {
      _attendanceData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_attendanceData?['percentage'] ?? 95) as int;
    final present = (_attendanceData?['present'] ?? 20) as int;
    final absent = (_attendanceData?['absent'] ?? 1) as int;
    final late = (_attendanceData?['late'] ?? 1) as int;
    final total = (_attendanceData?['total'] ?? 22) as int;
    final history = (_attendanceData?['history'] as List<dynamic>?) ?? [];

    Color pctColor = pct >= 85
        ? AppTheme.successGreen
        : pct >= 75
            ? Colors.orange.shade700
            : AppTheme.dangerRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Strict Read-Only Info Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.brandBlue.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.brandBlue.withAlpha(40)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: AppTheme.brandBlue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Official Student Record • Strictly Read-Only. Only Center Admin can modify.',
                                style: TextStyle(fontSize: 12, color: AppTheme.inkPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Attendance Circular Gauge Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppTheme.line),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 140,
                                    height: 140,
                                    child: CircularProgressIndicator(
                                      value: pct / 100.0,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$pct%',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: pctColor,
                                        ),
                                      ),
                                      const Text(
                                        'Overall Ratio',
                                        style: TextStyle(fontSize: 11, color: AppTheme.inkSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                pct >= 85
                                    ? 'Excellent! You meet the 85% attendance criteria.'
                                    : 'Please ensure regular attendance to maintain academic standards.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: pctColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Metric Stats Row
                      Row(
                        children: [
                          _buildStatCard('Total Classes', '$total', AppTheme.brandBlue),
                          const SizedBox(width: 8),
                          _buildStatCard('Present', '$present', AppTheme.successGreen),
                          const SizedBox(width: 8),
                          _buildStatCard('Absent', '$absent', AppTheme.dangerRed),
                          const SizedBox(width: 8),
                          _buildStatCard('Late', '$late', Colors.orange.shade700),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date-by-date Calendar History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history, color: AppTheme.brandBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Daily Attendance Logs',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.inkPrimary),
                              ),
                            ],
                          ),
                          Text('${history.length} records', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Present', 'Absent', 'Late'].map((f) {
                            final isSel = _statusFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: isSel,
                                selectedColor: AppTheme.brandBlueSoft,
                                labelStyle: TextStyle(
                                  color: isSel ? AppTheme.brandBlue : AppTheme.inkSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => setState(() => _statusFilter = f),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Builder(
                        builder: (context) {
                          final filteredHistory = history.where((h) {
                            final s = (h['status'] ?? 'P').toString();
                            if (_statusFilter == 'Present') return s == 'P';
                            if (_statusFilter == 'Absent') return s == 'A';
                            if (_statusFilter == 'Late') return s == 'L';
                            return true;
                          }).toList();

                          if (filteredHistory.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.line),
                              ),
                              child: Center(
                                child: Text(
                                  _statusFilter == 'All'
                                      ? 'Attendance records will appear here as classes are conducted.'
                                      : 'No logs found for "$_statusFilter" status.',
                                  style: const TextStyle(color: AppTheme.inkSecondary),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, idx) {
                              final item = filteredHistory[idx];
                              final date = item['date'] ?? '';
                              final status = item['status'] ?? 'P';
                              final isPresent = status == 'P';
                              final isAbsent = status == 'A';

                            final color = isPresent
                                ? AppTheme.successGreen
                                : isAbsent
                                    ? AppTheme.dangerRed
                                    : Colors.orange.shade700;

                            final label = isPresent
                                ? 'Present'
                                : isAbsent
                                    ? 'Absent'
                                    : 'Late';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: AppTheme.line),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withAlpha(20),
                                  child: Icon(
                                    isPresent ? Icons.check : isAbsent ? Icons.close : Icons.schedule,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: const Text('Scheduled Session • 2 Hours', style: TextStyle(fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.inkSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
