import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'appointment_detail_screen.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _loading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMyAppointments();
      if (res != null) {
        // res could be List<dynamic> or Map -> try both
        if (res is List) {
          _appointments = res;
        } else if (res is Map && res['data'] is List) {
          _appointments = res['data'];
        } else {
          _appointments = [];
        }
      } else {
        _appointments = [];
      }
    } catch (e) {
      _appointments = [];
      // optionally show error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildItem(dynamic item) {
    final id = item['id'] ?? item['appointmentId'] ?? '';
    final doctorName = item['doctor']?['fullName'] ?? item['doctorName'] ?? '—';
    final startsAt = item['startsAt'] ?? item['starts_at'] ?? item['date'] ?? '';
    final status = (item['status'] ?? 'Pending').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('When: $startsAt'),
            const SizedBox(height: 4),
            Text('Status: $status', style: TextStyle(color: status == 'Confirmed' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange))),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: item)),
            ).then((_) => _fetchAppointments());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAppointments,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.calendar_today_outlined, size: 80, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Center(child: Text('No appointments yet', style: TextStyle(fontSize: 16))),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const BookAppointmentScreen())).then((_) => _fetchAppointments());
                          },
                          child: const Text('Book your first appointment'),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _appointments.length,
                    itemBuilder: (_, i) => _buildItem(_appointments[i]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BookAppointmentScreen())).then((_) => _fetchAppointments());
        },
      ),
    );
  }
}
