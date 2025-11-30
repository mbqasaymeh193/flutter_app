import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  List<dynamic> appointments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final data = await ApiService.getDoctorAppointments(); // أو دالة admin
    setState(() {
      appointments = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📅 إدارة المواعيد")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, i) {
                final a = appointments[i];
                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("المريض: ${a["patientName"] ?? "غير معروف"}"),
                  subtitle: Text("الطبيب: ${a["doctorName"] ?? "غير محدد"}"),
                  trailing: Text(a["startsAt"] ?? ""),
                );
              },
            ),
    );
  }
}
