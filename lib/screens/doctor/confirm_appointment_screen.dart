import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

/// شاشة إدارة / تأكيد / رفض مواعيد الطبيب
class DoctorConfirmAppointmentsScreen extends StatefulWidget {
  const DoctorConfirmAppointmentsScreen({super.key});

  @override
  State<DoctorConfirmAppointmentsScreen> createState() =>
      _DoctorConfirmAppointmentsScreenState();
}

class _DoctorConfirmAppointmentsScreenState
    extends State<DoctorConfirmAppointmentsScreen> {
  bool _loading = true;
  List<dynamic> _appointments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getDoctorAppointments();
      setState(() {
        _appointments = (data ?? []);
      });
    } catch (e) {
      setState(() {
        _appointments = [];
        _error = 'حدث خطأ أثناء تحميل المواعيد';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _changeStatus(dynamic id, String newStatus) async {
    final ok = await ApiService.updateAppointmentStatus(id, newStatus);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'تم تأكيد الموعد بنجاح ✅'
                : 'تم رفض الموعد ❌',
          ),
        ),
      );
      await _loadAppointments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحديث حالة الموعد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('إدارة مواعيد الطبيب'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'الذهاب إلى لوحة الطبيب',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () {
              // ✅ يرجّعك إلى DoctorHomeShell على تبويب "المواعيد"
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.doctorHomeShell,
                (route) => false,
                arguments: 1, // tab index للمواعيد
              );
            },
          ),
          IconButton(
            tooltip: 'تحديث المواعيد',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)),
              )
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : _appointments.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد مواعيد حالياً 📭',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF1976D2),
                        onRefresh: _loadAppointments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final a = _appointments[index];

                            final patientName =
                                a['patient']?['fullName'] ??
                                a['patientName'] ??
                                'Patient';

                            final doctorName =
                                a['doctor']?['fullName'] ??
                                a['doctorName'] ??
                                'Doctor';

                            final startsAtStr = a['startsAt']?.toString() ?? '';
                            DateTime? startsAt;
                            try {
                              startsAt = DateTime.tryParse(startsAtStr);
                            } catch (_) {}
                            final dateText = startsAt == null
                                ? startsAtStr
                                : startsAt.toLocal().toString().substring(0, 16);

                            final status =
                                (a['status'] ?? 'Pending').toString();

                            return Card(
                              elevation: 3,
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0x221976D2),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                      title: Text(
                                        patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'الطبيب: $doctorName\nالوقت: $dateText',
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: status.toLowerCase() ==
                                                  'confirmed'
                                              ? null
                                              : () => _changeStatus(
                                                  a['id'], 'confirmed'),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: const Text('تأكيد'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: status.toLowerCase() ==
                                                  'rejected'
                                              ? null
                                              : () => _changeStatus(
                                                  a['id'], 'rejected'),
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'رفض',
                                            style: TextStyle(
                                                color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
