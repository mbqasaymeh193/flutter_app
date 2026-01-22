import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorAddMedicalRecordScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  // ✅ إذا موجود => تعديل، إذا null => إنشاء
  final int? recordId;

  // ✅ قيم ابتدائية عند التعديل
  final String? initialDiagnosis;
  final String? initialNotes;
  final String? initialMedication;
  final String? initialAllergies;
  final String? initialSideEffects;

  // (اختياري)
  final int? appointmentId;

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
    this.appointmentId,
  });

  @override
  State<DoctorAddMedicalRecordScreen> createState() =>
      _DoctorAddMedicalRecordScreenState();
}

class _DoctorAddMedicalRecordScreenState
    extends State<DoctorAddMedicalRecordScreen> {
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

  String? _emptyToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final diagnosis = _diagnosis.text.trim();
      final notes = _notes.text.trim();

      final medication = _emptyToNull(_medication.text);
      final allergies = _emptyToNull(_allergies.text);
      final sideEffects = _emptyToNull(_sideEffects.text);

      bool ok;

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
          SnackBar(
            content: Text(_isEdit
                ? 'تم تحديث السجل الطبي ✅'
                : 'تم حفظ السجل الطبي ✅'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'فشل تحديث السجل الطبي ❌'
                : 'فشل حفظ السجل الطبي ❌'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ السجل')),
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
    final subtitle = _isEdit
        ? 'تعديل سجل موجود'
        : (widget.appointmentId == null
            ? 'سيتم إنشاء سجل للمريض المختار'
            : 'موعد رقم #${widget.appointmentId}');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل سجل طبي' : 'إضافة سجل طبي'),
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
                  subtitle: Text(subtitle),
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
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Diagnosis مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notes,
                        decoration: _dec('Notes', hint: 'ملاحظات الطبيب'),
                        minLines: 3,
                        maxLines: 6,
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
                              : Icon(_isEdit ? Icons.check : Icons.save),
                          label: Text(_loading
                              ? 'Saving...'
                              : (_isEdit ? 'Update Medical Record' : 'Save Medical Record')),
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
