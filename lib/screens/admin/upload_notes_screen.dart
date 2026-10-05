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
  final _titleController = TextEditingController(text: 'Chapter Formula & Practice Notes');

  // Option A (Camera Multi-Page Scan) State
  final List<Map<String, String>> _scannedPages = [
    {'title': 'Page 1: Title & Formulas', 'time': '10:15 AM'},
    {'title': 'Page 2: Solved Examples', 'time': '10:16 AM'},
  ];

  // Option B (File Picker) State
  String? _pickedFileName = 'Class_10_Math_Formula_Sheet.pdf';
  String? _pickedFileSize = '2.8 MB';
  int _pickedFilePages = 12;

  // Option C (Create in App Test/Notes) State
  final List<TextEditingController> _questionControllers = [
    TextEditingController(text: 'What is the SI unit of Magnetic Field Strength?'),
    TextEditingController(text: 'State Ohm\'s Law and write its mathematical formula.'),
    TextEditingController(text: 'Explain the working principle of an Electric Motor.'),
  ];
  final _marksController = TextEditingController(text: '25');
  final _durationController = TextEditingController(text: '20');

  final List<String> subjects = ['Mathematics', 'Science', 'Physics', 'Chemistry', 'Accountancy', 'Economics', 'English'];

  @override
  void initState() {
    super.initState();
    final allowed = _appData.classesForCurrentAdmin;
    if (allowed.isNotEmpty) {
      _selectedClass = allowed.first;
    }
  }

  // Option A: Open Simulated Live Camera Modal
  void _openCameraScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.80,
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: const Text('Camera Scanner Viewfinder', style: TextStyle(fontSize: 16)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.amber),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.document_scanner, size: 72, color: Color(0xFF4F46E5)),
                              SizedBox(height: 12),
                              Text('Align Document Inside Grid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Auto-Edge Detection Enabled', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                          Positioned(
                            bottom: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Pages Captured: ${_scannedPages.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text('Done', style: TextStyle(color: Colors.white)),
                        ),
                        // Shutter Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _scannedPages.add({
                                'title': 'Page ${_scannedPages.length + 1}: Captured Document Photo',
                                'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                              });
                            });
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('📸 Captured Page ${_scannedPages.length} successfully!')),
                            );
                          },
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF4F46E5), width: 4),
                            ),
                            child: const Icon(Icons.camera, color: Color(0xFF4F46E5), size: 36),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _previewScannedPdf();
                          },
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF22C55E)),
                          label: const Text('Preview PDF', style: TextStyle(color: Color(0xFF22C55E))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Option B: Open Storage File Picker Modal
  void _openFilePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sampleFiles = [
          {'name': 'Class_10_Math_Formula_Sheet.pdf', 'size': '2.8 MB', 'pages': 12},
          {'name': 'Science_Physics_Magnetism_Notes.pdf', 'size': '4.2 MB', 'pages': 18},
          {'name': 'Commerce_Accountancy_TrialBalance.pdf', 'size': '1.9 MB', 'pages': 8},
          {'name': 'English_Grammar_Complete_Guide.pdf', 'size': '3.1 MB', 'pages': 15},
        ];

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select PDF File from Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              ...sampleFiles.map((f) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: Text(f['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Size: ${f['size']} • ${f['pages']} Pages', style: const TextStyle(fontSize: 11)),
                onTap: () {
                  setState(() {
                    _pickedFileName = f['name'] as String;
                    _pickedFileSize = f['size'] as String;
                    _pickedFilePages = f['pages'] as int;
                    if (_titleController.text.isEmpty) {
                      _titleController.text = _pickedFileName!.replaceAll('.pdf', '').replaceAll('_', ' ');
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('📄 Selected file: ${_pickedFileName!}')),
                  );
                },
              )),
            ],
          ),
        );
      },
    );
  }

  // Preview PDF Document Modal
  void _previewScannedPdf() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_titleController.text.isNotEmpty ? _titleController.text : 'PDF Document Preview', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ZM Tuition – Old Bus Stand, Nakur', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 13)),
                        Text('Target Batch: $_selectedClass | Subject: $_selectedSubject', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedUploadOption == 0) ...[
                    Text('Total Scanned Pages: ${_scannedPages.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._scannedPages.map((p) => Card(
                      color: Colors.grey.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.image, color: Color(0xFF4F46E5)),
                        title: Text(p['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('Captured at ${p['time']}', style: const TextStyle(fontSize: 10)),
                      ),
                    )),
                  ] else if (_selectedUploadOption == 1) ...[
                    ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Colors.red, size: 32),
                      title: Text(_pickedFileName ?? 'Document.pdf', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Size: ${_pickedFileSize ?? "2.5 MB"} | Total Pages: $_pickedFilePages', style: const TextStyle(fontSize: 11)),
                    ),
                  ] else ...[
                    const Text('Question Paper Header:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Time Duration: ${_durationController.text} Mins | Max Marks: ${_marksController.text}', style: const TextStyle(fontSize: 12)),
                    const Divider(),
                    ...List.generate(_questionControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('Q${i + 1}. ${_questionControllers[i].text}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
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
                  // Institute Watermark Header Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.school, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppData.instituteName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              Text(
                                'Section 15: Document & Test Paper Publishing Hub',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class & Subject Dropdowns
                          DropdownButtonFormField<String>(
                            value: _selectedClass,
                            decoration: const InputDecoration(labelText: 'Target Batch / Class', border: OutlineInputBorder()),
                            items: allowedClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedClass = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            value: _selectedSubject,
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

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _previewScannedPdf,
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Preview PDF'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _saveUpload,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: Text(
                                    _selectedUploadOption == 2 ? 'Publish Test' : 'Upload PDF',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
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
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility, color: Color(0xFF4F46E5)),
                      onPressed: _previewScannedPdf,
                    ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
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
              onPressed: _openCameraScannerModal,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Launch Camera', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...List.generate(_scannedPages.length, (index) {
          final page = _scannedPages[index];
          return Card(
            color: Colors.grey.shade50,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.document_scanner, color: Color(0xFF4F46E5)),
              title: Text(page['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('Captured at ${page['time']}', style: const TextStyle(fontSize: 10)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    _scannedPages.removeAt(index);
                  });
                },
              ),
            ),
          );
        }),
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
          onTap: _openFilePickerModal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4), style: BorderStyle.solid, width: 1.5),
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
                  _pickedFileSize != null ? 'File Size: $_pickedFileSize • $_pickedFilePages Pages' : '(Supported formats: PDF, DOCX, JPG, PNG)',
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
