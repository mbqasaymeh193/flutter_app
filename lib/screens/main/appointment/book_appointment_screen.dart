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
  bool _loadingSlots = false;
  bool _booking = false;

  List<Map<String, dynamic>> _doctors = [];

  int? _selectedDoctorId;
  DateTime? _selectedDate;

  // fallback (الاختيار اليدوي)
  TimeOfDay? _selectedTime;

  // slots (من السيرفر)
  List<Map<String, dynamic>> _availableSlots = [];
  int? _selectedSlotIndex;
  DateTime? _selectedSlotStart;
  DateTime? _selectedSlotEnd;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  bool _routeArgsApplied = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    // دعم الطريقة القديمة: widget.doctor
    _applyIncomingDoctorMap(widget.doctor);

    _fetchDoctors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // دعم الطريقة الجديدة: arguments من routes
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _applyIncomingDoctorMap(args.cast<String, dynamic>());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ========================== Data Loading ==========================

  Future<void> _fetchDoctors() async {
    setState(() => _loading = true);

    try {
      final res = await ApiService.getDoctors();
      _doctors = res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // إذا عندنا doctorId مسبقاً (من profile) ولم يتم اختيار تاريخ، نضع تاريخ غداً افتراضياً
      if (_selectedDoctorId != null && _selectedDate == null) {
        _selectedDate = DateTime.now().add(const Duration(days: 1));
      }

      // إذا عندنا doctorId + date جلب slots مباشرة
      if (_selectedDoctorId != null && _selectedDate != null) {
        await _fetchAvailableSlots();
      }
    } catch (_) {
      _doctors = [];
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
      _fadeController.forward();
    }
  }

  Future<void> _fetchAvailableSlots() async {
    final doctorId = _selectedDoctorId;
    final date = _selectedDate;

    if (doctorId == null || date == null) return;

    setState(() {
      _loadingSlots = true;
      _availableSlots = [];
      _selectedSlotIndex = null;
      _selectedSlotStart = null;
      _selectedSlotEnd = null;
    });

    try {
      // ✅ endpoint الجديد
      final slots = await ApiService.getDoctorAvailableSlots(
        doctorId: doctorId,
        date: date,
      );

      final list = slots
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // فلترة وترتيب بالساعات
      list.sort((a, b) {
        final sa = _parseSlotStart(a) ?? DateTime(2100);
        final sb = _parseSlotStart(b) ?? DateTime(2100);
        return sa.compareTo(sb);
      });

      if (!mounted) return;

      setState(() {
        _availableSlots = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableSlots = [];
      });
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  // ========================== Incoming Doctor ==========================

  void _applyIncomingDoctorMap(Map<String, dynamic>? map) {
    if (map == null) return;

    // مهم جداً:
    // نجرّب doctorId أولاً (اللي نمرره من DoctorPublicProfileScreen)
    // ثم id (لو جاي من list)
    final incomingId = _tryInt(map['doctorId']) ?? _tryInt(map['id']);

    if (incomingId != null && incomingId > 0) {
      _selectedDoctorId = incomingId;
    }
  }

  // ========================== Date & Time ==========================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: (now.add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (d != null) {
      setState(() {
        _selectedDate = d;

        // reset selections
        _selectedTime = null;
        _availableSlots = [];
        _selectedSlotIndex = null;
        _selectedSlotStart = null;
        _selectedSlotEnd = null;
      });

      // بعد اختيار التاريخ، نجلب slots
      await _fetchAvailableSlots();
    }
  }

  Future<void> _pickTimeFallback() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (t != null) {
      setState(() {
        _selectedTime = t;

        // إذا اخترنا وقت يدوي، نلغي اختيار slot (لمنع التضارب)
        _selectedSlotIndex = null;
        _selectedSlotStart = null;
        _selectedSlotEnd = null;
      });
    }
  }

  // ========================== Booking ==========================

  Future<void> _book() async {
    if (_selectedDoctorId == null) {
      _toast('يرجى اختيار طبيب');
      return;
    }
    if (_selectedDate == null) {
      _toast('يرجى اختيار التاريخ');
      return;
    }

    // أولوية للـ Slot إذا موجود
    DateTime? startsAt;
    DateTime? endsAt;

    if (_selectedSlotStart != null && _selectedSlotEnd != null) {
      startsAt = _selectedSlotStart;
      endsAt = _selectedSlotEnd;
    } else {
      // fallback: وقت يدوي
      if (_selectedTime == null) {
        _toast('يرجى اختيار الوقت أو اختيار وقت من الأوقات المتاحة');
        return;
      }

      startsAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      endsAt = startsAt.add(const Duration(minutes: 30));
    }

    if (startsAt!.isBefore(DateTime.now())) {
      _toast('لا يمكن حجز موعد في وقت سابق');
      return;
    }

    setState(() => _booking = true);

    try {
      final ok = await ApiService.bookAppointment(
        doctorId: _selectedDoctorId!,
        startsAt: startsAt,
        endsAt: endsAt!,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ========================== Helpers ==========================

  int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  DateTime? _tryDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseSlotStart(Map<String, dynamic> slot) {
    // احتمالات أسماء الحقول حسب الباك اند/النسخ:
    return _tryDate(slot['startsAt']) ??
        _tryDate(slot['start']) ??
        _tryDate(slot['from']);
  }

  DateTime? _parseSlotEnd(Map<String, dynamic> slot) {
    return _tryDate(slot['endsAt']) ??
        _tryDate(slot['end']) ??
        _tryDate(slot['to']);
  }

  String _formatSelected() {
    // إذا slot مختار
    if (_selectedSlotStart != null && _selectedSlotEnd != null) {
      final s = DateFormat('EEE, MMM d • HH:mm').format(_selectedSlotStart!);
      final e = DateFormat('HH:mm').format(_selectedSlotEnd!);
      return '$s - $e';
    }

    // fallback (يدوي)
    if (_selectedDate != null && _selectedTime != null) {
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      return DateFormat('EEE, MMM d • HH:mm').format(dt);
    }

    return 'اختر التاريخ والوقت';
  }

  // ========================== UI ==========================

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
                    const SizedBox(height: 12),

                    // ✅ الأوقات المتاحة من السيرفر
                    _buildAvailableSlotsSection(),
                    const SizedBox(height: 12),

                    // fallback: وقت يدوي
                    _buildTimeTileFallback(),
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
                              minimumSize: const Size(double.infinity, 50),
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

  // ========================== Widgets ==========================

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
            final id = _tryInt(d['id']);
            final name = (d['fullName'] ?? d['name'] ?? 'Doctor').toString();
            final spec = (d['specialty'] ?? '').toString();

            return DropdownMenuItem<int>(
              value: id,
              child: Text('$name ${spec.isNotEmpty ? "— $spec" : ""}'),
            );
          }).toList(),
          onChanged: (v) async {
            setState(() {
              _selectedDoctorId = v;

              // reset selections
              _selectedTime = null;
              _availableSlots = [];
              _selectedSlotIndex = null;
              _selectedSlotStart = null;
              _selectedSlotEnd = null;

              // إذا ما في تاريخ، نحطه غداً
              _selectedDate ??= DateTime.now().add(const Duration(days: 1));
            });

            await _fetchAvailableSlots();
          },
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

  Widget _buildAvailableSlotsSection() {
    final doctorId = _selectedDoctorId;
    final date = _selectedDate;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأوقات المتاحة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            if (doctorId == null || date == null)
              const Text(
                'اختر الطبيب والتاريخ لعرض الأوقات المتاحة.',
                style: TextStyle(color: Colors.black54),
              )
            else if (_loadingSlots)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                ),
              )
            else if (_availableSlots.isEmpty)
              const Text(
                'لا توجد أوقات متاحة لهذا اليوم (يمكنك اختيار وقت يدوي كخيار احتياطي).',
                style: TextStyle(color: Colors.black54),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_availableSlots.length, (i) {
                  final slot = _availableSlots[i];
                  final s = _parseSlotStart(slot);
                  final e = _parseSlotEnd(slot);

                  final label = (s != null && e != null)
                      ? '${DateFormat('HH:mm').format(s)} - ${DateFormat('HH:mm').format(e)}'
                      : 'Slot';

                  final selected = _selectedSlotIndex == i;

                  return ChoiceChip(
                    selected: selected,
                    label: Text(label),
                    onSelected: (_) {
                      setState(() {
                        _selectedSlotIndex = i;
                        _selectedSlotStart = s;
                        _selectedSlotEnd = e;

                        // عند اختيار slot: نلغي الوقت اليدوي
                        _selectedTime = null;
                      });
                    },
                  );
                }),
              ),

            const SizedBox(height: 8),

            if (doctorId != null && date != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _fetchAvailableSlots,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث الأوقات'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTileFallback() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
      title: Text(
        _selectedTime == null
            ? 'اختيار وقت يدوي (احتياطي)'
            : _selectedTime!.format(context),
      ),
      subtitle: const Text(
        'يفضل اختيار الوقت من "الأوقات المتاحة" أعلاه إن وُجدت.',
        style: TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _pickTimeFallback,
    );
  }
}
