import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorWorkingHoursScreen extends StatefulWidget {
  const DoctorWorkingHoursScreen({super.key});

  @override
  State<DoctorWorkingHoursScreen> createState() => _DoctorWorkingHoursScreenState();
}

class _DoctorWorkingHoursScreenState extends State<DoctorWorkingHoursScreen> {
  bool _loading = true;
  bool _saving = false;

  final List<_WorkingDay> _days = _defaultDays();

  static List<_WorkingDay> _defaultDays() {
    return [
      _WorkingDay(dayOfWeek: 'Sunday', label: 'الأحد'),
      _WorkingDay(dayOfWeek: 'Monday', label: 'الاثنين'),
      _WorkingDay(dayOfWeek: 'Tuesday', label: 'الثلاثاء'),
      _WorkingDay(dayOfWeek: 'Wednesday', label: 'الأربعاء'),
      _WorkingDay(dayOfWeek: 'Thursday', label: 'الخميس'),
      _WorkingDay(dayOfWeek: 'Friday', label: 'الجمعة'),
      _WorkingDay(dayOfWeek: 'Saturday', label: 'السبت'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final list = await ApiService.getDoctorWorkingHours();

    for (final day in _days) {
      day.isActive = false;
      day.start = const TimeOfDay(hour: 9, minute: 0);
      day.end = const TimeOfDay(hour: 17, minute: 0);
      day.slotMinutes = 30;
    }

    for (final raw in list) {
      if (raw is! Map) continue;
      final dayKey = (raw['dayOfWeek'] ?? raw['DayOfWeek'] ?? '')
          .toString()
          .trim();
      final item = _days.firstWhere(
        (d) => d.dayOfWeek.toLowerCase() == dayKey.toLowerCase(),
        orElse: () => _WorkingDay.empty(),
      );
      if (item.isEmpty) continue;

      item.isActive = _asBool(raw['isActive'] ?? raw['IsActive']);

      final startStr = (raw['startTime'] ?? raw['StartTime'])?.toString();
      final endStr = (raw['endTime'] ?? raw['EndTime'])?.toString();
      final slot = raw['slotDurationMinutes'] ?? raw['SlotDurationMinutes'];

      if (item.isActive) {
        final start = _parseTime(startStr);
        final end = _parseTime(endStr);

        if (start != null) item.start = start;
        if (end != null) item.end = end;
      }

      final slotInt = int.tryParse(slot?.toString() ?? '');
      if (slotInt != null && slotInt > 0) item.slotMinutes = slotInt;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;

    final error = _validateDays();
    if (error != null) {
      _snack(error);
      return;
    }

    setState(() => _saving = true);

    final payload = _days.map((d) {
      return {
        'dayOfWeek': d.dayOfWeek,
        'startTime': d.isActive ? _formatTime(d.start) : null,
        'endTime': d.isActive ? _formatTime(d.end) : null,
        'slotDurationMinutes': d.slotMinutes,
        'isActive': d.isActive,
      };
    }).toList();

    final ok = await ApiService.updateDoctorWorkingHours(payload);

    if (!mounted) return;
    setState(() => _saving = false);

    _snack(ok ? 'تم حفظ الدوام بنجاح' : 'فشل حفظ الدوام');
  }

  String? _validateDays() {
    for (final d in _days) {
      if (!d.isActive) continue;
      if (d.start == null || d.end == null) {
        return 'يرجى تحديد وقت البداية والنهاية ليوم ${d.label}';
      }
      final start = _toMinutes(d.start!);
      final end = _toMinutes(d.end!);
      if (end <= start) {
        return 'وقت النهاية يجب أن يكون بعد البداية (${d.label})';
      }
      final duration = end - start;
      if (duration < d.slotMinutes) {
        return 'المدة أقل من طول الحصة (${d.label})';
      }
      if (duration % d.slotMinutes != 0) {
        return 'المدة لا تقبل القسمة على طول الحصة (${d.label})';
      }
    }
    return null;
  }

  Future<void> _pickTime(_WorkingDay day, {required bool isStart}) async {
    final initial = isStart ? day.start : day.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        day.start = picked;
      } else {
        day.end = picked;
      }
    });
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ساعات دوام الطبيب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'حدد ساعات الدوام ليتمكن المرضى من رؤية الأوقات المتاحة وحجز المواعيد.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._days.map((d) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.isActive
                                          ? '${_formatTime(d.start)} → ${_formatTime(d.end)}'
                                          : 'غير مفعل',
                                      style: TextStyle(
                                        color: d.isActive ? Colors.black54 : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: d.isActive,
                                onChanged: (v) => setState(() => d.isActive = v),
                              ),
                            ],
                          ),
                          if (d.isActive) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickTime(d, isStart: true),
                                    icon: const Icon(Icons.access_time),
                                    label: Text('من: ${_formatTime(d.start)}'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickTime(d, isStart: false),
                                    icon: const Icon(Icons.access_time),
                                    label: Text('إلى: ${_formatTime(d.end)}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('مدة الحصة:'),
                                const SizedBox(width: 10),
                                DropdownButton<int>(
                                  value: d.slotMinutes,
                                  items: const [
                                    DropdownMenuItem(value: 15, child: Text('15')),
                                    DropdownMenuItem(value: 20, child: Text('20')),
                                    DropdownMenuItem(value: 30, child: Text('30')),
                                    DropdownMenuItem(value: 45, child: Text('45')),
                                    DropdownMenuItem(value: 60, child: Text('60')),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => d.slotMinutes = v);
                                  },
                                ),
                                const SizedBox(width: 6),
                                const Text('دقيقة'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('حفظ الدوام'),
        ),
      ),
    );
  }
}

class _WorkingDay {
  final String dayOfWeek;
  final String label;
  bool isActive;
  TimeOfDay? start;
  TimeOfDay? end;
  int slotMinutes;
  final bool isEmpty;

  _WorkingDay({
    required this.dayOfWeek,
    required this.label,
    this.isEmpty = false,
  })  : isActive = false,
        start = const TimeOfDay(hour: 9, minute: 0),
        end = const TimeOfDay(hour: 17, minute: 0),
        slotMinutes = 30;

  factory _WorkingDay.empty() => _WorkingDay(
        dayOfWeek: '',
        label: '',
        isEmpty: true,
      );
}
