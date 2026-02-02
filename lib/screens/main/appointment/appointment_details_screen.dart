import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final dynamic appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _processing = false;

  Future<void> _cancelAppointment() async {
    final id = widget.appointment['id'] ?? widget.appointment['appointmentId'];
    if (id == null) return;

    setState(() => _processing = true);
    try {
      final ok = await ApiService.cancelAppointment(id);
      if (!mounted) return;
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final doctor = appt['doctor'] ?? {};
    final startsAt = appt['startsAt'] ?? appt['starts_at'] ?? appt['date'] ?? '';
    final status = appt['status'] ?? 'Pending';
    final notes = appt['notes'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details'), backgroundColor: const Color(0xFF1976D2)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${doctor['fullName'] ?? doctor['name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('When: $startsAt'),
            const SizedBox(height: 8),
            Text('Status: $status', style: TextStyle(color: status == 'Confirmed' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange))),
            const SizedBox(height: 12),
            if (notes.isNotEmpty) ...[
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(notes),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            _processing
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: status == 'Confirmed' ? null : _cancelAppointment,
                      child: const Text('Cancel Appointment'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
