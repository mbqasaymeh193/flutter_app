import 'package:flutter/material.dart';
import 'package:medical_booking_app/services/api_service.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  List<dynamic> patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final result = await ApiService.getDoctorPatients();
    setState(() {
      patients = result ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
              ? const Center(child: Text('No patients found'))
              : ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blueAccent),
                        title: Text(p['name']),
                        subtitle: Text('Email: ${p['email'] ?? 'N/A'}'),
                      ),
                    );
                  },
                ),
    );
  }
}
