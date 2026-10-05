import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/app_data.dart';
import '../admin/upload_notes_screen.dart';
import 'pdf_document_viewer.dart';

class ClassroomHubScreen extends StatefulWidget {
  const ClassroomHubScreen({super.key});

  @override
  State<ClassroomHubScreen> createState() => _ClassroomHubScreenState();
}

class _ClassroomHubScreenState extends State<ClassroomHubScreen> {
  final AppData _appData = AppData();
  String _searchQuery = '';
  Map<String, dynamic>? _selectedCourse;

  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Mathematics & Algebra [MTH-101]',
      'subtitle': 'CLASS 10-LECTURE 1 (A) - LECTURE',
      'className': 'Class 10th (Science & Math)',
      'faculty': 'Muskan',
      'type': 'LECTURE',
      'code': 'MTH-101',
    },
    {
      'title': 'Science & Magnetism [SCI-102]',
      'subtitle': 'CLASS 10-LECTURE 2 (B) - LECTURE',
      'className': 'Class 10th (Science & Math)',
      'faculty': 'Muskan',
      'type': 'LECTURE',
      'code': 'SCI-102',
    },
    {
      'title': 'Accountancy & Trial Balance [ACC-201]',
      'subtitle': 'COMMERCE 12-LECTURE 1 (A) - LECTURE',
      'className': 'Class 12th (Commerce)',
      'faculty': 'Zoya',
      'type': 'LECTURE',
      'code': 'ACC-201',
    },
    {
      'title': 'Economics & Financial Studies [ECO-202]',
      'subtitle': 'COMMERCE 11-LECTURE 1 (A) - LECTURE',
      'className': 'Class 11th (Commerce)',
      'faculty': 'Zoya',
      'type': 'LECTURE',
      'code': 'ECO-202',
    },
    {
      'title': 'Physics Mechanics & Electricity Lab [PHY-301]',
      'subtitle': 'SCIENCE 11-A2 - PRACTICAL',
      'className': 'Class 11th (Science & Math)',
      'faculty': 'Muskan',
      'type': 'PRACTICAL',
      'code': 'PHY-301',
    },
    {
      'title': 'Class 9th Mathematics Basics [MTH-090]',
      'subtitle': 'CLASS 9-A2 - LECTURE',
      'className': 'Class 9th (Science & Math)',
      'faculty': 'Muskan',
      'type': 'LECTURE',
      'code': 'MTH-090',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_selectedCourse != null) {
      return _buildClassroomDetailScreen(_selectedCourse!);
    }

    final filteredCourses = _courses.where((c) {
      final q = _searchQuery.toLowerCase();
      return c['title'].toString().toLowerCase().contains(q) ||
          c['className'].toString().toLowerCase().contains(q) ||
          c['faculty'].toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE11D48), // Vibrant Red Header as in Image 1
        foregroundColor: Colors.white,
        title: const Text('ZM Classroom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Course, class, Faculty...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // Subject Courses List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                final isPractical = course['type'] == 'PRACTICAL';

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCourse = course;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${course['code']} - ${course['faculty'].toString().toUpperCase()} - ',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                course['type'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPractical ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFFE11D48),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Classroom'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Help Center'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
        ],
      ),
    );
  }

  // Image 2 Screen: Subject Classroom Menu View
  Widget _buildClassroomDetailScreen(Map<String, dynamic> course) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE11D48), // Vibrant Red Header as in Image 2
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedCourse = null),
        ),
        title: const Text('Classroom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Header Card displaying course name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${course['subtitle']} - Faculty: ${course['faculty']}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Menu Options matching Image 2
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildClassroomMenuItem('Course Work', Icons.menu_book, () {
                  _showCourseWorkNotesModal(course);
                }),
                _buildClassroomMenuItem('Resources', Icons.description_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen()));
                }),
                _buildClassroomMenuItem('Assignments', Icons.assignment_outlined, () {
                  _showHomeworkModal(course);
                }),
                _buildClassroomMenuItem('Assessment Results', Icons.bar_chart, () {
                  _showTestResultsModal(course);
                }),
                _buildClassroomMenuItem('Quizzes', Icons.quiz_outlined, () {
                  _showQuizzesModal(course);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showCourseWorkNotesModal(Map<String, dynamic> course) {
    final notes = _appData.notes.where((n) => n.className == course['className'] || n.className == 'All').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              AppBar(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                title: Text('Course Work: ${course['title']}'),
                actions: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadNotesScreen()));
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('+ Upload New Note / Material (Camera / File)'),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('File: ${note.fileName} (${note.fileSize}) • Date: ${note.date}', style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          PdfDocumentViewerModal.open(context, note);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.download_for_offline, color: Color(0xFFE11D48)),
                          onPressed: () {
                            PdfDocumentViewerModal.open(context, note);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHomeworkModal(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assignments for ${course['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.assignment, color: Color(0xFFE11D48)),
                title: Text('Chapter 4 Homework & Formulas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Due Date: 28 Sep 2026 • Max Marks: 20'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTestResultsModal(Map<String, dynamic> course) {
    final results = _appData.testResults;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assessment Results: ${course['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Divider(),
              ...results.map((r) => ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text('${r.studentName}: ${r.score}/${r.totalMarks}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Test: ${r.testTitle} • Date: ${r.date}'),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showQuizzesModal(Map<String, dynamic> course) {
    final tests = _appData.testSeriesList.where((t) => t.className == course['className'] || t.className == 'All').toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quizzes & Live Tests: ${course['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Divider(),
              ...tests.map((t) => ListTile(
                leading: const Icon(Icons.quiz, color: Color(0xFFE11D48)),
                title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Duration: ${t.durationMinutes} Mins • Total Marks: ${t.totalMarks}'),
              )),
            ],
          ),
        );
      },
    );
  }
}
