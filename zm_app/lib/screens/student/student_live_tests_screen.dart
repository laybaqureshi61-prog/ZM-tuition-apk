import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'live_test_exam_screen.dart';

class StudentLiveTestsScreen extends StatefulWidget {
  final UserModel user;
  const StudentLiveTestsScreen({super.key, required this.user});

  @override
  State<StudentLiveTestsScreen> createState() => _StudentLiveTestsScreenState();
}

class _StudentLiveTestsScreenState extends State<StudentLiveTestsScreen> {
  bool _isLoading = true;
  List<dynamic> _tests = [];

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getTests();
    if (!mounted) return;
    setState(() {
      _tests = list;
      _isLoading = false;
    });
  }

  void _startTestConfirmation(dynamic test) {
    final title = test['title'] ?? 'Exam';
    final totalMarks = test['totalMarks'] ?? 20;
    final duration = test['durationMinutes'] ?? 15;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.brandBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.brandBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Live Proctored Exam Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text('• Duration: $duration Minutes | Marks: $totalMarks', style: const TextStyle(color: AppTheme.inkSecondary, fontSize: 13)),
            const Divider(height: 24),
            const Text('🚨 Strict Anti-Cheating Guidelines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.dangerRed)),
            const SizedBox(height: 8),
            const Text('1. Do NOT switch or minimize the app. You will receive 3 warnings; on the 4th attempt, your test will be instantly cancelled and auto-submitted.', style: TextStyle(fontSize: 12, height: 1.4)),
            const SizedBox(height: 4),
            const Text('2. Live camera & microphone monitoring will remain active.', style: TextStyle(fontSize: 12, height: 1.4)),
            const SizedBox(height: 4),
            const Text('3. Speaking or asking questions aloud will trigger suspicion warnings.', style: TextStyle(fontSize: 12, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveTestExamScreen(user: widget.user, test: test),
                ),
              ).then((_) => _loadTests());
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Agree & Start Exam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Proctored Tests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTests,
              child: _tests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          const Text('No live tests scheduled right now.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Zoya Mam & Muskan Mam will post exam schedules here.', style: TextStyle(color: AppTheme.inkSecondary, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tests.length,
                      itemBuilder: (context, idx) {
                        final t = _tests[idx];
                        final title = t['title'] ?? 'Live Test';
                        final subject = t['subject'] ?? 'General';
                        final totalMarks = t['totalMarks'] ?? 20;
                        final duration = t['durationMinutes'] ?? 15;
                        final submissions = (t['submissions'] as List<dynamic>? ?? []);
                        final mySubmission = submissions.firstWhere(
                          (sub) => sub['studentId'] == widget.user.id,
                          orElse: () => null,
                        );

                        final hasAttempted = mySubmission != null;
                        final isDisqualified = mySubmission?['status'] == 'DISQUALIFIED';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDisqualified
                                  ? AppTheme.dangerRed.withAlpha(80)
                                  : hasAttempted
                                      ? AppTheme.successGreen.withAlpha(80)
                                      : AppTheme.brandBlue.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandBlue.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        subject,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.brandBlue),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (hasAttempted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDisqualified ? Colors.red.shade100 : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isDisqualified ? 'DISQUALIFIED' : 'SUBMITTED',
                                          style: TextStyle(
                                            color: isDisqualified ? Colors.red.shade900 : Colors.green.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                                          SizedBox(width: 4),
                                          Text('LIVE NOW', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 14, color: AppTheme.inkSecondary),
                                        const SizedBox(width: 4),
                                        Text('$duration mins', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.grade_outlined, size: 14, color: AppTheme.inkSecondary),
                                        const SizedBox(width: 4),
                                        Text('$totalMarks Marks', style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.teal),
                                        const SizedBox(width: 4),
                                        const Text('AI Camera & Voice Proctored', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (hasAttempted)
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    alignment: WrapAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Your Score: ${mySubmission['obtainedMarks']} / $totalMarks Marks',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.brandBlue),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _startTestConfirmation(t),
                                        child: const Text('Retake Practice'),
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.brandBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _startTestConfirmation(t),
                                      icon: const Icon(Icons.play_circle_fill_rounded),
                                      label: const Text('Start Live Exam Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
