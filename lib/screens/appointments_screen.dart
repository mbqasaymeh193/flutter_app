import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  final bool isDoctor;
  const AppointmentsScreen({super.key, this.isDoctor = false});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<dynamic>?> _futureAppointments;

  @override
  void initState() {
    super.initState();
    _futureAppointments = widget.isDoctor
        ? ApiService.getDoctorAppointments()
        : ApiService.getMyAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isDoctor ? "Doctor Appointments" : "My Appointments"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>?>(
        future: _futureAppointments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No appointments found."));
          }

          final appointments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final a = appointments[index];
              final name = widget.isDoctor
                  ? a['patient']['fullName']
                  : a['doctor']['fullName'];

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                      "Date: ${a['date']} - Time: ${a['time']} - Status: ${a['status']}"),
                  trailing: widget.isDoctor
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                final ok = await ApiService.updateAppointmentStatus(
                                    a['id'], 'Accepted');
                                if (ok) setState(() => _futureAppointments = ApiService.getDoctorAppointments());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                final ok = await ApiService.updateAppointmentStatus(
                                    a['id'], 'Rejected');
                                if (ok) setState(() => _futureAppointments = ApiService.getDoctorAppointments());
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
