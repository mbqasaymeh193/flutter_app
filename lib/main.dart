import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/payment_screen.dart';

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
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
      ),
      // 👇 اجعل البداية من شاشة تسجيل الدخول مؤقتًا للتجربة
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin': (context) => const AdminScreen(),
        '/payment': (context) => const PaymentScreen(),
      },
    );
  }
}
