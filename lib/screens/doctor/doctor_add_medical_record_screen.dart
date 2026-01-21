import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorAddMedicalRecordScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  // ✅ edit mode (اختياري)
  final int? recordId;
  final String? initialDiagnosis;
  final String? initialNotes;
  final String? initialMedication;
  final String? initialAllergies;
  final String? initialSideEffects;

  const DoctorAddMedicalRecordScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.recordId,
    this.initialDiagnosis,
    this.initialNotes,
    this.initialMedication,
    this.initialAllergies,
    this.initialSideEffects,
  });

  @override
  State<DoctorAddMedicalRecordScreen> createState() => _DoctorAddMedicalRecordScreenState();
}

class _DoctorAddMedicalRecordScreenState extends State<DoctorAddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _diagnosis;
  late final TextEditingController _notes;
  late final TextEditingController _medication;
  late final TextEditingController _allergies;
  late final TextEditingController _sideEffects;

  bool _loading = false;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    _diagnosis = TextEditingController(text: widget.initialDiagnosis ?? '');
    _notes = TextEditingController(text: widget.initialNotes ?? '');
    _medication = TextEditingController(text: widget.initialMedication ?? '');
    _allergies = TextEditingController(text: widget.initialAllergies ?? '');
    _sideEffects = TextEditingController(text: widget.initialSideEffects ?? '');
  }

  @override
  void dispose() {
    _diagnosis.dispose();
    _notes.dispose();
    _medication.dispose();
    _allergies.dispose();
    _sideEffects.dispose();
    super.dispose();
  }

  String? _req(String? v, String msg) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final diagnosis = _diagnosis.text.trim();
    final notes = _notes.text.trim();
    final medication = _medication.text.trim().isEmpty ? null : _medication.text.trim();
    final allergies = _allergies.text.trim().isEmpty ? null : _allergies.text.trim();
    final sideEffects = _sideEffects.text.trim().isEmpty ? null : _sideEffects.text.trim();

    try {
      final bool ok;

      if (_isEdit) {
        ok = await ApiService.updateMedicalRecord(
          recordId: widget.recordId!,
          diagnosis: diagnosis,
          notes: notes,
          medication: medication,
          allergies: allergies,
          sideEffects: sideEffects,
        );
      } else {
        ok = await ApiService.createMedicalRecord(
          patientId: widget.patientId,
          diagnosis: diagnosis,
          notes: notes,
          medication: medication,
          allergies: allergies,
          sideEffects: sideEffects,
        );
      }

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'تم تعديل السجل ✅' : 'تم حفظ السجل الطبي ✅')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'فشل تعديل السجل ❌' : 'فشل حفظ السجل ❌')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء العملية')),
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل سجل طبي' : 'إضافة سجل طبي')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(widget.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_isEdit ? 'تعديل السجل رقم #${widget.recordId}' : 'إنشاء سجل جديد للمريض'),
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
                        decoration: _dec('Diagnosis', hint: 'مثال: Flu, Allergy...'),
                        validator: (v) => _req(v, 'Diagnosis مطلوب'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notes,
                        decoration: _dec('Notes', hint: 'ملاحظات الطبيب'),
                        minLines: 3,
                        maxLines: 6,
                        validator: (v) => _req(v, 'Notes مطلوبة'),
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save),
                          label: Text(_loading ? 'Saving...' : (_isEdit ? 'Update Medical Record' : 'Save Medical Record')),
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
