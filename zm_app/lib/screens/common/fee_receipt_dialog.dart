import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class FeeReceiptDialog extends StatelessWidget {
  final String studentName;
  final String rollNo;
  final String batch;
  final String month;
  final int amount;
  final String receiptNo;
  final String paymentMode;
  final String date;
  final String authorizedBy;

  const FeeReceiptDialog({
    super.key,
    required this.studentName,
    required this.rollNo,
    required this.batch,
    required this.month,
    required this.amount,
    required this.receiptNo,
    this.paymentMode = 'UPI / Online Transfer',
    required this.date,
    this.authorizedBy = 'Zoya & Muskan (ZM Tuition)',
  });

  static void show(
    BuildContext context, {
    required String studentName,
    required String rollNo,
    required String batch,
    required String month,
    required int amount,
    String? receiptNo,
    String paymentMode = 'UPI / Online Transfer',
    String? date,
    String authorizedBy = 'Zoya & Muskan (ZM Tuition)',
  }) {
    final rNo = receiptNo ?? 'ZM-RCP-${DateTime.now().year}-${(1000 + DateTime.now().millisecond)}';
    final d = date ?? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FeeReceiptDialog(
        studentName: studentName,
        rollNo: rollNo,
        batch: batch,
        month: month,
        amount: amount,
        receiptNo: rNo,
        paymentMode: paymentMode,
        date: d,
        authorizedBy: authorizedBy,
      ),
    );
  }

  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.successGreen,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receipt $receiptNo downloaded successfully as PDF!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 580,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.brandBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppTheme.brandBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Fee Receipt',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            'ZM Tuition Center • Payment Acknowledgment',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Printable Receipt Paper Card
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.paperDark : AppTheme.paperLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppTheme.lineDark : AppTheme.line, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Watermark / Tuition info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ZM TUITION CENTER',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : AppTheme.brandBlue,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('Main Road, Opp. City Center', style: TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreenSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.successGreen),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                                SizedBox(width: 4),
                                Text(
                                  'PAID',
                                  style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Meta Table
                      _buildRow('Receipt Number:', receiptNo, isBold: true),
                      const SizedBox(height: 8),
                      _buildRow('Payment Date:', date),
                      const SizedBox(height: 8),
                      _buildRow('Student Name:', studentName, isBold: true),
                      const SizedBox(height: 8),
                      _buildRow('Roll Number:', rollNo),
                      const SizedBox(height: 8),
                      _buildRow('Class / Batch:', batch),
                      const SizedBox(height: 8),
                      _buildRow('Fee Month:', month),
                      const SizedBox(height: 8),
                      _buildRow('Payment Mode:', paymentMode),

                      const Divider(height: 24),

                      // Amount Highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount Cleared:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹$amount',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Seal & Sign
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stamp / Status', style: TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.successGreen),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VERIFIED ONLINE',
                                  style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Authorized By:', style: TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                authorizedBy,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Text('ZM Tuition Academic Team', style: TextStyle(fontSize: 10, color: AppTheme.inkSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandBlue),
                        onPressed: () => _downloadReceipt(context),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
