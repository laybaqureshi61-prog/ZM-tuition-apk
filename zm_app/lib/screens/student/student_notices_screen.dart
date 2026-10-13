import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class StudentNoticesScreen extends StatefulWidget {
  final UserModel user;
  const StudentNoticesScreen({super.key, required this.user});

  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen> {
  bool _isLoading = true;
  List<dynamic> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getNotices();
    if (!mounted) return;
    setState(() {
      _notices = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuition Notice Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadNotices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No notices posted currently.', style: TextStyle(color: AppTheme.inkSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notices.length,
                  itemBuilder: (context, idx) {
                    final item = _notices[idx];
                    final title = item['title'] ?? 'Notice';
                    final content = item['content'] ?? '';
                    final date = item['date'] ?? '';
                    final teacher = item['teacher'] ?? 'Administration';
                    final isUrgent = title.toString().contains('URGENT');
                    final isExam = title.toString().contains('EXAM');

                    final headerColor = isUrgent
                        ? AppTheme.dangerRed
                        : isExam
                            ? Colors.orange.shade800
                            : AppTheme.brandBlue;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: headerColor.withAlpha(60),
                          width: isUrgent ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isUrgent
                                      ? Icons.warning_rounded
                                      : isExam
                                          ? Icons.assignment_late_outlined
                                          : Icons.info_outline,
                                  color: headerColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: headerColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              content,
                              style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.inkPrimary),
                            ),
                            const Divider(height: 22),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: AppTheme.inkSecondary),
                                const SizedBox(width: 4),
                                Text('By $teacher', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                const Spacer(),
                                const Icon(Icons.access_time, size: 14, color: AppTheme.inkSecondary),
                                const SizedBox(width: 4),
                                Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
