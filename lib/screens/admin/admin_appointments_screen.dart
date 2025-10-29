import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _loading = true;
  int? _processingId;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getAllAppointments();
      if (res == null) {
        _appointments = [];
      } else if (res is List) {
        _appointments = res;
      } else if (res is Map && res['data'] is List) {
        _appointments = res['data'];
      } else {
        _appointments = [];
      }
    } catch (e) {
      _appointments = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(dynamic apptId, String status) async {
    setState(() => _processingId = apptId as int?);
    try {
      final ok = await ApiService.updateAppointmentStatus(apptId, status);
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
        await _fetchAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Widget _buildRow(dynamic appt) {
    final id = appt['id'] ?? appt['appointmentId'];
    final patientName = appt['patient']?['fullName'] ?? appt['patientName'] ?? '—';
    final doctorName = appt['doctor']?['fullName'] ?? appt['doctorName'] ?? '—';
    final date = appt['startsAt'] ?? appt['date'] ?? appt['starts_at'] ?? '';
    final status = (appt['status'] ?? 'Pending').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('$patientName  →  $doctorName', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 6),
          Text('When: $date'),
          const SizedBox(height: 4),
          Text('Status: $status', style: TextStyle(color: status == 'Confirmed' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange))),
        ]),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'Confirm') {
              _changeStatus(id, 'Confirmed');
            } else if (value == 'Reject') {
              _changeStatus(id, 'Rejected');
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'Confirm', child: Text('Confirm')),
            const PopupMenuItem(value: 'Reject', child: Text('Reject')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Appointments'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAppointments,
              child: _appointments.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No appointments found')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _appointments.length,
                      itemBuilder: (_, i) {
                        final appt = _appointments[i];
                        return _buildRow(appt);
                      },
                    ),
            ),
    );
  }
}
