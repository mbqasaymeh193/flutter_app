import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMyNotifications();
      setState(() => _items = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains("confirmed")) return Icons.verified_rounded;
    if (t.contains("rejected")) return Icons.cancel_rounded;
    if (t.contains("pending")) return Icons.hourglass_bottom_rounded;
    if (t.contains("reminder")) return Icons.alarm_rounded;
    if (t.contains("doctor")) return Icons.medical_services_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains("confirmed")) return Colors.green;
    if (t.contains("rejected")) return Colors.red;
    if (t.contains("pending")) return Colors.orange;
    if (t.contains("reminder")) return Colors.blue;
    return const Color(0xFF1976D2);
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    DateTime? d;
    if (v is String) d = DateTime.tryParse(v);
    if (v is DateTime) d = v;
    if (d == null) return v.toString();
    return DateFormat('y/MM/dd • HH:mm').format(d.toLocal());
  }

  Future<void> _markAll() async {
    final ok = await ApiService.markAllNotificationsRead();
    if (ok) await _load();
  }

  Future<void> _openItem(dynamic n) async {
    final id = n['id'];
    if (id != null) {
      final intId = id is int ? id : int.tryParse(id.toString());
      if (intId != null) {
        await ApiService.markNotificationRead(intId);
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);
    final bg = const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: primary,
        actions: [
          IconButton(
            tooltip: 'تحديد الكل كمقروء',
            onPressed: _items.isEmpty ? null : _markAll,
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 90),
                        Icon(Icons.notifications_none_rounded,
                            size: 70, color: Colors.grey),
                        SizedBox(height: 14),
                        Center(
                          child: Text(
                            'لا يوجد إشعارات حالياً',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text(
                            'ستظهر هنا إشعارات المواعيد والتنبيهات.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        final msg = (n['message'] ?? '').toString();
                        final type = (n['type'] ?? 'General').toString();
                        final isRead = (n['isRead'] ?? false) == true;
                        final createdAt = n['createdAt'] ?? n['createdAtUtc'];

                        final color = _colorForType(type);
                        final icon = _iconForType(type);

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openItem(n),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(icon, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                type,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: primary
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: const Text(
                                                  'جديد',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: primary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          msg.isEmpty ? '—' : msg,
                                          style: TextStyle(
                                            height: 1.4,
                                            color: Colors.grey.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _fmtDate(createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
