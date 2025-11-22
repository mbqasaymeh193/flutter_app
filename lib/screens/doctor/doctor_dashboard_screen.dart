import 'package:flutter/material.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
import 'package:healthcare_flutter_app/core/routes/app_routes.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int totalAppointments = 0;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await ApiService.getDoctorAppointments();

      setState(() {
        totalAppointments = (appointments ?? []).length;
        _loading = false;
      });

      debugPrint(
          "📊 DoctorDashboard: loaded ${appointments?.length ?? 0} appointments");
    } catch (e) {
      debugPrint("DoctorDashboard _loadAppointments error: $e");
      setState(() {
        totalAppointments = 0;
        _loading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل المواعيد';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الطبيب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month,
                          color: Colors.blue),
                      title: const Text('إجمالي المواعيد'),
                      trailing: Text(
                        '$totalAppointments',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // نستخدم الراوت الموحد اللي يفتح DoctorHomeShell على تبويب المواعيد
                      Navigator.pushNamed(
                        context,
                        AppRoutes.doctorAppointments,
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('عرض قائمة المواعيد'),
                  ),
                ],
              ),
      ),
    );
  }
}
