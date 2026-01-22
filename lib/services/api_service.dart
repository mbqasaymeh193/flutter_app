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
    final res = await http
        .get(_url(path), headers: _jsonHeaders(withAuth: withAuth))
        .timeout(_timeout);
    return res;
  }

  static Future<http.Response> _post(
    String path, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    final res = await http
        .post(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return res;
  }

  static Future<http.Response> _put(
    String path, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    final res = await http
        .put(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return res;
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

  // ====================== Auth ======================

  /// 🔐 تسجيل الدخول
  /// ✅ يعالج اختلاف الحقول: fullName/name + userId/id + role
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _post(
        "/api/login",
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
        final name = _pickString(map, ["fullName", "FullName", "name", "Name"]) ?? "";
        final userId = _pickInt(map, ["userId", "UserId", "id", "Id"]);

        // ✅ نخزن بيانات المستخدم أيضًا (حتى لو LoginScreen ما خزّنها)
        await saveUserInfo(role: role, name: name, userId: userId);

        // ✅ لتوافق LoginScreen الحالي اللي يقرأ result['name']
        if (map['name'] == null || map['name'].toString().isEmpty) {
          map['name'] = name;
        }
        if (map['fullName'] == null || map['fullName'].toString().isEmpty) {
          map['fullName'] = name;
        }
        if (map['userId'] == null && userId != null) {
          map['userId'] = userId;
        }

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

  /// 🧾 إنشاء حساب جديد
  static Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String nationalId,
    required String phoneNumber,
    String role = "Patient",
    String? specialty,
  }) async {
    try {
      final res = await _post(
        "/api/register",
        body: {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
          "nationalId": nationalId,
          "phoneNumber": phoneNumber,
          "role": role,
          "specialty": specialty,
        },
      );

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

  /// ⚠️ Password endpoints تعتمد على وجودها في الباك-اند (إذا ما كانت موجودة سترجع 404)
  static Future<bool> forgotPassword(String email) async {
    try {
      final res = await _postWithFallback(
        const ["/api/password/forgot", "/api/auth/forgot-password"],
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
        const ["/api/password/change", "/api/auth/change-password"],
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
        const ["/api/password/reset", "/api/auth/reset-password"],
        body: {"email": email, "newPassword": newPassword},
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("resetPassword error: $e");
      return false;
    }
  }

  // ==================== Doctors =====================

  static Future<List<dynamic>> getDoctors() async {
    try {
      final res = await _get("/api/doctors");
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
        "/api/appointments/book",
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
      final res = await _get("/api/appointments/mine", withAuth: true);

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
      final res = await _get("/api/doctor/appointments", withAuth: true);

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
        "/api/appointments/$intId/status",
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

  // ================== Admin APIs ====================

  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/api/admin/appointments", withAuth: true);

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
      final res = await _get("/api/admin/users", withAuth: true);

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
      final res = await _get("/api/admin/stats", withAuth: true);
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
        "/api/medical-records",
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
        "/api/medical-records/$recordId",
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
        "/api/medical-records/patient/$patientId",
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
      final res = await _get("/api/medical-records/mine", withAuth: true);

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

  // ================= Doctor Patients Helper =================

  /// ✅ استخرج قائمة مرضى فريدين من مواعيد الطبيب (بدون endpoint إضافي)
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

  /// ✅ Endpoint موجود عندك بالباك-اند: GET /api/doctor/patients
  static Future<List<dynamic>> getDoctorPatients() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _getWithFallback(
        const ["/api/doctor/patients", "/api/doctor/patients/list"],
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
      final res = await _get("/api/notifications/mine", withAuth: true);

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

  /// الباك اند يرجع: { "unread": 5 }
  static Future<int> getUnreadCount() async {
    await loadToken();
    if (token == null) return 0;

    try {
      final res = await _get("/api/notifications/unread-count", withAuth: true);

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
      final res = await _put("/api/notifications/$id/read", withAuth: true);
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
      final res = await _put("/api/notifications/read-all", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("markAllNotificationsRead error: $e");
      return false;
    }
  }
}
