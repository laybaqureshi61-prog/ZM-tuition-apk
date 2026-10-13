import 'package:flutter/material.dart';
import '../../services/app_data.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appData.notifications.length,
        itemBuilder: (context, index) {
          final notif = appData.notifications[index];
          Color iconColor = const Color(0xFF4F46E5);
          if (notif.type == 'note') iconColor = Colors.purple;
          if (notif.type == 'fee') iconColor = Colors.green;
          if (notif.type == 'test') iconColor = Colors.orange;

          return Card(
            color: Colors.white,
            elevation: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(Icons.notifications_active, color: iconColor, size: 20),
              ),
              title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
              subtitle: Text('${notif.description}\n${notif.time}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
