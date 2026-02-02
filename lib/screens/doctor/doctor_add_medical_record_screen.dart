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

  // ✅ مهم عند الإنشاء
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

  bool get _hasValidAppointmentForCreate =>
      widget.appointmentId != null && widget.appointmentId! > 0;

  bool get _canSubmit => !_loading && (_isEdit || _hasValidAppointmentForCreate);

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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    if (!_formKey.currentState!.validate()) return;

    // ✅ منع إنشاء سجل بدون appointmentId
    if (!_isEdit && !_hasValidAppointmentForCreate) {
      _snack('لا يمكن إنشاء سجل طبي بدون رقم موعد صحيح.');
      return;
    }

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
          appointmentId: widget.appointmentId!, // ✅ الحل هنا
          diagnosis: diagnosis,
          notes: notes,
          medication: medication,
          allergies: allergies,
          sideEffects: sideEffects,
        );
      }

      if (!mounted) return;

      if (ok) {
        _snack(_isEdit ? 'تم تحديث السجل الطبي ✅' : 'تم حفظ السجل الطبي ✅');
        Navigator.pop(context, true);
      } else {
        _snack(_isEdit ? 'فشل تحديث السجل الطبي ❌' : 'فشل حفظ السجل الطبي ❌');
      }
    } catch (_) {
      if (!mounted) return;
      _snack('حدث خطأ أثناء حفظ السجل');
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
        : (_hasValidAppointmentForCreate
            ? 'موعد رقم #${widget.appointmentId}'
            : '⚠️ لا يوجد رقم موعد (لن يمكن الحفظ)');

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

              if (!_isEdit && !_hasValidAppointmentForCreate) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.08 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha((0.25 * 255).round())),
                  ),
                  child: const Text(
                    'لا يمكن إنشاء سجل طبي إلا إذا كان هناك appointmentId صحيح.\n'
                    'افتح هذه الشاشة من تفاصيل موعد مؤكد/محدد (Appointment) ثم أعد المحاولة.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _diagnosis,
                        decoration: _dec('Diagnosis', hint: 'مثال: Flu, Allergy...'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Diagnosis مطلوب' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notes,
                        decoration: _dec('Notes', hint: 'ملاحظات الطبيب'),
                        minLines: 3,
                        maxLines: 6,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Notes مطلوبة' : null,
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
                          label: Text(
                            _loading
                                ? 'Saving...'
                                : (_isEdit ? 'Update Medical Record' : 'Save Medical Record'),
                          ),
                          onPressed: _canSubmit ? _submit : null,
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
