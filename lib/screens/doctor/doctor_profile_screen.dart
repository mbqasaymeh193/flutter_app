import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/doctor_profile.dart';
import '../../core/routes/app_routes.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DoctorProfile>(
      future: ApiService.getDoctorProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final d = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Header =====
            Text(
              d.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              d.specialty,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),
            const Divider(),

            _infoRow(Icons.phone, d.phoneNumber),
            _infoRow(Icons.school, d.university),
            _infoRow(Icons.workspace_premium, d.qualification),
            _infoRow(Icons.location_on, d.clinicAddress),
            _infoRow(Icons.work_outline, '${d.experienceYears} سنوات خبرة'),

            const SizedBox(height: 12),
            Text(
              d.bio,
              style: const TextStyle(height: 1.4),
            ),

            const SizedBox(height: 16),

            // ===== Rating =====
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade600),
                const SizedBox(width: 6),
                Text(
                  '${d.averageRating.toStringAsFixed(1)} / 5',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${d.ratingsCount} تقييم)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'التقييم مبني على آراء المرضى بعد الزيارة.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),

            const SizedBox(height: 24),

            // ===== Edit Button =====
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('تعديل البيانات'),
              onPressed: () {
                Navigator.pushNamed(context, '/edit-doctor-profile');
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('ساعات الدوام'),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.doctorWorkingHours);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
