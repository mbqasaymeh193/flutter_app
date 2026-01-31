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
  late TextEditingController educationCtrl;
  late TextEditingController clinicNameCtrl;
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
    educationCtrl = TextEditingController(text: d.education);
    clinicNameCtrl = TextEditingController(text: d.clinicName);
    clinicAddressCtrl = TextEditingController(text: d.clinicAddress);
    bioCtrl = TextEditingController(text: d.bio);
    yearsCtrl =
        TextEditingController(text: d.yearsOfExperience.toString());

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    phoneCtrl.dispose();
    specialtyCtrl.dispose();
    educationCtrl.dispose();
    clinicNameCtrl.dispose();
    clinicAddressCtrl.dispose();
    bioCtrl.dispose();
    yearsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // 🔒 لاحقًا: PUT /doctor/profile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التعديلات (محليًا مؤقتًا)')),
    );

    Navigator.pop(context);
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
                  _field('الدراسة / الجامعة', educationCtrl),
                  _field('اسم العيادة', clinicNameCtrl),
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
