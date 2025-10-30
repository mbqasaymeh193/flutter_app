import 'package:flutter/material.dart';

// Doctor Screens
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/doctor/doctor_appointments_screen.dart';
import 'screens/doctor/doctor_patients_screen.dart';
import 'screens/doctor/doctor_profile_screen.dart';
import 'screens/doctor/doctor_notifications_screen.dart';
import 'screens/doctor/doctor_settings_screen.dart';

// Patient Screens
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/patient/patient_appointments_screen.dart';
import 'screens/patient/patient_profile_screen.dart';
import 'screens/patient/patient_notifications_screen.dart';
import 'screens/patient/patient_settings_screen.dart';


class AppRoutes {
  static const String doctorDashboard = '/doctorDashboard';
  static const String doctorAppointments = '/doctorAppointments';
  static const String doctorPatients = '/doctorPatients';
  static const String doctorProfile = '/doctorProfile';
  static const String doctorNotifications = '/doctorNotifications';
  static const String doctorSettings = '/doctorSettings';

  static const String patientDashboard = '/patientDashboard';
  static const String patientAppointments = '/patientAppointments';
  static const String patientProfile = '/patientProfile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Doctor Routes
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

      // Patient Routes
      case patientDashboard:
        return MaterialPageRoute(builder: (_) => const PatientDashboardScreen());
      case patientAppointments:
        return MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen());
      case patientProfile:
        return MaterialPageRoute(builder: (_) => const PatientProfileScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('الصفحة غير موجودة ❌')),
          ),
        );
    }
  }
}
