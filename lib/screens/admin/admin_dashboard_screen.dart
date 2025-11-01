import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loadingAppointments = true;
  bool _loadingUsers = true;
  List<dynamic> _appointments = [];
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _fetchAppointments();
    _fetchUsers();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _loadingAppointments = true);
    final data = await ApiService.getAdminAppointments();
    setState(() {
      _appointments = data;
      _loadingAppointments = false;
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _loadingUsers = true);
    final data = await ApiService.getAllUsers();
    setState(() {
      _users = data;
      _loadingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text(
          "لوحة تحكم الأدمن",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "تحديث البيانات",
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1976D2),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsHeader(),
              const SizedBox(height: 20),
              const Text(
                "📅 المواعيد الأخيرة",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 8),
              _loadingAppointments
                  ? const Center(child: CircularProgressIndicator())
                  : _appointments.isEmpty
                      ? const Text("لا توجد مواعيد حالياً")
                      : _buildAppointmentsList(),
              const SizedBox(height: 25),
              const Text(
                "👥 جميع المستخدمين",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 8),
              _loadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Text("لا يوجد مستخدمون مسجلون")
                      : _buildUsersList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 👑 رأس الإحصائيات السريعة
  Widget _buildStatsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard("المستخدمون", _users.length.toString(), Icons.people),
        _statCard("المواعيد", _appointments.length.toString(), Icons.event_note),
        _statCard("الأطباء", _users.where((u) => u['role'] == 'Doctor').length.toString(),
            Icons.local_hospital),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1976D2), size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  /// 🩺 عرض قائمة المواعيد
  Widget _buildAppointmentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _appointments.length,
      itemBuilder: (_, i) {
        final a = _appointments[i];
        final doctor = a['doctor']?['fullName'] ?? 'غير معروف';
        final patient = a['patient']?['fullName'] ?? 'غير معروف';
        final status = a['status'] ?? 'Pending';
        final date = a['startsAt'] != null
            ? DateFormat('yyyy/MM/dd • HH:mm').format(DateTime.parse(a['startsAt']))
            : 'غير محدد';

        Color statusColor;
        switch (status.toLowerCase()) {
          case 'confirmed':
          case 'accepted':
            statusColor = Colors.green;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
            title: Text("د. $doctor"),
            subtitle: Text("المريض: $patient\n$date"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 👤 عرض جميع المستخدمين
  Widget _buildUsersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final u = _users[i];
        final name = u['fullName'] ?? 'غير معروف';
        final email = u['email'] ?? '—';
        final role = u['role'] ?? '—';
        IconData icon = Icons.person_outline;
        Color color = Colors.blueGrey;

        if (role.toLowerCase() == 'doctor') {
          icon = Icons.local_hospital;
          color = Colors.blue;
        } else if (role.toLowerCase() == 'admin') {
          icon = Icons.shield;
          color = Colors.orange;
        }

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(email),
            trailing: Text(
              role,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
