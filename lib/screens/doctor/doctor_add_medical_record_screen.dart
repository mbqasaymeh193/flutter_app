import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorAddMedicalRecordScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  final int? appointmentId; // اختياري (للواجهة فقط الآن)

  const DoctorAddMedicalRecordScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
  });

  @override
  State<DoctorAddMedicalRecordScreen> createState() =>
      _DoctorAddMedicalRecordScreenState();
}

class _DoctorAddMedicalRecordScreenState
    extends State<DoctorAddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  final _medication = TextEditingController();
  final _allergies = TextEditingController();
  final _sideEffects = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _diagnosis.dispose();
    _notes.dispose();
    _medication.dispose();
    _allergies.dispose();
    _sideEffects.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return; // ✅ منع ضغط متكرر
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);

    try {
      final ok = await ApiService.createMedicalRecord(
        patientId: widget.patientId,
        diagnosis: _diagnosis.text.trim(),
        notes: _notes.text.trim(),
        medication:
            _medication.text.trim().isEmpty ? null : _medication.text.trim(),
        allergies:
            _allergies.text.trim().isEmpty ? null : _allergies.text.trim(),
        sideEffects:
            _sideEffects.text.trim().isEmpty ? null : _sideEffects.text.trim(),
      );

      if (!mounted) return;

      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السجل الطبي ✅')),
        );
        Navigator.pop(context, true); // ✅ يرجّع true للشاشة السابقة تعمل Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ السجل الطبي ❌')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.appointmentId == null
        ? 'سيتم إنشاء سجل للمريض المختار'
        : 'موعد رقم #${widget.appointmentId}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة سجل طبي'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    widget.patientName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('$subtitle • Patient ID: ${widget.patientId}'),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _diagnosis,
                        decoration:
                            _dec('Diagnosis', hint: 'مثال: Flu, Allergy...'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Diagnosis مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notes,
                        decoration: _dec('Notes', hint: 'ملاحظات الطبيب'),
                        minLines: 3,
                        maxLines: 7,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Notes مطلوبة'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _medication,
                        decoration: _dec('Medication (اختياري)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _allergies,
                        decoration: _dec('Allergies (اختياري)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _sideEffects,
                        decoration: _dec('Side Effects (اختياري)'),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_loading ? 'Saving...' : 'Save Medical Record'),
                          onPressed: _loading ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
