import 'dart:async';

import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/services/notification_store.dart';

class NotificationPoller {
  NotificationPoller._();

  static final NotificationPoller instance = NotificationPoller._();

  Timer? _timer;
  bool _running = false;
  bool _loading = false;

  Duration interval = const Duration(seconds: 5);

  void start() {
    if (_running) return;
    _running = true;
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Future<void> refresh() async {
    await _tick();
  }

  Future<void> _tick() async {
    if (_loading) return;
    _loading = true;

    try {
      await ApiService.loadToken();
      if ((ApiService.token ?? '').isEmpty) {
        _loading = false;
        return;
      }

      final unread = await ApiService.getUnreadCount();
      NotificationStore.instance.setUnread(unread);

      final items = await ApiService.getMyNotifications();
      NotificationStore.instance.setItems(items);
    } catch (_) {
      // تجاهل الأخطاء لتجنب إيقاف التحديث
    } finally {
      _loading = false;
    }
  }
}
