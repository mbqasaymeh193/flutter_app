import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final int appointmentId;
  final double amount;
  final String? doctorName;
  final String? specialty;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
    this.doctorName,
    this.specialty,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'wallet';
  bool _loading = false;
  bool _walletLoading = true;
  double _walletBalance = 0.0;
  double _walletOnHold = 0.0;

  final TextEditingController _cardName = TextEditingController();
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _cardExp = TextEditingController();
  final TextEditingController _cardCvv = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _cardName.dispose();
    _cardNumber.dispose();
    _cardExp.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _walletLoading = true);

    final data = await ApiService.getMyWallet();
    if (!mounted) return;

    final map = data ?? <String, dynamic>{};
    _walletBalance = _toDouble(map['balance']);
    _walletOnHold = _toDouble(map['onHold']);

    setState(() => _walletLoading = false);
  }

  double _walletAvailable() {
    final v = _walletBalance - _walletOnHold;
    return v < 0 ? 0.0 : v;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> _pay() async {
    if (_loading) return;

    if (widget.appointmentId <= 0) {
      _snack('Invalid appointment.');
      return;
    }

    if (_method == 'wallet' && _walletAvailable() < widget.amount) {
      _snack('رصيد المحفظة غير كافٍ.');
      return;
    }

    if (_method == 'card') {
      if (_cardName.text.trim().isEmpty ||
          _cardNumber.text.trim().isEmpty ||
          _cardExp.text.trim().isEmpty ||
          _cardCvv.text.trim().isEmpty) {
        _snack('Please fill all card fields.');
        return;
      }
    }

    setState(() => _loading = true);

    final res = await ApiService.checkoutPayment(
      appointmentId: widget.appointmentId,
      method: _method,
      cardName: _method == 'card' ? _cardName.text.trim() : null,
      cardNumber: _method == 'card' ? _cardNumber.text.trim() : null,
      cardExp: _method == 'card' ? _cardExp.text.trim() : null,
      cardCvv: _method == 'card' ? _cardCvv.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res == null) {
      _snack('Payment failed. Please try again.');
      return;
    }

    final code = res['statusCode'];
    final ok = (code is int && (code == 200 || code == 201)) ||
        res['ok'] == true ||
        res['success'] == true;
    final msg = (res['message'] ??
            (ok ? 'Payment processed.' : 'Payment failed.'))
        .toString();

    _snack(msg);

    if (ok) {
      Navigator.pop(context, true);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.amount.toStringAsFixed(2);
    final availableText = _walletAvailable().toStringAsFixed(2);
    final insufficientWallet = _method == 'wallet' && _walletAvailable() < widget.amount;
    final payLabel = _method == 'wallet' ? 'ادفع الآن (محفظة)' : 'ادفع الآن (بطاقة)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWallet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('رقم الموعد: ${widget.appointmentId}'),
                    if ((widget.doctorName ?? '').trim().isNotEmpty)
                      Text('Doctor: ${widget.doctorName}'),
                    if ((widget.specialty ?? '').trim().isNotEmpty)
                      Text('Specialty: ${widget.specialty}'),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: $amountText',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _walletLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المحفظة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('الرصيد: ${_walletBalance.toStringAsFixed(2)}'),
                          Text('معلّق: ${_walletOnHold.toStringAsFixed(2)}'),
                          Text(
                            'متاح: $availableText',
                            style: TextStyle(
                              color: insufficientWallet ? Colors.red : Colors.black87,
                              fontWeight: insufficientWallet ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر طريقة الدفع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'wallet',
                  label: Text('المحفظة'),
                  icon: Icon(Icons.account_balance_wallet),
                ),
                ButtonSegment(
                  value: 'card',
                  label: Text('بطاقة (Visa Demo)'),
                  icon: Icon(Icons.credit_card),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (value) {
                setState(() => _method = value.first);
              },
            ),
            const SizedBox(height: 8),
            if (_method == 'card') ...[
              TextField(
                controller: _cardName,
                decoration: const InputDecoration(
                  labelText: 'اسم صاحب البطاقة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cardNumber,
                decoration: const InputDecoration(
                  labelText: 'رقم البطاقة',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExp,
                      decoration: const InputDecoration(
                        labelText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cardCvv,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'قاعدة الديمو: إذا أي حقل = "0" يفشل الدفع.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading || insufficientWallet ? null : _pay,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(payLabel),
              ),
            ),
            if (insufficientWallet) ...[
              const SizedBox(height: 8),
              const Text(
                'رصيد المحفظة غير كافٍ لإتمام الدفع.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
