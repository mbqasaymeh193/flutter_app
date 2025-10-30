import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final dynamic doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<dynamic> _doctors = [];
  int? _selectedDoctorId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _booking = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _selectedDoctorId = widget.doctor?['id'];

    // ✨ إعداد حركة الدخول الناعمة
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getDoctors();
      _doctors = res;
    } catch (e) {
      _doctors = [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _fadeController.forward(); // 🔹 تشغيل الأنيميشن بعد التحميل
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _book() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final DateTime startsAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final endsAt = startsAt.add(const Duration(minutes: 30));

    setState(() => _booking = true);
    try {
      final ok = await ApiService.bookAppointment(
        doctorId: _selectedDoctorId!,
        startsAt: startsAt,
        endsAt: endsAt,
      );
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Appointment booked successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // 🌊 حركة انتقال ناعمة عند العودة
        Future.delayed(const Duration(milliseconds: 400), () {
          Navigator.pop(context, true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  String _formatSelected() {
    if (_selectedDate == null || _selectedTime == null) {
      return 'Select date & time';
    }
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return DateFormat('EEE, MMM d • HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 3,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<int>(
                          value: _selectedDoctorId,
                          decoration: const InputDecoration(
                            labelText: 'Choose Doctor',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medical_information),
                          ),
                          items: _doctors.map((d) {
                            final id = d['id'];
                            final name = d['fullName'] ?? d['name'] ?? 'Doctor';
                            final spec = d['specialty'] ?? d['speciality'] ?? '';
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '$name ${spec.isNotEmpty ? "— $spec" : ""}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedDoctorId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildDateTile(),
                    const SizedBox(height: 8),
                    _buildTimeTile(),
                    const SizedBox(height: 24),

                    Text(
                      _formatSelected(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _booking
                        ? const CircularProgressIndicator(color: Color(0xFF1976D2))
                        : ElevatedButton.icon(
                            onPressed: _book,
                            icon: const Icon(Icons.check_circle_outline),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            label: const Text(
                              'Confirm Booking',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  // 🗓️ عنصر اختيار التاريخ
  Widget _buildDateTile() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
      title: Text(
        _selectedDate == null
            ? 'Select Date'
            : DateFormat.yMMMMd().format(_selectedDate!),
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickDate,
    );
  }

  // ⏰ عنصر اختيار الوقت
  Widget _buildTimeTile() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
      title: Text(
        _selectedTime == null
            ? 'Select Time'
            : _selectedTime!.format(context),
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickTime,
    );
  }
}
