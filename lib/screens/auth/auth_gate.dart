import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await ApiService.loadToken();
    final t = ApiService.token;

    if (!mounted) return;

    if (t == null || t.trim().isEmpty) {
      _go(AppRoutes.login);
      return;
    }

    final role = _readRoleFromJwt(t);
    final doctorApproved = _readDoctorApprovedFromJwt(t);

    if (role == null) {
      await ApiService.logout();
      if (!mounted) return;
      _go(AppRoutes.login);
      return;
    }

    final r = role.toLowerCase();

    if (r == 'admin') {
      _go(AppRoutes.adminDashboard);
      return;
    }

    if (r == 'patient') {
      _go(AppRoutes.patientHomeShell);
      return;
    }

    if (r == 'doctor') {
      // إذا في claim وطلع false → صفحة انتظار الموافقة
      if (doctorApproved == false) {
        _go(DoctorPendingApprovalScreen.routeName);
        return;
      }
      _go(AppRoutes.doctorHomeShell, args: 0);
      return;
    }

    _go(AppRoutes.login);
  }

  void _go(String route, {Object? args}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (r) => false,
        arguments: args,
      );
    });
  }

  // ================= JWT helpers =================

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final obj = jsonDecode(decoded);

      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _readRoleFromJwt(String token) {
    final p = _decodeJwtPayload(token);
    if (p == null) return null;

    const candidates = [
      'role',
      'Role',
      'roles',
      'Roles',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
    ];

    for (final k in candidates) {
      final v = p[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
      }
    }
    return null;
  }

  bool? _readDoctorApprovedFromJwt(String token) {
    final p = _decodeJwtPayload(token);
    if (p == null) return null;

    const candidates = [
      'doctorApproved',
      'DoctorApproved',
      'isApproved',
      'IsApproved',
      'approved',
      'Approved',
    ];

    for (final k in candidates) {
      final v = p[k];
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true') return true;
        if (s == 'false') return false;
      }
      if (v is num) {
        if (v == 1) return true;
        if (v == 0) return false;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class DoctorPendingApprovalScreen extends StatelessWidget {
  static const routeName = '/doctorPendingApproval';

  const DoctorPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب الطبيب قيد المراجعة'),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.hourglass_top, size: 72, color: primary),
            const SizedBox(height: 16),
            const Text(
              'حساب الطبيب يحتاج موافقة الإدارة قبل تسجيل الدخول.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'سيتم تفعيل حسابك فور الموافقة عليه.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (r) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
