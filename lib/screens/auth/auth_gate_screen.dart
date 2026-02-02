import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // تأخير بسيط لعرض Splash بشكل لطيف
    await Future.delayed(const Duration(milliseconds: 250));

    // 1) حمّل التوكن (من prefs إلى ApiService.token)
    await ApiService.loadToken();
    final token = ApiService.token;

    if (!mounted) return;

    // لا يوجد توكن => روح على تسجيل الدخول
    if (token == null || token.isEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }

    // 2) حاول نقرأ الدور من JWT (أفضل من الاعتماد على prefs)
    String role = _readRoleFromJwt(token) ?? '';

    // 3) fallback: لو الدور مش موجود داخل JWT (نادر)، جرّبه من prefs
    if (role.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      role = (prefs.getString('role') ?? '').toLowerCase();
    }

    if (!mounted) return;

    // 4) التوجيه حسب الدور
    if (role == 'doctor') {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.doctorDashboard, (_) => false);
    } else if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.adminDashboard, (_) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.patientHomeShell, (_) => false);
    }
  }

  /// قراءة الدور من JWT بدون تحقق توقيع (للـ UI routing فقط)
  /// في الباك اند التحقق الحقيقي يتم عبر RequireAuthorization
  String? _readRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));

      if (payloadMap is! Map<String, dynamic>) return null;

      // أحياناً يكون role بهذا المفتاح:
      // "role" أو "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
      final role1 = payloadMap['role']?.toString();
      if (role1 != null && role1.isNotEmpty) return role1.toLowerCase();

      const claimRole =
          'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';
      final role2 = payloadMap[claimRole]?.toString();
      if (role2 != null && role2.isNotEmpty) return role2.toLowerCase();

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_rounded, size: 72, color: Color(0xFF1976D2)),
            SizedBox(height: 14),
            Text(
              'Medical Booking System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(color: Color(0xFF1976D2)),
          ],
        ),
      ),
    );
  }
}
