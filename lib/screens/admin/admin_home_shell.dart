import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class AdminHomeShell extends StatefulWidget {
  /// ✅ مهم: لدعم AppRoutes (initialTab)
  final int initialTab;

  const AdminHomeShell({super.key, this.initialTab = 0});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  late int _currentIndex;
  late final PageController _pageController;

  bool _loading = true;
  Map<String, dynamic> _stats = {};

  // ✅ بيانات الأدمن
  List<Map<String, dynamic>> _pendingDoctors = [];
  List<Map<String, dynamic>> _approvedDoctors = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();

    _currentIndex = _clampAdminTab(widget.initialTab);
    _pageController = PageController(
      keepPage: true,
      initialPage: _currentIndex,
    );

    _loadAll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static int _clampAdminTab(int tab) {
    if (tab < 0) return 0;
    if (tab > 4) return 4;
    return tab;
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final stats = await ApiService.getAdminStats();

      // ✅ doctors pending
      final pending = await ApiService.getPendingDoctors();

      // ✅ all users (filter doctors/patients)
      final users = await ApiService.getAllUsers();

      final doctorsUsers = users
          .where((u) =>
              (u is Map) &&
              ((u['role'] ?? '').toString().toLowerCase() == 'doctor'))
          .toList();

      final patientsUsers = users
          .where((u) =>
              (u is Map) &&
              ((u['role'] ?? '').toString().toLowerCase() == 'patient'))
          .toList();

      // ✅ approved doctors:
      // ApiService ما فيها getAllDoctors => نستخدم getDoctors (public)
      final approvedDoctorsRaw = await ApiService.getDoctors();

      // ✅ admin appointments
      final apps = await ApiService.getAdminAppointments();

      if (!mounted) return;

      setState(() {
        _stats = {
          ...stats,
          'pendingDoctors': pending.length,
          'users': users.length,
          'doctorsUsers': doctorsUsers.length,
        };

        _pendingDoctors = pending;

        // ✅ تحويل صحيح من dynamic -> Map<String,dynamic>
        _approvedDoctors = approvedDoctorsRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _patients = patientsUsers
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _appointments = apps
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      debugPrint('Admin _loadAll error: $e');

      if (!mounted) return;
      setState(() {
        _stats = {
          'doctors': 0,
          'patients': 0,
          'appointments': 0,
          'confirmed': 0,
          'pending': 0,
          'rejected': 0,
          'pendingDoctors': 0,
          'users': 0,
          'doctorsUsers': 0,
        };
        _pendingDoctors = [];
        _approvedDoctors = [];
        _patients = [];
        _appointments = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTab(int i) {
    final idx = _clampAdminTab(i);
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
        return 'لوحة الأدمن';
      case 1:
        return 'الموافقات (الأطباء)';
      case 2:
        return 'المستخدمون (المرضى)';
      case 3:
        return 'المواعيد';
      case 4:
      default:
        return 'الإعدادات';
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

  Future<void> _confirmDoctorAction({
    required Map<String, dynamic> doctor,
    required bool approve,
  }) async {
    final name = (doctor['fullName'] ?? doctor['name'] ?? 'Doctor').toString();
    final id = int.tryParse((doctor['id'] ?? '').toString());

    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'تأكيد الموافقة' : 'تأكيد الرفض'),
        content: Text(
          approve
              ? 'هل تريد الموافقة على الطبيب:\n$name ؟'
              : 'هل تريد رفض/تعطيل الطبيب:\n$name ؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = approve
        ? await ApiService.approveDoctor(id)
        : await ApiService.rejectDoctor(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (approve ? 'تمت الموافقة على الطبيب ✅' : 'تم رفض/تعطيل الطبيب ❌')
              : 'فشلت العملية',
        ),
      ),
    );

    if (success) await _loadAll();
  }

  Future<void> _toggleUserActive(Map<String, dynamic> user) async {
    final id = int.tryParse((user['id'] ?? '').toString());
    if (id == null) return;

    final isActive = (user['isActive'] ?? true) == true;
    final name = (user['fullName'] ?? 'User').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
        content: Text(
          isActive
              ? 'هل تريد تعطيل حساب:\n$name ؟'
              : 'هل تريد تفعيل حساب:\n$name ؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await ApiService.setUserActive(id, !isActive);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'تم تحديث حالة الحساب ✅' : 'فشلت العملية')),
    );

    if (success) await _loadAll();
  }

  Future<void> _deleteUserSoft(Map<String, dynamic> user) async {
    final id = int.tryParse((user['id'] ?? '').toString());
    if (id == null) return;

    final name = (user['fullName'] ?? 'User').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف/إلغاء تفعيل الحساب'),
        content: Text(
          'ملاحظة: الحذف الحقيقي يسبب مشاكل علاقات في قاعدة البيانات.\n'
          'سنقوم بـ تعطيل الحساب (Soft Delete) بدل الحذف.\n\n'
          'هل تريد تعطيل حساب:\n$name ؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await ApiService.softDeleteUser(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'تم تعطيل الحساب ✅' : 'فشلت العملية')),
    );

    if (success) await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleForIndex(_currentIndex);

    List<Widget>? actions;
    if (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3) {
      actions = [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'تحديث',
          onPressed: _loadAll,
        ),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 3,
        actions: actions,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AdminDashboardTab(stats: _stats, onGo: _onTab),
                _AdminDoctorsApprovalsTab(
                  pendingDoctors: _pendingDoctors,
                  approvedDoctors: _approvedDoctors,
                  onApprove: (d) => _confirmDoctorAction(doctor: d, approve: true),
                  onReject: (d) => _confirmDoctorAction(doctor: d, approve: false),
                ),
                _AdminUsersTab(
                  users: _patients,
                  onToggleActive: _toggleUserActive,
                  onSoftDelete: _deleteUserSoft,
                ),
                _AdminAppointmentsTab(
                  appointments: _appointments,
                  statusColor: _statusColor,
                  onChangeStatus: (id, status) async {
                    final ok = await ApiService.updateAppointmentStatus(id, status);
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'تم تحديث حالة الموعد ✅' : 'تعذّر تحديث حالة الموعد')),
                    );

                    if (ok) await _loadAll();
                  },
                ),
                _AdminSettingsTab(
                  onLogout: () async {
                    await ApiService.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                  },
                ),
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
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'الموافقات',
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
class _AdminDashboardTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final void Function(int) onGo;

  const _AdminDashboardTab({required this.stats, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('y/MM/dd • HH:mm').format(DateTime.now());

    int _int(dynamic v) => int.tryParse((v ?? 0).toString()) ?? 0;

    final doctors = _int(stats['doctors']);
    final patients = _int(stats['patients']);
    final appointments = _int(stats['appointments']);
    final pending = _int(stats['pending']);
    final pendingDoctors = _int(stats['pendingDoctors']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 3,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1565C0),
              child: Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            title: const Text('مرحباً بك 👋', style: TextStyle(fontWeight: FontWeight.bold)),
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
              value: doctors.toString(),
              icon: Icons.medical_services,
              color: Colors.indigo,
              onTap: () => onGo(1),
            ),
            _StatCard(
              title: 'المرضى',
              value: patients.toString(),
              icon: Icons.people_alt,
              color: Colors.teal,
              onTap: () => onGo(2),
            ),
            _StatCard(
              title: 'المواعيد',
              value: appointments.toString(),
              icon: Icons.calendar_month,
              color: Colors.orange,
              onTap: () => onGo(3),
            ),
            _StatCard(
              title: 'أطباء بانتظار الموافقة',
              value: pendingDoctors.toString(),
              icon: Icons.verified_user,
              color: Colors.redAccent,
              onTap: () => onGo(1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص المواعيد 📅',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0)),
                ),
                const SizedBox(height: 12),
                _summaryRow('قيد الانتظار', pending, Colors.orange),
                _summaryRow('مؤكدة', _int(stats['confirmed']), Colors.green),
                _summaryRow('مرفوضة', _int(stats['rejected']), Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, int value, Color color) {
    final v = (value == 0 ? 0.1 : 1.0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: v,
              color: color,
              backgroundColor: color.withOpacity(0.15),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Text('$label ($value)', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
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
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: color.withOpacity(0.85))),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======================= Doctors Approvals Tab =======================
class _AdminDoctorsApprovalsTab extends StatelessWidget {
  final List<Map<String, dynamic>> pendingDoctors;
  final List<Map<String, dynamic>> approvedDoctors;
  final void Function(Map<String, dynamic>) onApprove;
  final void Function(Map<String, dynamic>) onReject;

  const _AdminDoctorsApprovalsTab({
    required this.pendingDoctors,
    required this.approvedDoctors,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('أطباء بانتظار الموافقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (pendingDoctors.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('لا يوجد أطباء معلّقين حالياً'),
            ),
          )
        else
          ...pendingDoctors.map((d) {
            final name = (d['fullName'] ?? d['name'] ?? 'Doctor').toString();
            final spec = (d['specialty'] ?? '—').toString();
            final email = (d['email'] ?? '').toString();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('$spec${email.isEmpty ? '' : '\n$email'}'),
                isThreeLine: email.isNotEmpty,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'موافقة',
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => onApprove(d),
                    ),
                    IconButton(
                      tooltip: 'رفض',
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => onReject(d),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 6),
        const Divider(),
        const SizedBox(height: 6),
        const Text('أطباء معتمدون (عرض عام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (approvedDoctors.isEmpty)
          const Center(child: Text('لا يوجد أطباء حالياً'))
        else
          ...approvedDoctors.map((d) {
            final name = (d['fullName'] ?? d['name'] ?? 'Doctor').toString();
            final spec = (d['specialty'] ?? '—').toString();

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(spec),
              ),
            );
          }),
      ],
    );
  }
}

/// ======================= Users (Patients) Tab =======================
class _AdminUsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Future<void> Function(Map<String, dynamic>) onToggleActive;
  final Future<void> Function(Map<String, dynamic>) onSoftDelete;

  const _AdminUsersTab({
    required this.users,
    required this.onToggleActive,
    required this.onSoftDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('لا يوجد مرضى حالياً'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final name = (u['fullName'] ?? 'Patient').toString();
        final email = (u['email'] ?? '—').toString();
        final active = (u['isActive'] ?? true) == true;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: active ? const Color(0x221565C0) : Colors.grey.withOpacity(0.2),
              child: Icon(Icons.person, color: active ? const Color(0xFF1565C0) : Colors.grey),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('بريد: $email'),
            trailing: PopupMenuButton<String>(
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle', child: Text(active ? 'تعطيل الحساب' : 'تفعيل الحساب')),
                const PopupMenuItem(value: 'delete', child: Text('حذف/تعطيل نهائي (Soft Delete)')),
              ],
              onSelected: (v) async {
                if (v == 'toggle') {
                  await onToggleActive(u);
                } else if (v == 'delete') {
                  await onSoftDelete(u);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

/// ======================= Appointments Tab =======================
class _AdminAppointmentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final Color Function(String) statusColor;
  final Future<void> Function(int id, String status) onChangeStatus;

  const _AdminAppointmentsTab({
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
            ? ((a['doctor'] as Map)['fullName']?.toString() ?? 'Doctor')
            : (a['doctorName']?.toString() ?? 'Doctor');

        final patientName = a['patient'] is Map
            ? ((a['patient'] as Map)['fullName']?.toString() ?? 'Patient')
            : (a['patientName']?.toString() ?? 'Patient');

        final startsAtStr = (a['startsAt'] ?? '').toString();
        final dt = DateTime.tryParse(startsAtStr);
        final dateText = dt == null ? startsAtStr : DateFormat('y/MM/dd • HH:mm').format(dt.toLocal());

        final status = (a['status'] ?? 'Pending').toString();

        final id = (a['id'] is int) ? a['id'] as int : int.tryParse(a['id'].toString()) ?? -1;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const CircleAvatar(
              backgroundColor: Color(0x221565C0),
              child: Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
            ),
            title: Text('$doctorName ⇄ $patientName', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(dateText),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: statusColor(status)),
              onSelected: (value) async {
                if (id == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('معرّف الموعد غير صالح')),
                  );
                  return;
                }
                await onChangeStatus(id, value);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Pending', child: Text('تعليق (Pending)')),
                PopupMenuItem(value: 'Confirmed', child: Text('تأكيد (Confirmed)')),
                PopupMenuItem(value: 'Rejected', child: Text('رفض (Rejected)')),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ======================= Settings Tab =======================
class _AdminSettingsTab extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _AdminSettingsTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('تغيير كلمة المرور'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: onLogout,
          ),
        ),
      ],
    );
  }
}
