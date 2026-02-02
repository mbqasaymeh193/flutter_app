import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/appointment_card.dart';
import '../main/appointment/book_appointment_screen.dart';
import 'my_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/patient_medical_records_screen.dart';


class HomePatientScreen extends StatefulWidget {
  const HomePatientScreen({super.key});

  @override
  State<HomePatientScreen> createState() => _HomePatientScreenState();
}
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية للمريض'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // مثال: زر مواعيدي
            ElevatedButton.icon(
              onPressed: () {
                // هنا تذهب لشاشة مواعيد المريض لو عندك واحدة
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('مواعيدي'),
            ),
            const SizedBox(height: 16),

            // 👇 هذا الزر الجديد: "ملفي الطبي"
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.folder_shared, color: primary),
                title: const Text('ملفي الطبي'),
                subtitle:
                    const Text('عرض جميع التقارير الطبية التي كتبها الأطباء'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PatientMedicalRecordsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePatientScreenState extends State<HomePatientScreen> {
  bool _loading = false;
  List<dynamic> doctors = [];

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDoctors();
      setState(() => doctors = data);
    } catch (e) {
      debugPrint("🔴 Error fetching doctors: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Home")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CustomButton(
                    text: "My Appointments",
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const MyAppointmentsScreen()
                      ));
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return AppointmentCard(
                          doctorName: doctor['fullName'] ?? "Doctor",
                          date: "",
                          time: "",
                          status: "Available",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BookAppointmentScreen(doctor: doctor)
                            ));
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
}
