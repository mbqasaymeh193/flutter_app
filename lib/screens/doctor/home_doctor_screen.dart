import 'package:flutter/material.dart';
import 'package:medical_booking_app/services/api_service.dart';

class HomeDoctorScreen extends StatefulWidget {
  const HomeDoctorScreen({super.key});

  @override
  State<HomeDoctorScreen> createState() => _HomeDoctorScreenState();
}

class _HomeDoctorScreenState extends State<HomeDoctorScreen> {
  String? doctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final data = await ApiService.getProfile();
    setState(() {
      doctorName = data?['name'] ?? 'Doctor';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Dr. ${doctorName ?? 'Loading...'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildCard(
                  icon: Icons.schedule,
                  title: 'My Schedule',
                  onTap: () => Navigator.pushNamed(context, '/doctor-schedule'),
                ),
                _buildCard(
                  icon: Icons.people,
                  title: 'My Patients',
                  onTap: () => Navigator.pushNamed(context, '/doctor-patients'),
                ),
                _buildCard(
                  icon: Icons.message,
                  title: 'Messages',
                  onTap: () => Navigator.pushNamed(context, '/doctor-messages'),
                ),
                _buildCard(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
