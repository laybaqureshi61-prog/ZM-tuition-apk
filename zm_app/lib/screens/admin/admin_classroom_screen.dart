import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminClassroomScreen extends StatefulWidget {
  final UserModel user;
  const AdminClassroomScreen({super.key, required this.user});

  @override
  State<AdminClassroomScreen> createState() => _AdminClassroomScreenState();
}

class _AdminClassroomScreenState extends State<AdminClassroomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _students = [];

  bool get isZoya {
    final type = widget.user.adminType?.toLowerCase();
    final name = widget.user.name.toLowerCase();
    return type == 'zoya' || name.contains('zoya');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: isZoya ? 0 : 1);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getStudents();
    if (!mounted) return;
    setState(() {
      _students = list;
      _isLoading = false;
    });
  }

  void _showUpdateMeetLinkDialog(String batchName) {
    final linkCtrl = TextEditingController(text: batchName.contains('Commerce') ? 'https://meet.google.com/zoy-comm-zm1' : 'https://meet.google.com/mus-sci-zm2');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Live Class Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Google Meet or Zoom URL for $batchName:'),
            const SizedBox(height: 12),
            TextField(
              controller: linkCtrl,
              decoration: const InputDecoration(
                labelText: 'Meeting URL',
                hintText: 'https://meet.google.com/...',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.successGreen,
                  content: Text('Live class link updated and broadcasted to students in $batchName!'),
                ),
              );
            },
            child: const Text('Save & Broadcast'),
          ),
        ],
      ),
    );
  }

  Future<void> _startClassStream(String batchName) async {
    final url = batchName.contains('Commerce') ? 'https://meet.google.com/zoy-comm-zm1' : 'https://meet.google.com/mus-sci-zm2';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final commerceStudents = _students.where((s) => (s['batch'] ?? '').toString().contains('Commerce')).toList();
    final scienceStudents = _students.where((s) => !(s['batch'] ?? '').toString().contains('Commerce')).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classrooms & Batches'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentYellow,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Commerce (11-12) - Zoya'),
            Tab(text: 'Maths & Science (9-12) - Muskan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBatchDetails(
                  batchTitle: 'Class 11 & 12 (Commerce Stream)',
                  teacher: 'Zoya Mam',
                  timing: 'Monday - Saturday: 4:00 PM - 6:00 PM',
                  monthlyFee: '₹1,000 / month',
                  subjects: ['Accountancy', 'Business Studies', 'Economics', 'English Core'],
                  syllabusPct: 0.68,
                  students: commerceStudents,
                  color: AppTheme.brandBlue,
                ),
                _buildBatchDetails(
                  batchTitle: 'Class 9th to 12th (Maths & Science Stream)',
                  teacher: 'Muskan Mam',
                  timing: 'Monday - Saturday: 4:15 PM - 8:45 PM',
                  monthlyFee: '₹600 - ₹1,000 / month',
                  subjects: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'],
                  syllabusPct: 0.74,
                  students: scienceStudents,
                  color: Colors.teal.shade700,
                ),
              ],
            ),
    );
  }

  Widget _buildBatchDetails({
    required String batchTitle,
    required String teacher,
    required String timing,
    required String monthlyFee,
    required List<String> subjects,
    required double syllabusPct,
    required List<dynamic> students,
    required Color color,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Batch Overview Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withAlpha(50)),
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
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.school, color: color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(batchTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Lead Educator: $teacher', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.inkSecondary),
                          const SizedBox(width: 8),
                          Text(timing, style: const TextStyle(fontSize: 13, color: AppTheme.inkPrimary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, size: 16, color: AppTheme.inkSecondary),
                          const SizedBox(width: 8),
                          Text('Tuition Fee: $monthlyFee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.brandBlue)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Syllabus Tracker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Syllabus Completed', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${(syllabusPct * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: syllabusPct,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),

                      // Subjects Chips
                      const Text('Subjects Curriculum:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: subjects.map((sub) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withAlpha(50)),
                          ),
                          child: Text(sub, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Class Streaming Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.successGreen.withAlpha(80), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreenSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.videocam_rounded, color: AppTheme.successGreen, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Class Stream & Meeting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Google Meet / Zoom link for this batch', style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showUpdateMeetLinkDialog(batchTitle),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Update Meeting Link'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                            onPressed: () => _startClassStream(batchTitle),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Start Class'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Enrolled Students Header
              Row(
                children: [
                  const Icon(Icons.people, color: AppTheme.brandBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Enrolled Students (${students.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.inkPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (students.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: const Center(
                    child: Text('No students currently enrolled in this batch.', style: TextStyle(color: AppTheme.inkSecondary)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, idx) {
                    final s = students[idx];
                    final name = s['name'] ?? 'Student';
                    final phone = s['phone'] ?? '';
                    final rollNo = s['rollNo'] ?? 'ZM-${100 + idx}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppTheme.line),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(20),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Roll: $rollNo • Phone: $phone'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Active', style: TextStyle(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                        ),
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
