import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';
import 'package:healthcare_flutter_app/services/notification_store.dart';
import 'package:healthcare_flutter_app/services/notification_poller.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);

    return ValueListenableBuilder<int>(
      valueListenable: NotificationStore.instance.unreadCount,
      builder: (context, count, _) {
        return IconButton(
          tooltip: 'الإشعارات',
          onPressed: () async {
            await Navigator.pushNamed(context, AppRoutes.notifications);
            await NotificationPoller.instance.refresh();
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded, color: primary),
              if (count > 0)
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
                      count > 99 ? '99+' : '$count',
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
      },
    );
  }
}
