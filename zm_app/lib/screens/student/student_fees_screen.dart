import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../common/fee_receipt_dialog.dart';

class StudentFeesScreen extends StatefulWidget {
  final UserModel user;
  const StudentFeesScreen({super.key, required this.user});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _feeData;

  @override
  void initState() {
    super.initState();
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getMyFees();
    if (!mounted) return;
    setState(() {
      _feeData = data;
      _isLoading = false;
    });
  }

  void _openReceiptDialog(int amount, String month, String batch) {
    FeeReceiptDialog.show(
      context,
      studentName: widget.user.name.isNotEmpty ? widget.user.name : 'Student',
      rollNo: widget.user.rollNo ?? 'ZM-101',
      batch: batch,
      month: month,
      amount: amount,
      paymentMode: 'Cash / Direct Account Transfer',
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _feeData?['status'] ?? 'Due';
    final isPaid = status == 'Paid';
    final isHigherSecondary = (widget.user.batch ?? '').contains('11') || (widget.user.batch ?? '').contains('12') || (widget.user.batch ?? '').contains('Commerce');
    final amount = _feeData?['amount'] ?? (isHigherSecondary ? 1000 : 600);
    final month = _feeData?['month'] ?? 'October 2026';
    final batch = _feeData?['batch'] ?? widget.user.batch ?? 'Tuition Batch';
    final isCommerce = batch.contains('Commerce') || (widget.user.batch ?? '').contains('Commerce');

    final statusColor = isPaid ? AppTheme.successGreen : AppTheme.dangerRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tuition Fees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadFeeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Verified Student Fee Account Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.brandBlue.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.brandBlue.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 20, color: AppTheme.brandBlue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Official Student Account • ${widget.user.name.isNotEmpty ? widget.user.name : "Student"} (Roll No: ${widget.user.rollNo ?? "ZM-101"})',
                                style: const TextStyle(fontSize: 13, color: AppTheme.inkPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Main Fee Card
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: statusColor.withAlpha(70), width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          month,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          batch,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.inkSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 16, color: statusColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          isPaid ? 'PAID' : 'FEES DUE',
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),

                              // Fee Amount
                              Row(
                                children: [
                                  const Text('Monthly Tuition Fee:', style: TextStyle(fontSize: 15, color: AppTheme.inkSecondary, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  Text(
                                    '₹$amount',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.brandBlue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Stream / Department
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Department / Stream:', style: TextStyle(fontSize: 13.5, color: AppTheme.inkSecondary)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isCommerce ? 'Commerce (11 & 12)' : 'Science & Maths (9 & 10)',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.inkPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Monthly Due Cycle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Fee Cycle:', style: TextStyle(fontSize: 13.5, color: AppTheme.inkSecondary)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isPaid ? 'Cleared for $month' : 'Due by 10th of every month',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Paid Status Button or Pending Note
                              if (isPaid) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () => _openReceiptDialog(amount, month, batch),
                                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                                    label: const Text('Download / View Official Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Tuition fee for this month is due. Please deposit your fee at the tuition center office.',
                                          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fee Structure Reference
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.line),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, size: 18, color: AppTheme.brandBlue),
                                  SizedBox(width: 8),
                                  Text('Center Fee Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text('• Class 11 & 12 (Commerce & Science Streams): ₹1,000 / month (Accounts, Business, Eco, Maths & Science)', style: TextStyle(fontSize: 12.5, color: AppTheme.inkSecondary)),
                              SizedBox(height: 6),
                              Text('• Class 9 & 10 (Maths & Science): ₹600 / month (Mathematics & Science)', style: TextStyle(fontSize: 12.5, color: AppTheme.inkSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
