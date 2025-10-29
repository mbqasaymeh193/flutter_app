import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class PatientDoctorsScreen extends StatelessWidget {
  const PatientDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'الأطباء'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1976D2),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text('د. أحمد علي'),
              subtitle: const Text('أخصائي قلب'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF1976D2)),
                onPressed: () => Navigator.pushNamed(context, '/patient-book'),
              ),
            ),
          );
        },
      ),
    );
  }
}
