import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'الملف الشخصي'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFF1976D2)),
            const SizedBox(height: 10),
            const Text('رائد شدفات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF1976D2)),
              title: const Text('raed@example.com'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF1976D2)),
              title: const Text('+962 7 9000 0000'),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: () {},
              child: const Text('تعديل المعلومات'),
            ),
          ],
        ),
      ),
    );
  }
}
