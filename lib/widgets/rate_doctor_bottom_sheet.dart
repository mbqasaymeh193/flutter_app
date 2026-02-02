import 'package:flutter/material.dart';
import '../services/api_service.dart';

Future<void> showRateDoctorBottomSheet({
  required BuildContext context,
  required int appointmentId,
  required int doctorId,
  required String doctorName,
  required String specialty,
  required void Function() onRatedSuccessfully,
  required void Function() onRateLater,
}) async {
  final result = await showModalBottomSheet<_RateSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) {
      return _RateDoctorSheet(
        appointmentId: appointmentId,
        doctorId: doctorId,
        doctorName: doctorName,
        specialty: specialty,
        onRatedSuccessfully: onRatedSuccessfully,
        onResult: (r) => Navigator.pop(context, r),
      );
    },
  );

  if (result != _RateSheetResult.rated) {
    onRateLater();
  }
}

enum _RateSheetResult { rated, later }

class _RateDoctorSheet extends StatefulWidget {
  final int appointmentId;
  final int doctorId;
  final String doctorName;
  final String specialty;

  final void Function() onRatedSuccessfully;
  final void Function(_RateSheetResult result) onResult;

  const _RateDoctorSheet({
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.onRatedSuccessfully,
    required this.onResult,
  });

  @override
  State<_RateDoctorSheet> createState() => _RateDoctorSheetState();
}

class _RateDoctorSheetState extends State<_RateDoctorSheet> {
  int _stars = 5;
  bool _sending = false;
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;

    setState(() => _sending = true);

    final res = await ApiService.submitDoctorRatingDetailed(
      appointmentId: widget.appointmentId,
      stars: _stars,
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
    );

    if (!mounted) return;

    setState(() => _sending = false);

    final ok = res?['ok'] == true ||
        res?['statusCode'] == 200 ||
        res?['statusCode'] == 201;
    final msg = (res?['message'] ??
            res?['error'] ??
            res?['title'] ??
            res?['detail'])
        ?.toString()
        .trim();

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg?.isNotEmpty == true ? msg! : 'تم إرسال التقييم بنجاح')),
      );
      widget.onResult(_RateSheetResult.rated);
      widget.onRatedSuccessfully();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg?.isNotEmpty == true
                ? msg!
                : 'فشل إرسال التقييم، حاول مرة أخرى.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottom + 16, top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review, color: Color(0xFF1976D2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'قيّم زيارتك',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0x221976D2),
                  child: const Icon(Icons.person, color: Color(0xFF1976D2)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // اختيار النجوم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final index = i + 1;
              final selected = index <= _stars;
              return IconButton(
                onPressed: () => setState(() => _stars = index),
                icon: Icon(
                  selected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
              );
            }),
          ),

          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقًا (اختياري)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onResult(_RateSheetResult.later);
                  },
                  child: const Text('تقييم لاحقًا'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('إرسال'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
