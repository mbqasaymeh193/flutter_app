import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<dynamic>? appointments;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final data = await ApiService.getDoctorAppointments();
    setState(() {
      appointments = data;
      isLoading = false;
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    final success = await ApiService.updateAppointmentStatus(id, status);
    if (success) {
      _fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments == null || appointments!.isEmpty
              ? const Center(child: Text('No Appointments'))
              : ListView.builder(
                  itemCount: appointments!.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments![index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Patient: ${appointment['patientName']}'),
                        subtitle: Text('Time: ${appointment['startsAt']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _updateStatus(appointment['id'], 'Accepted'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _updateStatus(appointment['id'], 'Rejected'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
