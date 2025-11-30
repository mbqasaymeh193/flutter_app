import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class PatientMedicalRecordsScreen extends StatefulWidget {
  const PatientMedicalRecordsScreen({super.key});

  @override
  State<PatientMedicalRecordsScreen> createState() =>
      _PatientMedicalRecordsScreenState();
}

class _PatientMedicalRecordsScreenState
    extends State<PatientMedicalRecordsScreen> {
  bool _loading = true;
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getMyMedicalRecords();
      list.sort((a, b) {
        final da = DateTime.tryParse(a['visitDate'] ?? '');
        final db = DateTime.tryParse(b['visitDate'] ?? '');
        if (da == null || db == null) return 0;
        return db.compareTo(da); // الأحدث أولاً
      });
      setState(() => _records = list);
    } catch (e) {
      debugPrint("⚠️ getMyMedicalRecords error: $e");
      setState(() => _records = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? v) {
    if (v == null) return 'غير محدد';
    final d = DateTime.tryParse(v);
    if (d == null) return v;
    return DateFormat('y/MM/dd • HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);
    final bg = const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("ملفي الطبي"),
        backgroundColor: primary,
        elevation: 2,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: primary),
            )
          : _records.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadRecords,
                  color: primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Icon(Icons.folder_open,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          "لا توجد سجلات طبية بعد",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          "عند قيام الطبيب بكتابة تقرير طبي، سيظهر هنا.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primary,
                  onRefresh: _loadRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final r = _records[index];
                      final diagnosis =
                          (r['diagnosis'] ?? 'بدون عنوان').toString();
                      final notes = (r['notes'] ?? '').toString();
                      final med = (r['medication'] ?? '').toString();
                      final allg = (r['allergies'] ?? '').toString();
                      final side = (r['sideEffects'] ?? '').toString();
                      final visitDate =
                          _formatDate(r['visitDate']?.toString());
                      final doctorName =
                          (r['doctorName'] ?? 'غير مذكور').toString();
                      final doctorSpec =
                          (r['doctorSpecialty'] ?? '').toString();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x221976D2),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      diagnosis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                visitDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (notes.isNotEmpty) ...[
                                const Text(
                                  "الملاحظات:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(notes),
                                const SizedBox(height: 6),
                              ],
                              if (med.isNotEmpty) ...[
                                const Text(
                                  "الدواء:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(med),
                                const SizedBox(height: 6),
                              ],
                              if (allg.isNotEmpty) ...[
                                const Text(
                                  "الحساسية:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(allg),
                                const SizedBox(height: 6),
                              ],
                              if (side.isNotEmpty) ...[
                                const Text(
                                  "الآثار الجانبية:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(side),
                                const SizedBox(height: 6),
                              ],

                              const Divider(),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      doctorName,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  if (doctorSpec.isNotEmpty)
                                    Text(
                                      doctorSpec,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
