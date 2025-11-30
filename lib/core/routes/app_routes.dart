import 'package:flutter/material.dart';

// Doctor
import 'package:healthcare_flutter_app/screens/doctor/doctor_home_shell.dart';

// باقي الشاشات/المسارات لديك...
import 'package:healthcare_flutter_app/screens/auth/login_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/register_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/forgot_password_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/reset_password_screen.dart';
import 'package:healthcare_flutter_app/screens/change_password_screen.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_home_shell.dart';
import 'package:healthcare_flutter_app/screens/admin/admin_home_shell.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_appointments_screen.dart'; // ✅ جديد
import '../../screens/auth/register_success_screen.dart';
import '../../screens/doctor/doctor_patients_screen.dart';

class AppRoutes {
  // Auth
  static const String login = '/login_screen';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/changePassword';
  static const String registerSuccess = '/registerSuccess';

  // Patient
  static const String patientHomeShell = '/patientHomeShell';
  static const String patientAppointments = '/patientAppointments'; // ✅ جديد
  static const String doctorPatientsScreen = '/doctorPatientsScreen';


  // Doctor (كلها تفتح نفس الـShell مع تبويب مختلف)
  static const String doctorHomeShell = '/doctorHomeShell';
  static const String doctorDashboard = '/doctorDashboard';
  static const String doctorAppointments = '/doctorAppointments';
  static const String doctorPatients = '/doctorPatients';
  static const String doctorProfile = '/doctorProfile';
  static const String doctorSettings = '/doctorSettings';

  // Admin
  static const String adminDashboard = '/adminDashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case registerSuccess:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RegisterSuccessScreen(
            name: args?['name'],
            role: args?['role'],
            autoLoggedIn: args?['autoLoggedIn'] ?? true,
          ),
        );

      // Patient
      case patientHomeShell:
        return MaterialPageRoute(builder: (_) => const PatientHomeShell());
      case patientAppointments: // ✅ جديد
        return MaterialPageRoute(
          builder: (_) => const PatientAppointmentsScreen(),
        );

      // Doctor routes → نفس الـShell مع تبويب مناسب
      case doctorHomeShell:
        final tab = (settings.arguments as int?) ?? 0;
        return MaterialPageRoute(
            builder: (_) => DoctorHomeShell(initialTab: tab));
      case doctorDashboard:
        return MaterialPageRoute(
            builder: (_) => const DoctorHomeShell(initialTab: 0));
      case doctorAppointments:
        return MaterialPageRoute(
            builder: (_) => const DoctorHomeShell(initialTab: 1));
      case doctorPatients:
        return MaterialPageRoute(
            builder: (_) => const DoctorHomeShell(initialTab: 2));
      case doctorProfile:
        return MaterialPageRoute(
            builder: (_) => const DoctorHomeShell(initialTab: 3));
      case doctorSettings:
        return MaterialPageRoute(
            builder: (_) => const DoctorHomeShell(initialTab: 4));

      // Admin
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminHomeShell());
      case doctorPatientsScreen:
        return MaterialPageRoute(builder: (_) => const DoctorPatientsScreen());
  

      // 404
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('الصفحة غير موجودة')),
            body: Center(
              child: Text(
                'Route "${settings.name}" غير معرّف ❌',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
    }
  }
}
