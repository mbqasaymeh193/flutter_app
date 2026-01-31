import 'package:flutter/material.dart';
import '../../models/doctor_profile.dart';

class DoctorPublicProfileScreen extends StatelessWidget {
  final DoctorProfile doctor;

  const DoctorPublicProfileScreen({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملف الطبيب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 16),
          _rating(),
          const Divider(height: 32),
          _infoRow(Icons.work_outline, 'التخصص', doctor.specialty),
          _infoRow(Icons.school_outlined, 'الدراسة', doctor.education),
          _infoRow(Icons.timeline_outlined, 'سنوات الخبرة',
              '${doctor.yearsOfExperience} سنة'),
          _infoRow(Icons.local_hospital_outlined, 'العيادة',
              doctor.clinicName),
          _infoRow(Icons.location_on_outlined, 'الموقع',
              doctor.clinicAddress),
          const SizedBox(height: 20),
          Text(
            'نبذة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            doctor.bio.isEmpty ? 'لا توجد نبذة' : doctor.bio,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: const Text('حجز موعد'),
            onPressed: () {
              // لاحقًا: الانتقال لشاشة الحجز
            ElevatedButton.icon(
  icon: const Icon(Icons.calendar_month),
  label: const Text('حجز موعد'),
  onPressed: () {
    Navigator.pushNamed(
      context,
      AppRoutes.bookAppointment,
      arguments: {
        'doctorId': doctor.userId,
        'doctorName': doctor.fullName,
        'specialty': doctor.specialty,
      },
    );
  },
),
  
            },
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
                doctor.fullName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialty,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rating() {
    return Row(
      children: [
        _stars(doctor.averageRating),
        const SizedBox(width: 8),
        Text(
          '${doctor.averageRating.toStringAsFixed(1)}'
          ' (${doctor.ratingsCount} تقييم)',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $value',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
