import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/app_data.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  final AppData _appData = AppData();
  final _titleController = TextEditingController();

  String _selectedClass = 'Class 10th (Science & Math)';
  String _selectedSubject = 'Mathematics';
  String? _pickedFileName;
  String? _pickedFileSize;

  final List<String> subjects = ['Mathematics', 'Science', 'Physics', 'Chemistry', 'Accountancy', 'Economics', 'English'];

  @override
  void initState() {
    super.initState();
    final allowed = _appData.classesForCurrentAdmin;
    if (allowed.isNotEmpty) {
      _selectedClass = allowed.first;
    }
  }

  void _simulateFilePicker() {
    setState(() {
      _pickedFileName = 'Chapter_Notes_Lecture.pdf';
      _pickedFileSize = '3.8 MB';
      if (_titleController.text.isEmpty) {
        _titleController.text = 'Physics Chapter Notes';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📄 Selected file: Chapter_Notes_Lecture.pdf (3.8 MB)')),
    );
  }

  void _uploadNote() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note title')),
      );
      return;
    }

    final admin = _appData.currentUser;
    final newNote = NoteModel(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subject: _selectedSubject,
      className: _selectedClass,
      date: 'Today',
      fileUrl: 'https://example.com/pdf.pdf',
      uploadedBy: admin?.name ?? 'Admin',
      fileName: _pickedFileName ?? '${_titleController.text.trim().replaceAll(' ', '_')}.pdf',
      fileSize: _pickedFileSize ?? '2.5 MB',
    );

    _appData.addNote(newNote);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully uploaded ${newNote.title}!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allowedClasses = _appData.classesForCurrentAdmin;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Upload Notes & Materials'),
          backgroundColor: const Color(0xFF4F46E5),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Upload Files'),
              Tab(text: 'My Uploaded Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Upload Files (Matching PRD Screen 15)
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload New Study Material',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 16),

                      // Select Class Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Select Class',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_outlined, color: Color(0xFF4F46E5)),
                        ),
                        items: allowedClasses.map((cls) => DropdownMenuItem(value: cls, child: Text(cls))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedClass = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Select Subject Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Select Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book_outlined, color: Color(0xFF4F46E5)),
                        ),
                        items: subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSubject = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Note Title TextField
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Note Title / Topic Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title, color: Color(0xFF4F46E5)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // File Dropzone Box (PRD Screen 15 Design)
                      InkWell(
                        onTap: _simulateFilePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.4), style: BorderStyle.solid, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 50, color: Color(0xFF4F46E5)),
                              const SizedBox(height: 12),
                              Text(
                                _pickedFileName ?? 'Click to upload or drag & drop',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4F46E5)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _pickedFileSize != null ? 'Selected File Size: $_pickedFileSize' : '(PDF, DOC, DOCX, PPT) - Max size 10 MB',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Upload Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _uploadNote,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Upload Study Material', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab 2: My Uploaded Notes
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _appData.notes.length,
              itemBuilder: (context, index) {
                final note = _appData.notes[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ),
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Subject: ${note.subject} | Class: ${note.className}\nFile: ${note.fileName} (${note.fileSize})', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
