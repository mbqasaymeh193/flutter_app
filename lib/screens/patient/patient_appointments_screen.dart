import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../widgets/rate_doctor_bottom_sheet.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/notification_bell.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final bool embedded;

  const PatientAppointmentsScreen({super.key, this.embedded = false});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? errorMessage;

  bool _walletLoading = true;
  double _walletBalance = 0.0;
  double _walletOnHold = 0.0;

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
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _walletLoading = true);

    final data = await ApiService.getMyWallet();
    if (!mounted) return;

    final map = data ?? <String, dynamic>{};
    _walletBalance = _asDouble(map['balance']);
    _walletOnHold = _asDouble(map['onHold']);

    setState(() => _walletLoading = false);
  }

  double _walletAvailable() {
    final v = _walletBalance - _walletOnHold;
    return v < 0 ? 0.0 : v;
  }

  // ================= Safe Helpers =================
  String _asStr(dynamic v) => (v ?? '').toString().trim();

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  DateTime? _tryParseDate(dynamic v) {
    final s = _asStr(v);
    if (s.isEmpty) return null;
    return _parseApiDate(s);
  }

  DateTime? _parseApiDate(String s) {
    final hasOffset = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(s);
    final normalized = hasOffset ? s : '${s}Z';
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;
    return parsed.toLocal();
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _walletCard() {
    final availableText = _walletAvailable().toStringAsFixed(2);
    final balanceText = _walletBalance.toStringAsFixed(2);
    final onHoldText = _walletOnHold.toStringAsFixed(2);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _walletLoading ? null : _loadWallet,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x221976D2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المحفظة',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('متاح: $availableText'),
                    Text(
                      'الرصيد: $balanceText • معلّق: $onHoldText',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (_walletLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
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
    if (!mounted) return;

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

  Future<void> _refreshAll() async {
    await _fetchAppointments();
    await _loadWallet();
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

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final doctorName = _extractDoctorName(appointment);
    final specialty = _extractSpecialty(appointment);

    final startsAt = _tryParseDate(appointment['startsAt'])?.toLocal();
    final endsAt = _tryParseDate(appointment['endsAt'])?.toLocal();

    final startsText = startsAt == null
        ? _asStr(appointment['startsAt'])
        : DateFormat('y/MM/dd • HH:mm').format(startsAt);

    final endsText = endsAt == null ? '' : DateFormat('HH:mm').format(endsAt);

    final status = _asStr(appointment['status']).isEmpty
        ? 'Pending'
        : _asStr(appointment['status']);

    final bool confirmed = _isConfirmedStatus(status);
    final bool ended = _isAppointmentEnded(appointment);

    final payment = appointment['payment'];
    final rawPaymentStatus = _asStr(appointment['paymentStatus']);
    final paymentStatus = rawPaymentStatus.isNotEmpty
        ? rawPaymentStatus
        : (payment is Map ? _asStr(payment['status']) : '');

    final paymentRequired = _asBool(
      appointment['isPaymentRequired'] ?? appointment['paymentRequired'],
    );

    final priceRaw = appointment['price'] ??
        (payment is Map ? payment['amount'] : null) ??
        appointment['amount'];
    final priceText = _asStr(priceRaw);

    final effectivePaymentStatus =
        paymentStatus.isEmpty && paymentRequired ? 'pending' : paymentStatus;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    _statusColor(status).withAlpha((0.15 * 255).round()),
                child: Icon(
                  Icons.calendar_month,
                  color: _statusColor(status),
                ),
              ),
              title: Text(
                'الدكتور: $doctorName',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                specialty.isEmpty ? '' : 'التخصص: $specialty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status)
                      .withAlpha((0.12 * 255).round()),
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            // ===== الدفع =====
            if (effectivePaymentStatus.isNotEmpty ||
                priceText.isNotEmpty ||
                paymentRequired) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        if (paymentRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange
                                  .withAlpha((0.12 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'الدفع مطلوب',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (effectivePaymentStatus.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _paymentColor(paymentStatus)
                                  .withAlpha((0.12 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'الدفع: ${_paymentLabelAr(effectivePaymentStatus)}',
                              style: TextStyle(
                                color:
                                    _paymentColor(effectivePaymentStatus),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (priceText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black12
                                  .withAlpha((0.08 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'السعر: $priceText',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_canPayNow(effectivePaymentStatus) &&
                  (paymentRequired || effectivePaymentStatus.isNotEmpty)) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final appointmentId = _safeInt(appointment['id']);
                      if (appointmentId <= 0) {
                        _showSnack('رقم الموعد غير صالح للدفع.');
                        return;
                      }

                      final amount = _asDouble(priceRaw);

                      Navigator.pushNamed(
                        context,
                        AppRoutes.payment,
                        arguments: {
                          'appointmentId': appointmentId,
                          'amount': amount,
                          'doctorName': doctorName,
                          'specialty': specialty,
                        },
                    ).then((value) {
                      if (value == true) {
                        _refreshAll();
                      }
                    });
                  },
                    icon: const Icon(Icons.credit_card),
                    label: const Text('ادفع الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      onPressed: () => _openRatingSheetManually(appointment),
                    ),
                  );
                },
              ),
            if (confirmed && !ended)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'التقييم متاح بعد انتهاء الموعد.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _refreshAll,
        color: Theme.of(context).primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _walletCard(),
            const SizedBox(height: 12),
            if (errorMessage != null) ...[
              const SizedBox(height: 120),
              Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else if (appointments.isEmpty) ...[
              const SizedBox(height: 160),
              const Center(child: Text('لا توجد مواعيد حالياً')),
            ] else ...[
              ...appointments.whereType<Map>().map((raw) {
                final appt = Map<String, dynamic>.from(raw);
                return _buildAppointmentCard(appt);
              }),
            ],
          ],
        ),
      );
    }

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواعيدي'),
        actions: const [NotificationBell()],
      ),
      body: body,
    );
  }
}

