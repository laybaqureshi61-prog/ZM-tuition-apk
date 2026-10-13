import 'package:flutter/material.dart';
import '../../services/app_data.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Coaching Notices & Updates'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appData.notices.length,
        itemBuilder: (context, index) {
          final notice = appData.notices[index];
          Color iconBg;
          IconData iconData;

          if (notice.category == 'Holiday') {
            iconBg = Colors.purple.shade50;
            iconData = Icons.card_giftcard;
          } else if (notice.category == 'Exam') {
            iconBg = Colors.blue.shade50;
            iconData = Icons.quiz;
          } else if (notice.category == 'Fee') {
            iconBg = Colors.orange.shade50;
            iconData = Icons.account_balance_wallet;
          } else {
            iconBg = Colors.indigo.shade50;
            iconData = Icons.campaign;
          }

          return Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconData, color: const Color(0xFF4F46E5), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(notice.category, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(notice.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                        const SizedBox(height: 6),
                        Text(notice.description, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3)),
                      ],
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
}
