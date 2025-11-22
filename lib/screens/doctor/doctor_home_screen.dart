import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  bool _loading = false;
  String doctorName = "";

  @override
  void initState() {
    super.initState();
    fetchDoctorInfo();
  }

  Future<void> fetchDoctorInfo() async {
    setState(() => _loading = true);

    // لاحقاً يمكن ربطها مع API لجلب اسم الطبيب
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      doctorName = "Dr. John Doe"; // اسم مؤقت
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Doctor Home"),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Welcome, $doctorName",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // ⬇ زر يفتح DoctorHomeShell على تبويب المواعيد مباشرة
                  CustomButton(
                    text: "My Appointments",
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.doctorAppointments, // التبويب رقم 1 في الـShell
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomButton(
                    text: "Dashboard",
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.doctorDashboard, // التبويب رقم 0
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
