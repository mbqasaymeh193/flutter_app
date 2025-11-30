import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';
// لو أعطاك خطأ على .characters أضف هذا السطر:
import 'package:characters/characters.dart';

import 'doctor_patient_details_screen.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filtered = [];
  String _search = "";

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      // 🩺 نحصل على مواعيد الدكتور من الـ API
      final appointments = await ApiService.getDoctorAppointments() ?? [];

      final Map<String, Map<String, dynamic>> uniquePatients = {};

      for (final a in appointments) {
        final p = a['patient'];
        if (p == null) continue;

        final idStr = (p['id'] ?? p['Id'] ?? '').toString();
        if (idStr.isEmpty) continue;

        final intId = int.tryParse(idStr);
        final fullName =
            (p['fullName'] ?? p['name'] ?? p['FullName'] ?? 'مريض').toString();
        final email = (p['email'] ?? '').toString();
        final status = (a['status'] ?? 'Pending').toString();
        final startsAtStr = a['startsAt']?.toString() ?? '';
        DateTime? date;
        try {
          date = DateTime.tryParse(startsAtStr);
        } catch (_) {}

        if (!uniquePatients.containsKey(idStr)) {
          uniquePatients[idStr] = {
            'id': intId ?? p['id'] ?? p['Id'],
            'name': fullName,
            'email': email,
            'lastAppointment': date ?? startsAtStr,
            'lastStatus': status,
            'visitsCount': 1,
          };
        } else {
          final existing = uniquePatients[idStr]!;
          final existingDate = existing['lastAppointment'];
          bool isNewer = false;
          if (existingDate is DateTime && date != null) {
            isNewer = date.isAfter(existingDate);
          }
          if (isNewer) {
            existing['lastAppointment'] = date ?? startsAtStr;
            existing['lastStatus'] = status;
          }
          existing['visitsCount'] = (existing['visitsCount'] as int) + 1;
        }
      }

      final list = uniquePatients.values.toList()
        ..sort((a, b) {
          final da = a['lastAppointment'];
          final db = b['lastAppointment'];
          if (da is DateTime && db is DateTime) {
            return db.compareTo(da); // الأحدث أولاً
          }
          return 0;
        });

      setState(() {
        _patients = List<Map<String, dynamic>>.from(list);
        _applyFilter();
      });

      debugPrint("👥 DoctorPatientsScreen: loaded ${_patients.length} patients");
    } catch (e) {
      debugPrint("⚠️ DoctorPatientsScreen _loadPatients error: $e");
      setState(() {
        _patients = [];
        _filtered = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_search.trim().isEmpty) {
      _filtered = List<Map<String, dynamic>>.from(_patients);
    } else {
      final q = _search.toLowerCase();
      _filtered = _patients.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'مؤكد';
    if (lower == 'rejected') return 'مرفوض';
    return 'قيد الانتظار';
  }

  String _formatDate(dynamic v) {
    if (v == null) return 'غير محدد';
    if (v is DateTime) {
      return DateFormat('y/MM/dd • HH:mm').format(v.toLocal());
    }
    if (v is String) {
      final d = DateTime.tryParse(v);
      if (d != null) {
        return DateFormat('y/MM/dd • HH:mm').format(d.toLocal());
      }
      return v;
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1976D2);
    final bg = const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('مرضاي'),
        backgroundColor: primary,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'تحديث القائمة',
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن مريض بالاسم أو البريد...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _applyFilter();
                });
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primary,
                    ),
                  )
                : _filtered.isEmpty
                    ? RefreshIndicator(
                        color: primary,
                        onRefresh: _loadPatients,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'لا يوجد مرضى لعرضهم حالياً 👩‍⚕️',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Center(
                              child: Text(
                                'عند حجز المرضى لمواعيد معك سيظهرون هنا.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _loadPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            final id = p['id'];
                            final name = p['name'] ?? 'مريض';
                            final email = p['email'] ?? '';
                            final last = p['lastAppointment'];
                            final status =
                                (p['lastStatus'] ?? 'Pending').toString();
                            final visits = (p['visitsCount'] ?? 1).toString();

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DoctorPatientDetailsScreen(
                                          patient: {
                                            'id': id,
                                            'fullName': name,
                                            'email': email,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor:
                                              const Color(0x221976D2),
                                          child: Text(
                                            name.toString().isNotEmpty
                                                ? name
                                                    .toString()
                                                    .trim()
                                                    .characters
                                                    .first
                                                    .toUpperCase()
                                                : 'P',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name.toString(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (email
                                                  .toString()
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2),
                                                  child: Text(
                                                    email.toString(),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors
                                                          .grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'آخر زيارة: ${_formatDate(last)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      Colors.grey.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(
                                                              status)
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  999),
                                                    ),
                                                    child: Text(
                                                      _statusLabel(status),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                        color:
                                                            _statusColor(
                                                                status),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .blueGrey
                                                          .withOpacity(
                                                              0.06),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  999),
                                                    ),
                                                    child: Text(
                                                      '$visits زيارة',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
