import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPass = TextEditingController();
  final newPass = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> _changePassword() async {
    setState(() => loading = true);
    final result = await ApiService.changePassword(oldPass.text, newPass.text);
    setState(() {
      loading = false;
      message = result?['message'] ?? 'Failed to change password';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Old Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "New Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text("Change Password"),
                  ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(message!),
            ]
          ],
        ),
      ),
    );
  }
}
