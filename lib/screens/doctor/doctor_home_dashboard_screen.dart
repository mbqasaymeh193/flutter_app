import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DoctorHomeDashboardScreen extends StatefulWidget {
  const DoctorHomeDashboardScreen({super.key});

  @override
  State<DoctorHomeDashboardScreen> createState() => _DoctorHomeDashboardScreenState();
}

class _DoctorHomeDashboardScreenState extends State<DoctorHomeDashboardScreen> {
  bool _loading = true;
  String? _error;

  int todayCount = 0;
  int pending = 0;
  int confirmed = 0;
  int rejected = 0;

  Map<String, dynamic>? nextAppointment; // أقرب موعد

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _tryParse(dynamic v) {
    final s = v?.toString() ?? '';
    return DateTime.tryParse(s);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apps = await ApiService.getDoctorAppointments();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int t = 0, p = 0, c = 0, r = 0;
      Map<String, dynamic>? next;
      DateTime? nextTime;

      for (final a in apps) {
        if (a is! Map) continue;
        final status = (a['status'] ?? '').toString().toLowerCase();
        if (status == 'pending') {
          p++;
        } else if (status == 'confirmed' || status == 'accepted') {
          c++;
        } else if (status == 'rejected') {
          r++;
        }

        final startsAt = _tryParse(a['startsAt']);
        if (startsAt != null) {
          final day = DateTime(startsAt.year, startsAt.month, startsAt.day);
          if (day == today) t++;

          if (startsAt.isAfter(now)) {
            if (nextTime == null || startsAt.isBefore(nextTime)) {
              nextTime = startsAt;
              next = Map<String, dynamic>.from(a);
            }
          }
        }
      }

      setState(() {
        todayCount = t;
        pending = p;
        confirmed = c;
        rejected = r;
        nextAppointment = next;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'حدث خطأ أثناء تحميل البيانات';
      });
    }
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    final n = nextAppointment;
    final patientName = n?['patient']?['fullName'] ?? n?['patientName'] ?? 'Patient';
    final starts = _tryParse(n?['startsAt']);
    final timeText = starts == null ? '-' : DateFormat('y/MM/dd • HH:mm').format(starts.toLocal());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              _statCard('مواعيد اليوم', todayCount, Icons.today),
              _statCard('Confirmed', confirmed, Icons.check_circle_outline),
            ],
          ),
          Row(
            children: [
              _statCard('Pending', pending, Icons.hourglass_top),
              _statCard('Rejected', rejected, Icons.cancel_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('أقرب موعد قادم', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('المريض: $patientName\nالوقت: $timeText'),
            ),
          ),
        ],
      ),
    );
  }
}
