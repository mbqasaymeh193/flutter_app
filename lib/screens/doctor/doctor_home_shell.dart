import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

// ✅ شاشة السجلات للطبيب (تعرض سجلات المريض + زر إنشاء أول سجل + تعديل)
import 'package:healthcare_flutter_app/screens/doctor/patient_medical_records_for_doctor_screen.dart';

// ✅ شاشة إضافة/تعديل سجل طبي
import 'package:healthcare_flutter_app/screens/doctor/doctor_add_medical_record_screen.dart';

class DoctorHomeShell extends StatefulWidget {
  final int initialTab;

  const DoctorHomeShell({super.key, this.initialTab = 0});

  @override
  State<DoctorHomeShell> createState() => _DoctorHomeShellState();
}

class _DoctorHomeShellState extends State<DoctorHomeShell> {
  late int _currentIndex;
  late final PageController _pageController;

  bool _loadingAppointments = true;
  List<dynamic> _appointments = [];

  // ✅ مفتاح لتحديث تبويب السجلات من AppBar
  final GlobalKey<_RecordsTabState> _recordsTabKey = GlobalKey<_RecordsTabState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = _clampTab(widget.initialTab);
       _pageController = PageController(keepPage: true, initialPage: _currentIndex);
    _loadAppointments();
  }

  static int _clampTab(int tab) {
    if (tab < 0) return 0;
    if (tab > 3) return 3;
    return tab;
  }

  // 🩺 تحميل مواعيد الطبيب
  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final data = await ApiService.getDoctorAppointments();
      if (!mounted) return;
      setState(() => _appointments = (data));
    } catch (e) {
      debugPrint("DoctorHomeShell _loadAppointments error: $e");
      if (!mounted) return;
      setState(() => _appointments = []);
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  void _onTab(int i) {
    final idx = _clampTab(i);
    setState(() => _currentIndex = idx);
    _pageController.animateToPage(
      idx,
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
        return 'السجلات الطبية';
      case 3:
      default:
        return 'حسابي';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ أزرار AppBar حسب التبويب
    List<Widget>? appBarActions;
    if (_currentIndex == 1) {
      appBarActions = [
        IconButton(
          tooltip: 'تحديث المواعيد',
          onPressed: _loadAppointments,
          icon: const Icon(Icons.refresh),
        ),
      ];
    } else if (_currentIndex == 2) {
      appBarActions = [
        IconButton(
          tooltip: 'تحديث قائمة المرضى',
          onPressed: () => _recordsTabKey.currentState?._loadPatients(),
          icon: const Icon(Icons.refresh),
        ),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(_titleForIndex(_currentIndex)),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
        actions: appBarActions,
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
          _RecordsTab(key: _recordsTabKey),
          const _ProfileTab(),
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
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared),
            label: 'السجلات',
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
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
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

/// 🔹 تبويب المواعيد للطبيب (مصمم ليكون آمن لو الداتا رجعت بصيغة مختلفة)
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

  String _statusLabel(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'مؤكد';
    if (lower == 'rejected') return 'مرفوض';
    return 'قيد الانتظار';
  }

  Map<String, dynamic>? _asMap(dynamic x) => x is Map<String, dynamic> ? x : null;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      );
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
          final a = _asMap(appointments[i]);
          if (a == null) {
            return const SizedBox.shrink(); // تجاهل عنصر غير صحيح
          }

          // patient ممكن يكون Map أو اسم نصي
          final patientObj = a['patient'];
          String patientName = 'Patient';
          if (patientObj is Map) {
            patientName = (patientObj['fullName'] ?? patientObj['name'] ?? 'Patient').toString();
          } else {
            patientName = (a['patientName'] ?? 'Patient').toString();
          }

          final startsAtStr = (a['startsAt'] ?? '').toString();
          final startsAt = DateTime.tryParse(startsAtStr);
          final dateText = startsAt == null
              ? startsAtStr
              : DateFormat('y/MM/dd • HH:mm').format(startsAt.toLocal());

          final status = (a['status'] ?? 'Pending').toString();
          final rawId = a['id'];
          final intId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '') ?? -1;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Color(0x221976D2),
                child: Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              title: Text(
                patientName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '$dateText\nالحالة: ${_statusLabel(status)}',
                maxLines: 3,
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: _statusColor(status)),
                onSelected: (value) async {
                  if (intId <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('معرّف الموعد غير صالح')),
                    );
                    return;
                  }

                  final ok = await ApiService.updateAppointmentStatus(intId, value);
                  if (!context.mounted) return;

                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value.toLowerCase() == 'confirmed'
                              ? 'تم تأكيد الموعد ✅'
                              : value.toLowerCase() == 'rejected'
                                  ? 'تم رفض الموعد ❌'
                                  : 'تم تحديث الحالة ✅',
                        ),
                      ),
                    );
                    await onRefresh();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل في تحديث حالة الموعد')),
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

/// ✅ تبويب السجلات الطبية للطبيب
class _RecordsTab extends StatefulWidget {
  const _RecordsTab({super.key});

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _patients = [];
  String? _error;

  // ✅ Loading لكل مريض بشكل مستقل
  final Set<int> _openingPatientIds = {};

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  // ⚠ استدعيناها من الـ AppBar عبر GlobalKey
  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patients = await ApiService.getPatientsFromDoctorAppointments();

      patients.sort((a, b) => (a['fullName'] ?? '')
          .toString()
          .compareTo((b['fullName'] ?? '').toString()));

      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loading = false;
      });
    } catch (e) {
      debugPrint("_RecordsTab _loadPatients error: $e");
      if (!mounted) return;
      setState(() {
        _patients = [];
        _loading = false;
        _error = 'حدث خطأ أثناء تحميل المرضى';
      });
    }
  }

  Future<void> _openMedicalFlow({
    required int patientId,
    required String patientName,
  }) async {
    if (patientId <= 0) return;
    if (_openingPatientIds.contains(patientId)) return;

    setState(() => _openingPatientIds.add(patientId));

    try {
      final records = await ApiService.getMedicalRecordsForPatient(patientId);

      if (!mounted) return;

      if (records.isEmpty) {
        // ✅ لا يوجد سجل → افتح إنشاء سجل مباشرة
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorAddMedicalRecordScreen(
              patientId: patientId,
              patientName: patientName,
            ),
          ),
        );

        if (ok == true) {
          // optional: refresh
        }
      } else {
        // ✅ يوجد سجلات → افتح شاشة السجلات
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientMedicalRecordsForDoctorScreen(
              patientId: patientId,
              patientName: patientName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("_openMedicalFlow error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء فتح السجل الطبي')),
      );
    } finally {
      if (mounted) {
        setState(() => _openingPatientIds.remove(patientId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_patients.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد مرضى مرتبطين بمواعيدك بعد 👨‍⚕️',
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

          final id = int.tryParse(p['id']?.toString() ?? '') ?? -1;
          final name = (p['fullName'] ?? 'Patient').toString();
          final phone = (p['phoneNumber'] ?? '').toString();
          final isOpening = _openingPatientIds.contains(id);

          if (id <= 0) return const SizedBox.shrink();

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Color(0x221976D2),
                child: Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: phone.isEmpty ? null : Text('رقم الهاتف: $phone'),
              trailing: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isOpening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.folder_shared),
                label: Text(isOpening ? 'فتح...' : 'السجل'),
                onPressed: isOpening
                    ? null
                    : () => _openMedicalFlow(patientId: id, patientName: name),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🔹 حسابي (الملف الشخصي + تغيير كلمة المرور + خروج)
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('تغيير كلمة المرور'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                onTap: () async {
                  await ApiService.logout();
                  if (!context.mounted) return;

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
