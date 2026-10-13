import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminNoticesScreen extends StatefulWidget {
  final UserModel user;
  const AdminNoticesScreen({super.key, required this.user});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  bool _isLoading = true;
  List<dynamic> _notices = [];

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _selectedPriority = 'General Announcement';
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
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

  Future<void> _handlePostNotice() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.dangerRed,
          content: Text('Please enter both title and content for the notice.'),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final formattedTitle = _selectedPriority == 'Urgent Alert'
        ? '🚨 [URGENT] $title'
        : _selectedPriority == 'Exam Notification'
            ? '📝 [EXAM] $title'
            : '📢 $title';

    final ok = await ApiService.addNotice(formattedTitle, content);

    if (!mounted) return;
    setState(() => _isPosting = false);

    if (ok) {
      _titleCtrl.clear();
      _contentCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text('Notice published! Notification broadcasted to all ZM Tuition students.'),
          duration: Duration(seconds: 4),
        ),
      );
      _loadNotices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.dangerRed,
          content: Text('Failed to publish notice.'),
        ),
      );
    }
  }

  Future<void> _handleDeleteNotice(dynamic item) async {
    final id = item['id']?.toString() ?? '';
    final title = item['title'] ?? 'Notice';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice'),
        content: Text('Are you sure you want to remove notice "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && id.isNotEmpty) {
      setState(() => _isLoading = true);
      final ok = await ApiService.deleteNotice(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
          content: Text(ok ? 'Notice deleted.' : 'Failed to delete notice.'),
        ),
      );
      _loadNotices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board & Broadcast'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Post New Notice Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.line),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
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
                                    child: const Icon(Icons.campaign, color: AppTheme.brandBlue, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Broadcast Notice to All Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text('Instant notification delivered to every student app', style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Priority Selector
                              const Text('Notice Category & Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('📢 General'),
                                    selected: _selectedPriority == 'General Announcement',
                                    onSelected: (s) => setState(() => _selectedPriority = 'General Announcement'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('🚨 Urgent Alert'),
                                    selected: _selectedPriority == 'Urgent Alert',
                                    selectedColor: AppTheme.dangerRed.withAlpha(30),
                                    onSelected: (s) => setState(() => _selectedPriority = 'Urgent Alert'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('📝 Exam Notification'),
                                    selected: _selectedPriority == 'Exam Notification',
                                    selectedColor: Colors.orange.withAlpha(30),
                                    onSelected: (s) => setState(() => _selectedPriority = 'Exam Notification'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              const Text('Notice Headline / Title *', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Tomorrow Extra Class Timing Changed',
                                ),
                              ),
                              const SizedBox(height: 14),

                              const Text('Notice Details / Instructions *', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _contentCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Provide comprehensive guidelines for all students...',
                                ),
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton.icon(
                                onPressed: _isPosting ? null : _handlePostNotice,
                                icon: _isPosting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.send_rounded),
                                label: Text(_isPosting ? 'Publishing...' : 'Publish & Broadcast Notice'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Existing Notices Header
                      Row(
                        children: [
                          const Icon(Icons.history, color: AppTheme.brandBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Published Notices (${_notices.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.inkPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_notices.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: const Center(
                            child: Text('No notices posted yet.', style: TextStyle(color: AppTheme.inkSecondary)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _notices.length,
                          itemBuilder: (context, idx) {
                            final item = _notices[idx];
                            final title = item['title'] ?? 'Notice';
                            final content = item['content'] ?? '';
                            final date = item['date'] ?? '';
                            final teacher = item['teacher'] ?? 'Administration';
                            final isUrgent = title.toString().contains('URGENT');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isUrgent ? AppTheme.dangerRed.withAlpha(70) : AppTheme.line,
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
                                          isUrgent ? Icons.warning_rounded : Icons.info_outline,
                                          color: isUrgent ? AppTheme.dangerRed : AppTheme.brandBlue,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isUrgent ? AppTheme.dangerRed : AppTheme.inkPrimary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed),
                                          tooltip: 'Delete Notice',
                                          onPressed: () => _handleDeleteNotice(item),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      content,
                                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.inkPrimary),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_pin, size: 14, color: AppTheme.inkSecondary),
                                        const SizedBox(width: 4),
                                        Text('Posted by $teacher', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
