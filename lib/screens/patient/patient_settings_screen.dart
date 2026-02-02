import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ApiService.logout();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
