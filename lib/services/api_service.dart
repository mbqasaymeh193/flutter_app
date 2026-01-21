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
    if (token != null && token!.isNotEmpty) return;
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

  /// Helper: جرّب أكثر من Endpoint لنفس العملية (Fallback)
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

  static Future<http.Response> _postWithFallback(
    List<String> paths, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    http.Response? last;
    for (final p in paths) {
      final res = await http.post(
        _url(p),
        headers: _jsonHeaders(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      );
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
        _url("/api/login"),
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

  /// 🧾 إنشاء حساب جديد (حسب باك اندك: FirstName/LastName/NationalId/PhoneNumber)
  /// ملاحظة: أنت كنت مرسل fullName فقط، وهذا سيكسر التسجيل في الباك اند الحالي.
  static Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String nationalId,
    required String phoneNumber,
    String role = "Patient",
    String? specialty, // للطبيب فقط
  }) async {
    try {
      final body = <String, dynamic>{
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        "nationalId": nationalId,
        "phoneNumber": phoneNumber,
        "role": role,
        "specialty": specialty, // إذا null لا مشكلة
      };

      final res = await http.post(
        _url("/api/register"),
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

  // ⚠️ هذه الـ endpoints غير موجودة في Swagger اللي عندك حالياً.
  // إذا ما عندك باك اند لها: اتركها لكن لن تعمل (لن تكسر التطبيق إلا إذا استدعيتها).
  static Future<bool> forgotPassword(String email) async {
    try {
      final res = await http.post(
        _url("/api/password/forgot"),
        headers: _jsonHeaders(),
        body: jsonEncode({"email": email}),
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
      final res = await http.put(
        _url("/api/password/change"),
        headers: _jsonHeaders(withAuth: true),
        body: jsonEncode({"oldPassword": oldPass, "newPassword": newPass}),
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("changePassword error: $e");
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final res = await http.post(
        _url("/api/password/reset"),
        headers: _jsonHeaders(),
        body: jsonEncode({"email": email, "newPassword": newPassword}),
      );
      return res.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("resetPassword error: $e");
      return false;
    }
  }

  // ==================== Doctors =====================

  /// 👩‍⚕️ جلب قائمة الأطباء (Public)
  static Future<List<dynamic>> getDoctors() async {
    try {
      final res = await http.get(_url("/api/doctors"), headers: _jsonHeaders());
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
        _url("/api/appointments/book"),
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
        _url("/api/appointments/mine"),
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
        _url("/api/doctor/appointments"),
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
        _url("/api/appointments/$intId/status"),
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

  // ================== Admin APIs ====================

  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/api/admin/appointments"),
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
        _url("/api/admin/users"),
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
      final res = await http.get(_url("/api/doctors"), headers: _jsonHeaders());
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

  /// ⚠️ endpoint /api/admin/patients غير ظاهر في Swagger عندك
  static Future<List<dynamic>> getAllPatients() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/api/admin/patients"),
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
      final res = await http.get(
        _url("/api/admin/stats"),
        headers: _jsonHeaders(withAuth: true),
      );

      final data = _tryDecode(res.body);
      if (res.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    // fallback
    try {
      final apps = await getAdminAppointments();
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

  /// ✅ إنشاء سجل طبي (Doctor only)
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
      final res = await http.post(
        _url("/api/medical-records"),
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

      // ignore: avoid_print
      print("📝 createMedicalRecord status: ${res.statusCode}");
      // ignore: avoid_print
      print("📝 createMedicalRecord body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print("createMedicalRecord error: $e");
      return false;
    }
  }

  /// ✅ سجلات مريض محدد (Doctor)
  static Future<List<dynamic>> getMedicalRecordsForPatient(int patientId) async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/api/medical-records/patient/$patientId"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📚 getMedicalRecordsForPatient status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("getMedicalRecordsForPatient error: $e");
      return [];
    }
  }

  /// ✅ سجلاتي أنا (Patient)
  static Future<List<dynamic>> getMyMedicalRecords() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/api/medical-records/mine"),
        headers: _jsonHeaders(withAuth: true),
      );

      // ignore: avoid_print
      print("📚 getMyMedicalRecords status: ${res.statusCode}");

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

  // ================= Doctor Patients Helper =================

  /// ✅ (حل عملي) استخرج قائمة مرضى فريدين من مواعيد الطبيب
  /// يريحك من أي endpoint إضافي
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
        // fallback إذا الباك رجع patientName فقط
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

  /// ✅ إذا عندك Endpoint جاهز للمرضى (اختياري) بنعمل له fallback
  /// (إن لم يوجد يرجع []
  static Future<List<dynamic>> getDoctorPatients() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _getWithFallback(
        const [
          "/api/doctor/patients",
          "/api/doctor/patients-screen",
          "/api/doctor/patients/list",
        ],
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

  /// 🔔 إشعارات المستخدم الحالي
  static Future<List<dynamic>> getMyNotifications() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await http.get(
        _url("/api/notifications/mine"),
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
      print("getMyNotifications error: $e");
      return [];
    }
  }

  /// 🔢 عدد الإشعارات غير المقروءة
  /// الباك اند عندك يرجّع: { "unread": 5 }
  static Future<int> getUnreadCount() async {
    await loadToken();
    if (token == null) return 0;

    try {
      final res = await http.get(
        _url("/api/notifications/unread-count"),
        headers: _jsonHeaders(withAuth: true),
      );

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

  /// ✅ تعليم إشعار كمقروء
  static Future<bool> markNotificationRead(int id) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await http.put(
        _url("/api/notifications/$id/read"),
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
        _url("/api/notifications/read-all"),
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
