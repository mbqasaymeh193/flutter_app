import 'package:flutter/material.dart';
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await ApiService.getMedicalRecordsForPatient(widget.patientId);
      setState(() {
        _records = data ?? [];
        _loading = false;
      });
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
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
                subtitle: Text('Patient ID: ${widget.patientId}'),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)))
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
                                final r = _records[i];
                                final diagnosis =
                                    (r['diagnosis'] ?? '').toString();
                                final notes = (r['notes'] ?? '').toString();
                                final date =
                                    (r['visitDate'] ?? '').toString();

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
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      date.length > 10
                                          ? date.substring(0, 10)
                                          : date,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(diagnosis.isEmpty
                                              ? 'Diagnosis'
                                              : diagnosis),
                                          content: SingleChildScrollView(
                                            child: Text(
                                              'Notes:\n$notes\n\nMedication: ${r['medication'] ?? '-'}\nAllergies: ${r['allergies'] ?? '-'}\nSideEffects: ${r['sideEffects'] ?? '-'}',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('إغلاق'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
