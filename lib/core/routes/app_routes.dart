import 'package:flutter/material.dart';

// Doctor Screens
import 'package:healthcare_flutter_app/screens/doctor/doctor_dashboard_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_patients_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_profile_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_notifications_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_settings_screen.dart';

// Patient Screens
import 'package:healthcare_flutter_app/screens/patient/patient_dashboard_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_profile_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_home_shell.dart'; // اختياري

// Auth Screens
import 'package:healthcare_flutter_app/screens/auth/login_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/register_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/forgot_password_screen.dart';

class AppRoutes {
  // ======= نفس أسماء المسارات التي أرسلتها =======
  // Doctor
  static const String doctorDashboard = '/doctorDashboard';
  static const String doctorAppointments = '/doctorAppointments';
  static const String doctorPatients = '/doctorPatients';
  static const String doctorProfile = '/doctorProfile';
  static const String doctorNotifications = '/doctorNotifications';
  static const String doctorSettings = '/doctorSettings';

  // Patient
  static const String patientDashboard = '/patientDashboard';
  static const String patientAppointments = '/patientAppointments';
  static const String patientProfile = '/patientProfile';

  // Auth
  static const String login = '/login_screen';
  static const String register = '/register_screen';
  static const String forgotPassword = '/forgot_password';

  // (اختياري) حاوية المريض الجديدة بالـ BottomNav
  static const String patientHomeShell = '/patientHomeShell';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // -------- Doctor Routes --------
      case doctorDashboard:
        return MaterialPageRoute(builder: (_) => const DoctorDashboardScreen());
      case doctorAppointments:
        return MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen());
      case doctorPatients:
        return MaterialPageRoute(builder: (_) => const DoctorPatientsScreen());
      case doctorProfile:
        return MaterialPageRoute(builder: (_) => const DoctorProfileScreen());
      case doctorNotifications:
        return MaterialPageRoute(builder: (_) => const DoctorNotificationsScreen());
      case doctorSettings:
        return MaterialPageRoute(builder: (_) => const DoctorSettingsScreen());

      // -------- Patient Routes --------
      case patientDashboard:
        return MaterialPageRoute(builder: (_) => const PatientDashboardScreen());
      case patientAppointments:
        return MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen());
      case patientProfile:
        return MaterialPageRoute(builder: (_) => const PatientProfileScreen());

      // (اختياري) تبويب المريض الحديث مع Bottom Navigation
      case patientHomeShell:
        return MaterialPageRoute(builder: (_) => const PatientHomeShell());

      // -------- Auth Routes --------
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());



      // -------- Default (404) --------
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('الصفحة غير موجودة'),
              backgroundColor: const Color(0xFF1976D2),
            ),
            body: Center(
              child: Text(
                'الصفحة "${settings.name}" غير موجودة ❌',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
    }
  }
}
