import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<dynamic>? appointments;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await ApiService.getMyAppointments();
      print("📋 PatientAppointmentsScreen: loaded ${data.length} appointments");
      setState(() {
        appointments = data;
        isLoading = false;
      });
    } catch (e) {
      print("⚠️ _fetchAppointments error: $e");
      setState(() {
        appointments = [];
        isLoading = false;
      });
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
    final list = appointments ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواعيدي'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? const Center(child: Text('لا توجد مواعيد حالياً'))
              : RefreshIndicator(
                  onRefresh: _fetchAppointments,
                  color: Theme.of(context).primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final appointment = list[index];

                      // ✅ نحاول نقرأ اسم الدكتور من الكائن Doctor أو من doctorName القديمة
                      final doctorName = appointment['doctor']?['fullName'] ??
                          appointment['doctorName'] ??
                          'Doctor';

                      // ✅ وقت البداية
                      final startsAtStr =
                          appointment['startsAt']?.toString() ?? '';
                      DateTime? startsAt;
                      try {
                        startsAt = DateTime.tryParse(startsAtStr);
                      } catch (_) {}
                      final dateText = startsAt == null
                          ? startsAtStr
                          : DateFormat('y/MM/dd • HH:mm').format(startsAt);

                      // ✅ الحالة
                      final status =
                          (appointment['status'] ?? 'Pending').toString();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor:
                                _statusColor(status).withOpacity(0.15),
                            child: Icon(
                              Icons.calendar_month,
                              color: _statusColor(status),
                            ),
                          ),
                          title: Text(
                            'الدكتور: $doctorName',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'الوقت: $dateText\nالحالة: ${_statusLabel(status)}',
                            maxLines: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
