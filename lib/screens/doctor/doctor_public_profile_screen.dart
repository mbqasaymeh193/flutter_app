import 'package:flutter/material.dart';
import '../../models/doctor_profile.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/star_rating.dart';

class DoctorPublicProfileScreen extends StatelessWidget {
  final DoctorProfile doctor;

  const DoctorPublicProfileScreen({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    final String specialty = _safe(doctor.specialty);
    final String education = _safe(doctor.education);
    final String clinicName = _safe(doctor.clinicName);
    final String clinicAddress = _safe(doctor.clinicAddress);
    final String bio = _safe(doctor.bio);
    final int years = _safeInt(doctor.yearsOfExperience);

    // مهم جداً:
    // في الـ Backend endpoint /api/doctors يرجع d.Id (DoctorId)
    // لذلك الأفضل تمرير doctor.id وليس userId
    // ✅ تصحيح الخطأ: كانت doctor. بدون اسم خاصية
    // ✅ مع fallback إذا الموديل لا يحتوي id
    final int doctorId = _resolveDoctorId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الطبيب'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 16),

          _rating(context),
          const Divider(height: 32),

          _infoRow(Icons.work_outline, 'التخصص', specialty),
          _infoRow(Icons.school_outlined, 'الدراسة', education),
          _infoRow(Icons.timeline_outlined, 'سنوات الخبرة', '$years سنة'),
          _infoRow(Icons.local_hospital_outlined, 'العيادة', clinicName),
          _infoRow(Icons.location_on_outlined, 'الموقع', clinicAddress),

          const SizedBox(height: 20),

          Text(
            'نبذة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            bio.isEmpty ? 'لا توجد نبذة' : bio,
            style: const TextStyle(color: Colors.black87),
          ),

          const SizedBox(height: 24),

          // زر الحجز (مصَحَّح)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('حجز موعد'),
              onPressed: () {
                if (doctorId <= 0) {
                  _showSnack(context, 'خطأ: رقم الطبيب غير صحيح.');
                  return;
                }

                Navigator.pushNamed(
                  context,
                  AppRoutes.bookAppointment,
                  arguments: {
                    // مهم: هذا هو DoctorId الذي يحتاجه:
                    // GET /api/doctors/{doctorId}/available-slots
                    // POST /api/appointments/book (DoctorId)
                    'doctorId': doctorId,

                    // لعرضها في شاشة الحجز:
                    'doctorName': _safe(doctor.fullName),
                    'specialty': specialty,

                    // اختيارياً (قد تستفيد منها UI)
                    'clinicName': clinicName,
                    'clinicAddress': clinicAddress,
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // تحسين بسيط: زر معاينة (اختياري) يجهزنا للـ endpoint الجديد available-slots
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time),
            label: const Text('عرض الأوقات المتاحة (قريباً)'),
            onPressed: () {
              // حالياً مجرد رسالة — في الخطوة القادمة سنربطه بـ:
              // GET /api/doctors/{doctorId}/available-slots?date=yyyy-MM-dd
              _showSnack(
                context,
                'سنربط هذا الزر قريباً بجدول الأوقات المتاحة من السيرفر.',
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= UI أجزاء =================

  Widget _header(BuildContext context) {
    final String name = _safe(doctor.fullName);
    final String specialty = _safe(doctor.specialty);

    return Row(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, size: 40),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'اسم غير متوفر' : name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                specialty.isEmpty ? 'تخصص غير متوفر' : specialty,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rating(BuildContext context) {
    final double avg = _safeDouble(doctor.averageRating);
    final int count = _safeInt(doctor.ratingsCount);

    return StarRating(
      rating: avg,
      count: count,
      showValue: true,
      label: 'التقييم',
      size: 22,
    );
  }

  Widget _stars(double value) {
    final int full = value.floor();

    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < full ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    final String v = value.trim().isEmpty ? 'غير متوفر' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $v',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= Helpers (بدون اختصارات غامضة) =================

  String _safe(String? v) => (v ?? '').trim();

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ================= DoctorId Resolver =================
  // الهدف: استخدم DoctorId الحقيقي (الـ id القادم من جدول Doctors)
  // لو موديل DoctorProfile عندك يحتوي id => ممتاز
  // لو لا، نستخدم userId كحل مؤقت حتى نصلّح الموديل/التحويل
  int _resolveDoctorId() {
    // 1) أفضل خيار
    try {
      // إذا الموديل فيه id
      final dynamic maybeId = (doctor as dynamic).id;
      final int id = _safeInt(maybeId);
      if (id > 0) return id;
    } catch (_) {
      // تجاهل
    }

    // 2) fallback: userId (لو موجود) — ليس الأفضل لكن يمنع الكراش
    try {
      final dynamic maybeUserId = (doctor as dynamic).userId;
      final int uid = _safeInt(maybeUserId);
      if (uid > 0) return uid;
    } catch (_) {
      // تجاهل
    }

    return 0;
  }
}
