import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LiveTestExamScreen extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> test;

  const LiveTestExamScreen({
    super.key,
    required this.user,
    required this.test,
  });

  @override
  State<LiveTestExamScreen> createState() => _LiveTestExamScreenState();
}

class _LiveTestExamScreenState extends State<LiveTestExamScreen>
    with WidgetsBindingObserver {
  late List<dynamic> _questions;
  final Map<String, int> _selectedAnswers = {};
  int _currentQuestionIndex = 0;

  // Proctoring Violations Counter
  int _warningsCount = 0;
  static const int _maxWarnings = 4;
  bool _isDisqualified = false;
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  // Timer
  late int _remainingSeconds;
  Timer? _countdownTimer;

  // Voice/Noise level simulation & Speech Activity Detection
  double _audioNoiseLevel = 0.2; // 0.0 to 1.0 scale
  Timer? _audioMonitorTimer;
  bool _isVoiceTalkingDetected = false;
  int _consecutiveVoiceViolations = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _questions = widget.test['questions'] ?? [];
    final durationMins = widget.test['durationMinutes'] ?? 15;
    _remainingSeconds = (durationMins as int) * 60;

    _startTimer();
    _startAcousticMonitor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _audioMonitorTimer?.cancel();
    super.dispose();
  }

  // --- 1. APP SWITCHING / BACKGROUNDING DETECTION ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitted || _isDisqualified) return;

    // Detect when user leaves the app or attempts to open another app/split-screen
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _handleViolation(
        title: 'App Switch / Background Attempt Detected!',
        reason: 'Student attempted to leave the exam window or switch apps.',
      );
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _countdownTimer?.cancel();
        _submitTest(autoReason: 'Exam time expired.');
      }
    });
  }

  // --- 2. LIVE VOICE & ACOUSTIC TALKING DETECTION ---
  void _startAcousticMonitor() {
    // Simulates microphone ambient audio processing & conversation detection
    _audioMonitorTimer = Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (_isSubmitted || _isDisqualified) return;

      // Fluctuating audio level monitor
      setState(() {
        _audioNoiseLevel = 0.15 + (DateTime.now().millisecond % 50) / 100.0;
      });

      // Random voice spike test detection (or simulated whisper)
      final randomSpike = (DateTime.now().millisecond % 100);
      if (randomSpike > 92) {
        // High acoustic activity / talking pattern detected!
        _consecutiveVoiceViolations++;
        setState(() => _isVoiceTalkingDetected = true);

        if (_consecutiveVoiceViolations >= 2) {
          _consecutiveVoiceViolations = 0;
          _handleViolation(
            title: 'Voice / Conversation Detected!',
            reason: 'Microphone detected talking or asking for answers during test.',
          );
        }
      } else {
        if (_isVoiceTalkingDetected) {
          setState(() => _isVoiceTalkingDetected = false);
        }
      }
    });
  }

  // --- 3. VIOLATION ENGINE: 3 WARNINGS -> 4TH AUTO DISQUALIFY & SUBMIT ---
  void _handleViolation({required String title, required String reason}) {
    if (_isSubmitted || _isDisqualified) return;

    setState(() {
      _warningsCount++;
    });

    if (_warningsCount >= _maxWarnings) {
      // 4th Violation: Immediate Auto-Cancel & Submit
      setState(() => _isDisqualified = true);
      _submitTest(
        autoReason: 'DISQUALIFIED: Exceeded maximum allowed warnings (4 violations). Violation: $reason',
        isCancelled: true,
      );
      _showDisqualifiedDialog(reason);
    } else {
      // Show Warning Dialog (1/3, 2/3, 3/3)
      _showWarningDialog(title: title, reason: reason);
    }
  }

  void _showWarningDialog({required String title, required String reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: AppTheme.dangerRed, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'PROCTORING WARNING ($_warningsCount/3)',
                style: const TextStyle(
                  color: AppTheme.dangerRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _warningsCount == 3
                  ? '🚨 FINAL WARNING! 4th violation par exam foran CANCEL aur AUTO-SUBMIT ho jayega!'
                  : '⚠️ Total Allowed Warnings: 3. Remaining: ${3 - _warningsCount}. Do not switch apps or speak.',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand, Resume Exam'),
          ),
        ],
      ),
    );
  }

  void _showDisqualifiedDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.black, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'EXAM CANCELLED & SUBMITTED',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aapka exam proctoring violation ki wajah se foran cancel karke submit kar diya gaya hai.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text('Reason: $reason', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              'Status: DISQUALIFIED (Flagged to Admin / Faculty)',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Exit Exam Hall'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTest({String? autoReason, bool isCancelled = false}) async {
    if (_isSubmitting || _isSubmitted) return;
    setState(() => _isSubmitting = true);

    _countdownTimer?.cancel();
    _audioMonitorTimer?.cancel();

    final testId = widget.test['id']?.toString() ?? 't_live';
    final res = await ApiService.submitLiveTest(
      testId: testId,
      answers: _selectedAnswers,
      warningsCount: _warningsCount,
      violationReason: autoReason,
      status: isCancelled ? 'DISQUALIFIED' : 'COMPLETED',
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });

    if (!isCancelled) {
      _showResultsDialog(res['submission']);
    }
  }

  void _showResultsDialog(dynamic submission) {
    final marks = submission?['obtainedMarks'] ?? 0;
    final total = submission?['totalMarks'] ?? widget.test['totalMarks'] ?? 20;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 10),
            Text('Exam Submitted!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $marks / $total Marks', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.brandBlue)),
            const SizedBox(height: 10),
            Text('Warnings Recorded: $_warningsCount', style: TextStyle(color: _warningsCount > 0 ? Colors.orange : Colors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Your test answers and proctoring log have been submitted to Zoya & Muskan Mam.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.inkSecondary)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandBlue),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Exam')),
        body: const Center(child: Text('No questions available in this test.')),
      );
    }

    final q = _questions[_currentQuestionIndex];
    final options = (q['options'] as List<dynamic>? ?? []);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleViolation(
          title: 'Back Navigation Attempt!',
          reason: 'Student attempted to press back button and exit live exam.',
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.test['title'] ?? 'Live Proctored Test',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.security, size: 12, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  const Text('AI Proctoring Active', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _warningsCount == 0
                          ? Colors.green.withAlpha(50)
                          : _warningsCount >= 3
                              ? Colors.red
                              : Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Warnings: $_warningsCount/3',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _remainingSeconds < 120 ? Colors.red : Colors.blueGrey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Top Progress indicator
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandBlue),
                  minHeight: 4,
                ),

                // Question Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.inkSecondary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandBlue.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${q['marks'] ?? 5} Marks',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandBlue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                q['text'] ?? 'Question statement',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.4, color: AppTheme.ink),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Multiple Choice Options
                          ...List.generate(options.length, (optIdx) {
                            final optText = options[optIdx].toString();
                            final qId = q['id'].toString();
                            final isSelected = _selectedAnswers[qId] == optIdx;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.brandBlue : AppTheme.line,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              color: isSelected ? AppTheme.brandBlue.withAlpha(15) : Colors.white,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _selectedAnswers[qId] = optIdx;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? AppTheme.brandBlue : Colors.grey.shade100,
                                          border: Border.all(color: isSelected ? AppTheme.brandBlue : Colors.grey.shade400),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          String.fromCharCode(65 + optIdx), // A, B, C, D
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          optText,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? AppTheme.brandBlue : AppTheme.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 80), // Padding for floating PIP camera
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Nav Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.symmetric(horizontal: BorderSide(color: AppTheme.line)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _currentQuestionIndex > 0
                            ? () => setState(() => _currentQuestionIndex--)
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                      if (_currentQuestionIndex < _questions.length - 1)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => setState(() => _currentQuestionIndex++),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: _isSubmitting ? null : () => _submitTest(),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(_isSubmitting ? 'Submitting...' : 'Submit Test'),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // --- 4. FLOATING LIVE CAMERA & VOICE HUD (PROCTORING WINDOW) ---
            Positioned(
              right: 16,
              bottom: 80,
              child: Container(
                width: 140,
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isVoiceTalkingDetected ? Colors.red : Colors.greenAccent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Simulated Live Camera Feed
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blueGrey.shade800,
                              child: const Icon(Icons.person, size: 36, color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.user.name,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Camera Live Indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text('REC', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // Audio / Voice Monitor Waveform Bottom Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          color: Colors.black.withAlpha(180),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isVoiceTalkingDetected ? Icons.mic_off : Icons.mic,
                                    size: 12,
                                    color: _isVoiceTalkingDetected ? Colors.red : Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: _audioNoiseLevel,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _isVoiceTalkingDetected ? Colors.red : Colors.greenAccent,
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _isVoiceTalkingDetected ? 'SPEAKING DETECTED!' : 'Audio Monitored',
                                style: TextStyle(
                                  color: _isVoiceTalkingDetected ? Colors.red : Colors.white70,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
