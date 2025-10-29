import 'package:flutter/material.dart';
import 'package:medical_booking_app/services/api_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  List<dynamic> schedule = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final data = await ApiService.getDoctorSchedule();
    setState(() {
      schedule = data ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : schedule.isEmpty
              ? const Center(child: Text('No scheduled appointments'))
              : ListView.builder(
                  itemCount: schedule.length,
                  itemBuilder: (context, index) {
                    final item = schedule[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.blueAccent),
                        title: Text(item['patientName']),
                        subtitle: Text(
                          'Date: ${item['date']}\nStatus: ${item['status']}',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
