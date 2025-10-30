import 'package:flutter/material.dart';
import 'admin_appointments_screen.dart';
import '../../widgets/custom_button.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Welcome, Admin",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "View All Appointments",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAppointmentsScreen()),
                );
              }, color: null,
            ),
          ],
        ),
      ),
    );
  }
}
