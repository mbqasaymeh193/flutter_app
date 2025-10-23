import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text("Name: Patient One", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Email: patient1@demo.com", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            Text("Appointments:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("• Dr. Rashed Emad - Cardiology - 10 Nov, 2:00 PM"),
          ],
        ),
      ),
    );
  }
}
