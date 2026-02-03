import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();

  String _role = 'Patient';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Map<String, String> _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return {'firstName': '', 'lastName': ''};
    if (parts.length == 1) {
      // fallback: إذا كتب كلمة واحدة فقط
      return {'firstName': parts.first, 'lastName': parts.first};
    }

    return {
      'firstName': parts.first,
      'lastName': parts.sublist(1).join(' '),
    };
  }

  bool _isValidEmail(String email) {
    // تحقق بسيط (مش RFC كامل لكنه كافي للتطبيقات العادية)
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email);
  }

  Future<void> _register() async {
    if (_isLoading) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nationalId = _nationalIdController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final specialty = _specialtyController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        nationalId.isEmpty ||
        phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    final isDoctor = _role.toLowerCase() == 'doctor';
    if (isDoctor && specialty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter specialty for Doctor')),
      );
      return;
    }

    final nameParts = _splitName(fullName);
    final firstName = nameParts['firstName'] ?? '';
    final lastName = nameParts['lastName'] ?? '';

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid full name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = false;
    String message = '';
    try {
      final res = await ApiService.registerDetailed(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        nationalId: nationalId,
        phoneNumber: phoneNumber,
        role: _role, // Patient/Doctor
        specialty: isDoctor ? specialty : null,
      );
      success = res?['ok'] == true;
      message = (res?['message'] ?? '').toString().trim();
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.registerSuccess,
        (_) => false,
        arguments: {
          'name': fullName,
          'role': _role,
          'autoLoggedIn': false,
          'message': message,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isNotEmpty ? message : 'Failed to register ❌',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = _role.toLowerCase() == 'doctor';

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password *'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _nationalIdController,
              decoration: const InputDecoration(labelText: 'National ID *'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              key: ValueKey<String>(_role),
              initialValue: _role,
              items: const [
                DropdownMenuItem(value: 'Patient', child: Text('Patient')),
                DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
              ],
              onChanged: _isLoading
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _role = v;
                        // ✅ لو رجع Patient نمسح specialty حتى لا يُرسل بالغلط
                        if (_role.toLowerCase() != 'doctor') {
                          _specialtyController.clear();
                        }
                      });
                    },
              decoration: const InputDecoration(labelText: 'Role *'),
            ),

            if (isDoctor) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty *'),
                textInputAction: TextInputAction.done,
              ),
            ],

            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
