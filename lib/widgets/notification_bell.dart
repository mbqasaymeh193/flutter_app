import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCount();

    // تحديث خفيف كل 15 ثانية
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _loadCount());
  }

  Future<void> _loadCount() async {
    try {
      final c = await ApiService.getUnreadCount(); // ✅ موجودة عندك
      if (!mounted) return;
      setState(() => _count = c);
    } catch (_) {
      // لا نكسر الـ UI لو فشل الطلب
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);

    return IconButton(
      tooltip: 'الإشعارات',
      onPressed: () async {
        await Navigator.pushNamed(context, AppRoutes.notifications);
        await _loadCount(); // تحديث بعد الرجوع
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_rounded, color: primary),
          if (_count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  _count > 99 ? '99+' : '$_count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
