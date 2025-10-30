import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  List<dynamic>? appointments;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final data = await ApiService.getAdminAppointments();
    setState(() {
      appointments = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Appointments')),
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
                        title: Text('Doctor: ${appointment['doctorName']}'),
                        subtitle: Text('Patient: ${appointment['patientName']}'),
                        trailing: Text('Status: ${appointment['status']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
