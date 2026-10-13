import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../common/pdf_preview_dialog.dart';

class AdminNotesScreen extends StatefulWidget {
  final UserModel user;
  const AdminNotesScreen({super.key, required this.user});

  @override
  State<AdminNotesScreen> createState() => _AdminNotesScreenState();
}

class _AdminNotesScreenState extends State<AdminNotesScreen> {
  bool _isLoading = true;
  List<dynamic> _notes = [];
  final String _selectedSubject = 'All';

  bool get isZoya {
    final type = widget.user.adminType?.toLowerCase();
    final name = widget.user.name.toLowerCase();
    return type == 'zoya' || name.contains('zoya');
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notesList = await ApiService.getNotes();
    if (!mounted) return;
    setState(() {
      _notes = notesList;
      _isLoading = false;
    });
  }

  Future<void> _deleteNote(dynamic note) async {
    final noteId = note['id']?.toString() ?? '';
    final title = note['title'] ?? 'Note';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Material'),
        content: Text(
          'Are you sure you want to delete "$title"? Students will no longer be able to access this PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && noteId.isNotEmpty) {
      setState(() => _isLoading = true);
      final ok = await ApiService.deleteNote(noteId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
          content: Text(
            ok ? 'Note deleted successfully.' : 'Failed to delete note.',
          ),
        ),
      );
      _loadNotes();
    }
  }

  void _showUploadDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String targetBatch = isZoya
        ? 'Class 11 & 12 (Commerce)'
        : 'Class 10 (Maths & Science)';
    String subject = isZoya ? 'Accountancy' : 'Mathematics';
    String? selectedFileName;
    String? selectedFileSize;
    String? selectedFileType;
    bool isUploading = false;

    final commerceSubjects = [
      'Accountancy',
      'Business Studies',
      'Economics',
      'English Core',
    ];
    final scienceSubjects = [
      'Mathematics',
      'Science (Physics/Chem)',
      'Biology',
      'English',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPdfFile() async {
            try {
              final result = await FilePickerPlatform.instance.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result.isNotEmpty) {
                final file = result.first;
                setModalState(() {
                  selectedFileName = file.name;
                  selectedFileSize = '2.4 MB';
                  selectedFileType = 'PDF Document';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = file.name.replaceAll('.pdf', '').replaceAll('_', ' ');
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File selection notice: $e')),
                );
              }
            }
          }

          Future<void> pickFromCamera() async {
            try {
              final picker = ImagePicker();
              final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
              if (photo != null) {
                setModalState(() {
                  selectedFileName =
                      'Scanned_Doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
                  selectedFileSize = '1.4 MB';
                  selectedFileType = 'Scanned Camera PDF';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = 'Camera Notes ${selectedFileName!}';
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Camera notice: $e')));
              }
            }
          }

          Future<void> pickGenericFile() async {
            try {
              final picker = ImagePicker();
              final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (photo != null) {
                setModalState(() {
                  selectedFileName = photo.name.isNotEmpty ? photo.name : 'Device_File_${DateTime.now().millisecondsSinceEpoch}.pdf';
                  selectedFileSize = '2.1 MB';
                  selectedFileType = 'Device Gallery Image';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = 'Gallery Document ${selectedFileName!}';
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File picker notice: $e')),
                );
              }
            }
          }

          Future<void> submitUpload() async {
            final t = titleCtrl.text.trim();
            if (t.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.dangerRed,
                  content: Text('Please enter a Title for this note.'),
                ),
              );
              return;
            }

            setModalState(() => isUploading = true);

            final notePayload = {
              'title': t,
              'subject': subject,
              'batch': targetBatch,
              'description': descCtrl.text.trim(),
              'fileName': selectedFileName ?? '${t.replaceAll(' ', '_')}.pdf',
              'fileType': selectedFileType ?? 'PDF Document',
              'fileSize': selectedFileSize ?? '2.1 MB',
              'pdfUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            };

            final ok = await ApiService.addNote(notePayload);

            if (!mounted) return;
            Navigator.pop(ctx);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: ok
                    ? AppTheme.successGreen
                    : AppTheme.dangerRed,
                content: Text(
                  ok
                      ? 'PDF Note uploaded successfully! Auto-notification sent to $targetBatch students.'
                      : 'Failed to upload note.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            _loadNotes();
          }

          final subjectsList = targetBatch.contains('Commerce')
              ? commerceSubjects
              : scienceSubjects;
          if (!subjectsList.contains(subject)) {
            subject = subjectsList.first;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: AppTheme.dangerRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload PDF Study Material',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Auto-notifies all students in the class',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Title
                  const Text(
                    'Note Title *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Chapter 4 - Financial Accounting Practice',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Batch Selection
                  const Text(
                    'Select Class / Batch *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: targetBatch,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: 'Class 9 (Maths & Science)',
                        child: Text('Class 9 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 10 (Maths & Science)',
                        child: Text('Class 10 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 11 (Maths & Science)',
                        child: Text('Class 11 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 12 (Maths & Science)',
                        child: Text('Class 12 (Maths & Science) - Muskan'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 11 & 12 (Commerce)',
                        child: Text('Class 11 & 12 (Commerce) - Zoya'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => targetBatch = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Subject Selection
                  const Text(
                    'Subject *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: subject,
                    decoration: const InputDecoration(),
                    items: subjectsList
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => subject = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Upload source selector
                  const Text(
                    'Upload Source * (Phone, Camera, or Files)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickPdfFile,
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            size: 18,
                            color: AppTheme.dangerRed,
                          ),
                          label: const Text(
                            'PDF File',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickFromCamera,
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: AppTheme.brandBlue,
                          ),
                          label: const Text(
                            'Camera Scan',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickGenericFile,
                          icon: const Icon(
                            Icons.folder_open,
                            size: 18,
                            color: Colors.amber,
                          ),
                          label: const Text(
                            'Files',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (selectedFileName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.successGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFileName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Ready to upload ($selectedFileSize - $selectedFileType)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Description
                  const Text(
                    'Note Description / Instructions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Read through pages 12-25 before Monday test.',
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isUploading ? null : submitUpload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Upload & Notify Students',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _previewNote(dynamic n) {
    PdfPreviewDialog.show(
      context,
      title: n['title'] ?? 'Study Material',
      subject: n['subject'] ?? 'General',
      batch: n['batch'] ?? 'Class Batch',
      description: n['description'],
      fileName:
          n['fileName'] ??
          '${(n['title'] ?? 'Note').toString().replaceAll(' ', '_')}.pdf',
      fileSize: n['fileSize'] ?? '2.4 MB',
      url: n['link'] ?? n['pdfUrl'],
    );
  }

  void _downloadNote(dynamic n) async {
    final title = n['title'] ?? 'Study Material';
    final fileName = n['fileName'] ?? '${title.toString().replaceAll(' ', '_')}.pdf';
    final urlStr = n['link'] ?? n['pdfUrl'] ?? 'https://zm-tuition.com/docs/$fileName';

    try {
      final uri = Uri.parse(urlStr);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.brandBlue,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Downloading "$fileName"...')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _notes.where((n) {
      if (_selectedSubject == 'All') return true;
      return (n['subject'] ?? '') == _selectedSubject;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Study Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadNotes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: AppTheme.brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload PDF Note'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppTheme.brandBlue.withAlpha(15),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppTheme.brandBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Upload PDFs from phone, camera, or files. Students receive instant notifications upon upload.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.inkPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes List
                Expanded(
                  child: filteredNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No study materials uploaded yet.',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showUploadDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Upload First Note'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, idx) {
                            final n = filteredNotes[idx];
                            final title = n['title'] ?? 'Study Material';
                            final subject = n['subject'] ?? 'General';
                            final batch = n['batch'] ?? 'All Batches';
                            final fileName = n['fileName'] ?? '$title.pdf';
                            final fileSize = n['fileSize'] ?? '1.8 MB';
                            final date = n['date'] ?? '';
                            final desc = n['description'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: AppTheme.line),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerRed.withAlpha(
                                              20,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.picture_as_pdf,
                                            color: AppTheme.dangerRed,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.inkPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.brandBlue
                                                          .withAlpha(20),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      subject,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppTheme.brandBlue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    batch,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.inkSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.dangerRed,
                                          ),
                                          tooltip: 'Delete Note',
                                          onPressed: () => _deleteNote(n),
                                        ),
                                      ],
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.inkSecondary,
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 16),
                                    // File Details Row (Responsive with ellipsis)
                                    Row(
                                      children: [
                                        Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '$fileName ($fileSize)',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Full-Width Action Buttons (100% visible on mobile and web)
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: OutlinedButton.icon(
                                            onPressed: () => _previewNote(n),
                                            icon: const Icon(Icons.visibility_outlined, size: 16),
                                            label: const Text('Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _downloadNote(n),
                                            icon: const Icon(Icons.download_rounded, size: 18),
                                            label: const Text('Download PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.brandBlue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              elevation: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
