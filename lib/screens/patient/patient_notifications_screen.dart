import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class PatientNotificationsScreen extends StatelessWidget {
  const PatientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'الإشعارات'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.notifications, color: Color(0xFF1976D2)),
            title: Text('تم تأكيد موعدك مع د. أحمد علي'),
            subtitle: Text('منذ ساعتين'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications, color: Color(0xFF1976D2)),
            title: Text('تم تعديل موعدك القادم'),
            subtitle: Text('منذ يوم واحد'),
          ),
        ],
      ),
    );
  }
}
