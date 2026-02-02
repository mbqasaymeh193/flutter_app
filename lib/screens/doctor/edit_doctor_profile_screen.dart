import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/doctor_profile.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  const EditDoctorProfileScreen({super.key});

  @override
  State<EditDoctorProfileScreen> createState() =>
      _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController fullNameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController specialtyCtrl;
  late TextEditingController universityCtrl;
  late TextEditingController qualificationCtrl;
  late TextEditingController clinicAddressCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController yearsCtrl;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final DoctorProfile d = await ApiService.getDoctorProfile();

    fullNameCtrl = TextEditingController(text: d.fullName);
    phoneCtrl = TextEditingController(text: d.phoneNumber);
    specialtyCtrl = TextEditingController(text: d.specialty);
    universityCtrl = TextEditingController(text: d.university);
    qualificationCtrl = TextEditingController(text: d.qualification);
    clinicAddressCtrl = TextEditingController(text: d.clinicAddress);
    bioCtrl = TextEditingController(text: d.bio);
    yearsCtrl = TextEditingController(text: d.experienceYears.toString());

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    phoneCtrl.dispose();
    specialtyCtrl.dispose();
    universityCtrl.dispose();
    qualificationCtrl.dispose();
    clinicAddressCtrl.dispose();
    bioCtrl.dispose();
    yearsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      "university": universityCtrl.text.trim(),
      "qualification": qualificationCtrl.text.trim(),
      "clinicAddress": clinicAddressCtrl.text.trim(),
      "bio": bioCtrl.text.trim(),
      "experienceYears": int.tryParse(yearsCtrl.text.trim()) ?? 0,
      // optional extras (ignored if backend doesn't support them)
      "fullName": fullNameCtrl.text.trim(),
      "phoneNumber": phoneCtrl.text.trim(),
      "specialty": specialtyCtrl.text.trim(),
    };

    final ok = await ApiService.updateDoctorProfile(payload);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حفظ التعديلات بنجاح' : 'فشل حفظ التعديلات'),
      ),
    );

    if (ok) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل حساب الطبيب')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field('الاسم الكامل', fullNameCtrl),
                  _field('رقم الهاتف', phoneCtrl),
                  _field('التخصص', specialtyCtrl),
                  _field('الجامعة', universityCtrl),
                  _field('المؤهل', qualificationCtrl),
                  _field('عنوان العيادة', clinicAddressCtrl),
                  _field(
                    'نبذة تعريفية',
                    bioCtrl,
                    maxLines: 3,
                  ),
                  _field(
                    'سنوات الخبرة',
                    yearsCtrl,
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('حفظ التغييرات'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (v) =>
            v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
