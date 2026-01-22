import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'doctor_add_medical_record_screen.dart';

class PatientMedicalRecordsForDoctorScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientMedicalRecordsForDoctorScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientMedicalRecordsForDoctorScreen> createState() =>
      _PatientMedicalRecordsForDoctorScreenState();
}

class _PatientMedicalRecordsForDoctorScreenState
    extends State<PatientMedicalRecordsForDoctorScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(dynamic v) {
    if (v == null) return '-';
    final s = v.toString();
    final dt = DateTime.tryParse(s);
    if (dt == null) {
      // fallback بسيط
      return s.length > 10 ? s.substring(0, 10) : s;
    }
    return DateFormat('y/MM/dd • HH:mm').format(dt.toLocal());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await ApiService.getMedicalRecordsForPatient(widget.patientId);

      if (!mounted) return;

      setState(() {
        _records = data; // ✅ عندك الدالة ترجع List<dynamic> (غير nullable)
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _records = [];
        _loading = false;
        _error = 'حدث خطأ أثناء تحميل السجلات';
      });
    }
  }

  Future<void> _addNewRecord() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorAddMedicalRecordScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    );

    if (ok == true) await _load();
  }

  Future<void> _editRecord(Map<String, dynamic> r) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorAddMedicalRecordScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
          recordId: int.tryParse(r['id']?.toString() ?? ''),
          initialDiagnosis: (r['diagnosis'] ?? '').toString(),
          initialNotes: (r['notes'] ?? '').toString(),
          initialMedication: r['medication']?.toString(),
          initialAllergies: r['allergies']?.toString(),
          initialSideEffects: r['sideEffects']?.toString(),
        ),
      ),
    );

    if (ok == true) await _load();
  }

  void _showDetails(Map<String, dynamic> r) {
    final diagnosis = (r['diagnosis'] ?? '').toString();
    final notes = (r['notes'] ?? '').toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(diagnosis.isEmpty ? 'Diagnosis' : diagnosis),
        content: SingleChildScrollView(
          child: Text(
            '📅 التاريخ: ${_formatDate(r['visitDate'])}\n\n'
            '📝 Notes:\n${notes.isEmpty ? '-' : notes}\n\n'
            '💊 Medication: ${r['medication'] ?? '-'}\n'
            '🤧 Allergies: ${r['allergies'] ?? '-'}\n'
            '⚠️ Side Effects: ${r['sideEffects'] ?? '-'}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editRecord(r);
            },
            icon: const Icon(Icons.edit),
            label: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = 'عرض/إنشاء/تعديل السجل الطبي للمريض';

    return Scaffold(
      appBar: AppBar(
        title: const Text('السجلات الطبية'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewRecord,
        icon: const Icon(Icons.add),
        label: const Text('إضافة سجل'),
      ),
      body: Padding(
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : _records.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.folder_open,
                                      size: 56, color: Colors.grey),
                                  const SizedBox(height: 10),
                                  const Text('لا يوجد سجل طبي لهذا المريض بعد'),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _addNewRecord,
                                    icon: const Icon(Icons.note_add),
                                    label: const Text('إنشاء أول سجل'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _records.length,
                              itemBuilder: (_, i) {
                                final item = _records[i];
                                if (item is! Map) {
                                  return const SizedBox.shrink();
                                }

                                // ✅ تحويل آمن
                                final r = Map<String, dynamic>.from(item);

                                final diagnosis =
                                    (r['diagnosis'] ?? '').toString();
                                final notes = (r['notes'] ?? '').toString();
                                final dateText = _formatDate(r['visitDate']);

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(
                                      diagnosis.isEmpty
                                          ? 'Diagnosis'
                                          : diagnosis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      notes.isEmpty ? 'No notes' : notes,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          dateText,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey),
                                          textAlign: TextAlign.right,
                                        ),
                                        const SizedBox(height: 6),
                                        const Icon(Icons.edit, size: 18),
                                      ],
                                    ),
                                    onTap: () => _editRecord(r),
                                    onLongPress: () => _showDetails(r),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
