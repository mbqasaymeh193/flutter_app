import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    if (oldPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill both fields')));
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.changePassword(oldPass, newPass);
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
      _oldPassController.clear();
      _newPassController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _oldPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            const SizedBox(height: 10),
            TextField(controller: _newPassController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _changePassword, child: const Text('Change Password')),
          ],
        ),
      ),
    );
  }
}
