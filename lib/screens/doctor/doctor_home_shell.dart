import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';
import 'doctor_patient_details_screen.dart';

class DoctorHomeShell extends StatefulWidget {
  final int initialTab; // ✅ تبويب البداية (0..4)

  const DoctorHomeShell({super.key, this.initialTab = 0});

  @override
  State<DoctorHomeShell> createState() => _DoctorHomeShellState();
}

class _DoctorHomeShellState extends State<DoctorHomeShell>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late final PageController _pageController;

  bool _loadingAppointments = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 4);
    _pageController = PageController(keepPage: true, initialPage: _currentIndex);
    _loadAppointments();
  }

  // 🩺 تحميل مواعيد الطبيب
  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final data = await ApiService.getDoctorAppointments();
      setState(() => _appointments = (data ?? []));
    } catch (_) {
      setState(() => _appointments = []);
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
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

  String _titleForIndex(int i) {
    switch (i) {
      case 0:
        return 'لوحة الطبيب';
      case 1:
        return 'مواعيدي';
      case 2:
        return 'مرضاي';
      case 3:
        return 'الملف الشخصي';
      case 4:
      default:
        return 'الإعدادات';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(_titleForIndex(_currentIndex)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
        actions: _currentIndex == 1
            ? [
                IconButton(
                  tooltip: 'تحديث المواعيد',
                  onPressed: _loadAppointments,
                  icon: const Icon(Icons.refresh),
                )
              ]
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const _DashboardTab(),
          _AppointmentsTab(
            loading: _loadingAppointments,
            appointments: _appointments,
            onRefresh: _loadAppointments,
          ),
          const _PatientsTab(),
          const _ProfileTab(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTab,
        indicatorColor: const Color(0x331976D2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'المواعيد',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'المرضى',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'الملف الشخصي',
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

/// 🔹 تبويب لوحة التحكم
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          child: ListTile(
            leading: Icon(Icons.medical_services, color: Color(0xFF1976D2)),
            title: Text('مرحباً بك دكتور 👋'),
            subtitle: Text('لوحة التحكم الخاصة بك'),
          ),
        ),
      ],
    );
  }
}

/// 🔹 تبويب المواعيد للطبيب
class _AppointmentsTab extends StatelessWidget {
  final bool loading;
  final List<dynamic> appointments;
  final Future<void> Function() onRefresh;

  const _AppointmentsTab({
    required this.loading,
    required this.appointments,
    required this.onRefresh,
  });

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
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1976D2)));
    }
    if (appointments.isEmpty) {
      return const Center(child: Text('لا توجد مواعيد حالياً'));
    }
    return RefreshIndicator(
      color: const Color(0xFF1976D2),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (_, i) {
          final a = appointments[i];
          final patientName =
              a['patient']?['fullName'] ?? a['patientName'] ?? 'Patient';
          final startsAtStr = a['startsAt'] ?? '';
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: const Color(0x221976D2),
                child: const Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              title: Text(patientName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(dateText),
              trailing: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: _statusColor(status),
                ),
                onSelected: (value) async {
                  final ok = await ApiService.updateAppointmentStatus(
                      a['id'], value);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(value == 'confirmed'
                          ? 'تم تأكيد الموعد ✅'
                          : 'تم رفض الموعد ❌'),
                    ));
                    onRefresh();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('فشل في تحديث حالة الموعد')),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'confirmed', child: Text('تأكيد')),
                  PopupMenuItem(value: 'rejected', child: Text('رفض')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🔹 تبويب المرضى
class _PatientsTab extends StatefulWidget {
  const _PatientsTab();

  @override
  State<_PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<_PatientsTab> {
  bool _loading = true;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDoctorAppointments();
      final uniquePatients = <String, Map<String, dynamic>>{};

      if (data != null && data.isNotEmpty) {
        for (final a in data) {
          final p = a['patient'];
          if (p != null) {
            final id = p['id'].toString();
            uniquePatients.putIfAbsent(id, () {
              return {
                'id': p['id'],
                'name': p['fullName'] ?? 'Patient',
                'lastAppointment': a['startsAt'] ?? '',
                'status': a['status'] ?? 'Pending',
              };
            });
          }
        }
      }

      setState(() => _patients = uniquePatients.values.toList());
    } catch (e) {
      debugPrint("loadPatients error: $e");
      setState(() => _patients = []);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      );
    }

    if (_patients.isEmpty) {
      return const Center(
        child: Text(
          'لم يتم العثور على مرضى بعد 👩‍⚕️',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: const Color(0xFF1976D2),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (_, i) {
          final p = _patients[i];
          final dateStr = p['lastAppointment'] ?? '';
          DateTime? date;
          try {
            date = DateTime.tryParse(dateStr);
          } catch (_) {}
          final formatted = date == null
              ? dateStr
              : DateFormat('y/MM/dd • HH:mm').format(date);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              onTap: () {
                Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      DoctorPatientDetailsScreen(patient: {
                    'id': p['id'] ?? '',
                    'name': p['name'] ?? 'Patient',
                  }),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    final tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ));
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: const Color(0x221976D2),
                child: const Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              title: Text(p['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('آخر موعد: $formatted'),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(p['status']).withOpacity(.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p['status'],
                  style: TextStyle(
                    color: _statusColor(p['status']),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🔹 الملف الشخصي
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('بيانات الطبيب'),
            subtitle: Text('معلومات الحساب'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('تغيير كلمة المرور'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.changePassword),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج',
                    style: TextStyle(color: Colors.red)),
                trailing:
                    const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                onTap: () async {
                  await ApiService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 🔹 الإعدادات
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'إعدادات النظام للطبيب ⚙️',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
