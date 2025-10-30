import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';

class ConfirmAppointmentScreen extends StatefulWidget {
  final dynamic appointment;
  const ConfirmAppointmentScreen({super.key, required this.appointment});

  @override
  State<ConfirmAppointmentScreen> createState() => _ConfirmAppointmentScreenState();
}

class _ConfirmAppointmentScreenState extends State<ConfirmAppointmentScreen> {
  bool _loading = false;

  Future<void> updateStatus(String status) async {
    setState(() => _loading = true);
    final success = await ApiService.updateAppointmentStatus(widget.appointment['id'], status);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Appointment $status" : "Failed to update status")),
    );

    if (success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient: ${appt['patient']['fullName']}"),
            const SizedBox(height: 8),
            Text("Date: ${appt['startsAt']?.substring(0, 10) ?? ""}"),
            const SizedBox(height: 8),
            Text("Time: ${appt['startsAt']?.substring(11, 16) ?? ""}"),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "Accept",
                          onPressed: () => updateStatus("Accepted"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: "Reject",
                          onPressed: () => updateStatus("Rejected"),
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
