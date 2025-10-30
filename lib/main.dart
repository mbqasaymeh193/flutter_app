import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_colors.dart';

void main() {
  runApp(const HospitalApp());
}

class HospitalApp extends StatelessWidget {
  const HospitalApp({super.key});

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
      initialRoute: '/login_screen', // يمكنك تغييره مثل: AppRoutes.patientDashboard
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
