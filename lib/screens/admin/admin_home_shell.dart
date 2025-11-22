import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  bool _loading = true;
  Map<String, dynamic> _stats = {};

  // نفس القوائم السابقة (كانت Mock) — الآن ستُملأ من ApiService
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
    _loadStatsAndLists();
  }

  Future<void> _loadStatsAndLists() async {
    setState(() => _loading = true);
    try {
      // إحضار الإحصائيات (مع fallback داخلي إن لم تتوفر /admin/stats)
      final stats = await ApiService.getAdminStats();

      // القوائم
      final doctorsRaw = await ApiService.getAllDoctors();
      final patientsRaw = await ApiService.getAllPatients(); // قد تكون غير جاهزة => []
      final appsRaw = await ApiService.getAllAppointments(); // قد تكون غير جاهزة => []

      // Casting آمن إلى Map<String,dynamic>
      List<Map<String, dynamic>> castList(dynamic src) {
        if (src is List) {
          return src
              .whereType<Map<String, dynamic>>()
              .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
              .toList();
        }
        return <Map<String, dynamic>>[];
      }

      setState(() {
        _stats = stats;
        _doctors = castList(doctorsRaw);
        _patients = castList(patientsRaw);
        _appointments = castList(appsRaw);
      });
    } catch (e) {
      // فشل الجلب: لا نكسر الواجهة
      setState(() {
        _stats = {
          'doctors': 0,
          'patients': 0,
          'appointments': 0,
          'confirmed': 0,
          'pending': 0,
          'rejected': 0,
        };
        _doctors = [];
        _patients = [];
        _appointments = [];
      });
      debugPrint('Admin load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTab(int i) {
    setState(() => _currentIndex = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
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

  @override
  Widget build(BuildContext context) {
    final title = [
      'لوحة التحكم',
      'الأطباء',
      'المرضى',
      'المواعيد',
      'الإعدادات',
    ][_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 3,
        actions: [
          if (_currentIndex == 0 || _currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: _loadStatsAndLists,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 0) Dashboard
                _DashboardTab(
                  stats: _stats,
                  onGoDoctors: () => _onTab(1),
                  onGoPatients: () => _onTab(2),
                  onGoAppointments: () => _onTab(3),
                ),

                // 1) Doctors
                _DoctorsTab(doctors: _doctors),

                // 2) Patients
                _PatientsTab(patients: _patients),

                // 3) Appointments
                _AppointmentsTabAdmin(
                  appointments: _appointments,
                  statusColor: _statusColor,
                  onChangeStatus: (id, status) async {
                    // تحديث الحالة عبر الـ API ثم إعادة التحميل
                    try {
                      final ok =
                          await ApiService.updateAppointmentStatus(id, status);
                      if (ok) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              status == 'confirmed'
                                  ? 'تم تأكيد الموعد ✅'
                                  : status == 'rejected'
                                      ? 'تم رفض الموعد ❌'
                                      : 'تم تحديث الحالة',
                            ),
                          ));
                        }
                        await _loadStatsAndLists(); // حدّث القوائم والإحصائيات
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تعذّر تحديث حالة الموعد')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ: $e')),
                        );
                      }
                    }
                  },
                ),

                // 4) Settings
                const _SettingsTab(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTab,
        indicatorColor: const Color(0x331565C0),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'الأطباء',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'المرضى',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'المواعيد',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

/// ======================= Dashboard Tab =======================
class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onGoDoctors;
  final VoidCallback onGoPatients;
  final VoidCallback onGoAppointments;

  const _DashboardTab({
    required this.stats,
    required this.onGoDoctors,
    required this.onGoPatients,
    required this.onGoAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('y/MM/dd • HH:mm').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFF1565C0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            color: Colors.blue.shade50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              title: const Text(
                'مرحباً بك 👋',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('آخر تحديث: $now'),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                title: 'الأطباء',
                value: (stats['doctors'] ?? 0).toString(),
                icon: Icons.medical_services,
                color: Colors.indigo,
                onTap: onGoDoctors,
              ),
              _StatCard(
                title: 'المرضى',
                value: (stats['patients'] ?? 0).toString(),
                icon: Icons.people_alt,
                color: Colors.teal,
                onTap: onGoPatients,
              ),
              _StatCard(
                title: 'المواعيد',
                value: (stats['appointments'] ?? 0).toString(),
                icon: Icons.calendar_month,
                color: Colors.orange,
                onTap: onGoAppointments,
              ),
              _StatCard(
                title: 'قيد التنفيذ',
                value: (stats['pending'] ?? 0).toString(),
                icon: Icons.timelapse,
                color: Colors.amber.shade700,
                onTap: onGoAppointments,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AppointmentsSummary(stats: stats),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.2),
      child: Card(
        elevation: 2,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'عرض التفاصيل',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentsSummary extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _AppointmentsSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = ((stats['appointments'] ?? 0) as num).toDouble();
    final safeTotal = total == 0 ? 1.0 : total;

    Widget item(String label, int value, Color color) {
      final progress = (value / safeTotal).clamp(0.0, 1.0);
      return Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: color.withOpacity(0.15),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$label ($value)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تفاصيل المواعيد 📅',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            item('مؤكدة', (stats['confirmed'] ?? 0) as int, Colors.green),
            const SizedBox(height: 8),
            item('مرفوضة', (stats['rejected'] ?? 0) as int, Colors.red),
            const SizedBox(height: 8),
            item('معلقة', (stats['pending'] ?? 0) as int, Colors.orange),
          ],
        ),
      ),
    );
  }
}

/// ======================= Doctors Tab =======================
class _DoctorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> doctors;
  const _DoctorsTab({required this.doctors});

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const Center(child: Text('لا يوجد أطباء حالياً'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (_, i) {
        final d = doctors[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.local_hospital, color: Color(0xFF1565C0)),
            ),
            title: Text(d['fullName']?.toString() ?? 'Doctor',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(d['specialty']?.toString() ?? '—'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // لاحقاً: تفاصيل طبيب أو تعديل بياناته
            },
          ),
        );
    },
    );
  }
}

/// ======================= Patients Tab =======================
class _PatientsTab extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  const _PatientsTab({required this.patients});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Center(child: Text('لا يوجد مرضى حالياً'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patients.length,
      itemBuilder: (_, i) {
        final p = patients[i];
        DateTime? created;
        try {
          created = DateTime.tryParse((p['createdAt'] ?? '').toString());
        } catch (_) {}
        final createdText = created == null
            ? (p['createdAt']?.toString() ?? '')
            : DateFormat('y/MM/dd').format(created);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person, color: Color(0xFF1565C0)),
            ),
            title: Text(p['fullName']?.toString() ?? 'Patient',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('بريد: ${p['email'] ?? '—'} • إنشاء: $createdText'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // لاحقاً: تفاصيل مريض
            },
          ),
        );
      },
    );
  }
}

/// ======================= Appointments Tab =======================
class _AppointmentsTabAdmin extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final Color Function(String) statusColor;
  final Future<void> Function(int id, String status) onChangeStatus;

  const _AppointmentsTabAdmin({
    required this.appointments,
    required this.statusColor,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(child: Text('لا توجد مواعيد حالياً'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (_, i) {
        final a = appointments[i];
        final doctorName = a['doctor'] is Map
            ? (a['doctor']['fullName']?.toString() ?? 'Doctor')
            : (a['doctorName']?.toString() ?? 'Doctor');
        final patientName = a['patient'] is Map
            ? (a['patient']['fullName']?.toString() ?? 'Patient')
            : (a['patientName']?.toString() ?? 'Patient');

        DateTime? starts;
        try {
          starts = DateTime.tryParse((a['startsAt'] ?? '').toString());
        } catch (_) {}
        final dateText = starts == null
            ? (a['startsAt']?.toString() ?? '')
            : DateFormat('y/MM/dd • HH:mm').format(starts);

        final status = (a['status'] ?? 'pending').toString();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const CircleAvatar(
              backgroundColor: Color(0x221565C0),
              child: Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
            ),
            title: Text('$doctorName ⇄ $patientName',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(dateText),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: statusColor(status)),
              onSelected: (value) async {
                final id = (a['id'] is int)
                    ? a['id'] as int
                    : int.tryParse(a['id'].toString()) ?? -1;
                if (id == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('معرّف الموعد غير صالح')),
                  );
                  return;
                }
                await onChangeStatus(id, value);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'confirmed', child: Text('تأكيد')),
                PopupMenuItem(value: 'rejected', child: Text('رفض')),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ======================= Settings Tab =======================
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('تفعيل الإشعارات'),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.security),
            title: const Text('سياسات وأمان النظام'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
