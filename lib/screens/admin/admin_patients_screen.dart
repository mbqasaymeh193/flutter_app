import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class AdminPatientsScreen extends StatelessWidget {
  const AdminPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // لاحقًا سيتم استدعاء بيانات المرضى من API
    final patients = [
      {"name": "محمد خالد", "email": "mohammad@gmail.com"},
      {"name": "أحمد علي", "email": "ahmad@example.com"},
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: "إدارة المرضى"),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final p = patients[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(p["name"]!),
              subtitle: Text(p["email"]!),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // 🗑️ حذف مريض لاحقًا
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
