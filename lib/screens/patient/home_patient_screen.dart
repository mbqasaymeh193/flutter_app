import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

// شاشات المريض
import 'my_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/patient_medical_records_screen.dart';

// حجز الموعد
import '../main/appointment/book_appointment_screen.dart';

// Widgets
import '../../widgets/custom_button.dart';
import '../../widgets/appointment_card.dart';

// ألوان ثابتة للتصميم
const Color kPrimaryColor = Color(0xFF1976D2);
const Color kBackgroundColor = Color(0xFFF4F7FB);

class HomePatientScreen extends StatefulWidget {
  const HomePatientScreen({super.key});

  @override
  State<HomePatientScreen> createState() => _HomePatientScreenState();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = kBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("الصفحة الرئيسية للمريض"),
        backgroundColor: kPrimaryColor,
        elevation: 2,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: fetchDoctors,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== هيدر بسيط بترحيب =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x221976D2),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "أهلاً بك 👋",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "احجز مواعيدك وتابع ملفك الطبي بسهولة.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== أزرار سريعة =====
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: "مواعيدي",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyAppointmentsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kPrimaryColor,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PatientMedicalRecordsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.folder_shared),
                            label: const Text("ملفي الطبي"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "الأطباء المتاحون",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctors.isEmpty
                          ? "حالياً لا توجد قائمة أطباء متاحة."
                          : "اختر الطبيب المناسب لحجز موعد.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),

                    // ===== قائمة الأطباء =====
                    if (doctors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              size: 32,
                              color: kPrimaryColor,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "لا يوجد أطباء متاحون حالياً.",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          final name =
                              (doctor['fullName'] ?? 'Doctor').toString();
                          final specialty =
                              (doctor['specialty'] ?? 'General').toString();

                          return AppointmentCard(
                            doctorName: name,
                            date: specialty, // نستخدمها كسطر إضافي
                            time: "",
                            status: "Available",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookAppointmentScreen(doctor: doctor),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
