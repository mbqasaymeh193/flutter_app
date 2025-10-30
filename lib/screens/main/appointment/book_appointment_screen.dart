import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, required doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  bool _loading = true;
  List<dynamic> _doctors = [];
  dynamic _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getDoctors();
      if (res != null && res is List) {
        _doctors = res;
      } else if (res != null && res is Map && res['data'] is List) {
        _doctors = res['data'];
      } else {
        _doctors = [];
      }
    } catch (e) {
      _doctors = [];
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 9, minute: 0));
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _book() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a doctor')));
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
      return;
    }

    final DateTime startsAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final iso = startsAt.toIso8601String();

    setState(() => _booking = true);
    try {
      final ok = await ApiService.bookAppointment(_selectedDoctor['id'] ?? _selectedDoctor['doctorId'], iso);
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked successfully')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book appointment')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  String _formatSelected() {
    if (_selectedDate == null || _selectedTime == null) return 'Select date & time';
    final dt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    return DateFormat('EEE, MMM d • HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<dynamic>(
                    initialValue: _selectedDoctor,
                    decoration: const InputDecoration(labelText: 'Choose Doctor', border: OutlineInputBorder()),
                    items: _doctors.map((d) {
                      final name = d['fullName'] ?? d['name'] ?? 'Doctor';
                      final spec = d['specialty'] ?? d['speciality'] ?? '';
                      return DropdownMenuItem(value: d, child: Text('$name ${spec.isNotEmpty ? "— $spec" : ""}'));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedDoctor = v),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    onTap: _pickDate,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_selectedDate == null ? 'Select Date' : DateFormat.yMMMMd().format(_selectedDate!)),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    onTap: _pickTime,
                    leading: const Icon(Icons.access_time),
                    title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(height: 24),
                  Text(_formatSelected()),
                  const SizedBox(height: 20),
                  _booking
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _book,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), minimumSize: const Size(double.infinity, 48)),
                          child: const Text('Confirm Booking'),
                        ),
                ],
              ),
            ),
    );
  }
}
