import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ApiService.logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
