import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/nav.dart';
import 'patient_appointments_screen.dart';
import 'patient_profile_screen.dart';
import 'patient_dashboard_screen.dart'; // سنستخدمها لزر الانتقال للحجز
import '../main/appointment/book_appointment_screen.dart';

class PatientHomeShell extends StatefulWidget {
  const PatientHomeShell({super.key});

  @override
  State<PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<PatientHomeShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  // بيانات التبويبات
  bool _loadingDoctors = true;
  List<dynamic> _doctors = [];

  bool _loadingAppointments = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
    _loadDoctors();
    _loadAppointments();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final data = await ApiService.getDoctors();
      setState(() => _doctors = data);
    } catch (_) {
      setState(() => _doctors = []);
    } finally {
      setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final data = await ApiService.getMyAppointments();
      setState(() => _appointments = data);
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
          _currentIndex == 0
              ? 'الصفحة الرئيسية'
              : _currentIndex == 1
                  ? 'مواعيدي'
                  : 'الملف الشخصي',
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
        actions: _currentIndex == 0
            ? [
                IconButton(
                  tooltip: 'تحديث الأطباء',
                  onPressed: _loadDoctors,
                  icon: const Icon(Icons.refresh),
                )
              ]
            : _currentIndex == 1
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
          // تبويب الرئيسية (أطباء + احجز الآن)
          _HomeTab(
            loading: _loadingDoctors,
            doctors: _doctors,
            onBook: (doctor) async {
              // انتقال جانبي لطيف
              final booked = await Navigator.of(context).push(slideRoute(
                BookAppointmentScreen(doctor: doctor),
              ));
              if (booked == true) _loadAppointments();
            },
          ),

          // تبويب المواعيد
          _AppointmentsTab(
            loading: _loadingAppointments,
            appointments: _appointments,
            onRefresh: _loadAppointments,
          ),

          // تبويب الملف الشخصي
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTab,
        indicatorColor: const Color(0x331976D2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'المواعيد',
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

/// تبويب الرئيسية: عرض الأطباء كبطاقات جميلة + زر احجز الآن
class _HomeTab extends StatelessWidget {
  final bool loading;
  final List<dynamic> doctors;
  final void Function(dynamic doctor) onBook;

  const _HomeTab({
    required this.loading,
    required this.doctors,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
    }
    if (doctors.isEmpty) {
      return const Center(child: Text('لا يوجد أطباء متاحون حالياً'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (_, i) {
        final d = doctors[i];
        final name = d['fullName'] ?? 'Doctor';
        final spec = d['specialty'] ?? '';
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: const Color(0x221976D2),
              child: const Icon(Icons.local_hospital, color: Color(0xFF1976D2)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(spec.isEmpty ? '—' : spec),
            trailing: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onBook(d),
              child: const Text('احجز الآن'),
            ),
          ),
        );
      },
    );
  }
}

/// تبويب المواعيد: عرض محسّن للكروت + ألوان حسب الحالة
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
    }
    if (appointments.isEmpty) {
      return const Center(child: Text('لا توجد مواعيد حتى الآن'));
    }
    return RefreshIndicator(
      color: const Color(0xFF1976D2),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (_, i) {
          final a = appointments[i];
          final doctorName = a['doctor']?['fullName'] ?? a['doctorName'] ?? 'Doctor';
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
            elevation: 2.5,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: const Color(0x221976D2),
                child: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
              ),
              title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(dateText),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
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

/// تبويب الملف الشخصي: زر تغيير كلمة المرور وتسجيل خروج
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('الملف الشخصي'),
            subtitle: Text('بيانات المستخدم الحالي'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('تغيير كلمة المرور'),
                onTap: () => Navigator.pushNamed(context, '/settings'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل خروج', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await ApiService.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
