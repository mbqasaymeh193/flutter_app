import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  /// doctor يمكن أن يكون:
  /// - Map (قادِم من Doctor Profile)
  /// - null (في حال الدخول من قائمة عامة)
  const BookAppointmentScreen({super.key, this.doctor});

  final Map<String, dynamic>? doctor;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _booking = false;

  List<Map<String, dynamic>> _doctors = [];

  int? _selectedDoctorId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _selectedDoctorId = widget.doctor?['id'] as int?;
    _fetchDoctors();
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
      _doctors = res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      _doctors = [];
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
      _fadeController.forward();
    }
  }

  // ---------------- Date & Time ----------------

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (d != null) {
      setState(() => _selectedDate = d);
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (t != null) {
      setState(() => _selectedTime = t);
    }
  }

  // ---------------- Booking ----------------

  Future<void> _book() async {
    if (_selectedDoctorId == null) {
      _toast('يرجى اختيار طبيب');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _toast('يرجى اختيار التاريخ والوقت');
      return;
    }

    final startsAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (startsAt.isBefore(DateTime.now())) {
      _toast('لا يمكن حجز موعد في وقت سابق');
      return;
    }

    final endsAt = startsAt.add(const Duration(minutes: 30));

    setState(() => _booking = true);

    try {
      final ok = await ApiService.bookAppointment(
        doctorId: _selectedDoctorId!,
        startsAt: startsAt,
        endsAt: endsAt,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حجز الموعد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _toast('فشل حجز الموعد');
      }
    } catch (e) {
      _toast('خطأ أثناء الحجز');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatSelected() {
    if (_selectedDate == null || _selectedTime == null) {
      return 'اختر التاريخ والوقت';
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('حجز موعد'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDoctorDropdown(),
                    const SizedBox(height: 16),
                    _buildDateTile(),
                    const SizedBox(height: 8),
                    _buildTimeTile(),
                    const SizedBox(height: 20),
                    Text(
                      _formatSelected(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _booking
                        ? const CircularProgressIndicator(
                            color: Color(0xFF1976D2),
                          )
                        : ElevatedButton.icon(
                            onPressed: _book,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'تأكيد الحجز',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              minimumSize:
                                  const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------- Widgets ----------------

  Widget _buildDoctorDropdown() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<int>(
          value: _selectedDoctorId,
          decoration: const InputDecoration(
            labelText: 'اختيار الطبيب',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_information),
          ),
          items: _doctors.map((d) {
            final id = d['id'] as int?;
            final name = d['fullName'] ?? d['name'] ?? 'Doctor';
            final spec = d['specialty'] ?? '';

            return DropdownMenuItem<int>(
              value: id,
              child: Text('$name ${spec.isNotEmpty ? "— $spec" : ""}'),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedDoctorId = v),
        ),
      ),
    );
  }

  Widget _buildDateTile() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
      title: Text(
        _selectedDate == null
            ? 'اختر التاريخ'
            : DateFormat.yMMMMd().format(_selectedDate!),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickDate,
    );
  }

  Widget _buildTimeTile() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
      title: Text(
        _selectedTime == null
            ? 'اختر الوقت'
            : _selectedTime!.format(context),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickTime,
    );
  }
}
