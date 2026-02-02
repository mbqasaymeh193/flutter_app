// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// ✅ جاهزين لاستخدام routes لاحقاً

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? errorMessage;

  int? _updatingAppointmentId;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dynamic response = await ApiService.getDoctorAppointments();
      if (!mounted) return;

      List<dynamic> list = [];

      if (response is List) {
        list = List<dynamic>.from(response);
      } else if (response is Map && response['appointments'] is List) {
        list = List<dynamic>.from(response['appointments'] as List);
      } else if (response is Map && response['items'] is List) {
        list = List<dynamic>.from(response['items'] as List);
      } else {
        list = [];
      }

      setState(() {
        appointments = list;
        isLoading = false;
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

  // ====================== Helpers (Safe) ======================

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _safeStr(dynamic v) => (v ?? '').toString().trim();

  DateTime? _parseApiDate(String s) {
    final hasOffset = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(s);
    final normalized = hasOffset ? s : '${s}Z';
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;
    return parsed.toLocal();
  }

  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _safeBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  String _formatDateTime(dynamic isoString) {
    final s = _safeStr(isoString);
    if (s.isEmpty) return 'غير معروف';
    final dt = _parseApiDate(s);
    if (dt == null) return s;
    return DateFormat('y/MM/dd • HH:mm').format(dt);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================== Status (Text + Code) ======================

  String _normalizeStatusText(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'Confirmed';
    if (lower == 'rejected') return 'Rejected';
    if (lower == 'pending') return 'Pending';
    return s;
  }

  String _statusFromAny(dynamic v) {
    if (v is int) {
      switch (v) {
        case 0:
          return 'Pending';
        case 1:
          return 'Confirmed';
        case 2:
          return 'Rejected';
        default:
          return 'Pending';
      }
    }
    final s = _safeStr(v);
    return s.isEmpty ? 'Pending' : _normalizeStatusText(s);
  }

  bool _isPendingAny(dynamic v) {
    if (v is int) return v == 0;
    return _safeStr(v).toLowerCase() == 'pending';
  }

  String _statusLabel(String s) => _normalizeStatusText(s);

  String _statusLabelAr(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'مؤكد ✅';
    if (lower == 'rejected') return 'مرفوض ❌';
    if (lower == 'pending') return 'قيد الانتظار ⏳';
    return s;
  }

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

  // ====================== Payment ======================

  String _paymentLabelAr(dynamic s) {
    final v = _safeStr(s);
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

  Color _paymentColor(dynamic s) {
    final v = _safeStr(s).toLowerCase();
    if (v == 'captured') return Colors.green;
    if (v == 'authorized') return Colors.blue;
    if (v == 'failed') return Colors.red;
    if (v == 'released') return Colors.purple;
    return Colors.grey;
  }

  String _extractPaymentStatus(Map appointment) {
    final direct = _safeStr(appointment['paymentStatus']);
    if (direct.isNotEmpty) return direct;
    final payment = appointment['payment'];
    if (payment is Map) {
      final s = _safeStr(payment['status'] ?? payment['paymentStatus']);
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  bool _isPaymentAuthorized(String status) {
    final s = status.toLowerCase();
    return s == 'authorized' || s == 'captured';
  }

  bool _isPaymentRequired(Map appointment, double price) {
    final v = appointment['isPaymentRequired'] ?? appointment['paymentRequired'];
    if (_safeBool(v)) return true;
    return price > 0;
  }

  // ====================== Update Status (No Compile Type Errors) ======================

  Future<_UpdateResult> _callUpdateAppointmentStatus({
    required int appointmentId,
    required String statusText,
  }) async {
    final normalized = _normalizeStatusText(statusText);
    final res = await ApiService.updateAppointmentStatusDetailed(
      appointmentId: appointmentId,
      status: normalized,
    );

    if (res == null) {
      final fallback = await ApiService.updateAppointmentStatus(
        appointmentId,
        normalized,
      );
      return _UpdateResult(
        fallback == true,
        fallback == true ? '' : 'فشل في تحديث حالة الموعد',
      );
    }

    final ok = res['ok'] == true ||
        res['statusCode'] == 200 ||
        res['statusCode'] == 204;
    final msg = (res['message'] ??
            res['error'] ??
            res['title'] ??
            res['detail'])
        ?.toString();
    return _UpdateResult(ok, msg ?? '');
  }

  Future<void> _updateStatus(
    dynamic appointmentIdRaw,
    String statusText, {
    required bool paymentRequired,
    required String paymentStatus,
  }) async {
    if (_updatingAppointmentId != null) return;

    final int appointmentId = _safeInt(appointmentIdRaw);
    if (appointmentId <= 0) {
      _snack('رقم الموعد غير صحيح');
      return;
    }

    if (statusText.toLowerCase() == 'confirmed' &&
        paymentRequired &&
        !_isPaymentAuthorized(paymentStatus)) {
      _snack('لا يمكن تأكيد الموعد قبل الدفع المفوّض.');
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد العملية'),
        content: Text(
          statusText.toLowerCase() == 'confirmed'
              ? 'هل تريد تأكيد هذا الموعد؟'
              : 'هل تريد رفض هذا الموعد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _updatingAppointmentId = appointmentId);

    try {
      final result = await _callUpdateAppointmentStatus(
        appointmentId: appointmentId,
        statusText: statusText,
      );

      if (!mounted) return;

      if (result.ok) {
        _snack(
          statusText.toLowerCase() == 'confirmed'
              ? 'تم تأكيد الموعد ✅'
              : 'تم رفض الموعد ❌',
        );
        await _fetchAppointments();
      } else {
        _snack(result.message.isNotEmpty ? result.message : 'فشل في تحديث حالة الموعد');
      }
    } catch (_) {
      if (!mounted) return;
      _snack('حدث خطأ أثناء تحديث حالة الموعد');
    } finally {
      if (mounted) setState(() => _updatingAppointmentId = null);
    }
  }

  // ====================== Details Sheet ======================

  void _openDetailsSheet({
    required int appointmentId,
    required String patientName,
    required String startsAtText,
    required String statusText,
    required dynamic paymentStatus,
    required String priceText,
    required String patientPhone,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'تفاصيل الموعد #$appointmentId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text('المريض: ${patientName.isEmpty ? "غير معروف" : patientName}'),
            Text('الوقت: $startsAtText'),
            Text('الحالة: ${_statusLabelAr(statusText)}'),
            Text('الدفع: ${_paymentLabelAr(paymentStatus)}'),
            if (priceText.isNotEmpty) Text('السعر: $priceText'),
            if (patientPhone.isNotEmpty) Text('هاتف: $patientPhone'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ====================== UI ======================

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAppointments,
        child: ListView(
          children: const [
            SizedBox(height: 220),
            Center(child: Text('لا توجد مواعيد حالياً')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final raw = appointments[index];
          if (raw is! Map) return const SizedBox.shrink();
          final appointment = Map<String, dynamic>.from(raw);

          final patientMap = appointment['patient'];
          final patientName = (patientMap is Map)
              ? _safeStr(patientMap['fullName'])
              : _safeStr(appointment['patientName']);

          final patientPhone = (patientMap is Map)
              ? _safeStr(patientMap['phoneNumber'])
              : '';

          final startsAtText = _formatDateTime(appointment['startsAt']);

          final statusText = _statusFromAny(appointment['status']);
          final paymentStatus = _extractPaymentStatus(appointment);
          final priceValue = _safeDouble(appointment['price']);
          final priceText = _safeStr(appointment['price']);
          final paymentRequired = _isPaymentRequired(appointment, priceValue);

          final appointmentId = _safeInt(appointment['id']);
          final bool canChangeStatus = _isPendingAny(appointment['status']);
          final bool isUpdatingThis = _updatingAppointmentId == appointmentId;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x221976D2),
                child: Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              title: Text(
                patientName.isEmpty ? 'المريض: غير معروف' : 'المريض: $patientName',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('الوقت: $startsAtText'),
                  if (priceText.isNotEmpty) Text('السعر: $priceText'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _paymentColor(paymentStatus).withAlpha((0.15 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'الدفع: ${_paymentLabelAr(paymentStatus)}',
                          style: TextStyle(
                            color: _paymentColor(paymentStatus),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (patientPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('هاتف المريض: $patientPhone'),
                  ],
                ],
              ),
              onTap: () {
                _openDetailsSheet(
                  appointmentId: appointmentId,
                  patientName: patientName,
                  startsAtText: startsAtText,
                  statusText: statusText,
                  paymentStatus: paymentStatus,
                  priceText: priceText,
                  patientPhone: patientPhone,
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(statusText).withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(statusText),
                      style: TextStyle(
                        color: _statusColor(statusText),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isUpdatingThis)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: (canChangeStatus && appointmentId > 0)
                          ? () => _updateStatus(
                                appointmentId,
                                'confirmed',
                                paymentRequired: paymentRequired,
                                paymentStatus: paymentStatus,
                              )
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: (canChangeStatus && appointmentId > 0)
                          ? () => _updateStatus(
                                appointmentId,
                                'rejected',
                                paymentRequired: paymentRequired,
                                paymentStatus: paymentStatus,
                              )
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UpdateResult {
  final bool ok;
  final String message;

  const _UpdateResult(this.ok, this.message);
}
