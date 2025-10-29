import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';

// placeholder home routes (ستستبدلها لاحقًا بالشاشات التفصيلية حسب الدور)
import 'screens/patient/patient_home_screen.dart';
import 'screens/doctor/home_doctor_screen.dart';
import 'screens/admin/admin_home_screen.dart';

void main() {
  runApp(const MedicalBookingApp());
}

class MedicalBookingApp extends StatelessWidget {
  const MedicalBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1976D2),
        useMaterial3: true,
      ),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/patient-home': (_) => const PatientHomeScreen(),
        '/doctor-home': (_) => const DoctorHomeScreen(),
        '/admin-home': (_) => const AdminHomeScreen(),
      },
      initialRoute: '/splash',
    );
  }
}
