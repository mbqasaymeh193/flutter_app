import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'doctor_home_dashboard_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_patients_records_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_notifications_screen.dart';

class DoctorRootScreen extends StatefulWidget {
  const DoctorRootScreen({super.key});

  @override
  State<DoctorRootScreen> createState() => _DoctorRootScreenState();
}

class _DoctorRootScreenState extends State<DoctorRootScreen> {
  int _index = 0;

  // badge للإشعارات
  int _unread = 0;

  final _pages = const [
    DoctorHomeDashboardScreen(),
    DoctorAppointmentsScreen(),
    DoctorPatientsRecordsScreen(),
    DoctorProfileScreen(),
  ];

  final _titles = const [
    'الرئيسية',
    'مواعيدي',
    'المرضى والسجلات',
    'حسابي',
  ];

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final c = await ApiService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unread = c);
    } catch (_) {
      // لا شيء
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorNotificationsScreen()),
    );
    // بعد الرجوع: حدّث badge
    await _loadUnread();
  }

  Widget _notifIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: _openNotifications,
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _unread > 99 ? '99+' : '$_unread',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          _notifIcon(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // ريفرش بسيط: يعيد قراءة badge ويعمل rebuild للصفحة الحالية
              await _loadUnread();
              setState(() {});
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'مواعيدي'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_outlined), label: 'السجلات'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}
