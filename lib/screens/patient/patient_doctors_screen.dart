import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';

class PatientDoctorsScreen extends StatefulWidget {
  const PatientDoctorsScreen({super.key});

  @override
  State<PatientDoctorsScreen> createState() => _PatientDoctorsScreenState();
}

class _PatientDoctorsScreenState extends State<PatientDoctorsScreen> {
  List<dynamic>? doctors;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    final data = await ApiService.getDoctors();
    setState(() {
      doctors = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "الأطباء"),
      body: doctors == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: doctors!.length,
              itemBuilder: (context, index) {
                final d = doctors![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(d['fullName']),
                    subtitle: Text(d['specialty']),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        // مستقبلاً: فتح نافذة حجز موعد
                      },
                      child: const Text("احجز موعد"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
