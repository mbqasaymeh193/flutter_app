import 'package:flutter/material.dart';
import 'package:flutter_app/core/routes/app_routes.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

void main() {
  runApp(const HospitalApp());
}

class HospitalApp extends StatelessWidget {
  const HospitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام المستشفى',
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
      initialRoute: AppRoutes.doctorDashboard, // يمكنك تغييره مثل: AppRoutes.patientDashboard
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
