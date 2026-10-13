import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../common/pdf_preview_dialog.dart';

class StudentNotesScreen extends StatefulWidget {
  final UserModel user;
  const StudentNotesScreen({super.key, required this.user});

  @override
  State<StudentNotesScreen> createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  bool _isLoading = true;
  List<dynamic> _notes = [];
  String _searchQuery = '';
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getNotes();
    if (!mounted) return;
    setState(() {
      _notes = list;
      _isLoading = false;
    });
  }

    Future<void> _downloadNote(dynamic n) async {
    final rawUrl = (n['link'] ?? n['pdfUrl'] ?? '').toString();
    final fileName = n['fileName'] ?? '${(n['title'] ?? 'Note').toString().replaceAll(' ', '_')}.pdf';
    final targetUrl = rawUrl.isNotEmpty 
        ? rawUrl 
        : 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.brandBlue,
        content: Row(
          children: [
            const Icon(Icons.downloading, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Opening / Downloading "$fileName"...',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _previewNote(dynamic n) {
    PdfPreviewDialog.show(
      context,
      title: n['title'] ?? 'Study Material',
      subject: n['subject'] ?? 'General',
      batch: n['batch'] ?? 'Class Batch',
      description: n['description'],
      fileName: n['fileName'] ?? '${(n['title'] ?? 'Note').toString().replaceAll(' ', '_')}.pdf',
      fileSize: n['fileSize'] ?? '2.4 MB',
      url: n['link'] ?? n['pdfUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter notes relevant to student's enrolled batch
    final studentBatch = widget.user.batch ?? '';
    final isCommerceStudent = studentBatch.contains('Commerce');

    final relevantNotes = _notes.where((n) {
      final noteBatch = (n['batch'] ?? '').toString().toLowerCase();
      final sBatch = studentBatch.toLowerCase();
      
      if (studentBatch.isNotEmpty) {
        if (isCommerceStudent && !noteBatch.contains('commerce') && !noteBatch.contains('all')) {
          return false;
        }
        if (!isCommerceStudent && noteBatch.contains('commerce')) {
          return false;
        }

        // If batch has a class specified (e.g. 9, 10, 11, 12), match that class
        for (final c in ['class 9', 'class 10', 'class 11', 'class 12']) {
          if (sBatch.contains(c) && !noteBatch.contains('all')) {
            if (!noteBatch.contains(c)) {
              return false;
            }
          }
        }
      }

      if (_selectedSubject != 'All' && (n['subject'] ?? '') != _selectedSubject) {
        return false;
      }

      final title = (n['title'] ?? '').toString().toLowerCase();
      final sub = (n['subject'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || sub.contains(q);
    }).toList();

    final subjects = {'All', ...relevantNotes.map((n) => (n['subject'] ?? '').toString()).where((s) => s.isNotEmpty)};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials & PDFs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppTheme.brandBlue.withAlpha(15),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.brandBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing verified syllabus materials for ${studentBatch.isNotEmpty ? studentBatch : "Your Class"}.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.inkPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Box
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search notes by title or chapter...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.brandBlue),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Subject filter chips
                if (subjects.length > 2)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: subjects.map((sub) {
                        final isSel = _selectedSubject == sub;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sub),
                            selected: isSel,
                            onSelected: (s) => setState(() => _selectedSubject = sub),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Notes List
                Expanded(
                  child: relevantNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No notes matching "$_searchQuery"'
                                    : 'No study materials uploaded for this class yet.',
                                style: const TextStyle(color: AppTheme.inkSecondary, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: relevantNotes.length,
                          itemBuilder: (context, idx) {
                            final n = relevantNotes[idx];
                            final title = n['title'] ?? 'Study Material';
                            final subject = n['subject'] ?? 'General';
                            final fileName = n['fileName'] ?? '$title.pdf';
                            final fileSize = n['fileSize'] ?? '1.8 MB';
                            final date = n['date'] ?? '';
                            final desc = n['description'] ?? '';
                            final addedBy = n['addedBy'] ?? 'Teacher';

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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerRed.withAlpha(20),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.picture_as_pdf, color: AppTheme.dangerRed, size: 28),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.brandBlue.withAlpha(20),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      subject,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.brandBlue,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'By $addedBy',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        desc,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
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
