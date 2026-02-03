import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class RegisterSuccessScreen extends StatefulWidget {
  final String? name;
  final String? role;
  final bool autoLoggedIn;
  final String? message;

  const RegisterSuccessScreen({
    super.key,
    this.name,
    this.role,
    this.autoLoggedIn = false,
    this.message,
  });

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen> {
  Timer? _timer;
  Timer? _countdownTimer;
  int _secondsLeft = 4;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.name == null || widget.name!.trim().isEmpty) ? 'مرحبًا بك' : widget.name!;
    final displayRole = (widget.role ?? 'Patient');
    final lowerRole = (widget.role ?? '').toLowerCase();

    final String mainMessage;
    if ((widget.message ?? '').trim().isNotEmpty) {
      mainMessage = widget.message!.trim();
    } else if (lowerRole == 'doctor') {
      mainMessage = 'تم إنشاء حساب الطبيب بنجاح، وبانتظار موافقة الأدمن.';
    } else {
      mainMessage = 'تم إنشاء الحساب بنجاح.';
    }

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
                  mainMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D47A1),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$displayName — الدور: $displayRole',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  'سيتم تحويلك تلقائيًا إلى صفحة تسجيل الدخول خلال $_secondsLeft ثوانٍ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('الذهاب لتسجيل الدخول الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    ),
                  ),
                ),
                if (widget.autoLoggedIn) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.patientHomeShell,
                      (_) => false,
                    ),
                    child: const Text('الانتقال إلى الصفحة الرئيسية'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
