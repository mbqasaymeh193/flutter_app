import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'patient_medical_records_for_doctor_screen.dart';

class DoctorPatientsRecordsScreen extends StatefulWidget {
  const DoctorPatientsRecordsScreen({super.key});

  @override
  State<DoctorPatientsRecordsScreen> createState() => _DoctorPatientsRecordsScreenState();
}

class _DoctorPatientsRecordsScreenState extends State<DoctorPatientsRecordsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];
  String _q = '';

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
      final fromEndpoint = await ApiService.getDoctorPatients();

      if (fromEndpoint.isNotEmpty) {
        final list = fromEndpoint.map((e) {
          final m = (e is Map) ? e : <String, dynamic>{};
          return <String, dynamic>{
            "id": int.tryParse(m['patientId']?.toString() ?? m['id']?.toString() ?? '') ?? 0,
            "fullName": (m['fullName'] ?? m['patientName'] ?? 'Patient').toString(),
            "phoneNumber": m['phoneNumber']?.toString(),
          };
        }).where((x) => (x["id"] ?? 0) != 0).toList();

        setState(() {
          _patients = list;
          _loading = false;
        });
        return;
      }

      final list = await ApiService.getPatientsFromDoctorAppointments();
      setState(() {
        _patients = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _patients = [];
        _loading = false;
        _error = 'حدث خطأ أثناء تحميل المرضى';
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return _patients;
    return _patients.where((p) {
      final name = (p['fullName'] ?? '').toString().toLowerCase();
      final phone = (p['phoneNumber'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  Future<int> _recordsCount(int patientId) async {
    final list = await ApiService.getMedicalRecordsForPatient(patientId);
    return list.length;
  }

  void _openPatient(Map<String, dynamic> p) {
    final id = p['id'] as int;
    final name = (p['fullName'] ?? 'Patient').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientMedicalRecordsForDoctorScreen(
          patientId: id,
          patientName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث باسم المريض أو رقم الهاتف...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : items.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              children: const [
                                SizedBox(height: 200),
                                Center(child: Text('لا يوجد مرضى لعرضهم')),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final p = items[i];
                                final id = p['id'] as int;
                                final name = (p['fullName'] ?? 'Patient').toString();
                                final phone = (p['phoneNumber'] ?? '').toString();

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: const CircleAvatar(child: Icon(Icons.person)),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: phone.isEmpty ? null : Text(phone),
                                    trailing: FutureBuilder<int>(
                                      future: _recordsCount(id),
                                      builder: (_, snap) {
                                        final done = snap.connectionState == ConnectionState.done && snap.hasData;
                                        final count = done ? (snap.data ?? 0) : null;

                                        final label = count == null
                                            ? '...'
                                            : (count == 0 ? 'إنشاء سجل' : 'عرض/تعديل');

                                        final color = count == null
                                            ? Colors.grey
                                            : (count == 0 ? Colors.orange : Colors.green);

                                        return ElevatedButton(
                                          onPressed: () => _openPatient(p),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                          child: Text(label),
                                        );
                                      },
                                    ),
                                    onTap: () => _openPatient(p),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
