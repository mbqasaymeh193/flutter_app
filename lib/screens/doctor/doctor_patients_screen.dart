import 'package:flutter/material.dart';

class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Patients')),
      body: const Center(child: Text('Patients list coming soon')),
    );
  }
}
