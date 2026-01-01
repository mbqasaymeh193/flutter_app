import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String? token;

  // ====================== Token ======================

  /// ✅ تخزين التوكن
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    token = newToken;
    await prefs.setString('jwt_token', newToken);
  }

  /// ✅ تحميل التوكن
  static Future<void> loadToken() async {
    if (token != null && token!.isNotEmpty) return; // already loaded
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
  }

  /// ✅ حذف التوكن عند تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;
    await prefs.remove('jwt_token');
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

  static bool _isNotFound(http.Response res) => res.statusCode == 404;

  /// Helper: جرّب أكثر من Endpoint لنفس العملية (مفيد لأنك قلت قد لا تكون موجودة)
  static Future<http.Response> _getWithFallback(
    List<String> paths, {
    bool withAuth = false,
  }) async {
    http.Response? last;
    for (final p in paths) {
      final res = await http.get(_url(p), headers: _jsonHeaders(withAuth: withAuth));
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
      final res = await http.put(
        _url(p),
        headers: _jsonHeaders(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      );
      last = res;
      if (!_isNotFound(res)) return res;
    }
    return last ?? http.Response("Not Found", 404);
  }

  // ====================== Auth ======================

  /// 🔐 تسجيل الدخول
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        _url("/login"),
        headers: _jsonHeaders(),
        body: jsonEncode({"email": email, "password": password}),
      );

      // ignore: avoid_print
      print("🔐 login status: ${res.statusCode}");
      // ignore: avoid_print
      print("🔐 login body: ${res.body}");

      final data = _tryDecode(res.body);

      if (res.statusCode == 200 && data is Map) {
        final map = Map<String, dynamic>.from(data);
        final t = map['token']?.toString();
        if (t != null && t.isNotEmpty) await saveToken(t);
        return map;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Login error: $e");
      return null;
    }
  }

  /// 🧾 إنشاء حساب جديد (يدعم الدور والتخصص)
  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = "Patient",
    String specialty = "General",
  }) async {
    try {
      final body = <String, dynamic>{
        "fullName": fullName,
        "email": email,
        "password": password,
        "role": role,
      };

      if (role.toLowerCase() == "doctor") {
        body["specialty"] = specialty;
      }

      final res = await http.post(
        _url("/register"),
        headers: _jsonHeaders(),
        body: jsonEncode(body),
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

  /// 🔑 نسيت كلمة المرور
  static Future<bool> forgotPassword(String email) async {
    try {
      final res = await http.post(
        _url("/password/forgot"),
        headers: _jsonHeaders(),
        body: jsonEncode({"email": email}),
      );

      // ignore: avoid_print
      print("🔑 forgotPassword status: ${res.statusCode}");
      // ignore: avoid_print
      print("🔑 forgotPassword body: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("forgotPassword error: $e");
      return false;
    }
  }

  /// 🔐 تغيير كلمة المرور بعد تسجيل الدخول
  static Future<bool> changePassword(String oldPass, String newPass) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await http.put(
        _url("/password/change"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode({"oldPassword": oldPass, "newPassword": newPass}),
      );

      // ignore: avoid_print
      print("🔐 changePassword status: ${res.statusCode}");
      // ignore: avoid_print
      print("🔐 changePassword body: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("changePassword error: $e");
      return false;
    }
  }

  /// 🧩 إعادة تعيين كلمة المرور
  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final res = await http.post(
        _url("/password/reset"),
        headers: _jsonHeaders(),
        body: jsonEncode({"email": email, "newPassword": newPassword}),
      );

      // ignore: avoid_print
      print("🧩 resetPassword status: ${res.statusCode}");
      // ignore: avoid_print
      print("🧩 resetPassword body: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("resetPassword error: $e");
      return false;
    }
  }

  // ==================== Doctors =====================

  /// 👩‍⚕️ جلب قائمة الأطباء
  static Future<List<dynamic>> getDoctors() async {
    try {
      final res = await http.get(_url("/doctors"), headers: _jsonHeaders());
      // ignore: avoid_print
      print("👩‍⚕️ getDoctors status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getDoctors error: $e");
      return [];
    }
  }

  // ================= Appointments ===================

  /// 📅 حجز موعد
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
      final res = await http.post(
        _url("/appointments/book"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode({
          "doctorId": id,
          "startsAt": startsAt.toIso8601String(),
          "endsAt": endsAt.toIso8601String(),
        }),
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

  /// 📋 مواعيد المريض
  static Future<List<dynamic>> getMyAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/appointments/mine"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📋 getMyAppointments status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMyAppointments error: $e");
      return [];
    }
  }

  /// 🩺 مواعيد الطبيب
  static Future<List<dynamic>> getDoctorAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/doctor/appointments"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📦 Doctor appointments status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['appointments'] is List) {
          return List<dynamic>.from(data['appointments']);
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

  /// ✅ تحديث حالة الموعد
  static Future<bool> updateAppointmentStatus(dynamic id, String status) async {
    await loadToken();
    if (token == null) return false;

    final int? intId = int.tryParse(id.toString());
    if (intId == null) return false;

    try {
      final res = await http.put(
        _url("/appointments/$intId/status"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode({"status": _normalizeStatus(status)}),
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

  /// ❌ إلغاء موعد (إذا endpoint موجود)
  static Future<bool> cancelAppointment(dynamic id) async {
    await loadToken();
    if (token == null) return false;

    final int? intId = int.tryParse(id.toString());
    if (intId == null) return false;

    try {
      final res = await http.post(
        _url("/appointments/$intId/cancel"),
        headers: _jsonHeaders(withAuth: true),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print("cancelAppointment error: $e");
      return false;
    }
  }

  // ================== Admin APIs ====================

  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/admin/appointments"),
        headers: _jsonHeaders(withAuth: true),
      );

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
      print("getAdminAppointments error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/admin/users"),
        headers: _jsonHeaders(withAuth: true),
      );

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
      print("getAllUsers error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getAllDoctors() async {
    try {
      final res = await http.get(_url("/doctors"), headers: _jsonHeaders());
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("getAllDoctors error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getAllPatients() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/admin/patients"),
        headers: _jsonHeaders(withAuth: true),
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("getAllPatients error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getAllAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/admin/appointments"),
        headers: _jsonHeaders(withAuth: true),
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("getAllAppointments error: $e");
    }
    return [];
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

    // 1) إذا endpoint موجود
    try {
      final res = await http.get(
        _url("/admin/stats"),
        headers: _jsonHeaders(withAuth: true),
      );

      final data = _tryDecode(res.body);
      if (res.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    // 2) fallback
    try {
      final apps = await getAllAppointments();
      int confirmed = 0, rejected = 0, pending = 0;
      for (final a in apps) {
        final s = (a['status'] ?? '').toString().toLowerCase();
        if (s == 'confirmed' || s == 'accepted') {
          confirmed++;
        } else if (s == 'rejected') {
          rejected++;
        } else {
          pending++;
        }
      }

      final doctors = await getAllDoctors();
      final patients = await getAllPatients();

      return {
        "appointments": apps.length,
        "confirmed": confirmed,
        "rejected": rejected,
        "pending": pending,
        "doctors": doctors.length,
        "patients": patients.length,
      };
    } catch (_) {
      return {
        "appointments": 0,
        "confirmed": 0,
        "rejected": 0,
        "pending": 0,
        "doctors": 0,
        "patients": 0,
      };
    }
  }

  // ================= Medical Records =================

  static Future<Map<String, dynamic>?> createMedicalRecord({
    required int patientId,
    required String diagnosis,
    required String notes,
    String? medication,
    String? allergies,
    String? sideEffects,
  }) async {
    await loadToken();
    if (token == null) return null;

    try {
      final res = await http.post(
        _url("/medical-records"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode({
          "patientId": patientId,
          "diagnosis": diagnosis,
          "notes": notes,
          "medication": medication,
          "allergies": allergies,
          "sideEffects": sideEffects,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = _tryDecode(res.body);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("createMedicalRecord error: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getPatientMedicalRecords(int patientId) async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/medical-records/patient/$patientId"),
        headers: _jsonHeaders(withAuth: true),
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getPatientMedicalRecords error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getMyMedicalRecords() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/medical-records/mine"),
        headers: _jsonHeaders(withAuth: true),
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMyMedicalRecords error: $e");
      return [];
    }
  }

  // ================= Notifications =================

/// 🔔 إشعارات المستخدم الحالي
static Future<List<dynamic>> getMyNotifications() async {
  await loadToken();
  if (token == null) return [];

  try {
    final res = await http.get(
      _url("/notifications/mine"),
      headers: _jsonHeaders(withAuth: true),
    );

    if (res.statusCode == 200) {
      final data = _tryDecode(res.body);
      if (data is List) return data;
      if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
    }
    return [];
  } catch (e) {
    // ignore: avoid_print
    print("getMyNotifications error: $e");
    return [];
  }
}

/// 🔢 عدد الإشعارات غير المقروءة (من Endpoint الحقيقي عندك)
static Future<int> getUnreadCount() async {
  await loadToken();
  if (token == null) return 0;

  try {
    final res = await http.get(
      _url("/notifications/unread-count"),
      headers: _jsonHeaders(withAuth: true),
    );

    if (res.statusCode == 200) {
      final data = _tryDecode(res.body);

      // حالات محتملة للـ response:
      // 1) رقم مباشر: 5
      if (data is int) return data;

      // 2) string رقم: "5"
      if (data is String) return int.tryParse(data) ?? 0;

      // 3) object: { "count": 5 }
      if (data is Map && data['count'] != null) {
        return int.tryParse(data['count'].toString()) ?? 0;
      }
    }

    return 0;
  } catch (e) {
    // ignore: avoid_print
    print("getUnreadCount error: $e");
    return 0;
  }
}

/// ✅ تعليم إشعار كمقروء
static Future<bool> markNotificationRead(int id) async {
  await loadToken();
  if (token == null) return false;

  try {
    final res = await http.put(
      _url("/notifications/$id/read"),
      headers: _jsonHeaders(withAuth: true),
    );

    return res.statusCode == 200 || res.statusCode == 204;
  } catch (e) {
    // ignore: avoid_print
    print("markNotificationRead error: $e");
    return false;
  }
}

/// ✅ تعليم كل الإشعارات كمقروءة
static Future<bool> markAllNotificationsRead() async {
  await loadToken();
  if (token == null) return false;

  try {
    final res = await http.put(
      _url("/notifications/read-all"),
      headers: _jsonHeaders(withAuth: true),
    );

    return res.statusCode == 200 || res.statusCode == 204;
  } catch (e) {
    // ignore: avoid_print
    print("markAllNotificationsRead error: $e");
    return false;
  }
}

}