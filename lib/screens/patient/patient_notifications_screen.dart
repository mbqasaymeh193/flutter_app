import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/widgets/notification_bell.dart';


class PatientNotificationsScreen extends StatelessWidget {
  const PatientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('...'),
  actions: const [NotificationBell()],
),

      body: const Center(child: Text('No notifications yet')),
    );
  }
}
