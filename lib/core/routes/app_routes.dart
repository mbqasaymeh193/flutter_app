import 'package:flutter/material.dart';

// ===== Doctor Screens =====
import 'package:healthcare_flutter_app/screens/doctor/doctor_dashboard_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_patients_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_profile_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_notifications_screen.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_settings_screen.dart';

// ===== Patient Screens =====
import 'package:healthcare_flutter_app/screens/patient/patient_dashboard_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_profile_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_home_shell.dart';

// ===== Auth Screens =====
import 'package:healthcare_flutter_app/screens/auth/login_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/register_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/forgot_password_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/reset_password_screen.dart';
import 'package:healthcare_flutter_app/screens/change_password_screen.dart';
import 'package:healthcare_flutter_app/screens/admin/admin_home_shell.dart';

class AppRoutes {
  // -------- Auth --------
  static const String login = '/login_screen';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/changePassword'; // ✅ (الجديد)

  // -------- Patient --------
  static const String patientDashboard = '/patientDashboard';
  static const String patientAppointments = '/patientAppointments';
  static const String patientProfile = '/patientProfile';
  static const String patientHomeShell = '/patientHomeShell'; // (اختياري للحاوية الحديثة)

  // -------- Doctor --------
  static const String doctorDashboard = '/doctorDashboard';
  static const String doctorAppointments = '/doctorAppointments';
  static const String doctorPatients = '/doctorPatients';
  static const String doctorProfile = '/doctorProfile';
  static const String doctorNotifications = '/doctorNotifications';
  static const String doctorSettings = '/doctorSettings';
  static const String adminDashboard = '/adminDashboard'; // ✅ جديد
  // ====== Router ======
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ----- Auth -----
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case changePassword: // ✅ مضافة
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      // ----- Patient -----
      case patientHomeShell:
        return MaterialPageRoute(builder: (_) => const PatientHomeShell());
      case patientDashboard:
        return MaterialPageRoute(builder: (_) => const PatientDashboardScreen());
      case patientAppointments:
        return MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen());
      case patientProfile:
        return MaterialPageRoute(builder: (_) => const PatientProfileScreen());

      // ----- Doctor -----
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
      case adminDashboard:
       return MaterialPageRoute(builder: (_) => const AdminHomeShell());  

      // ----- 404 -----
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('الصفحة غير موجودة')),
            body: Center(
              child: Text('Route "${settings.name}" غير معرّف ❌',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        );
    }
  }
}
