import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
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
      final list = await ApiService.getMyAppointments();
      list.sort((a, b) {
        final sa = DateTime.tryParse(a['startsAt'] ?? '');
        final sb = DateTime.tryParse(b['startsAt'] ?? '');
        if (sa == null || sb == null) return 0;
        return sa.compareTo(sb);
      });
      setState(() => _appointments = list);
    } catch (e) {
      debugPrint("⚠️ MyAppointmentsScreen error: $e");
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

  String _formatDate(String? value) {
    if (value == null) return 'غير محدد';
    final d = DateTime.tryParse(value);
    if (d == null) return value;
    return DateFormat('y/MM/dd • HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);
    final bg = const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("مواعيدي"),
        backgroundColor: primary,
        elevation: 2,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: primary),
            )
          : _appointments.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadAppointments,
                  color: primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      const Icon(Icons.event_busy,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          "لا يوجد مواعيد حالياً",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          "يمكنك حجز موعد جديد من الصفحة الرئيسية.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primary,
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final a = _appointments[index];
                      final doctor = a['doctor'];
                      final doctorName =
                          (doctor?['fullName'] ?? 'الطبيب').toString();
                      final specialty =
                          (doctor?['specialty'] ?? 'غير محدد').toString();
                      final status =
                          (a['status'] ?? 'Pending').toString().trim();
                      final startsAt =
                          _formatDate(a['startsAt']?.toString() ?? '');
                      final endsAt =
                          _formatDate(a['endsAt']?.toString() ?? '');

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x221976D2),
                                    ),
                                    child: const Icon(
                                      Icons.medical_services_outlined,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctorName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          specialty,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "من: $startsAt",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.timelapse,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "إلى: $endsAt",
                                      style: const TextStyle(fontSize: 13),
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
    );
  }
}
