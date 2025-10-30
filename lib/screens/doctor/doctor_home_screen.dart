import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'doctor_appointments_screen.dart';
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
    // يمكن إضافة استدعاء API للحصول على معلومات الطبيب إذا كانت متوفرة
    // الآن سنستخدم اسم افتراضي
    setState(() {
      doctorName = "Dr. John Doe";
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Home")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Welcome, $doctorName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: "My Appointments",
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen()));
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
