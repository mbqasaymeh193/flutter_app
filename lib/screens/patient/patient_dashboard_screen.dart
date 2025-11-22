import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int totalAppointments = 0;
  Map<String, dynamic>? _lastAppointment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    try {
      final appointments = await ApiService.getMyAppointments();

      // ✅ نفس الفكرة الأصلية: نحسب عدد المواعيد
      totalAppointments = appointments.length;

      // 🔹 إضافة بسيطة: حفظ آخر موعد (اختياري للعرض)
      if (appointments.isNotEmpty) {
        _lastAppointment = appointments.last;
      } else {
        _lastAppointment = null;
      }
    } catch (e) {
      debugPrint("PatientDashboard _loadAppointments error: $e");
      totalAppointments = 0;
      _lastAppointment = null;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return 'غير محدد';
    try {
      final dt = DateTime.tryParse(raw.toString());
      if (dt == null) return raw.toString();
      return DateFormat('y/MM/dd • HH:mm').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المريض'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    color: Colors.blue[50],
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'إجمالي المواعيد',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        '$totalAppointments',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_lastAppointment != null) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          color: Colors.deepPurple,
                        ),
                        title: const Text(
                          'آخر موعد',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'الطبيب: ${_lastAppointment?['doctor']?['fullName'] ?? _lastAppointment?['doctorName'] ?? 'غير معروف'}',
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الوقت: ${_formatDateTime(_lastAppointment?['startsAt'])}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الحالة: ${_lastAppointment?['status'] ?? 'غير معروفة'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      // ✅ هنا نستخدم نص الراوت مباشرة
                      // تأكّد في الـ MaterialApp أن عندك:
                      // routes: { '/patientAppointments': (_) => PatientAppointmentsScreen(), ... }
                      Navigator.pushNamed(
                        context,
                        '/patientAppointments',
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('عرض جميع المواعيد'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
