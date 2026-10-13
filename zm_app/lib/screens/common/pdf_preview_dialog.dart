import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class PdfPreviewDialog extends StatefulWidget {
  final String title;
  final String subject;
  final String batch;
  final String? description;
  final String? fileName;
  final String? fileSize;
  final String? url;

  const PdfPreviewDialog({
    super.key,
    required this.title,
    required this.subject,
    required this.batch,
    this.description,
    this.fileName,
    this.fileSize,
    this.url,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subject,
    required String batch,
    String? description,
    String? fileName,
    String? fileSize,
    String? url,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PdfPreviewDialog(
        title: title,
        subject: subject,
        batch: batch,
        description: description,
        fileName: fileName,
        fileSize: fileSize,
        url: url,
      ),
    );
  }

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  int _currentPage = 1;
  final int _totalPages = 6;
  double _zoomLevel = 1.0;

  Future<void> _launchExternalUrl() async {
    final target = widget.url ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    final uri = Uri.parse(target);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _downloadPdf() async {
    final target = widget.url ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    final uri = Uri.parse(target);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloaded "${widget.fileName ?? widget.title}.pdf" to your device storage!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 720,
        height: 680,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: isDark ? AppTheme.lineDark : AppTheme.line)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.dangerRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.brandBlueSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.subject,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.fileSize ?? "2.4 MB"} • Verified Material',
                              style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppTheme.brandBlue),
                    tooltip: 'Download PDF',
                    onPressed: _downloadPdf,
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_browser_rounded),
                    tooltip: 'Open in Browser',
                    onPressed: _launchExternalUrl,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      ),
                      Text(
                        'Page $_currentPage of $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.zoom_out, size: 20),
                        tooltip: 'Zoom Out',
                        onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.8, 1.5)),
                      ),
                      Text('${(_zoomLevel * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.zoom_in, size: 20),
                        tooltip: 'Zoom In',
                        onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.8, 1.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PDF Reader Body (Simulated Interactive Document View)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Center(
                    child: Transform.scale(
                      scale: _zoomLevel,
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 580,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: isDark ? AppTheme.lineDark : AppTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header of Document
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandBlue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('ZM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('ZM TUITION CENTER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandBlueSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.batch,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandBlue),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Document Title & Subject
                            Text(
                              widget.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Subject: ${widget.subject} • Chapter Series • Document Page #$_currentPage',
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),

                            if (widget.description != null && widget.description!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDarkElevated : AppTheme.paperLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.description!,
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Page Content Sections
                            _buildSampleSection(
                              '1. Key Formulae & Core Definitions',
                              '• All standard NCERT equations & theorem proofs are encapsulated below.\n'
                              '• Important definitions must be revised thoroughly for unit tests & finals.\n'
                              '• Practice step-by-step problem statements with standard notations.',
                            ),
                            const SizedBox(height: 14),

                            _buildSampleSection(
                              '2. Important Solved Concept Examples',
                              'Problem 1: Derive the standard formulation with given boundary parameters.\n'
                              'Solution: Applying the core identity, we evaluate step 1 through step 3.\n'
                              'Note: Always write units and final boxed results in tests.',
                            ),
                            const SizedBox(height: 14),

                            _buildSampleSection(
                              '3. Teacher Guidelines (Zoya & Muskan)',
                              '• Homework submission is mandatory before next Tuesday.\n'
                              '• In-class doubts will be addressed during regular tuition slots.\n'
                              '• Refer to this digital copy for quick formula recall anytime.',
                            ),

                            const Divider(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Verified by ZM Faculty', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.inkSecondaryDark : AppTheme.inkSecondary)),
                                Text('Page $_currentPage / $_totalPages', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppTheme.inkSecondaryDark : AppTheme.inkSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: isDark ? AppTheme.lineDark : AppTheme.line)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 16, color: AppTheme.successGreen),
                  const SizedBox(width: 6),
                  const Text('Secure Student Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.successGreen)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Download PDF'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.brandBlue)),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(fontSize: 12.5, height: 1.5)),
      ],
    );
  }
}
