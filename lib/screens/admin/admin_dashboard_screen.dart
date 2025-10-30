import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalAppointments = 0;
  int totalDoctors = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final myAppointments = await ApiService.getAdminAppointments();
    final doctors = await ApiService.getDoctors();
    setState(() {
      totalAppointments = myAppointments?.length ?? 0;
      totalDoctors = doctors.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue[50],
              child: ListTile(
                title: const Text('Total Appointments'),
                trailing: Text(
                  '$totalAppointments',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.blue[50],
              child: ListTile(
                title: const Text('Total Doctors'),
                trailing: Text(
                  '$totalDoctors',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-appointments');
              },
              child: const Text('View All Appointments'),
            ),
          ],
        ),
      ),
    );
  }
}
