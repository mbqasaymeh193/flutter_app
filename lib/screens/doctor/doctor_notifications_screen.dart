import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getMyNotifications();
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _items = [];
        _loading = false;
        _error = 'حدث خطأ أثناء تحميل الإشعارات';
      });
    }
  }

  Future<void> _markRead(int id) async {
    final ok = await ApiService.markNotificationRead(id);
    if (!mounted) return;
    if (ok) await _load();
  }

  Future<void> _markAllRead() async {
    final ok = await ApiService.markAllNotificationsRead();
    if (!mounted) return;
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(icon: const Icon(Icons.done_all), onPressed: _markAllRead),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _items.isEmpty
                  ? const Center(child: Text('لا توجد إشعارات'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final n = _items[i];
                        final id = int.tryParse(n['id']?.toString() ?? '') ?? 0;
                        final msg = (n['message'] ?? '').toString();
                        final type = (n['type'] ?? '').toString();
                        final isRead = (n['isRead'] ?? false) == true;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(isRead ? Icons.notifications : Icons.notifications_active),
                            ),
                            title: Text(type.isEmpty ? 'Notification' : type),
                            subtitle: Text(msg),
                            trailing: isRead
                                ? const Icon(Icons.check, color: Colors.green)
                                : TextButton(
                                    onPressed: id == 0 ? null : () => _markRead(id),
                                    child: const Text('قراءة'),
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
