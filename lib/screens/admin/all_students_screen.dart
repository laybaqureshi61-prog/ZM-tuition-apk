import 'package:flutter/material.dart';
import '../../services/app_data.dart';
import 'add_edit_student_screen.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final AppData _appData = AppData();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final admin = _appData.currentUser;
    final isZoya = admin?.name.toLowerCase().contains('zoya') == true || admin?.email == 'zm@124';

    final approvedStudents = _appData.users.where((u) {
      if (u.role != 'student' || u.status != 'approved') return false;
      if (isZoya) {
        return u.assignedClass.contains('Commerce');
      } else {
        return !u.assignedClass.contains('Commerce');
      }
    }).where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.assignedClass.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.rollNo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('All Students Directory'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: Column(
        children: [
          // Search Student Bar (PRD Screen 10)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search student by name, class, roll no...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4F46E5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: approvedStudents.isEmpty
                ? const Center(child: Text('No students found', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: approvedStudents.length,
                    itemBuilder: (context, index) {
                      final student = approvedStudents[index];
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
                          ),
                          title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('Class: ${student.assignedClass} • Roll No: ${student.rollNo}\nEmail: ${student.email}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddEditStudentScreen(studentToEdit: student)),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }
}
