import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class DoctorPatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const DoctorPatientDetailsScreen({super.key, required this.patient});

  @override
  State<DoctorPatientDetailsScreen> createState() =>
      _DoctorPatientDetailsScreenState();
}

class _DoctorPatientDetailsScreenState
    extends State<DoctorPatientDetailsScreen> {
  bool _loading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    try {
      final allAppointments = await ApiService.getDoctorAppointments() ?? [];
      final filtered = allAppointments
          .where((a) =>
              a['patient']?['id']?.toString() ==
              widget.patient['id'].toString())
          .toList();
      setState(() => _appointments = filtered);
      debugPrint(
          "🩺 DoctorPatientDetails: loaded ${filtered.length} appointments for patient ${widget.patient['id']}");
    } catch (e) {
      debugPrint("⚠️ loadAppointments error: $e");
      setState(() => _appointments = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'مؤكد';
    if (lower == 'rejected') return 'مرفوض';
    return 'قيد الانتظار';
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.patient['name'] ?? 'Patient';

    return Scaffold(
      appBar: AppBar(
        title: Text('المريض: $patientName'),
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // ✅ رجوع طبيعي لنفس شاشة المرضى (PatientsTab) مع الحركة العكسية
            Navigator.pop(context);
          },
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)),
            )
          : _appointments.isEmpty
              ? const Center(
                  child: Text('لا توجد مواعيد لهذا المريض حالياً'),
                )
              : RefreshIndicator(
                  color: const Color(0xFF1976D2),
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (_, i) {
                      final a = _appointments[i];
                      final startsAtStr = a['startsAt']?.toString() ?? '';
                      DateTime? startsAt;
                      try {
                        startsAt = DateTime.tryParse(startsAtStr);
                      } catch (_) {}
                      final dateText = startsAt == null
                          ? startsAtStr
                          : DateFormat('y/MM/dd • HH:mm').format(startsAt);
                      final status = (a['status'] ?? 'Pending').toString();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x221976D2),
                            child: Icon(Icons.calendar_today,
                                color: Color(0xFF1976D2)),
                          ),
                          title: Text(dateText),
                          subtitle: Text('الحالة: ${_statusLabel(status)}'),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: _statusColor(status)),
                            onSelected: (value) async {
                              bool ok = false;

                              if (value == 'cancel') {
                                // 🗑️ تأكيد الإلغاء
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('تأكيد الإلغاء'),
                                    content: const Text(
                                        'هل أنت متأكد من حذف هذا الموعد نهائيًا؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1976D2),
                                        ),
                                        child: const Text('تأكيد'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;

                                ok = await ApiService.cancelAppointment(a['id']);
                                if (ok) {
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green, size: 28),
                                          SizedBox(width: 8),
                                          Text('تم الإلغاء بنجاح'),
                                        ],
                                      ),
                                      content: const Text(
                                        'تم حذف الموعد نهائيًا من النظام ✅',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            // ✅ رجوع إلى تبويب مرضاي في Shell الطبيب
                                            Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              AppRoutes.doctorPatients,
                                              (route) => false,
                                            );
                                          },
                                          child: const Text(
                                            'رجوع إلى المرضى',
                                            style: TextStyle(
                                                color: Color(0xFF1976D2)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  _loadAppointments();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('فشل في إلغاء الموعد ❌')),
                                  );
                                }
                              } else {
                                // ✅ قبول أو رفض
                                ok = await ApiService.updateAppointmentStatus(
                                    a['id'], value);
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(value == 'confirmed'
                                          ? 'تم تأكيد الموعد ✅'
                                          : 'تم رفض الموعد ❌'),
                                    ),
                                  );
                                  _loadAppointments();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'فشل في تحديث حالة الموعد ❌')),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'confirmed',
                                  child: Text('تأكيد الموعد')),
                              PopupMenuItem(
                                  value: 'rejected',
                                  child: Text('رفض الموعد')),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text(
                                  'إلغاء الموعد نهائيًا 🗑️',
                                  style: TextStyle(color: Colors.red),
                                ),
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
