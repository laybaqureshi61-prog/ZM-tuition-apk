import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../common/fee_receipt_dialog.dart';

class AdminFeesScreen extends StatefulWidget {
  final UserModel user;
  const AdminFeesScreen({super.key, required this.user});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  bool _isLoading = true;
  List<dynamic> _fees = [];
  String _batchFilter = 'All';

  bool get isZoya {
    final type = widget.user.adminType?.toLowerCase();
    final name = widget.user.name.toLowerCase();
    return type == 'zoya' || name.contains('zoya');
  }

  @override
  void initState() {
    super.initState();
    _batchFilter = isZoya ? 'Commerce' : 'Science';
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() => _isLoading = true);
    final feesList = await ApiService.getFees();
    if (!mounted) return;
    setState(() {
      _fees = feesList;
      _isLoading = false;
    });
  }

  Future<void> _markPaid(dynamic feeItem) async {
    final feeId = feeItem['id']?.toString() ?? '';
    final studentName = feeItem['studentName'] ?? 'Student';
    final amount = feeItem['amount'] ?? 500;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Fee Payment'),
        content: Text('Mark fee of ₹$amount as PAID for student "$studentName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true && feeId.isNotEmpty) {
      setState(() => _isLoading = true);
      final ok = await ApiService.payFee(feeId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppTheme.successGreen : AppTheme.dangerRed,
          content: Text(ok ? 'Payment of ₹$amount recorded for $studentName!' : 'Failed to update fee record.'),
        ),
      );
      _loadFees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFees = _fees.where((f) {
      final b = (f['batch'] ?? '').toString();
      if (_batchFilter == 'Commerce') return b.contains('Commerce');
      if (_batchFilter == 'Science') return !b.contains('Commerce');
      return true;
    }).toList();

    int totalCollected = 0;
    int totalPending = 0;
    int paidCount = 0;
    int dueCount = 0;

    for (var f in filteredFees) {
      final amount = (f['amount'] is num) ? (f['amount'] as num).toInt() : int.tryParse(f['amount'].toString()) ?? 500;
      final status = f['status'] ?? 'Due';
      if (status == 'Paid') {
        totalCollected += amount;
        paidCount++;
      } else {
        totalPending += amount;
        dueCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Tracking & Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadFees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Metrics
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.brandBlue.withAlpha(15),
                  child: Row(
                    children: [
                      _buildMetricCard('Collected', '₹$totalCollected', '$paidCount Students', AppTheme.successGreen),
                      const SizedBox(width: 12),
                      _buildMetricCard('Pending Due', '₹$totalPending', '$dueCount Students', AppTheme.dangerRed),
                    ],
                  ),
                ),

                // Batch Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Commerce (₹1000)'),
                        selected: _batchFilter == 'Commerce',
                        onSelected: (s) => setState(() => _batchFilter = 'Commerce'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Science (₹500)'),
                        selected: _batchFilter == 'Science',
                        onSelected: (s) => setState(() => _batchFilter = 'Science'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _batchFilter == 'All',
                        onSelected: (s) => setState(() => _batchFilter = 'All'),
                      ),
                    ],
                  ),
                ),

                // Fee Records List
                Expanded(
                  child: filteredFees.isEmpty
                      ? const Center(child: Text('No fee records found for this batch.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredFees.length,
                          itemBuilder: (context, idx) {
                            final fee = filteredFees[idx];
                            final name = fee['studentName'] ?? 'Student';
                            final batch = fee['batch'] ?? 'General';
                            final month = fee['month'] ?? 'October 2026';
                            final amount = fee['amount'] ?? 500;
                            final status = fee['status'] ?? 'Due';
                            final isPaid = status == 'Paid';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isPaid ? AppTheme.line : AppTheme.dangerRed.withAlpha(50),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isPaid ? AppTheme.successGreen.withAlpha(20) : AppTheme.dangerRed.withAlpha(20),
                                      child: Icon(
                                        isPaid ? Icons.check_circle : Icons.pending_actions,
                                        color: isPaid ? AppTheme.successGreen : AppTheme.dangerRed,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$batch • $month',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Fee Amount: ₹$amount / month',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.brandBlue),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isPaid)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successGreen.withAlpha(20),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppTheme.successGreen),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, size: 14, color: AppTheme.successGreen),
                                                SizedBox(width: 4),
                                                Text('Paid', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.receipt_long, size: 20, color: AppTheme.brandBlue),
                                            tooltip: 'View Fee Receipt',
                                            onPressed: () {
                                              FeeReceiptDialog.show(
                                                context,
                                                studentName: name,
                                                rollNo: 'ZM-${fee['studentId'] ?? '101'}',
                                                batch: batch,
                                                month: month,
                                                amount: amount,
                                                authorizedBy: isZoya ? 'Zoya (Director)' : 'Muskan (Director)',
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: () => _markPaid(fee),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.brandBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        child: const Text('Mark Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildMetricCard(String title, String amount, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary)),
            const SizedBox(height: 4),
            Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.inkSecondary)),
          ],
        ),
      ),
    );
  }
}
