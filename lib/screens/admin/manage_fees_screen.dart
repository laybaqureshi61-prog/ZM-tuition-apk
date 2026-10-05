import 'package:flutter/material.dart';
import '../../services/app_data.dart';

class ManageFeesScreen extends StatefulWidget {
  const ManageFeesScreen({super.key});

  @override
  State<ManageFeesScreen> createState() => _ManageFeesScreenState();
}

class _ManageFeesScreenState extends State<ManageFeesScreen> {
  final AppData _appData = AppData();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Manage Tuition Fees'),
          backgroundColor: const Color(0xFF4F46E5),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Fee List'),
              Tab(text: 'Payment Records'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Fee List (PRD Screen 12)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _appData.fees.length,
              itemBuilder: (context, index) {
                final fee = _appData.fees[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(fee.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${fee.className} • ${fee.month}\nAmount: ₹${fee.amount.toStringAsFixed(0)}'),
                    isThreeLine: true,
                    trailing: Switch(
                      value: fee.isPaid,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() {
                          fee.isPaid = val;
                          fee.date = val ? 'Today' : 'Pending';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${fee.studentName} fee status updated to ${val ? "PAID" : "PENDING"}')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Tab 2: Payment Records (PRD Screen 14)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _appData.fees.where((f) => f.isPaid).length,
              itemBuilder: (context, index) {
                final fee = _appData.fees.where((f) => f.isPaid).toList()[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    title: Text(fee.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Paid Amount: ₹${fee.amount.toStringAsFixed(0)} • Date: ${fee.date}'),
                    trailing: const Chip(
                      label: Text('PAID'),
                      backgroundColor: Color(0xFFE8F5E9),
                      labelStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
}
