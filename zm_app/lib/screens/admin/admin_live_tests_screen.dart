import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminLiveTestsScreen extends StatefulWidget {
  final UserModel user;
  const AdminLiveTestsScreen({super.key, required this.user});

  @override
  State<AdminLiveTestsScreen> createState() => _AdminLiveTestsScreenState();
}

class _AdminLiveTestsScreenState extends State<AdminLiveTestsScreen> {
  bool _isLoading = true;
  List<dynamic> _tests = [];
  String _selectedBatchFilter = 'All';

  final List<String> _batches = [
    'All',
    'Class 9 (Maths & Science)',
    'Class 10 (Maths & Science)',
    'Class 11 (Maths & Science)',
    'Class 12 (Maths & Science)',
    'Class 11 & 12 (Commerce)',
  ];

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getTests(_selectedBatchFilter == 'All' ? null : _selectedBatchFilter);
    if (!mounted) return;
    setState(() {
      _tests = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteTest(dynamic test) async {
    final title = test['title'] ?? 'Test';
    final testId = test['id']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Live Test?'),
        content: Text('Are you sure you want to remove "$title"? Students will no longer be able to attempt this exam.'),
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

    if (confirmed == true && testId.isNotEmpty) {
      final ok = await ApiService.deleteTest(testId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
          content: Text(ok ? 'Test deleted successfully.' : 'Failed to delete test.'),
        ),
      );
      _loadTests();
    }
  }

  void _showSubmissionsModal(dynamic test) {
    final title = test['title'] ?? 'Exam';
    final submissions = (test['submissions'] as List<dynamic>? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.brandBlue.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.analytics_outlined, color: AppTheme.brandBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submissions: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${submissions.length} Students have attempted', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            if (submissions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No student has submitted this test yet.', style: TextStyle(color: AppTheme.inkSecondary)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: submissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final sub = submissions[idx];
                    final name = sub['studentName'] ?? 'Student';
                    final phone = sub['studentPhone'] ?? '';
                    final marks = sub['obtainedMarks'] ?? 0;
                    final total = sub['totalMarks'] ?? test['totalMarks'] ?? 20;
                    final isDisqualified = sub['status'] == 'DISQUALIFIED';
                    final warnings = sub['warningsCount'] ?? 0;
                    final reason = sub['violationReason'] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDisqualified ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDisqualified ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDisqualified ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            radius: 18,
                            child: Icon(isDisqualified ? Icons.close : Icons.check, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDisqualified ? Colors.red : Colors.green,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isDisqualified ? 'DISQUALIFIED (Cheat)' : 'Score: $marks / $total',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Phone: $phone • Warnings: $warnings', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                if (reason.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Reason: $reason', style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
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
    );
  }

  void _showCreateTestDialog() {
    final titleCtrl = TextEditingController();
    String selectedBatch = 'Class 10 (Maths & Science)';
    String selectedSubject = 'Mathematics';
    int durationMinutes = 15;
    DateTime selectedDate = DateTime.now();

    final List<Map<String, dynamic>> questions = [
      {
        'text': TextEditingController(),
        'options': [
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ],
        'correctIndex': 0,
        'marks': 5,
      },
    ];

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void addQuestion() {
            setModalState(() {
              questions.add({
                'text': TextEditingController(),
                'options': [
                  TextEditingController(),
                  TextEditingController(),
                  TextEditingController(),
                  TextEditingController(),
                ],
                'correctIndex': 0,
                'marks': 5,
              });
            });
          }

          void loadSampleTemplate() {
            setModalState(() {
              titleCtrl.text = '$selectedSubject Chapter Test (${DateFormat('dd MMM').format(selectedDate)})';
              questions.clear();
              questions.addAll([
                {
                  'text': TextEditingController(text: 'Which of the following represents the correct formula?'),
                  'options': [
                    TextEditingController(text: 'Option A (Correct standard definition)'),
                    TextEditingController(text: 'Option B (Secondary method)'),
                    TextEditingController(text: 'Option C (Alternative formula)'),
                    TextEditingController(text: 'Option D (None of the above)'),
                  ],
                  'correctIndex': 0,
                  'marks': 5,
                },
                {
                  'text': TextEditingController(text: 'What is the primary unit or rule associated with this concept?'),
                  'options': [
                    TextEditingController(text: 'Option 1 (Standard Unit)'),
                    TextEditingController(text: 'Option 2 (Derived Unit)'),
                    TextEditingController(text: 'Option 3 (Inverse rule)'),
                    TextEditingController(text: 'Option 4 (Zero constant)'),
                  ],
                  'correctIndex': 0,
                  'marks': 5,
                },
              ]);
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
                            decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.add_task_rounded, color: Colors.red, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create & Schedule Live Test', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text('Anti-cheating camera & voice proctoring enabled', style: TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Test / Exam Title *',
                      hintText: 'e.g. Chapter 5: Periodic Classification Live Test',
                      prefixIcon: Icon(Icons.title_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Batch & Subject Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedBatch,
                          decoration: const InputDecoration(labelText: 'Target Batch *'),
                          items: const [
                            DropdownMenuItem(value: 'Class 9 (Maths & Science)', child: Text('Class 9 (Maths & Science)')),
                            DropdownMenuItem(value: 'Class 10 (Maths & Science)', child: Text('Class 10 (Maths & Science)')),
                            DropdownMenuItem(value: 'Class 11 (Maths & Science)', child: Text('Class 11 (Maths & Science)')),
                            DropdownMenuItem(value: 'Class 12 (Maths & Science)', child: Text('Class 12 (Maths & Science)')),
                            DropdownMenuItem(value: 'Class 11 & 12 (Commerce)', child: Text('Class 11 & 12 Commerce')),
                            DropdownMenuItem(value: 'All Batches', child: Text('All Batches')),
                          ],
                          onChanged: (v) => setModalState(() => selectedBatch = v ?? selectedBatch),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSubject,
                          decoration: const InputDecoration(labelText: 'Subject *'),
                          items: const [
                            DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                            DropdownMenuItem(value: 'Physics', child: Text('Physics')),
                            DropdownMenuItem(value: 'Chemistry', child: Text('Chemistry')),
                            DropdownMenuItem(value: 'Biology', child: Text('Biology')),
                            DropdownMenuItem(value: 'Accountancy', child: Text('Accountancy')),
                            DropdownMenuItem(value: 'Economics', child: Text('Economics')),
                            DropdownMenuItem(value: 'Business Studies', child: Text('Business Studies')),
                          ],
                          onChanged: (v) => setModalState(() => selectedSubject = v ?? selectedSubject),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date & Duration Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (d != null) setModalState(() => selectedDate = d);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Test Date', prefixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
                            child: Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: durationMinutes,
                          decoration: const InputDecoration(labelText: 'Duration *', prefixIcon: Icon(Icons.timer_outlined, size: 18)),
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10 Minutes')),
                            DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                            DropdownMenuItem(value: 20, child: Text('20 Minutes')),
                            DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                            DropdownMenuItem(value: 45, child: Text('45 Minutes')),
                            DropdownMenuItem(value: 60, child: Text('60 Minutes')),
                          ],
                          onChanged: (v) => setModalState(() => durationMinutes = v ?? durationMinutes),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // AI Proctoring Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.red, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active Live Proctoring Enabled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                              Text('Monitors App Switching (3 warnings + auto-cancel), Live Camera HUD, and Voice Activity.', style: TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Questions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions (${questions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Load Practice Template', style: TextStyle(fontSize: 12)),
                        onPressed: loadSampleTemplate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Questions List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, qIdx) {
                      final q = questions[qIdx];
                      final textCtrl = q['text'] as TextEditingController;
                      final opts = q['options'] as List<TextEditingController>;
                      int correctIndex = q['correctIndex'] as int;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.pillInputFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.brandBlue,
                                  child: Text('${qIdx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text('Question ${qIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                if (questions.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                                    onPressed: () => setModalState(() => questions.removeAt(qIdx)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: textCtrl,
                              decoration: const InputDecoration(labelText: 'Question Text *', hintText: 'Enter question statement'),
                            ),
                            const SizedBox(height: 10),
                            const Text('Options & Mark Correct Option:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.inkSecondary)),
                            const SizedBox(height: 6),
                            for (int optIdx = 0; optIdx < 4; optIdx++) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: optIdx,
                                      groupValue: correctIndex,
                                      onChanged: (val) {
                                        setModalState(() => q['correctIndex'] = val ?? 0);
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: opts[optIdx],
                                        decoration: InputDecoration(
                                          hintText: 'Option ${String.fromCharCode(65 + optIdx)}',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    if (correctIndex == optIdx)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('CORRECT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: addQuestion,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('+ Add Another Question', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.rocket_launch_rounded),
                      label: Text(
                        isSubmitting ? 'Publishing Test...' : 'Publish Live Test to $selectedBatch 🚀',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(backgroundColor: AppTheme.dangerRed, content: Text('Please enter test title.')),
                                );
                                return;
                              }

                              final formattedQuestions = <Map<String, dynamic>>[];
                              int totalMarks = 0;

                              for (int i = 0; i < questions.length; i++) {
                                final q = questions[i];
                                final qText = (q['text'] as TextEditingController).text.trim();
                                if (qText.isEmpty) continue;
                                final opts = (q['options'] as List<TextEditingController>).map((c) => c.text.trim()).toList();
                                final correctIdx = q['correctIndex'] as int;
                                final marks = q['marks'] as int;
                                totalMarks += marks;

                                formattedQuestions.add({
                                  'id': 'q_${i + 1}',
                                  'text': qText,
                                  'options': opts,
                                  'correctIndex': correctIdx,
                                  'marks': marks,
                                });
                              }

                              if (formattedQuestions.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(backgroundColor: AppTheme.dangerRed, content: Text('Please fill at least 1 valid question with text.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final payload = {
                                'title': title,
                                'subject': selectedSubject,
                                'batch': selectedBatch,
                                'durationMinutes': durationMinutes,
                                'totalMarks': totalMarks,
                                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                                'isLive': true,
                                'proctoringEnabled': true,
                                'questions': formattedQuestions,
                              };

                              final ok = await ApiService.addTest(payload);

                              if (!mounted) return;
                              setModalState(() => isSubmitting = false);
                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
                                  content: Text(ok ? 'Live Test published! Students of "$selectedBatch" can now see it.' : 'Failed to create test.'),
                                ),
                              );
                              _loadTests();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Proctored Exams & Tests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _loadTests),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Create Live Test', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showCreateTestDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTests,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch filter pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _batches.map((b) {
                          final isSelected = _selectedBatchFilter == b;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(b),
                              selected: isSelected,
                              selectedColor: Colors.red.shade100,
                              checkmarkColor: Colors.red.shade800,
                              labelStyle: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.red.shade900 : AppTheme.ink,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedBatchFilter = b);
                                _loadTests();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_tests.isEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 14),
                              const Text('No live tests scheduled for this batch.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 6),
                              const Text('Click the button below to create your first proctored test!', style: TextStyle(color: AppTheme.inkSecondary, fontSize: 13)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                                icon: const Icon(Icons.add),
                                label: const Text('Create First Live Test'),
                                onPressed: _showCreateTestDialog,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, idx) {
                          final t = _tests[idx];
                          final title = t['title'] ?? 'Test';
                          final subject = t['subject'] ?? 'Subject';
                          final batch = t['batch'] ?? 'Class';
                          final duration = t['durationMinutes'] ?? 15;
                          final marks = t['totalMarks'] ?? 20;
                          final date = t['date'] ?? '';
                          final qCount = (t['questions'] as List<dynamic>? ?? []).length;
                          final submissions = (t['submissions'] as List<dynamic>? ?? []);
                          final disqualifiedCount = submissions.where((s) => s['status'] == 'DISQUALIFIED').length;
                          final completedCount = submissions.length - disqualifiedCount;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.line),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(subject, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandBlue.withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(batch, style: const TextStyle(color: AppTheme.brandBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                                      tooltip: 'Delete Test',
                                      onPressed: () => _deleteTest(t),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 14, color: AppTheme.inkSecondary),
                                        const SizedBox(width: 4),
                                        Text('$duration Mins', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.score_outlined, size: 14, color: AppTheme.inkSecondary),
                                        const SizedBox(width: 4),
                                        Text('$marks Marks ($qCount Qs)', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                      ],
                                    ),
                                    if (date.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.inkSecondary),
                                          const SizedBox(width: 4),
                                          Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                        ],
                                      ),
                                  ],
                                ),
                                const Divider(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        submissions.isEmpty
                                            ? 'No submissions yet'
                                            : '${submissions.length} attempts ($completedCount Done • $disqualifiedCount Disqualified)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: disqualifiedCount > 0 ? Colors.red.shade700 : AppTheme.inkSecondary,
                                        ),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                      label: const Text('View Results', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _showSubmissionsModal(t),
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
              ),
            ),
    );
  }
}
