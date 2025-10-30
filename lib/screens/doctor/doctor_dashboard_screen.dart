import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../doctor/doctor_appointments_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int totalAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appointments = await ApiService.getDoctorAppointments();
    setState(() {
      totalAppointments = appointments?.length ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Dashboard')),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/doctor-appointments');
              },
              child: const Text('View Appointments'),
            ),
          ],
        ),
      ),
    );
  }
}
