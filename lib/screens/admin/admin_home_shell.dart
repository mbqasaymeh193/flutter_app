import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:intl/intl.dart';

class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // 🧩 مؤقتًا: بيانات ثابتة لحين ربط API
  Future<void> _loadStats() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // محاكاة تحميل
    setState(() {
      _stats = {
        'doctors': 12,
        'patients': 58,
        'appointments': 120,
        'confirmed': 80,
        'pending': 25,
        'rejected': 15,
      };
    });
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الإحصائيات',
            onPressed: _loadStats,
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: const Color(0xFF1565C0),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildMainStats(),
                  const SizedBox(height: 16),
                  _buildAppointmentsStats(),
                ],
              ),
            ),
    );
  }

  /// 🩺 بطاقة الترحيب
  Widget _buildHeaderCard() {
    final now = DateFormat('y/MM/dd • HH:mm').format(DateTime.now());
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  /// 📊 الإحصائيات الأساسية (أطباء، مرضى، مواعيد)
  Widget _buildMainStats() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('الأطباء', _stats['doctors'].toString(),
            Icons.medical_services, Colors.indigo),
        _buildStatCard('المرضى', _stats['patients'].toString(),
            Icons.people_alt, Colors.teal),
        _buildStatCard('المواعيد', _stats['appointments'].toString(),
            Icons.calendar_month, Colors.orange),
        _buildStatCard('قيد التنفيذ', _stats['pending'].toString(),
            Icons.timelapse, Colors.amber),
      ],
    );
  }

  /// 📅 تفاصيل حالة المواعيد
  Widget _buildAppointmentsStats() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل المواعيد 📅',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 12),
            _buildProgressItem('مؤكدة', _stats['confirmed'], Colors.green),
            const SizedBox(height: 8),
            _buildProgressItem('مرفوضة', _stats['rejected'], Colors.red),
            const SizedBox(height: 8),
            _buildProgressItem('معلقة', _stats['pending'], Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int value, Color color) {
    final total = (_stats['appointments'] ?? 1).toDouble();
    final progress = (value / total).clamp(0.0, 1.0);
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
        Text('$label (${value.toString()})',
            style:
                TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
      ],
    );
  }

  /// 🧮 بطاقة صغيرة للإحصاءات الرئيسية
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
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
          ],
        ),
      ),
    );
  }
}
