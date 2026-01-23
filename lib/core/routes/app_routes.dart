import 'package:flutter/material.dart';

// Doctor
import 'package:healthcare_flutter_app/screens/doctor/doctor_home_shell.dart';
import 'package:healthcare_flutter_app/screens/doctor/doctor_patients_screen.dart';

// Auth
import 'package:healthcare_flutter_app/screens/auth/login_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/signup_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/forgot_password_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/reset_password_screen.dart';
import 'package:healthcare_flutter_app/screens/change_password_screen.dart';
import 'package:healthcare_flutter_app/screens/auth/register_success_screen.dart';

// Gate
import 'package:healthcare_flutter_app/screens/auth/auth_gate_screen.dart';

// Patient/Admin shells
import 'package:healthcare_flutter_app/screens/patient/patient_home_shell.dart';
import 'package:healthcare_flutter_app/screens/patient/patient_appointments_screen.dart';
import 'package:healthcare_flutter_app/screens/admin/admin_home_shell.dart';

// Notifications screens
import 'package:healthcare_flutter_app/screens/notifications/notifications_screen.dart';
import 'package:healthcare_flutter_app/screens/admin/admin_notifications_screen.dart';

class AppRoutes {
  // ===================== Gate =====================
  static const String gate = '/gate';

  // ===================== Auth =====================
static const String login = '/login';
static const String signup = '/signup';

// alias قديم (اختياري)
static const String register = '/register';


  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/changePassword';
  static const String registerSuccess = '/registerSuccess';

  // ================= Notifications =================
  static const String notifications = '/notifications';
  static const String adminNotifications = '/adminNotifications';

  // ===================== Patient ====================
  static const String patientHomeShell = '/patientHomeShell';
  static const String patientAppointments = '/patientAppointments';

  // ===================== Doctor =====================
  // 0: Dashboard, 1: Appointments, 2: Records, 3: Profile
  static const String doctorHomeShell = '/doctorHomeShell';
  static const String doctorDashboard = '/doctorDashboard';
  static const String doctorAppointments = '/doctorAppointments';
  static const String doctorRecords = '/doctorRecords';
  static const String doctorProfile = '/doctorProfile';

  static const String doctorPatientsScreen = '/doctorPatientsScreen';

  // ===================== Admin ======================
  // 0: Dashboard, 1: Doctors approvals, 2: Patients, 3: Appointments, 4: Settings
  static const String adminHomeShell = '/adminHomeShell';
  static const String adminDashboard = '/adminDashboard';
  static const String adminDoctors = '/adminDoctors';
  static const String adminPatients = '/adminPatients';
  static const String adminAppointments = '/adminAppointments';
  static const String adminSettings = '/adminSettings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ---------- Gate ----------
      case gate:
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());

      // ---------- Auth ----------
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case register:
        // ✅ alias يرجع لنفس شاشة Signup
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());

      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case registerSuccess: {
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RegisterSuccessScreen(
            name: args?['name'],
            role: args?['role'],
            autoLoggedIn: args?['autoLoggedIn'] ?? true,
          ),
        );
      }

      // ---------- Notifications ----------
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case adminNotifications:
        return MaterialPageRoute(builder: (_) => const AdminNotificationsScreen());

      // ---------- Patient ----------
      case patientHomeShell:
        return MaterialPageRoute(builder: (_) => const PatientHomeShell());

      case patientAppointments:
        return MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen());

      // ---------- Doctor Shell ----------
      case doctorHomeShell: {
        final tab = (settings.arguments as int?) ?? 0;
        return MaterialPageRoute(
          builder: (_) => DoctorHomeShell(initialTab: _clampDoctorTab(tab)),
        );
      }

      case doctorDashboard:
        return MaterialPageRoute(builder: (_) => const DoctorHomeShell(initialTab: 0));

      case doctorAppointments:
        return MaterialPageRoute(builder: (_) => const DoctorHomeShell(initialTab: 1));

      case doctorRecords:
        return MaterialPageRoute(builder: (_) => const DoctorHomeShell(initialTab: 2));

      case doctorProfile:
        return MaterialPageRoute(builder: (_) => const DoctorHomeShell(initialTab: 3));

      case doctorPatientsScreen:
        return MaterialPageRoute(builder: (_) => const DoctorPatientsScreen());

      // ---------- Admin Shell ----------
      case adminHomeShell: {
        final tab = (settings.arguments as int?) ?? 0;
        return MaterialPageRoute(
          builder: (_) => AdminHomeShell(initialTab: _clampAdminTab(tab)),
        );
      }

      // aliases (تفتح نفس الـ shell على تاب محدد)
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminHomeShell(initialTab: 0));

      case adminDoctors:
        return MaterialPageRoute(builder: (_) => const AdminHomeShell(initialTab: 1));

      case adminPatients:
        return MaterialPageRoute(builder: (_) => const AdminHomeShell(initialTab: 2));

      case adminAppointments:
        return MaterialPageRoute(builder: (_) => const AdminHomeShell(initialTab: 3));

      case adminSettings:
        return MaterialPageRoute(builder: (_) => const AdminHomeShell(initialTab: 4));

      // ---------- 404 ----------
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

  static int _clampDoctorTab(int tab) {
    if (tab < 0) return 0;
    if (tab > 3) return 3;
    return tab;
  }

  static int _clampAdminTab(int tab) {
    if (tab < 0) return 0;
    if (tab > 4) return 4;
    return tab;
  }
}
