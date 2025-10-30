import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class DoctorHomeShell extends StatefulWidget {
  const DoctorHomeShell({super.key});

  @override
  State<DoctorHomeShell> createState() => _DoctorHomeShellState();
}

class _DoctorHomeShellState extends State<DoctorHomeShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  bool _loadingAppointments = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
    _loadAppointments();
  }

  // 🩺 تحميل مواعيد الطبيب
  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final data = await ApiService.getDoctorAppointments();
      setState(() => _appointments = data ?? []);
    } catch (_) {
      setState(() => _appointments = []);
    } finally {
      setState(() => _loadingAppointments = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'مواعيدي' : 'الملف الشخصي',
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
        actions: _currentIndex == 0
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
          _AppointmentsTab(
            loading: _loadingAppointments,
            appointments: _appointments,
            onRefresh: _loadAppointments,
          ),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTab,
        indicatorColor: const Color(0x331976D2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'مواعيدي',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
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
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'confirmed', child: Text('تأكيد')),
                  const PopupMenuItem(value: 'rejected', child: Text('رفض')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🔹 تبويب الملف الشخصي للطبيب
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const ListTile(
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
