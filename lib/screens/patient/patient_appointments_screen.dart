import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'مواعيدي'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
              title: const Text('موعد مع د. أحمد علي'),
              subtitle: const Text('12 نوفمبر 2025 - الساعة 10:00 ص'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
              ),
            ),
          );
        },
      ),
    );
  }
}
