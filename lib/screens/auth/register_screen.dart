import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Patient';
  String _selectedSpecialty = 'General';
  bool _isLoading = false;
  bool _hidePassword = true;

  final List<String> _roles = ['Patient', 'Doctor'];
  final List<String> _specialties = [
    'General',
    'Cardiology',
    'Dermatology',
    'Dentistry',
    'Pediatrics',
    'Neurology',
    'Orthopedics',
    'Radiology'
  ];

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال جميع الحقول')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ApiService.register(
      fullName: name,
      email: email,
      password: password,
      role: _selectedRole,
      specialty: _selectedRole == 'Doctor' ? _selectedSpecialty : 'General',
    );

    setState(() => _isLoading = false);

    if (success) {
      // تسجيل الدخول مباشرة بعد التسجيل
      final loginResult = await ApiService.login(email, password);
      if (loginResult != null && loginResult['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', loginResult['token']);
        await prefs.setString('role', loginResult['role'] ?? '');
        await prefs.setString('name', loginResult['name'] ?? '');
        ApiService.token = loginResult['token'];

        final role = (loginResult['role'] ?? '').toString().toLowerCase();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب بنجاح ✅')),
        );

        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, AppRoutes.doctorDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.patientHomeShell);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إنشاء الحساب ❌')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'املأ بياناتك للمتابعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 25),

            // الاسم الكامل
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // البريد الإلكتروني
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // كلمة المرور
            TextField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
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
            const SizedBox(height: 16),

            // الدور
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: 'الدور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_circle_outlined),
              ),
              items: _roles
                  .map((role) =>
                      DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 16),

            // التخصص (للدكتور فقط)
            if (_selectedRole == 'Doctor')
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialty,
                decoration: InputDecoration(
                  labelText: 'التخصص الطبي',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.local_hospital_outlined),
                ),
                items: _specialties
                    .map((spec) =>
                        DropdownMenuItem(value: spec, child: Text(spec)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedSpecialty = value!),
              ),

            const SizedBox(height: 28),

            // زر التسجيل
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)))
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إنشاء حساب',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
            const SizedBox(height: 20),

            // رابط تسجيل الدخول
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('لديك حساب بالفعل؟'),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
