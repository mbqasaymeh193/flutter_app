import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('حساب الطبيب', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('تعديل البيانات من السيرفر عبر /api/doctor/profile'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.popUntil(context, (r) => r.isFirst);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ),
        ],
      ),
    );
  }
}
