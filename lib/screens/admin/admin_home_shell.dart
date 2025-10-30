import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class AdminHomeShell extends StatelessWidget {
  const AdminHomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings, size: 56, color: Color(0xFF1976D2)),
            const SizedBox(height: 12),
            const Text('مرحبًا بك! شاشة الأدمن قيد الإعداد.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // لاحقًا: انتقل لشاشات إدارة المواعيد/المستخدمين
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سيتم إضافة مزيد من مزايا الأدمن لاحقًا')),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('قريبًا'),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () async {
                await ApiService.logout();
                // رجوع لتسجيل الدخول
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
