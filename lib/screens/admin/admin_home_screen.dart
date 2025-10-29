import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int totalUsers = 0;
  int totalAppointments = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final appts = await ApiService.getAllAppointments();
      final users = await ApiService.getAllUsers();

      // try to extract counts safely
      final apptsList = (appts is List) ? appts : (appts is Map && appts['data'] is List ? appts['data'] : <dynamic>[]);
      final usersList = (users is List) ? users : (users is Map && users['data'] is List ? users['data'] : <dynamic>[]);

      setState(() {
        totalAppointments = apptsList.length;
        totalUsers = usersList.length;
      });
    } catch (e) {
      // ignore - keep zeros
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statCard('Total Appointments', totalAppointments, Icons.calendar_today, Colors.blueAccent),
                  _statCard('Total Users', totalUsers, Icons.people, Colors.indigo),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin-appointments'),
                    icon: const Icon(Icons.list),
                    label: const Text('Manage Appointments'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin-users'),
                    icon: const Icon(Icons.supervised_user_circle),
                    label: const Text('Manage Users'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  ),
                ],
              ),
            ),
    );
  }
}
