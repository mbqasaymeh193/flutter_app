import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ApiService {
  static String? token;

  // ✅ مفاتيح موحّدة (وتدعم القديم أيضًا)
  static const String _kTokenNew = 'token';
  static const String _kTokenOld = 'jwt_token';

  static const String _kRole = 'role';
  static const String _kName = 'name';
  static const String _kUserId = 'userId';

  // ✅ Timeout لكل الطلبات
  static const Duration _timeout = Duration(seconds: 15);

  // ====================== Token ======================

  /// ✅ تخزين التوكن (يكتب الجديد + القديم للتوافق)
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    token = newToken;

    await prefs.setString(_kTokenNew, newToken);
    await prefs.setString(_kTokenOld, newToken); // backward compatibility
  }

  /// ✅ تحميل التوكن (يقرأ الجديد ثم القديم)
  static Future<void> loadToken() async {
    if (token != null && token!.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kTokenNew) ?? prefs.getString(_kTokenOld);
  }

  /// ✅ تخزين بيانات المستخدم الأساسية
  static Future<void> saveUserInfo({
    String? role,
    String? name,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (role != null) await prefs.setString(_kRole, role);
    if (name != null) await prefs.setString(_kName, name);
    if (userId != null) await prefs.setInt(_kUserId, userId);
  }

  /// ✅ حذف كل شيء عند تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;

    await prefs.remove(_kTokenNew);
    await prefs.remove(_kTokenOld);
    await prefs.remove(_kRole);
    await prefs.remove(_kName);
    await prefs.remove(_kUserId);
  }

  // ====================== Helpers ======================

  /// ✅ AppConfig.apiBaseUrl يجب أن يكون مثل:
  /// http://127.0.0.1:7000/api
  static Uri _url(String path) => Uri.parse("${AppConfig.apiBaseUrl}$path");

  static Map<String, String> _jsonHeaders({bool withAuth = false}) {
    final h = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (withAuth && token != null && token!.isNotEmpty) {
      h["Authorization"] = "Bearer $token";
    }
    return h;
  }

  static dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String? _pickString(Map map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static int? _pickInt(Map map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final n = int.tryParse(v.toString());
      if (n != null) return n;
    }
    return null;
  }

  static bool _isNotFound(http.Response res) => res.statusCode == 404;

  static Future<http.Response> _get(
    String path, {
    bool withAuth = false,
  }) async {
    return http
        .get(_url(path), headers: _jsonHeaders(withAuth: withAuth))
        .timeout(_timeout);
  }

  static Future<http.Response> _post(
    String path, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    return http
        .post(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> _put(
    String path, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    return http
        .put(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> _delete(
    String path, {
    bool withAuth = false,
  }) async {
    return http
        .delete(_url(path), headers: _jsonHeaders(withAuth: withAuth))
        .timeout(_timeout);
  }

  /// Helper: جرّب أكثر من Endpoint لنفس العملية (Fallback)
  static Future<http.Response> _getWithFallback(
    List<String> paths, {
    bool withAuth = false,
  }) async {
    http.Response? last;
    for (final p in paths) {
      final res = await _get(p, withAuth: withAuth);
      last = res;
      if (!_isNotFound(res)) return res;
    }
    return last ?? http.Response("Not Found", 404);
  }

  static Future<http.Response> _postWithFallback(
    List<String> paths, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    http.Response? last;
    for (final p in paths) {
      final res = await _post(p, withAuth: withAuth, body: body);
      last = res;
      if (!_isNotFound(res)) return res;
    }
    return last ?? http.Response("Not Found", 404);
  }

  static Future<http.Response> _putWithFallback(
    List<String> paths, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    http.Response? last;
    for (final p in paths) {
      final res = await _put(p, withAuth: withAuth, body: body);
      last = res;
      if (!_isNotFound(res)) return res;
    }
    return last ?? http.Response("Not Found", 404);
  }

  static Future<http.Response> _deleteWithFallback(
    List<String> paths, {
    bool withAuth = false,
  }) async {
    http.Response? last;
    for (final p in paths) {
      final res = await _delete(p, withAuth: withAuth);
      last = res;
      if (!_isNotFound(res)) return res;
    }
    return last ?? http.Response("Not Found", 404);
  }

  // ====================== Auth ======================

  /// 🔐 تسجيل الدخول
  /// ✅ Endpoint الصحيح عندك: POST /api/login
  /// وبما أن baseUrl يحتوي /api => هنا نستخدم "/login"
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _post(
        "/login",
        body: {"email": email, "password": password},
      );

      // ignore: avoid_print
      print("🔐 login status: ${res.statusCode}");
      // ignore: avoid_print
      print("🔐 login body: ${res.body}");

      final data = _tryDecode(res.body);

      if (res.statusCode == 200 && data is Map) {
        final map = Map<String, dynamic>.from(data);

        final t = _pickString(map, ["token", "Token"]);
        if (t != null && t.isNotEmpty) {
          await saveToken(t);
        }

        final role = _pickString(map, ["role", "Role"]) ?? "";
        final name =
            _pickString(map, ["fullName", "FullName", "name", "Name"]) ?? "";
        final userId = _pickInt(map, ["userId", "UserId", "id", "Id"]);

        await saveUserInfo(role: role, name: name, userId: userId);

        // لتوافق الشاشات
        map['name'] ??= name;
        map['fullName'] ??= name;
        if (map['userId'] == null && userId != null) map['userId'] = userId;

        return map;
      }

      return null;
    } on TimeoutException {
      // ignore: avoid_print
      print("Login timeout");
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Login error: $e");
      return null;
    }
  }

  Map<String, String> _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return {'firstName': '', 'lastName': ''};
    if (parts.length == 1) {
      return {'firstName': parts.first, 'lastName': parts.first};
    }
    return {
      'firstName': parts.first,
      'lastName': parts.sublist(1).join(' '),
    };
  }

  /// 🧾 إنشاء حساب جديد
  /// ✅ Endpoint الصحيح عندك: POST /api/register
  /// وبما أن baseUrl يحتوي /api => هنا نستخدم "/register"
  ///
  /// ✅ يدعم طريقتين:
  /// 1) fullName (للشاشات القديمة)
  /// 2) firstName + lastName (+ باقي الحقول)
  static Future<bool> register({
    String? fullName,
    String? firstName,
    String? lastName,
    required String email,
    required String password,
    String? nationalId,
    String? phoneNumber,
    String role = "Patient",
    String? specialty,
  }) async {
    try {
      String fn = (firstName ?? '').trim();
      String ln = (lastName ?? '').trim();

      if ((fn.isEmpty || ln.isEmpty) && (fullName ?? '').trim().isNotEmpty) {
        final parts = ApiService()._splitName(fullName!.trim());
        fn = parts['firstName'] ?? fn;
        ln = parts['lastName'] ?? ln;
      }

      final body = <String, dynamic>{
        "email": email,
        "password": password,
        "role": role,
      };

      // ✅ أرسل الاسم بالطريقة المتاحة
      if (fn.isNotEmpty && ln.isNotEmpty) {
        body["firstName"] = fn;
        body["lastName"] = ln;
      } else if ((fullName ?? '').trim().isNotEmpty) {
        body["fullName"] = fullName!.trim();
      }

      // ✅ حقول اختيارية
      if ((nationalId ?? '').trim().isNotEmpty) body["nationalId"] = nationalId!.trim();
      if ((phoneNumber ?? '').trim().isNotEmpty) body["phoneNumber"] = phoneNumber!.trim();

      final isDoctor = role.toLowerCase() == 'doctor';
      if (isDoctor && (specialty ?? '').trim().isNotEmpty) {
        body["specialty"] = specialty!.trim();
      }

      final res = await _post("/register", body: body);

      // ignore: avoid_print
      print("📦 Register status: ${res.statusCode}");
      // ignore: avoid_print
      print("📦 Register body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ Register error: $e");
      return false;
    }
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      final res = await _postWithFallback(
        const ["/password/forgot"],
        body: {"email": email},
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("forgotPassword error: $e");
      return false;
    }
  }

  static Future<bool> changePassword(String oldPass, String newPass) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _putWithFallback(
        const ["/password/change"],
        withAuth: true,
        body: {"oldPassword": oldPass, "newPassword": newPass},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("changePassword error: $e");
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final res = await _postWithFallback(
        const ["/password/reset"],
        body: {"email": email, "newPassword": newPassword},
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("resetPassword error: $e");
      return false;
    }
  }

  static Future<bool> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await _post(
        "/password/reset",
        body: {
          "email": email,
          "code": code,
          "newPassword": newPassword,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("resetPasswordWithCode error: $e");
      return false;
    }
  }

  // ==================== Doctors =====================

  static Future<List<dynamic>> getDoctors() async {
    try {
      final res = await _get("/doctors");
      // ignore: avoid_print
      print("👩‍⚕️ getDoctors status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getDoctors error: $e");
      return [];
    }
  }

  // ✅✅ Alias (إن احتجته)
  static Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final list = await getDoctors();
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final users = await getAllUsers();
    return users
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((u) => (u['role'] ?? '').toString().toLowerCase() == 'patient')
        .toList();
  }

  // ================= Appointments ===================

  static Future<bool> bookAppointment({
    required dynamic doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await loadToken();
    if (token == null) return false;

    final int? id = int.tryParse(doctorId.toString());
    if (id == null) return false;

    try {
      final res = await _post(
        "/appointments/book",
        withAuth: true,
        body: {
          "doctorId": id,
          "startsAt": startsAt.toIso8601String(),
          "endsAt": endsAt.toIso8601String(),
        },
      );

      // ignore: avoid_print
      print("📅 bookAppointment status: ${res.statusCode}");
      // ignore: avoid_print
      print("📅 bookAppointment body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print("bookAppointment error: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getMyAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/appointments/mine", withAuth: true);

      // ignore: avoid_print
      print("📋 getMyAppointments status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMyAppointments error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getDoctorAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/doctor/appointments", withAuth: true);

      // ignore: avoid_print
      print("📦 Doctor appointments status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['appointments'] is List) {
          return List<dynamic>.from(data['appointments']);
        }
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ getDoctorAppointments error: $e");
      return [];
    }
  }

  static String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'Confirmed';
    if (lower == 'rejected') return 'Rejected';
    if (lower == 'pending') return 'Pending';
    return s;
  }

  /// ✅ مطابق للباك-اند: PUT /api/appointments/{id}/status
  static Future<bool> updateAppointmentStatus(dynamic id, String status) async {
    await loadToken();
    if (token == null) return false;

    final int? intId = int.tryParse(id.toString());
    if (intId == null) return false;

    try {
      final res = await _put(
        "/appointments/$intId/status",
        withAuth: true,
        body: {"status": _normalizeStatus(status)},
      );

      // ignore: avoid_print
      print("🔄 updateAppointmentStatus [$intId] => ${res.statusCode}");
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("updateAppointmentStatus error: $e");
      return false;
    }
  }

  // ================= Admin: Doctors approvals =================

  static Future<List<Map<String, dynamic>>> getPendingDoctors() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/admin/doctors/pending", withAuth: true);

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) {
          return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items'])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("getPendingDoctors error: $e");
    }

    return [];
  }

  static Future<bool> approveDoctor(int doctorId) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/admin/doctors/$doctorId/approve", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("approveDoctor error: $e");
      return false;
    }
  }

  static Future<bool> rejectDoctor(int doctorId) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/admin/doctors/$doctorId/reject", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("rejectDoctor error: $e");
      return false;
    }
  }

  // ================= Admin: Users management =================

  static Future<bool> setUserActive(int userId, bool isActive) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put(
        "/admin/users/$userId/set-active",
        withAuth: true,
        body: {"isActive": isActive},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("setUserActive error: $e");
      return false;
    }
  }

  static Future<bool> softDeleteUser(int userId) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _delete("/admin/users/$userId", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("softDeleteUser error: $e");
      return false;
    }
  }

  // ================== Admin APIs ====================

  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/admin/appointments", withAuth: true);

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getAdminAppointments error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/admin/users", withAuth: true);

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getAllUsers error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    await loadToken();
    if (token == null) {
      return {
        "appointments": 0,
        "confirmed": 0,
        "rejected": 0,
        "pending": 0,
        "doctors": 0,
        "patients": 0,
      };
    }

    try {
      final res = await _get("/admin/stats", withAuth: true);
      final data = _tryDecode(res.body);

      if (res.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    return {
      "appointments": 0,
      "confirmed": 0,
      "rejected": 0,
      "pending": 0,
      "doctors": 0,
      "patients": 0,
    };
  }

  // ================= Medical Records =================

  static Future<bool> createMedicalRecord({
    required int patientId,
    required String diagnosis,
    required String notes,
    String? medication,
    String? allergies,
    String? sideEffects,
  }) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _post(
        "/medical-records",
        withAuth: true,
        body: {
          "patientId": patientId,
          "diagnosis": diagnosis,
          "notes": notes,
          "medication": medication,
          "allergies": allergies,
          "sideEffects": sideEffects,
        },
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print("createMedicalRecord error: $e");
      return false;
    }
  }

  static Future<bool> updateMedicalRecord({
    required int recordId,
    required String diagnosis,
    required String notes,
    String? medication,
    String? allergies,
    String? sideEffects,
  }) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put(
        "/medical-records/$recordId",
        withAuth: true,
        body: {
          "diagnosis": diagnosis,
          "notes": notes,
          "medication": medication,
          "allergies": allergies,
          "sideEffects": sideEffects,
        },
      );

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("updateMedicalRecord error: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getMedicalRecordsForPatient(int patientId) async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get(
        "/medical-records/patient/$patientId",
        withAuth: true,
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMedicalRecordsForPatient error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getMyMedicalRecords() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/medical-records/mine", withAuth: true);

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMyMedicalRecords error: $e");
      return [];
    }
  }

  // ================= Compatibility APIs =================

  /// ✅ Compatibility: بعض الشاشات تستدعي هذا الاسم
  static Future<List<dynamic>> getPatientMedicalRecords(int patientId) async {
    return getMedicalRecordsForPatient(patientId);
  }

  /// ⚠️ ملاحظة مهمة:
  /// حسب قائمة endpoints التي أرسلتها: لا يوجد DELETE لإلغاء الموعد.
  /// هذه الدالة ستُرجع false غالباً (404) إلا إذا عندك endpoint مخفي.
  static Future<bool> cancelAppointment(dynamic id) async {
    await loadToken();
    if (token == null) return false;

    final int? intId = int.tryParse(id.toString());
    if (intId == null) return false;

    try {
      final res = await _deleteWithFallback(
        [
          "/appointments/$intId",
          "/appointments/$intId/cancel",
          "/doctor/appointments/$intId",
        ],
        withAuth: true,
      );

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("cancelAppointment error: $e");
      return false;
    }
  }

  // ================= Doctor Patients Helper =================

  static Future<List<Map<String, dynamic>>> getPatientsFromDoctorAppointments() async {
    final apps = await getDoctorAppointments();
    final Map<int, Map<String, dynamic>> unique = {};

    for (final a in apps) {
      if (a is! Map) continue;

      final patient = a['patient'];
      if (patient is Map) {
        final id = int.tryParse(patient['id']?.toString() ?? '');
        if (id == null) continue;

        unique[id] = {
          "id": id,
          "fullName": patient['fullName']?.toString() ?? "Patient",
          "phoneNumber": patient['phoneNumber']?.toString(),
        };
      } else {
        final pid = int.tryParse(a['patientId']?.toString() ?? '');
        if (pid == null) continue;

        unique[pid] = {
          "id": pid,
          "fullName": a['patientName']?.toString() ?? "Patient",
        };
      }
    }

    return unique.values.toList();
  }
  static Future<DoctorProfile> getDoctorProfile() async {
  final res = await http.get(
    Uri.parse('$baseUrl/doctor/profile'),
    headers: _authHeaders(),
  );

  if (res.statusCode == 200) {
    return DoctorProfile.fromJson(jsonDecode(res.body));
  } else {
    throw Exception('Failed to load doctor profile');
  }
  }
  static Future<bool> updateDoctorProfile(Map<String, dynamic> data) async {
  final res = await http.put(
    Uri.parse('$baseUrl/doctor/profile'),
    headers: _authHeaders(),
    body: jsonEncode(data),
  );

  return res.statusCode == 200;
}
static Future<DoctorProfile> getDoctorDetails(int doctorId) async {
  final res = await http.get(
    Uri.parse('$baseUrl/doctors/$doctorId'),
  );

  if (res.statusCode == 200) {
    return DoctorProfile.fromJson(jsonDecode(res.body));
  } else {
    throw Exception('Doctor not found');
  }
}

  static Future<List<dynamic>> getDoctorPatients() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _getWithFallback(
        const ["/doctor/patients"],
        withAuth: true,
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
    } catch (e) {
      // ignore: avoid_print
      print("getDoctorPatients error: $e");
    }
    return [];
  }

  // ================= Notifications =================

  static Future<List<dynamic>> getMyNotifications() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/notifications/mine", withAuth: true);

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMyNotifications error: $e");
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    await loadToken();
    if (token == null) return 0;

    try {
      final res = await _get("/notifications/unread-count", withAuth: true);

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);

        if (data is int) return data;
        if (data is String) return int.tryParse(data) ?? 0;

        if (data is Map) {
          if (data['unread'] != null) return int.tryParse(data['unread'].toString()) ?? 0;
          if (data['count'] != null) return int.tryParse(data['count'].toString()) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      // ignore: avoid_print
      print("getUnreadCount error: $e");
      return 0;
    }
  }

  static Future<bool> markNotificationRead(int id) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/notifications/$id/read", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("markNotificationRead error: $e");
      return false;
    }
  }

  static Future<bool> markAllNotificationsRead() async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/notifications/read-all", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("markAllNotificationsRead error: $e");
      return false;
    }
  }
}
