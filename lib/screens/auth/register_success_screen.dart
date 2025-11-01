import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class RegisterSuccessScreen extends StatelessWidget {
  final String? name;
  final String? role;
  final bool autoLoggedIn;

  const RegisterSuccessScreen({
    super.key,
    this.name,
    this.role,
    this.autoLoggedIn = true,
  });

  void _goToHome(BuildContext context) {
    final r = (role ?? '').toLowerCase();
    if (r == 'doctor') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.doctorDashboard,
        (_) => false,
      );
    } else if (r == 'admin') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminDashboard,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.patientHomeShell,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.trim().isEmpty) ? 'مرحبًا بك' : name!;
    final displayRole = (role ?? 'Patient');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text('تم إنشاء الحساب'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0x331976D2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1976D2), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 56, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 16),
                Text(
                  'تم إنشاء الحساب بنجاح ✅',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$displayName — الدور: $displayRole',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                const Text(
                  'يمكنك الآن متابعة استخدام النظام. اضغط على الزر أدناه للانتقال إلى صفحتك الرئيسية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    label: const Text('اذهب إلى صفحتي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _goToHome(context),
                  ),
                ),
                const SizedBox(height: 12),
                if (!autoLoggedIn)
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    ),
                    child: const Text('العودة إلى تسجيل الدخول'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
