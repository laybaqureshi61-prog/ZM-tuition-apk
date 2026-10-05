import 'dart:async';
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/app_data.dart';

class LiveTestScreen extends StatefulWidget {
  final TestSeriesModel testSeries;

  const LiveTestScreen({super.key, required this.testSeries});

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> with WidgetsBindingObserver {
  final AppData _appData = AppData();
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex

  late Timer _timer;
  late int _remainingSeconds;

  int _warningCount = 0;
  bool _isTestTerminated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _remainingSeconds = widget.testSeries.durationMinutes * 60;
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer.cancel();
        _autoSubmitTest('Time Expired');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isTestTerminated) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _warningCount++;

      if (_warningCount <= 3) {
        _showCheatingWarningDialog();
      } else {
        _cancelTestDueToCheating();
      }
    }
  }

  void _showCheatingWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 8),
            Text('ANTI-CHEATING ALERT ($_warningCount/3)', style: const TextStyle(color: Color(0xFFD97706), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'App switching or leaving the test window detected!\n\n'
          '⚠️ Warning $_warningCount of 3.\n'
          'Do NOT leave the app, open floating apps, or switch tabs.\n'
          'On 4th attempt, your live test will be PERMANENTLY CANCELLED!',
          style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand & Resume Test'),
          ),
        ],
      ),
    );
  }

  void _cancelTestDueToCheating() {
    if (_isTestTerminated) return;
    _isTestTerminated = true;
    _timer.cancel();

    final student = _appData.currentUser;
    final result = TestResultModel(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
      studentId: student?.id ?? 'student_1',
      studentName: student?.name ?? 'Student',
      testTitle: widget.testSeries.title,
      score: 0,
      totalMarks: widget.testSeries.totalMarks,
      status: 'CANCELLED (Cheating Violation - 4 Attempts)',
      date: 'Today',
    );
    _appData.recordTestResult(result);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.gpp_bad, color: Colors.red, size: 30),
            SizedBox(width: 8),
            Text('TEST CANCELLED!', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your test has been automatically CANCELLED and submitted with 0 marks due to exceeding anti-cheating app-switching limits (4 violations).',
          style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // return to dashboard
            },
            child: const Text('Return to Portal'),
          ),
        ],
      ),
    );
  }

  void _autoSubmitTest(String reason) {
    if (_isTestTerminated) return;
    _isTestTerminated = true;
    _timer.cancel();

    int score = 0;
    final questions = widget.testSeries.questions;
    final marksPerQ = widget.testSeries.totalMarks / (questions.isEmpty ? 1 : questions.length);

    _selectedAnswers.forEach((qIdx, selectedOptIdx) {
      if (qIdx < questions.length && questions[qIdx].correctOptionIndex == selectedOptIdx) {
        score += marksPerQ.round();
      }
    });

    final student = _appData.currentUser;
    final result = TestResultModel(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
      studentId: student?.id ?? 'student_1',
      studentName: student?.name ?? 'Student',
      testTitle: widget.testSeries.title,
      score: score,
      totalMarks: widget.testSeries.totalMarks,
      status: 'Completed ($reason)',
      date: 'Today',
    );
    _appData.recordTestResult(result);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('TEST SUBMITTED!', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Score: $score / ${widget.testSeries.totalMarks}\n'
          'Status: Completed successfully ($reason)',
          style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.testSeries.questions;
    final currentQuestion = questions.isNotEmpty ? questions[_currentQuestionIndex] : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Cannot exit during Live Test. Submit test to finish.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBEB), // Soft Yellow Tint
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFEC4899), // Pink
          elevation: 0,
          title: Text(widget.testSeries.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _warningCount == 0 ? Colors.white : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _warningCount == 0 ? Colors.white : const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, size: 14, color: _warningCount == 0 ? const Color(0xFFEC4899) : const Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Text('Warnings: $_warningCount/3', style: TextStyle(color: _warningCount == 0 ? const Color(0xFFEC4899) : const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Proctored Banner & Countdown Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFFEC4899), size: 18),
                      const SizedBox(width: 6),
                      Text('PROCTORED LIVE TEST • Q ${_currentQuestionIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7), // Light Yellow
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimer(_remainingSeconds),
                          style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: currentQuestion == null
                  ? const Center(child: Text('No questions available in this test', style: TextStyle(color: Colors.grey)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Question ${_currentQuestionIndex + 1}:', style: const TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(
                                  currentQuestion.questionText,
                                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Options List
                          const Text('Select Answer:', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...List.generate(currentQuestion.options.length, (optIdx) {
                            final optionText = currentQuestion.options[optIdx];
                            final isSelected = _selectedAnswers[_currentQuestionIndex] == optIdx;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFCE7F3) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? const Color(0xFFEC4899) : Colors.grey.shade300, width: 1.5),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected ? const Color(0xFFEC4899) : const Color(0xFFFEF3C7),
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(optionText, style: TextStyle(color: isSelected ? const Color(0xFFEC4899) : Colors.black87, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                onTap: () {
                                  setState(() {
                                    _selectedAnswers[_currentQuestionIndex] = optIdx;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),

            // Navigation & Submit Bottom Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQuestionIndex > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: const BorderSide(color: Colors.grey)),
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox.shrink(),

                    if (_currentQuestionIndex < questions.length - 1)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        },
                        child: const Text('Next Question'),
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _autoSubmitTest('Completed'),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('SUBMIT TEST'),
                      ),
                  ],
                ),
              ),
            ),

            // Footer Watermark
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.white,
              child: const Center(
                child: Text('Powered by zm Tuition • Proctored Mode Active', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
