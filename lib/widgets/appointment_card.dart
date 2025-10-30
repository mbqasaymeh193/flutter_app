import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  final String doctorName;
  final String date;
  final String time;
  final String status;
  final VoidCallback onTap;

  const AppointmentCard({
    super.key,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
    required this.onTap,
  });

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$date at $time"),
        trailing: Text(
          status,
          style: TextStyle(color: getStatusColor(), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
