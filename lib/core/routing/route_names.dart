import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/patient/home_patient_screen.dart';
import '../../screens/doctor/doctor_home_screen.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/shared/not_found_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.homePatient:
        return MaterialPageRoute(builder: (_) => const HomePatientScreen());
      case AppRoutes.homeDoctor:
        return MaterialPageRoute(builder: (_) => const DoctorHomeScreen());
      case AppRoutes.homeAdmin:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}
