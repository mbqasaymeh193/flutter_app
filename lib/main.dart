import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'services/notification_poller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HospitalApp());
}

class HospitalApp extends StatefulWidget {
  const HospitalApp({super.key});

  @override
  State<HospitalApp> createState() => _HospitalAppState();
}

class _HospitalAppState extends State<HospitalApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationPoller.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationPoller.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationPoller.instance.start();
    } else if (state == AppLifecycleState.paused) {
      NotificationPoller.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Booking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: AppRoutes.gate,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
