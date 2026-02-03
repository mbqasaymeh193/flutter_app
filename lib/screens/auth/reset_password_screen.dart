import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';
import 'package:healthcare_flutter_app/widgets/otp_notification_hint.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _hidePassword = true;
  bool _argsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final email = args['email']?.toString().trim();
      if ((email ?? '').isNotEmpty && _emailController.text.trim().isEmpty) {
        _emailController.text = email!;
      }
    }
  }

  Future<void> _reset() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (email.isEmpty || code.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال البريد والرمز وكلمة المرور الجديدة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.resetPasswordWithCode(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إعادة تعيين كلمة المرور بنجاح ✅')),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في إعادة التعيين ❌')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OtpNotificationHint(
              onFill: (code) => _codeController.text = code,
            ),
            const SizedBox(height: 12),
            const Text(
              'أدخل بريدك وكلمة المرور الجديدة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // البريد الإلكتروني
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // رمز التحقق (OTP)
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'رمز التحقق (OTP)',
                prefixIcon: const Icon(Icons.verified_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // كلمة المرور الجديدة
            TextField(
              controller: _newPasswordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 28),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)))
                : ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تأكيد التغيير',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('العودة إلى تسجيل الدخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
