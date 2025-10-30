import 'package:flutter/material.dart';
import 'package:hospital_app/data/api/api_service.dart';
import 'package:hospital_app/presentation/widgets/custom_app_bar.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  List<dynamic>? doctors;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    final data = await ApiService.getDoctors();
    setState(() {
      doctors = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "إدارة الأطباء"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : doctors == null || doctors!.isEmpty
              ? const Center(child: Text("لا يوجد أطباء مسجلين"))
              : ListView.builder(
                  itemCount: doctors!.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors![index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(doctor['fullName']),
                        subtitle: Text(doctor['specialty']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // 🗑️ حذف الطبيب لاحقًا
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
