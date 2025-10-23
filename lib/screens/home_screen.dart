import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Doctor>> _futureDoctors;

  @override
  void initState() {
    super.initState();
    _futureDoctors = _loadDoctors();
  }

  Future<List<Doctor>> _loadDoctors() async {
    try {
      final list = await ApiService.getDoctors();
      if (list == null) return [];
      return list.map<Doctor>((json) => Doctor.fromJson(json)).toList();
    } catch (e) {
      debugPrint("🔴 Error loading doctors: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors List'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Doctor>>(
        future: _futureDoctors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }

          final doctors = snapshot.data ?? [];

          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final d = doctors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(d.fullName),
                  subtitle: Text(d.specialty),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Booking with ${d.fullName}...')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
