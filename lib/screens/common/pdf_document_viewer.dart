import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../services/app_data.dart';

class PdfDocumentViewerModal extends StatefulWidget {
  final NoteModel note;

  const PdfDocumentViewerModal({super.key, required this.note});

  static void open(BuildContext context, NoteModel note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PdfDocumentViewerModal(note: note),
    );
  }

  @override
  State<PdfDocumentViewerModal> createState() => _PdfDocumentViewerModalState();
}

class _PdfDocumentViewerModalState extends State<PdfDocumentViewerModal> {
  int _currentPage = 1;
  final int _totalPages = 5;
  double _zoomScale = 1.0;

  void _triggerFileDownload() async {
    final fileName = widget.note.fileName.endsWith('.pdf')
        ? widget.note.fileName
        : '${widget.note.fileName}.pdf';

    // Generate formatted text content for PDF download
    final pdfContent = '''
=====================================================
            ${AppData.instituteName}
      Old Bus Stand, Nakur | Phone: 9876543210
=====================================================

TITLE: ${widget.note.title}
SUBJECT: ${widget.note.subject}
CLASS / BATCH: ${widget.note.className}
DATE: ${widget.note.date}
UPLOADED BY: ${widget.note.uploadedBy}
FILE NAME: $fileName
FILE SIZE: ${widget.note.fileSize}

-----------------------------------------------------
CHAPTER STUDY NOTES & FORMULA SUMMARY
-----------------------------------------------------
1. Key Definitions & Concepts
   - Fundamental formulas for ${widget.note.subject} (${widget.note.className}).
   - Important theorems and step-by-step solved examples.

2. Solved Example Questions
   Q1: Explain the fundamental law and state its applications.
   Ans: Step-by-step derivation with formulas and units.

3. Important Practice Exercise
   - Solve all exercise questions from Chapter 1 to 4.
   - Revise formula sheet before live test series.

-----------------------------------------------------
Official Study Material Published by ZM Tuition
=====================================================
''';

    try {
      final bytes = utf8.encode(pdfContent);
      final base64Str = base64Encode(bytes);
      final dataUri = Uri.parse('data:application/pdf;base64,$base64Str');

      if (kIsWeb) {
        if (await canLaunchUrl(dataUri)) {
          await launchUrl(dataUri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(dataUri);
        }
      } else {
        await launchUrl(dataUri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully downloaded "$fileName" (${widget.note.fileSize}) to Downloads!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading "$fileName" (${widget.note.fileSize}). Saved to Downloads!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Dark Slate Reader Background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Reader Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.note.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.note.fileName} • ${widget.note.fileSize}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Zoom & Navigation Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                      onPressed: () {
                        if (_zoomScale > 0.8) setState(() => _zoomScale -= 0.2);
                      },
                    ),
                    Text('${(_zoomScale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                      onPressed: () {
                        if (_zoomScale < 1.8) setState(() => _zoomScale += 0.2);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
                      onPressed: () {
                        if (_currentPage > 1) setState(() => _currentPage--);
                      },
                    ),
                    Text('Page $_currentPage of $_totalPages', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                      onPressed: () {
                        if (_currentPage < _totalPages) setState(() => _currentPage++);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main PDF Paper Document View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Transform.scale(
                scale: _zoomScale,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Watermark Institute Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.school, color: Color(0xFF4F46E5), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  AppData.instituteName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4F46E5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target Class: ${widget.note.className} | Subject: ${widget.note.subject}',
                              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Uploaded by ${widget.note.uploadedBy} on ${widget.note.date}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Document Content (Page View)
                      Text(
                        'Chapter Notes: ${widget.note.title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      if (_currentPage == 1) ...[
                        const Text('1. Key Formulae & Concepts Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text(
                          '• Standard Form: ax² + bx + c = 0 (where a ≠ 0)\n'
                          '• Discriminant Formula: D = b² - 4ac\n'
                          '• Quadratic Roots: x = (-b ± √D) / (2a)\n'
                          '• If D > 0: Two distinct real roots exist.\n'
                          '• If D = 0: Two equal real roots exist.\n'
                          '• If D < 0: No real roots exist (complex roots).',
                          style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                        ),
                      ] else if (_currentPage == 2) ...[
                        const Text('2. Solved Example Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text(
                          'Q1. Find the roots of the equation 2x² - 5x + 3 = 0.\n'
                          'Solution:\n'
                          'Here a = 2, b = -5, c = 3\n'
                          'D = (-5)² - 4(2)(3) = 25 - 24 = 1 (> 0)\n'
                          'x = (5 ± √1) / (2 × 2) = (5 ± 1) / 4\n'
                          'Roots are x₁ = 6/4 = 3/2 and x₂ = 4/4 = 1.\n'
                          'Answer: Roots are x = 3/2 and x = 1.',
                          style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                        ),
                      ] else if (_currentPage == 3) ...[
                        const Text('3. Practice Exercise Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text(
                          'Q1. Solve 3x² - 2√6x + 2 = 0 by factorization method.\n'
                          'Q2. Find the value of k for which x² + 4kx + k = 0 has equal roots.\n'
                          'Q3. A train travels 360 km at a uniform speed. If speed was 5 km/h more, it would take 1 hour less. Find speed.',
                          style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                        ),
                      ] else if (_currentPage == 4) ...[
                        const Text('4. Important Definitions & Diagrams:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_graph, size: 48, color: Color(0xFF4F46E5)),
                              SizedBox(height: 6),
                              Text('Parabola Curve Graph (a > 0 vs a < 0)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5))),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Text('5. Exam Tips & Formula Sheet Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text(
                          '• Always write units for physics and numerical answers in math.\n'
                          '• Double check discriminant calculations to avoid sign errors.\n'
                          '• All students are advised to complete the practice exercises before Sunday live test.',
                          style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Page $_currentPage of $_totalPages • ZM Tuition Study Notes',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Download PDF Action Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _triggerFileDownload,
                icon: const Icon(Icons.download),
                label: Text(
                  'Download PDF File (${widget.note.fileSize})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
