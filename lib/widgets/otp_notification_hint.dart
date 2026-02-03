import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healthcare_flutter_app/services/notification_store.dart';

class OtpNotificationHint extends StatefulWidget {
  final ValueChanged<String>? onFill;

  const OtpNotificationHint({
    super.key,
    this.onFill,
  });

  @override
  State<OtpNotificationHint> createState() => _OtpNotificationHintState();
}

class _OtpNotificationHintState extends State<OtpNotificationHint> {
  String? _code;
  bool _visible = true;
  bool _loading = false;
  Timer? _autoHide;
  late final VoidCallback _itemsListener;

  @override
  void initState() {
    super.initState();
    _itemsListener = _handleItemsChanged;
    NotificationStore.instance.items.addListener(_itemsListener);
    _handleItemsChanged();
  }

  @override
  void dispose() {
    NotificationStore.instance.items.removeListener(_itemsListener);
    _autoHide?.cancel();
    super.dispose();
  }

  void _handleItemsChanged() {
    if (!mounted) return;
    setState(() => _loading = true);

    final list = NotificationStore.instance.items.value;
    final code = _extractLatestOtp(list);
    if (code == null) {
      setState(() {
        _code = null;
        _visible = false;
        _loading = false;
      });
      return;
    }

    if (code != _code) {
      setState(() {
        _code = code;
        _visible = true;
        _loading = false;
      });
      _startAutoHide();
    } else {
      setState(() => _loading = false);
    }
  }

  String? _extractLatestOtp(List<dynamic> list) {
    String? bestCode;
    DateTime? bestDate;

    for (final n in list) {
      if (n is! Map) continue;
      final msg = (n['message'] ?? '').toString().trim();
      final code = _extractOtpFromMessage(msg);
      if (code == null) continue;

      final dt = _parseDate(n['createdAt'] ?? n['createdAtUtc']);
      if (bestDate == null && bestCode == null) {
        bestCode = code;
        bestDate = dt;
        continue;
      }

      if (dt != null && bestDate != null && dt.isAfter(bestDate)) {
        bestCode = code;
        bestDate = dt;
      } else if (bestDate == null && dt != null) {
        bestCode = code;
        bestDate = dt;
      }
    }

    return bestCode;
  }

  String? _extractOtpFromMessage(String msg) {
    if (msg.isEmpty) return null;

    // إذا الرسالة عبارة عن رقم فقط
    if (RegExp(r'^\d{4,8}$').hasMatch(msg)) {
      return msg;
    }

    // تحقّق من كلمات مفتاحية حتى لا نلتقط أرقام غير متعلقة بالـ OTP
    final lower = msg.toLowerCase();
    final looksLikeOtp = lower.contains('otp') ||
        lower.contains('code') ||
        lower.contains('reset') ||
        lower.contains('password') ||
        lower.contains('verification') ||
        msg.contains('رمز') ||
        msg.contains('كود') ||
        msg.contains('تحقق') ||
        msg.contains('التحقق');

    if (!looksLikeOtp) return null;

    // استخراج أول رمز 4-8 أرقام من النص
    final match = RegExp(r'(?<!\d)(\d{4,8})(?!\d)').firstMatch(msg);
    return match?.group(1);
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final hasOffset = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(s);
    final normalized = hasOffset ? s : '${s}Z';
    final parsed = DateTime.tryParse(normalized);
    return parsed?.toLocal();
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الرمز')),
    );
  }

  void _startAutoHide() {
    _autoHide?.cancel();
    _autoHide = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_code == null || !_visible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x221976D2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            size: 18,
            color: Color(0xFF1976D2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'رمز التحقق: $_code',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (widget.onFill != null)
            TextButton(
              onPressed: () => widget.onFill!(_code!),
              child: const Text('لصق'),
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'نسخ',
            onPressed: _loading ? null : () => _copy(_code!),
          ),
        ],
      ),
    );
  }
}
