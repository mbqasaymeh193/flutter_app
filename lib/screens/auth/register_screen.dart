import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/screens/auth/signup_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Wrapper: نفس شاشة التسجيل المعتمدة (SignupScreen)
    return const SignupScreen();
  }
}
