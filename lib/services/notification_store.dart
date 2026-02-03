import 'package:flutter/foundation.dart';

class NotificationStore {
  NotificationStore._();

  static final NotificationStore instance = NotificationStore._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<dynamic>> items = ValueNotifier<List<dynamic>>(<dynamic>[]);

  void setUnread(int value) {
    unreadCount.value = value;
  }

  void setItems(List<dynamic> list) {
    items.value = list;
  }
}
