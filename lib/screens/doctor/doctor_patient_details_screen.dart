import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:healthcare_flutter_app/services/api_service.dart';

class DoctorPatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const DoctorPatientDetailsScreen({super.key, required this.patient});

  @override
  State<DoctorPatientDetailsScreen> createState() =>
      _DoctorPatientDetailsScreenState();
}

class _DoctorPatientDetailsScreenState extends State<DoctorPatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loadingAppointments = true;
  bool _loadingRecords = true;

  List<dynamic> _appointments = [];
  List<dynamic> _medicalRecords = [];

  // فورم السجل الطبي الجديد
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _medicationController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _sideEffectsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        setState(() {});
      });
    _loadAppointments();
    _loadMedicalRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _medicationController.dispose();
    _allergiesController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  // ================== Helpers: Patient ==================

  int? get _patientId {
    final p = widget.patient;
    if (p['id'] is int) return p['id'] as int;
    if (p['Id'] is int) return p['Id'] as int;
    if (p['id'] is String) return int.tryParse(p['id']);
    if (p['Id'] is String) return int.tryParse(p['Id']);
    return null;
  }

  String get _patientName {
    return (widget.patient['fullName'] ??
            widget.patient['name'] ??
            widget.patient['FullName'] ??
            'Patient')
        .toString();
  }

  // ================== Helpers: Formatting ==================

  String _formatDateTime(dynamic value) {
    if (value == null) return '';
    final raw = value.toString();
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      return DateFormat('y/MM/dd • HH:mm').format(dt.toLocal());
    } catch (_) {
      return raw;
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

  // ================== Load Data ==================

  Future<void> _loadAppointments() async {
    setState(() => _loadingAppointments = true);
    try {
      final allAppointments = await ApiService.getDoctorAppointments();
      final pid = _patientId?.toString();

      final filtered = (allAppointments ?? [])
          .where((a) =>
              a is Map &&
              (a['patient']?['id']?.toString() == pid ||
                  a['patientId']?.toString() == pid))
          .toList();

      if (!mounted) return;
      setState(() => _appointments = filtered);
    } catch (e) {
      debugPrint("⚠️ loadAppointments error: $e");
      if (!mounted) return;
      setState(() => _appointments = []);
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _loadMedicalRecords() async {
    final pid = _patientId;
    if (pid == null) {
      if (!mounted) return;
      setState(() {
        _medicalRecords = [];
        _loadingRecords = false;
      });
      return;
    }

    setState(() => _loadingRecords = true);
    try {
      // ✅ FIX 1: الاسم الصحيح الموجود أو (Compatibility) الذي أضفناه
      final list = await ApiService.getPatientMedicalRecords(pid);

      if (!mounted) return;
      setState(() => _medicalRecords = list);
    } catch (e) {
      debugPrint("⚠️ loadMedicalRecords error: $e");
      if (!mounted) return;
      setState(() => _medicalRecords = []);
    } finally {
      if (mounted) setState(() => _loadingRecords = false);
    }
  }

  // ================== Add Medical Record (Bottom Sheet) ==================

  void _openAddMedicalRecordSheet() {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم معرف للمريض')),
      );
      return;
    }

    _diagnosisController.clear();
    _notesController.clear();
    _medicationController.clear();
    _allergiesController.clear();
    _sideEffectsController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            bottom: bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Text(
                    'إضافة تقرير طبي جديد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _patientName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'التشخيص (Diagnosis) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sick),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'التشخيص مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الزيارة (Notes) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'الملاحظات مطلوبة'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _medicationController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'الدواء (Medication)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                      labelText: 'الحساسية (Allergies)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _sideEffectsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'الآثار الجانبية / ملاحظات إضافية',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final pid = _patientId!;
                            final diag = _diagnosisController.text.trim();
                            final notes = _notesController.text.trim();
                            final med = _medicationController.text.trim();
                            final allg = _allergiesController.text.trim();
                            final side = _sideEffectsController.text.trim();

                            // ✅ FIX 2: createMedicalRecord ترجع bool
                            final ok = await ApiService.createMedicalRecord(
                              patientId: pid,
                              diagnosis: diag,
                              notes: notes,
                              medication: med.isEmpty ? null : med,
                              allergies: allg.isEmpty ? null : allg,
                              sideEffects: side.isEmpty ? null : side,
                            );

                            if (!mounted) return;

                            if (ok) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حفظ التقرير الطبي بنجاح ✅'),
                                ),
                              );
                              _loadMedicalRecords();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'فشل في حفظ السجل الطبي، حاول مرة أخرى ❌'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================== UI: Appointments Tab ==================

  Widget _buildAppointmentsTab() {
    if (_loadingAppointments) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      );
    }
    if (_appointments.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF1976D2),
        onRefresh: _loadAppointments,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 60),
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'لا توجد مواعيد لهذا المريض حالياً',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1976D2),
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (_, i) {
          final a = _appointments[i] as Map;
          final dateText = _formatDateTime(a['startsAt']);
          final status = (a['status'] ?? 'Pending').toString();

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x221976D2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: Color(0xFF1976D2), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateText.isEmpty ? 'موعد بدون تاريخ' : dateText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            _statusLabel(status),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _statusColor(status),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      bool ok = false;

                      if (value == 'cancel') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد الإلغاء'),
                            content: const Text('هل أنت متأكد من حذف هذا الموعد نهائيًا؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('إلغاء'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                ),
                                child: const Text('تأكيد'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        // ✅ FIX 3: cancelAppointment موجود الآن (بعد إضافته في ApiService)
                        ok = await ApiService.cancelAppointment(a['id']);

                        if (!mounted) return;

                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إلغاء الموعد نهائيًا ✅')),
                          );
                          _loadAppointments();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل في إلغاء الموعد ❌')),
                          );
                        }
                      } else {
                        ok = await ApiService.updateAppointmentStatus(a['id'], value);

                        if (!mounted) return;

                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value.toLowerCase() == 'confirmed'
                                    ? 'تم تأكيد الموعد ✅'
                                    : 'تم رفض الموعد ❌',
                              ),
                            ),
                          );
                          _loadAppointments();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل في تحديث حالة الموعد ❌')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Confirmed', child: Text('تأكيد الموعد')),
                      PopupMenuItem(value: 'Rejected', child: Text('رفض الموعد')),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text(
                          'إلغاء الموعد نهائيًا 🗑️',
                          style: TextStyle(color: Colors.red),
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
    );
  }

  // ================== UI: Medical Records Tab ==================

  Widget _buildMedicalRecordsTab() {
    if (_loadingRecords) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1976D2)),
      );
    }

    if (_medicalRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_shared_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد سجلات طبية لهذا المريض حتى الآن',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openAddMedicalRecordSheet,
              icon: const Icon(Icons.add),
              label: const Text('إضافة أول تقرير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1976D2),
      onRefresh: _loadMedicalRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicalRecords.length,
        itemBuilder: (_, i) {
          final r = _medicalRecords[i] as Map;
          final dateText = _formatDateTime(r['visitDate']);
          final diagnosis = (r['diagnosis'] ?? '').toString();
          final notes = (r['notes'] ?? '').toString();
          final med = (r['medication'] ?? '').toString();
          final allg = (r['allergies'] ?? '').toString();
          final side = (r['sideEffects'] ?? '').toString();
          final docName = (r['doctorName'] ?? '').toString();
          final docSpec = (r['doctorSpecialty'] ?? '').toString();

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x221976D2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description,
                            color: Color(0xFF1976D2), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          diagnosis.isEmpty ? 'تقرير طبي' : diagnosis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (dateText.isNotEmpty)
                    Text(
                      dateText,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  if (notes.isNotEmpty) ...[
                    const Text(
                      'الملاحظات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(notes),
                    const SizedBox(height: 6),
                  ],
                  if (med.isNotEmpty || allg.isNotEmpty || side.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (med.isNotEmpty)
                          const SizedBox.shrink(),
                        if (med.isNotEmpty)
                          Chip(
                            label: Text('دواء: $med', style: const TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                        if (allg.isNotEmpty)
                          Chip(
                            label: Text('حساسية: $allg', style: const TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFFFEBEE),
                          ),
                        if (side.isNotEmpty)
                          Chip(
                            label: Text('آثار جانبية: $side', style: const TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFFFF8E1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          docName.isEmpty ? 'غير مذكور' : docName,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (docSpec.isNotEmpty)
                        Text(
                          docSpec,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================== Build ==================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
          elevation: 2,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المريض: $_patientName'),
              if (_patientId != null)
                Text(
                  'ID: $_patientId',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'المواعيد'),
              Tab(icon: Icon(Icons.folder_shared), text: 'الملف الطبي'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentsTab(),
            _buildMedicalRecordsTab(),
          ],
        ),
        floatingActionButton: _tabController.index == 1
            ? FloatingActionButton.extended(
                onPressed: _openAddMedicalRecordSheet,
                backgroundColor: const Color(0xFF1976D2),
                icon: const Icon(Icons.add),
                label: const Text('إضافة تقرير'),
              )
            : null,
      ),
    );
  }
}
