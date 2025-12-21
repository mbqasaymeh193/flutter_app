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
    if (withAuth) {
      if (token != null && token!.isNotEmpty) {
        h["Authorization"] = "Bearer $token";
      }
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
        if (t != null && t.isNotEmpty) {
          await saveToken(t);
        }
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

      // 👩‍⚕️ إذا كان الدور Doctor أضف التخصص
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

  /// 🧩 إعادة تعيين كلمة المرور (من شاشة نسيت كلمة المرور)
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

  /// 👩‍⚕️ جلب قائمة الأطباء (لكل المستخدمين)
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

    int? id;
    if (doctorId is int) {
      id = doctorId;
    } else if (doctorId is String) {
      id = int.tryParse(doctorId);
    }
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
      // ignore: avoid_print
      print("📋 getMyAppointments body: ${res.body}");

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

  /// 🩺 جلب مواعيد الطبيب
  static Future<List<dynamic>> getDoctorAppointments() async {
    await loadToken();
    if (token == null) {
      // ignore: avoid_print
      print("⚠️ getDoctorAppointments: token is null");
      return [];
    }

    try {
      // ✅ مطابق للباك: GET /api/doctor/appointments
      final res = await http.get(
        _url("/doctor/appointments"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📦 Doctor appointments status: ${res.statusCode}");
      // ignore: avoid_print
      print("📦 Doctor appointments body: ${res.body}");

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

  /// 🔁 تطبيع قيم الحالة لتوافق الـ Backend
  static String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed') return 'Confirmed';
    if (lower == 'accepted') return 'Confirmed';
    if (lower == 'rejected') return 'Rejected';
    if (lower == 'pending') return 'Pending';
    return s;
  }

  /// ✅ تحديث حالة الموعد (يتوافق مع DTO UpdateAppointmentStatusRequest في الباك)
  static Future<bool> updateAppointmentStatus(dynamic id, String status) async {
    await loadToken();
    if (token == null) {
      // ignore: avoid_print
      print("⚠️ updateAppointmentStatus: token is null");
      return false;
    }

    int? intId;
    if (id is int) {
      intId = id;
    } else if (id is String) {
      intId = int.tryParse(id);
    } else {
      intId = int.tryParse(id.toString());
    }

    if (intId == null) {
      // ignore: avoid_print
      print("⚠️ updateAppointmentStatus: invalid id $id");
      return false;
    }

    final normalizedStatus = _normalizeStatus(status);

    // ignore: avoid_print
    print("🔄 updateAppointmentStatus => id=$intId, status=$status, normalized=$normalizedStatus");

    try {
      // ✅ مطابق للباك: PUT /api/appointments/{id}/status
      // الباك يستقبل JSON: { "status": "Confirmed" }
      final res = await http.put(
        _url("/appointments/$intId/status"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode({"status": normalizedStatus}),
      );

      final shortBody =
          res.body.length > 300 ? '${res.body.substring(0, 300)}…' : res.body;

      // ignore: avoid_print
      print("🔄 updateAppointmentStatus [$intId] => ${res.statusCode}");
      // ignore: avoid_print
      print("🔄 updateAppointmentStatus body: $shortBody");

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print("updateAppointmentStatus error: $e");
      return false;
    }
  }

  /// ❌ إلغاء موعد (لو endpoint موجود في الباك)
  static Future<bool> cancelAppointment(dynamic id) async {
    await loadToken();
    if (token == null) return false;

    int? intId;
    if (id is int) {
      intId = id;
    } else if (id is String) {
      intId = int.tryParse(id);
    } else {
      intId = int.tryParse(id.toString());
    }
    if (intId == null) return false;

    try {
      final res = await http.post(
        _url("/appointments/$intId/cancel"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("❌ cancelAppointment status: ${res.statusCode}");
      // ignore: avoid_print
      print("❌ cancelAppointment body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print("cancelAppointment error: $e");
      return false;
    }
  }

  // ================== Admin APIs ====================

  /// 🧾 مواعيد الأدمن (جميع المواعيد)
  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/admin/appointments"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("🛡️ Admin appointments status: ${res.statusCode}");
      // ignore: avoid_print
      print("🛡️ Admin appointments body: ${res.body}");

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

  /// 👥 جلب جميع المستخدمين (خاصة بالأدمن)
  static Future<List<dynamic>> getAllUsers() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/admin/users"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("🧾 getAllUsers status: ${res.statusCode}");
      // ignore: avoid_print
      print("🧾 getAllUsers body: ${res.body}");

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

  /// ========== Admin: Lists ==========

  static Future<List<dynamic>> getAllDoctors() async {
    try {
      final res = await http.get(_url("/doctors"), headers: _jsonHeaders());

      // ignore: avoid_print
      print("👨‍⚕️ getAllDoctors status: ${res.statusCode}");
      // ignore: avoid_print
      print("👨‍⚕️ getAllDoctors body: ${res.body}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
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

      // ignore: avoid_print
      print("👥 getAllPatients status: ${res.statusCode}");
      // ignore: avoid_print
      print("👥 getAllPatients body: ${res.body}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
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

      // ignore: avoid_print
      print("📅 getAllAppointments status: ${res.statusCode}");
      // ignore: avoid_print
      print("📅 getAllAppointments body: ${res.body}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return List<dynamic>.from(data['items']);
      }
    } catch (e) {
      // ignore: avoid_print
      print("getAllAppointments error: $e");
    }
    return [];
  }

  /// ========== Admin: Stats ==========

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

      // ignore: avoid_print
      print("📊 getAdminStats status: ${res.statusCode}");
      // ignore: avoid_print
      print("📊 getAdminStats body: ${res.body}");

      final data = _tryDecode(res.body);
      if (res.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    // 2) fallback: احسبها من الداتا
    try {
      final apps = await getAllAppointments();
      int confirmed = 0, rejected = 0, pending = 0;
      for (final a in apps) {
        final s = (a['status'] ?? '').toString().toLowerCase();
        if (s == 'confirmed' || s == 'accepted') {
          confirmed++;
        } else if (s == 'rejected') rejected++;
        else pending++;
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

  /// 🩺 إنشاء سجل / تقرير طبي جديد للمريض (يستخدمه الطبيب)
  static Future<Map<String, dynamic>?> createMedicalRecord({
    required int patientId,
    required String diagnosis,
    required String notes,
    String? medication,
    String? allergies,
    String? sideEffects,
  }) async {
    await loadToken();
    if (token == null) {
      // ignore: avoid_print
      print("⚠️ createMedicalRecord: token is null");
      return null;
    }

    try {
      final body = {
        "patientId": patientId,
        "diagnosis": diagnosis,
        "notes": notes,
        "medication": medication,
        "allergies": allergies,
        "sideEffects": sideEffects,
      };

      final res = await http.post(
        _url("/medical-records"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode(body),
      );

      // ignore: avoid_print
      print("🩺 createMedicalRecord status: ${res.statusCode}");
      // ignore: avoid_print
      print("🩺 createMedicalRecord body: ${res.body}");

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

  /// 📚 جلب السجلات الطبية لمريض معيّن (يستخدمها الطبيب)
  static Future<List<dynamic>> getPatientMedicalRecords(int patientId) async {
    await loadToken();
    if (token == null) {
      // ignore: avoid_print
      print("⚠️ getPatientMedicalRecords: token is null");
      return [];
    }

    try {
      final res = await http.get(
        _url("/medical-records/patient/$patientId"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📚 getPatientMedicalRecords status: ${res.statusCode}");
      // ignore: avoid_print
      print("📚 getPatientMedicalRecords body: ${res.body}");

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

  /// 📂 جلب السجلات الطبية للمستخدم الحالي (ملف المريض نفسه)
  static Future<List<dynamic>> getMyMedicalRecords() async {
    await loadToken();
    if (token == null) {
      // ignore: avoid_print
      print("⚠️ getMyMedicalRecords: token is null");
      return [];
    }

    try {
      final res = await http.get(
        _url("/medical-records/mine"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📂 getMyMedicalRecords status: ${res.statusCode}");
      // ignore: avoid_print
      print("📂 getMyMedicalRecords body: ${res.body}");

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
}
