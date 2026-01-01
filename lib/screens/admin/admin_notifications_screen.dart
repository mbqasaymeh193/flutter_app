import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getMyNotifications();
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('لا يوجد إشعارات حالياً'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      final msg = (n['message'] ?? '').toString();
                      final isRead = (n['isRead'] ?? false) == true;

                      return ListTile(
                        leading: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread),
                        title: Text(msg),
                        subtitle: Text((n['type'] ?? 'General').toString()),
                        onTap: () async {
                          final id = n['id'];
                          if (id != null && !isRead) {
                            await ApiService.markNotificationRead(id is int ? id : int.parse(id.toString()));
                            await _load();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
