import 'package:flutter/material.dart';
import '../../services/app_data.dart';

class SecondAdminViewScreen extends StatelessWidget {
  const SecondAdminViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData();
    final admin1 = appData.admins[0]; // Zoya
    final admin2 = appData.admins[1]; // Muskan

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Management & Views'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coaching Admin Teachers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),

            // Admin 1 Card (Zoya)
            _buildAdminCard(admin1, context, appData),
            const SizedBox(height: 16),

            // Admin 2 Card (Muskan)
            _buildAdminCard(admin2, context, appData),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(dynamic admin, BuildContext context, AppData appData) {
    final isCurrent = appData.currentUser?.id == admin.id;

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF4F46E5), size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(admin.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(admin.assignedClass, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                if (isCurrent)
                  Chip(
                    label: const Text('Active'),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Permissions & Stream Access', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.grey.shade300 : const Color(0xFF4F46E5),
                    foregroundColor: isCurrent ? Colors.black87 : Colors.white,
                  ),
                  onPressed: () {
                    appData.currentUser = admin;
                    appData.notifyListeners();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Switched active Admin view to ${admin.name}!')),
                    );
                  },
                  child: Text(isCurrent ? 'Current Admin' : 'Switch to ${admin.name.split(' ')[0]}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
