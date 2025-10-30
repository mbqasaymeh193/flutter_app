import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/appointment_card.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  bool _loading = false;
  List<dynamic> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMyAppointments();
      setState(() => appointments = data ?? []);
    } catch (e) {
      print("🔴 Error fetching appointments: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return AppointmentCard(
                  doctorName: appt['doctor']['fullName'] ?? "Doctor",
                  date: appt['startsAt']?.substring(0, 10) ?? "",
                  time: appt['startsAt']?.substring(11, 16) ?? "",
                  status: appt['status'] ?? "Pending",
                  onTap: () {},
                );
              },
            ),
    );
  }
}
