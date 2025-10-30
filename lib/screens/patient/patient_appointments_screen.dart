import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<dynamic>? appointments;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final data = await ApiService.getMyAppointments();
    setState(() {
      appointments = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
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
                        subtitle: Text('Time: ${appointment['startsAt']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
