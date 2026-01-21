import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// ✅ جديد: شاشة عرض سجلات مريض للطبيب
import 'patient_medical_records_for_doctor_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getDoctorAppointments();
      setState(() {
        appointments = (data ?? []);
        isLoading = false;
      });

      debugPrint("👨‍⚕️ DoctorAppointmentsScreen loaded: ${appointments.length} items");
    } catch (e) {
      debugPrint("DoctorAppointmentsScreen _fetchAppointments error: $e");
      setState(() {
        appointments = [];
        isLoading = false;
        errorMessage = 'حدث خطأ أثناء تحميل المواعيد';
      });
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(dynamic id, String status) async {
    final success = await ApiService.updateAppointmentStatus(id, status);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.toLowerCase() == 'confirmed'
                ? 'تم تأكيد الموعد ✅'
                : status.toLowerCase() == 'rejected'
                    ? 'تم رفض الموعد ❌'
                    : 'تم تحديث حالة الموعد',
          ),
        ),
      );
      await _fetchAppointments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحديث حالة الموعد')),
      );
    }
  }

  // ✅ جديد: افتح سجلات المريض من نفس بيانات الموعد
  Future<void> _openMedicalRecords(dynamic appointment) async {
    final patient = appointment['patient'];
    final patientId = patient?['id'];
    final patientName =
        patient?['fullName'] ?? appointment['patientName'] ?? 'Patient';

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح السجلات: PatientId غير موجود')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientMedicalRecordsForDoctorScreen(
          patientId: patientId as int,
          patientName: patientName.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواعيدي كطبيب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : appointments.isEmpty
                  ? const Center(child: Text('لا توجد مواعيد حالياً'))
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];

                          final patientName =
                              appointment['patient']?['fullName'] ??
                                  appointment['patientName'] ??
                                  'Patient';

                          final startsAtStr =
                              appointment['startsAt']?.toString() ?? '';
                          DateTime? startsAt;
                          try {
                            startsAt = DateTime.tryParse(startsAtStr);
                          } catch (_) {}
                          final timeText = startsAt == null
                              ? startsAtStr
                              : DateFormat('y/MM/dd • HH:mm')
                                  .format(startsAt.toLocal());

                          final status =
                              (appointment['status'] ?? 'Pending').toString();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 6.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0x221976D2),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              title: Text('المريض: $patientName'),
                              subtitle: Text('الوقت: $timeText'),
                              isThreeLine: true,

                              // ✅ زر “السجل الطبي” + أزرار الحالة
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر السجل الطبي
                                  IconButton(
                                    tooltip: 'السجل الطبي',
                                    icon: const Icon(Icons.description_outlined,
                                        color: Color(0xFF1976D2)),
                                    onPressed: () => _openMedicalRecords(appointment),
                                  ),

                                  // حالة الموعد
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _updateStatus(
                                        appointment['id'], 'confirmed'),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _updateStatus(
                                        appointment['id'], 'rejected'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
