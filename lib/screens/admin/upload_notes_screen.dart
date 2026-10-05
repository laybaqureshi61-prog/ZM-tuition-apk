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

  int _selectedUploadOption = 0; // 0: Option A (Scan), 1: Option B (Pick File), 2: Option C (Create in App)

  // Common Fields
  String _selectedClass = 'Class 10th (Science & Math)';
  String _selectedSubject = 'Mathematics';
  final _titleController = TextEditingController();

  // Option A (Camera Multi-Page Scan) State
  final List<String> _scannedPages = [
    'Page 1: Title & Formulas',
    'Page 2: Solved Example 1 & 2',
  ];

  // Option B (File Picker) State
  String? _pickedFileName;
  String? _pickedFileSize;

  // Option C (Create in App Test/Notes) State
  final List<TextEditingController> _questionControllers = [
    TextEditingController(text: 'What is the SI unit of Force?'),
    TextEditingController(text: 'Define Newton\'s Second Law of Motion.'),
  ];
  final _marksController = TextEditingController(text: '25');
  final _durationController = TextEditingController(text: '15');

  final List<String> subjects = ['Mathematics', 'Science', 'Physics', 'Chemistry', 'Accountancy', 'Economics', 'English'];

  @override
  void initState() {
    super.initState();
    final allowed = _appData.classesForCurrentAdmin;
    if (allowed.isNotEmpty) {
      _selectedClass = allowed.first;
    }
  }

  void _addScannedPage() {
    setState(() {
      _scannedPages.add('Page ${_scannedPages.length + 1}: Captured Notes Image');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📸 Captured Page ${_scannedPages.length} successfully!')),
    );
  }

  void _removeScannedPage(int index) {
    setState(() {
      _scannedPages.removeAt(index);
    });
  }

  void _simulateFilePicker() {
    setState(() {
      _pickedFileName = 'Chapter_Physics_Lecture.pdf';
      _pickedFileSize = '3.8 MB';
      if (_titleController.text.isEmpty) {
        _titleController.text = 'Physics Chapter Notes';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📄 Selected file: Chapter_Physics_Lecture.pdf (3.8 MB)')),
    );
  }

  void _addQuestionField() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _saveUpload() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Title / Topic name')),
      );
      return;
    }

    final admin = _appData.currentUser;

    if (_selectedUploadOption == 0) {
      // Option A: Multi-page Scan
      final newNote = NoteModel(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_titleController.text.trim()} (Scanned ${_scannedPages.length} Pages)',
        subject: _selectedSubject,
        className: _selectedClass,
        date: AppData.formatLocalDate(DateTime.now()),
        fileUrl: 'https://example.com/scanned_doc.pdf',
        uploadedBy: admin?.name ?? 'Admin',
        fileName: '${_titleController.text.trim().replaceAll(' ', '_')}_Scan.pdf',
        fileSize: '${(_scannedPages.length * 1.2).toStringAsFixed(1)} MB',
      );
      _appData.addNote(newNote);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded scanned document with ${_scannedPages.length} pages!')),
      );
    } else if (_selectedUploadOption == 1) {
      // Option B: File Picker
      final newNote = NoteModel(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        subject: _selectedSubject,
        className: _selectedClass,
        date: AppData.formatLocalDate(DateTime.now()),
        fileUrl: 'https://example.com/picked_doc.pdf',
        uploadedBy: admin?.name ?? 'Admin',
        fileName: _pickedFileName ?? '${_titleController.text.trim().replaceAll(' ', '_')}.pdf',
        fileSize: _pickedFileSize ?? '2.5 MB',
      );
      _appData.addNote(newNote);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded ${_pickedFileName ?? "document"} successfully!')),
      );
    } else {
      // Option C: Create in App
      final List<TestQuestion> questions = [];
      for (int i = 0; i < _questionControllers.length; i++) {
        final text = _questionControllers[i].text.trim();
        if (text.isNotEmpty) {
          questions.add(TestQuestion(
            id: 'q_${i + 1}',
            questionText: text,
            options: ['Option A', 'Option B', 'Option C', 'Option D'],
            correctOptionIndex: 0,
          ));
        }
      }

      final testSeries = TestSeriesModel(
        id: 'ts_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        subject: _selectedSubject,
        className: _selectedClass,
        totalMarks: int.tryParse(_marksController.text.trim()) ?? 25,
        durationMinutes: int.tryParse(_durationController.text.trim()) ?? 15,
        date: 'Date: ${AppData.formatLocalDate(DateTime.now())} | 10:00 AM',
        questions: questions,
      );

      _appData.addTestSeries(testSeries);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created Test "${testSeries.title}" with ${questions.length} questions!')),
      );
    }

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
              Tab(text: 'Section 15 Upload Options'),
              Tab(text: 'Published Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Section 15 Upload Options
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Institute Watermark Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.school, color: Color(0xFF4F46E5)),
                        SizedBox(width: 8),
                        Text(
                          AppData.instituteName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option Selectors Row (A, B, C)
                  const Text('Select Upload Mode (Section 15):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionChip(0, 'Option A', 'Camera Scan', Icons.camera_alt),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOptionChip(1, 'Option B', 'Pick File', Icons.folder_open),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOptionChip(2, 'Option C', 'Create in App', Icons.edit_note),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Main Form Card
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class & Subject Dropdowns
                          DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            decoration: const InputDecoration(labelText: 'Target Batch / Class', border: OutlineInputBorder()),
                            items: allowedClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedClass = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedSubject,
                            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                            items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSubject = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(labelText: 'Document / Test Title *', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),

                          // Dynamic Content Based on Selected Option
                          if (_selectedUploadOption == 0) _buildOptionACameraScan(),
                          if (_selectedUploadOption == 1) _buildOptionBPickFile(),
                          if (_selectedUploadOption == 2) _buildOptionCCreateInApp(),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _saveUpload,
                              icon: const Icon(Icons.cloud_upload),
                              label: Text(
                                _selectedUploadOption == 2 ? 'Publish Test / Notes' : 'Upload Study Document',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab 2: Published Notes List
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
                    subtitle: Text('Subject: ${note.subject} | Class: ${note.className}\nFile: ${note.fileName} (${note.fileSize})', style: const TextStyle(fontSize: 11, color: Colors.black54)),
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

  Widget _buildOptionChip(int optionIndex, String title, String subtitle, IconData icon) {
    final isSelected = _selectedUploadOption == optionIndex;

    return InkWell(
      onTap: () => setState(() => _selectedUploadOption = optionIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF4F46E5), size: 24),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(subtitle, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // Option A Widget: Camera Multi-Page Scan
  Widget _buildOptionACameraScan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Option A: Multi-Page Camera Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: _addScannedPage,
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Capture Page', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Reorderable Pages Preview Grid
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _scannedPages.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _scannedPages.removeAt(oldIndex);
              _scannedPages.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            return Card(
              key: ValueKey(_scannedPages[index]),
              color: Colors.grey.shade50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.document_scanner, color: Color(0xFF4F46E5)),
                title: Text(_scannedPages[index], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Drag to reorder page sequence', style: TextStyle(fontSize: 10)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _removeScannedPage(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Option B Widget: File Picker
  Widget _buildOptionBPickFile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Option B: Pick PDF / Document from Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
        const SizedBox(height: 10),

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
                const Icon(Icons.cloud_upload_outlined, size: 46, color: Color(0xFF4F46E5)),
                const SizedBox(height: 8),
                Text(
                  _pickedFileName ?? 'Click to select PDF/JPG/PNG file',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 4),
                Text(
                  _pickedFileSize != null ? 'File Size: $_pickedFileSize' : '(Supported formats: PDF, DOCX, JPG, PNG)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Option C Widget: Create in App
  Widget _buildOptionCCreateInApp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Option C: Create Test / Notes in App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _marksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Marks', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (Mins)', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Questions List (Auto-Numbered):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            TextButton.icon(
              onPressed: _addQuestionField,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Question'),
            ),
          ],
        ),

        ...List.generate(_questionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: TextField(
              controller: _questionControllers[index],
              decoration: InputDecoration(
                labelText: 'Q${index + 1}: Question Text',
                border: const OutlineInputBorder(),
              ),
            ),
          );
        }),
      ],
    );
  }
}
