import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../widgets/rate_doctor_bottom_sheet.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? errorMessage;

  bool _ratingSheetOpen = false;

  // ====== SharedPreferences Keys ======
  static const String _kRatedIds = 'rated_appointment_ids';

  // ✅ إصلاح جذري: نحول أي قيمة (حتى لو String) إلى int
  static int _safeInt(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  // ✅ إصلاح جذري: key تقبل Object? بدل int (حتى لو وصل String ما في مشكلة)
  static String _kSnoozeKey(Object? id) =>
      'rate_snooze_until_${_safeInt(id)}';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  // ================= Safe Helpers =================
  String _asStr(dynamic v) => (v ?? '').toString().trim();

  DateTime? _tryParseDate(dynamic v) {
    final s = _asStr(v);
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  // ================= Fetch =================
  Future<void> _fetchAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dynamic data = await ApiService.getMyAppointments();
      if (!mounted) return;

      // ✅ حماية: مهما كان شكل الداتا
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] is List) {
        list = List<dynamic>.from(data['items']);
      } else {
        list = [];
      }

      // ✅ ترتيب: الأحدث أولاً
      list.sort((a, b) {
        final da = (a is Map) ? _tryParseDate(a['startsAt']) : null;
        final db = (b is Map) ? _tryParseDate(b['startsAt']) : null;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      setState(() {
        appointments = list;
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybePromptRating();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        appointments = [];
        isLoading = false;
        errorMessage = 'حدث خطأ أثناء تحميل المواعيد';
      });
    }
  }

  // ================= Status Helpers =================
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'مؤكد';
    if (lower == 'rejected') return 'مرفوض';
    return 'قيد الانتظار';
  }

  bool _isConfirmedStatus(String status) {
    final s = status.toLowerCase();
    return s == 'confirmed' || s == 'accepted';
  }

  // ================= Payment Helpers =================
  String _paymentLabelAr(String? s) {
    final v = (s ?? '').trim();
    if (v.isEmpty) return 'غير معروف';
    switch (v.toLowerCase()) {
      case 'pending':
        return 'غير مدفوع';
      case 'authorized':
        return 'مفوض (On Hold)';
      case 'captured':
        return 'مدفوع';
      case 'failed':
        return 'فشل الدفع';
      case 'released':
        return 'تم الإرجاع/الإلغاء';
      default:
        return v;
    }
  }

  Color _paymentColor(String? s) {
    final v = (s ?? '').toLowerCase();
    if (v == 'captured') return Colors.green;
    if (v == 'authorized') return Colors.blue;
    if (v == 'failed') return Colors.red;
    if (v == 'released') return Colors.purple;
    return Colors.grey;
  }

  bool _canPayNow(String? s) {
    final v = (s ?? '').toLowerCase();
    return v == 'pending' || v == 'failed';
  }

  // ================= Rating Logic =================
  Future<Set<int>> _loadRatedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kRatedIds) ?? [];
    return list
        .map((e) => int.tryParse(e) ?? 0)
        .where((x) => x > 0)
        .toSet();
  }

  Future<void> _saveRatedIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRatedIds,
      ids.map((e) => e.toString()).toList(),
    );
  }

  // ✅ إصلاح: تقبل Object? (حتى لو String)
  Future<DateTime?> _getSnoozeUntil(Object? apptIdRaw) async {
    final apptId = _safeInt(apptIdRaw);
    if (apptId <= 0) return null;

    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kSnoozeKey(apptId));
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ✅ إصلاح: تقبل Object? (حتى لو String)
  Future<void> _setSnooze24h(Object? apptIdRaw) async {
    final apptId = _safeInt(apptIdRaw);
    if (apptId <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(hours: 24));
    await prefs.setInt(_kSnoozeKey(apptId), until.millisecondsSinceEpoch);
  }

  int _extractDoctorId(Map appointment) {
    final d = appointment['doctor'];
    if (d is Map) {
      final id = _safeInt(d['id']);
      if (id > 0) return id;

      final id2 = _safeInt(d['doctorId']);
      if (id2 > 0) return id2;

      final id3 = _safeInt(d['userId']);
      if (id3 > 0) return id3;
    }

    final direct = _safeInt(appointment['doctorId']);
    if (direct > 0) return direct;

    return 0;
  }

  String _extractDoctorName(Map appointment) {
    final d = appointment['doctor'];
    if (d is Map) {
      final name = _asStr(d['fullName']);
      if (name.isNotEmpty) return name;

      final name2 = _asStr(d['name']);
      if (name2.isNotEmpty) return name2;
    }
    final old = _asStr(appointment['doctorName']);
    if (old.isNotEmpty) return old;
    return 'Doctor';
  }

  String _extractSpecialty(Map appointment) {
    final d = appointment['doctor'];
    if (d is Map) {
      final s = _asStr(d['specialty']);
      if (s.isNotEmpty) return s;
    }
    return _asStr(appointment['specialty']);
  }

  bool _isAppointmentEnded(Map appointment) {
    final endsAt = _tryParseDate(appointment['endsAt']);
    if (endsAt != null) return endsAt.toLocal().isBefore(DateTime.now());

    final startsAt = _tryParseDate(appointment['startsAt']);
    if (startsAt == null) return false;

    final estimatedEnd = startsAt.toLocal().add(const Duration(minutes: 30));
    return estimatedEnd.isBefore(DateTime.now());
  }

  Future<bool> _isEligibleForRating(Map appointment) async {
    final appointmentId = _safeInt(appointment['id']);
    if (appointmentId <= 0) return false;

    final status = _asStr(appointment['status']);
    if (!_isConfirmedStatus(status)) return false;

    if (!_isAppointmentEnded(appointment)) return false;

    final rated = await _loadRatedIds();
    if (rated.contains(appointmentId)) return false;

    final snoozeUntil = await _getSnoozeUntil(appointmentId);
    if (snoozeUntil != null && snoozeUntil.isAfter(DateTime.now())) {
      return false;
    }

    return true;
  }

  Future<void> _maybePromptRating() async {
    if (_ratingSheetOpen) return;
    if (appointments.isEmpty) return;

    Map<String, dynamic>? eligible;

    for (final a in appointments) {
      if (a is! Map) continue;
      final appt = Map<String, dynamic>.from(a);

      final ok = await _isEligibleForRating(appt);
      if (ok) {
        eligible = appt;
        break;
      }
    }

    if (eligible == null) return;

    final appointmentId = _safeInt(eligible['id']);
    final doctorId = _extractDoctorId(eligible);
    final doctorName = _extractDoctorName(eligible);
    final specialty = _extractSpecialty(eligible);

    if (appointmentId <= 0) return;

    _ratingSheetOpen = true;
    try {
      await showRateDoctorBottomSheet(
        context: context,
        appointmentId: appointmentId,
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
        onRatedSuccessfully: () async {
          final rated = await _loadRatedIds();
          rated.add(appointmentId);
          await _saveRatedIds(rated);
          await _fetchAppointments();
        },
        onRateLater: () async {
          await _setSnooze24h(appointmentId);
        },
      );
    } finally {
      _ratingSheetOpen = false;
    }
  }

  Future<void> _openRatingSheetManually(Map appointment) async {
    final appointmentId = _safeInt(appointment['id']);
    final doctorId = _extractDoctorId(appointment);
    final doctorName = _extractDoctorName(appointment);
    final specialty = _extractSpecialty(appointment);

    if (appointmentId <= 0) return;

    await showRateDoctorBottomSheet(
      context: context,
      appointmentId: appointmentId,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      onRatedSuccessfully: () async {
        final rated = await _loadRatedIds();
        rated.add(appointmentId);
        await _saveRatedIds(rated);
        await _fetchAppointments();
      },
      onRateLater: () async {
        await _setSnooze24h(appointmentId);
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواعيدي')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : appointments.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      child: ListView(
                        children: const [
                          SizedBox(height: 220),
                          Center(child: Text('لا توجد مواعيد حالياً')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      color: Theme.of(context).primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final raw = appointments[index];
                          if (raw is! Map) return const SizedBox.shrink();

                          final appointment = Map<String, dynamic>.from(raw);

                          final doctorName = _extractDoctorName(appointment);
                          final specialty = _extractSpecialty(appointment);

                          final startsAt =
                              _tryParseDate(appointment['startsAt'])?.toLocal();
                          final endsAt =
                              _tryParseDate(appointment['endsAt'])?.toLocal();

                          final startsText = startsAt == null
                              ? _asStr(appointment['startsAt'])
                              : DateFormat('y/MM/dd • HH:mm').format(startsAt);

                          final endsText = endsAt == null
                              ? ''
                              : DateFormat('HH:mm').format(endsAt);

                          final status = _asStr(appointment['status']).isEmpty
                              ? 'Pending'
                              : _asStr(appointment['status']);

                          final bool confirmed = _isConfirmedStatus(status);
                          final bool ended = _isAppointmentEnded(appointment);

                          // الدفع
                          final paymentStatus =
                              _asStr(appointment['paymentStatus']);
                          final priceText = _asStr(appointment['price']);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: _statusColor(status)
                                          .withOpacity(0.15),
                                      child: Icon(
                                        Icons.calendar_month,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                    title: Text(
                                      'الدكتور: $doctorName',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      specialty.isEmpty
                                          ? ''
                                          : 'التخصص: $specialty',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    endsText.isEmpty
                                        ? 'الوقت: $startsText'
                                        : 'الوقت: $startsText → $endsText',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),

                                  // ===== الدفع =====
                                  if (paymentStatus.isNotEmpty ||
                                      priceText.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.payments_outlined,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 10,
                                            runSpacing: 6,
                                            children: [
                                              if (paymentStatus.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _paymentColor(
                                                            paymentStatus)
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    'الدفع: ${_paymentLabelAr(paymentStatus)}',
                                                    style: TextStyle(
                                                      color: _paymentColor(
                                                          paymentStatus),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              if (priceText.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black12
                                                        .withOpacity(0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    'السعر: $priceText',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (paymentStatus.isNotEmpty &&
                                        _canPayNow(paymentStatus) &&
                                        confirmed) ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    '🔜 سنربط زر الدفع قريباً مع Endpoint الدفع.'),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.credit_card),
                                          label: const Text('ادفع الآن'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1976D2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],

                                  const SizedBox(height: 8),

                                  // زر تقييم يدوي يظهر فقط إذا الموعد Confirmed وانتهى
                                  if (confirmed && ended)
                                    FutureBuilder<bool>(
                                      future: _isEligibleForRating(appointment),
                                      builder: (context, snap) {
                                        final eligible = snap.data == true;
                                        if (!eligible) {
                                          return const SizedBox.shrink();
                                        }

                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.star_rate_rounded,
                                              color: Colors.amber,
                                            ),
                                            label: const Text('قيّم الزيارة'),
                                            onPressed: () =>
                                                _openRatingSheetManually(
                                                    appointment),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

