import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class StudentClassroomScreen extends StatefulWidget {
  final UserModel user;
  const StudentClassroomScreen({super.key, required this.user});

  @override
  State<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen> {
  Future<void> _joinLiveClass(String meetUrl) async {
    final uri = Uri.parse(meetUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open meeting link directly. Copied link to clipboard.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Launching classroom: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.user.batch ?? 'Class 10 (Maths & Science)';
    final isCommerce = batch.contains('Commerce');

    final isSeniorScience = batch.contains('11') || batch.contains('12');
    final batchTitle = isCommerce 
        ? 'Class 11 & 12 (Commerce Stream)' 
        : (isSeniorScience ? 'Class 11 & 12 (Science Stream - PCM/PCB)' : 'Class 9 & 10 (Science & Maths)');
    final teacher = isCommerce ? 'Zoya Mam' : 'Muskan Mam';
    final timing = isCommerce 
        ? 'Monday - Saturday: 3:00 PM - 4:15 PM' 
        : (isSeniorScience ? 'Monday - Saturday: 6:15 PM - 8:45 PM' : 'Monday - Saturday: 4:15 PM - 6:15 PM');
    final subjects = isCommerce
        ? ['Accountancy', 'Business Studies', 'Economics', 'English Core']
        : (isSeniorScience 
            ? ['Physics', 'Chemistry', 'Biology', 'Mathematics'] 
            : ['Science', 'Mathematics', 'English']);
    final syllabusPct = isCommerce ? 0.68 : 0.76;
    final color = isCommerce ? AppTheme.brandBlue : AppTheme.brandTeal;
    final liveMeetUrl = isCommerce ? 'https://meet.google.com/zoy-comm-zm1' : 'https://meet.google.com/mus-sci-zm2';

    final weeklySchedule = isCommerce
        ? [
            {'day': 'Monday', 'subject': 'Accountancy', 'topic': 'Partnership Fundamentals & Balance Sheet', 'time': '4:00 PM - 5:00 PM'},
            {'day': 'Tuesday', 'subject': 'Business Studies', 'topic': 'Principles of Management & Case Studies', 'time': '4:00 PM - 5:00 PM'},
            {'day': 'Wednesday', 'subject': 'Economics', 'topic': 'Macroeconomics & National Income', 'time': '4:00 PM - 5:00 PM'},
            {'day': 'Thursday', 'subject': 'Accountancy', 'topic': 'Goodwill Valuation & Journal Entries', 'time': '4:00 PM - 5:00 PM'},
            {'day': 'Friday', 'subject': 'English Core', 'topic': 'Reading Comprehension & Writing Skills', 'time': '4:00 PM - 5:00 PM'},
            {'day': 'Saturday', 'subject': 'Weekly Test & Doubt Session', 'topic': 'Comprehensive Test & One-on-One Doubts', 'time': '4:00 PM - 6:00 PM'},
          ]
        : [
            {'day': 'Monday', 'subject': 'Mathematics', 'topic': 'Real Numbers, Polynomials & NCERT Solutions', 'time': '5:30 PM - 6:30 PM'},
            {'day': 'Tuesday', 'subject': 'Physics', 'topic': 'Light: Reflection and Refraction Ray Diagrams', 'time': '5:30 PM - 6:30 PM'},
            {'day': 'Wednesday', 'subject': 'Chemistry', 'topic': 'Chemical Reactions & Equations Balancing', 'time': '5:30 PM - 6:30 PM'},
            {'day': 'Thursday', 'subject': 'Biology', 'topic': 'Life Processes & Nutrition Mechanisms', 'time': '5:30 PM - 6:30 PM'},
            {'day': 'Friday', 'subject': 'Mathematics (Advanced)', 'topic': 'Quadratic Equations & Problem Bank', 'time': '5:30 PM - 6:30 PM'},
            {'day': 'Saturday', 'subject': 'Weekend Unit Assessment', 'topic': 'Full Chapter Test & Evaluation', 'time': '5:30 PM - 7:30 PM'},
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classroom & Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Batch Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withAlpha(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.school, color: color, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batchTitle,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mentor: $teacher',
                              style: const TextStyle(fontSize: 14, color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Live Class Join Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppTheme.successGreen, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreenSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.video_call_rounded, color: AppTheme.successGreen, size: 26),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      const Text(
                                        'Live Digital Classroom',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.fiber_manual_record, color: AppTheme.successGreen, size: 12),
                                          const SizedBox(width: 4),
                                          const Text('Active Slot', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'In-Class Streaming with Mentor Screenshare',
                                    style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Text('Meeting Platform: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Expanded(
                              child: Text(
                                'Google Meet / Tuition Stream',
                                style: TextStyle(fontSize: 13, color: AppTheme.brandBlue, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Next Lecture: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Expanded(
                              child: Text(
                                timing,
                                style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _joinLiveClass(liveMeetUrl),
                            icon: const Icon(Icons.videocam_rounded, size: 20),
                            label: const Text('Join Live Lecture Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Weekly Detailed Timetable Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, color: AppTheme.brandBlue, size: 22),
                            SizedBox(width: 10),
                            Text('Weekly Timetable & Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24),
                        ...weeklySchedule.map((slot) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slot['day']!,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot['subject']!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        slot['topic']!,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: AppTheme.inkSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            slot['time']!,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Syllabus Tracker
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Syllabus Completion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${(syllabusPct * 100).toInt()}% Done', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: syllabusPct,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 18),
                        const Text('Enrolled Subjects:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: subjects.map((sub) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withAlpha(60)),
                            ),
                            child: Text(sub, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Faculty Profile
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: color.withAlpha(25),
                          child: Icon(Icons.person, color: color, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(teacher, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                isCommerce ? 'Specialization in Commerce, Accounts & Economics' : 'Specialization in Mathematics & Science',
                                style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text('ZM Tuition Academic Faculty', style: TextStyle(fontSize: 11, color: AppTheme.brandBlue, fontWeight: FontWeight.w600)),
                            ],
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
    );
  }
}
