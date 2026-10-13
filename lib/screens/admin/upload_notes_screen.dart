import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
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
  final List<Map<String, String>> _scannedPages = [];

  // Option B (File Picker) State
  String? _pickedFileName;
  String? _pickedFileSize;
  int _pickedFilePages = 1;

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

  // Option A: Real Device Camera Capture / Photo Picker
  Future<void> _captureCameraPage() async {
    try {
      final picker = ImagePicker();
      XFile? photo;
      try {
        photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      } catch (_) {
        // Fallback to gallery / file selector if camera is not available on device
        photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      }

      if (photo != null) {
        final length = await photo.length();
        final sizeMb = (length / (1024 * 1024)).toStringAsFixed(2);
        setState(() {
          _scannedPages.add({
            'title': 'Page ${_scannedPages.length + 1}: ${photo!.name}',
            'size': '$sizeMb MB',
            'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          });
          if (_titleController.text.isEmpty) {
            _titleController.text = 'Scanned Notes ${photo.name.replaceAll('.jpg', '').replaceAll('.png', '')}';
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📸 Captured Page ${_scannedPages.length}: ${photo.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  // Option B: Native OS File Open Dialog (Pops up Windows/Mac/Web/Android file browser)
  Future<void> _pickDeviceDocument() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Documents & Images',
        extensions: <String>['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file != null) {
        final bytes = await file.length();
        final sizeMb = (bytes / (1024 * 1024)).toStringAsFixed(2);
        final sizeKb = (bytes / 1024).toStringAsFixed(0);
        final displaySize = bytes > (1024 * 1024) ? '$sizeMb MB' : '$sizeKb KB';

        setState(() {
          _pickedFileName = file.name;
          _pickedFileSize = displaySize;
          _pickedFilePages = (bytes / 150000).ceil().clamp(1, 99);
          if (_titleController.text.isEmpty) {
            _titleController.text = file.name.replaceAll('.pdf', '').replaceAll('_', ' ');
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📄 Selected File: ${file.name} ($displaySize)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
    }
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
                    if (_scannedPages.isEmpty)
                      const Text('No pages captured yet. Tap "Capture Page" to open camera.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      ..._scannedPages.map((p) => Card(
                        color: Colors.grey.shade100,
                        child: ListTile(
                          leading: const Icon(Icons.image, color: Color(0xFF4F46E5)),
                          title: Text(p['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text('Size: ${p['size'] ?? "1.2 MB"} • Captured at ${p['time']}', style: const TextStyle(fontSize: 10)),
                        ),
                      )),
                  ] else if (_selectedUploadOption == 1) ...[
                    if (_pickedFileName == null)
                      const Text('No file selected yet. Tap the box above to open file browser.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      ListTile(
                        leading: const Icon(Icons.insert_drive_file, color: Colors.red, size: 32),
                        title: Text(_pickedFileName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Size: $_pickedFileSize | Estimated Pages: $_pickedFilePages', style: const TextStyle(fontSize: 11)),
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

    if (_selectedUploadOption == 0 && _scannedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least 1 page using camera!')),
      );
      return;
    }

    if (_selectedUploadOption == 1 && _pickedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file from storage!')),
      );
      return;
    }

    final admin = _appData.currentUser;

    if (_selectedUploadOption == 0) {
      // Option A: Multi-page Scan
      final newNote = NoteModel(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_titleController.text.trim()} (${_scannedPages.length} Scanned Pages)',
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
        SnackBar(content: Text('Uploaded ${_pickedFileName!} successfully!')),
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
                            decoration: const InputDecoration(
                              labelText: 'Document / Test Title *',
                              border: OutlineInputBorder(),
                              hintText: 'e.g. Chapter 1 Physics Formula Notes',
                            ),
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
              onPressed: _captureCameraPage,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Capture Page', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_scannedPages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              children: [
                Icon(Icons.camera_alt_outlined, size: 36, color: Colors.grey),
                SizedBox(height: 6),
                Text('No pages scanned yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                Text('Tap "Capture Page" above to open your camera/device file browser.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        else
          ...List.generate(_scannedPages.length, (index) {
            final page = _scannedPages[index];
            return Card(
              color: Colors.grey.shade50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.document_scanner, color: Color(0xFF4F46E5)),
                title: Text(page['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('Size: ${page['size'] ?? "1.2 MB"} • Captured at ${page['time']}', style: const TextStyle(fontSize: 10)),
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
          onTap: _pickDeviceDocument,
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
                  _pickedFileName ?? 'Click here to open OS File Picker (Select PDF/JPG/PNG)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _pickedFileSize != null ? 'Selected File Size: $_pickedFileSize • $_pickedFilePages Pages' : '(Clicking opens your laptop/phone file open dialog)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
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
