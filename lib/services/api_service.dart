import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String? token;

  // ✅ تخزين التوكن
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    token = newToken;
    await prefs.setString('jwt_token', newToken);
  }

  // ✅ تحميل التوكن
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
  }

  // ✅ حذف التوكن عند تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;
    await prefs.remove('jwt_token');
  }

  // 🔐 تسجيل الدخول
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("🔐 login status: ${res.statusCode}");
      print("🔐 login body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) await saveToken(data['token']);
        return data;
      }
      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // 🧾 إنشاء حساب جديد (يدعم الدور والتخصص)
  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = "Patient",
    String specialty = "General",
  }) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/register");
      final body = {
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
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("📦 Register status: ${res.statusCode}");
      print("📦 Register body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("⚠️ Register error: $e");
      return false;
    }
  }

  // 👩‍⚕️ جلب قائمة الأطباء
  static Future<List<dynamic>> getDoctors() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
      final res = await http.get(url);
      print("👩‍⚕️ getDoctors status: ${res.statusCode}");
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("getDoctors error: $e");
      return [];
    }
  }

  // 📅 حجز موعد
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
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/book");
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctorId": id,
          "startsAt": startsAt.toIso8601String(),
          "endsAt": endsAt.toIso8601String(),
        }),
      );
      print("📅 bookAppointment status: ${res.statusCode}");
      print("📅 bookAppointment body: ${res.body}");
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("bookAppointment error: $e");
      return false;
    }
  }

  // 📋 مواعيد المريض
  static Future<List<dynamic>> getMyAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/mine");
      final res =
          await http.get(url, headers: {"Authorization": "Bearer $token"});

      print("📋 getMyAppointments status: ${res.statusCode}");
      print("📋 getMyAppointments body: ${res.body}");

      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("getMyAppointments error: $e");
      return [];
    }
  }

  // 🩺 جلب مواعيد الطبيب
  static Future<List<dynamic>?> getDoctorAppointments() async {
    await loadToken();
    if (token == null) {
      print("⚠️ getDoctorAppointments: token is null");
      return [];
    }

    try {
      // ✅ مطابق للباك: GET /api/appointments/doctor
      final url =
          Uri.parse("${AppConfig.apiBaseUrl}/appointments/doctor");
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("📦 Doctor appointments status: ${res.statusCode}");
      print("📦 Doctor appointments body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['appointments'] is List) {
          return List<dynamic>.from(data['appointments']);
        }
      }
      return [];
    } catch (e) {
      print("⚠️ getDoctorAppointments error: $e");
      return [];
    }
  }

  // 🔁 تطبيع قيم الحالة لتوافق الـ Backend
  static String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == 'confirmed') return 'Confirmed';
    if (lower == 'accepted') return 'Accepted';
    if (lower == 'rejected') return 'Rejected';
    if (lower == 'pending') return 'Pending';
    return s;
  }

  // ✅ تحديث حالة الموعد
  static Future<bool> updateAppointmentStatus(dynamic id, String status) async {
    await loadToken();
    if (token == null) {
      print("⚠️ updateAppointmentStatus: token is null");
      return false;
    }

    int? intId;
    if (id is int) {
      intId = id;
    } else if (id is String) {
      intId = int.tryParse(id);
    }
    if (intId == null) {
      print("⚠️ updateAppointmentStatus: invalid id $id");
      return false;
    }

    final normalizedStatus = _normalizeStatus(status);
    print("🔄 updateAppointmentStatus => id=$intId, status=$status, normalized=$normalizedStatus");

    try {
      // ✅ مطابق للباك: PUT /api/appointments/{id}/status
      // والباك يستقبل [FromBody] string status → نص خام
      final url =
          Uri.parse("${AppConfig.apiBaseUrl}/appointments/$intId/status");

      final res = await http.put(
        url,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Authorization": "Bearer $token",
        },
        // 🟢 نرسل نص عادي بدون JSON:
        // body: Confirmed أو Rejected
        body: normalizedStatus,
      );

      final shortBody =
          res.body.length > 300 ? '${res.body.substring(0, 300)}…' : res.body;

      print("🔄 updateAppointmentStatus [$intId] => ${res.statusCode}");
      print("🔄 updateAppointmentStatus body: $shortBody");

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("updateAppointmentStatus error: $e");
      return false;
    }
  }

  // 🔑 نسيت كلمة المرور
  static Future<bool> forgotPassword(String email) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/password/forgot");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      print("🔑 forgotPassword status: ${res.statusCode}");
      print("🔑 forgotPassword body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("forgotPassword error: $e");
      return false;
    }
  }

  // 🔐 تغيير كلمة المرور بعد تسجيل الدخول
  static Future<bool> changePassword(String oldPass, String newPass) async {
    await loadToken();
    if (token == null) return false;

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/password/change");
      final res = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"oldPassword": oldPass, "newPassword": newPass}),
      );
      print("🔐 changePassword status: ${res.statusCode}");
      print("🔐 changePassword body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("changePassword error: $e");
      return false;
    }
  }

  // 🧩 إعادة تعيين كلمة المرور (من شاشة نسيت كلمة المرور)
  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/password/reset");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "newPassword": newPassword}),
      );
      print("🧩 resetPassword status: ${res.statusCode}");
      print("🧩 resetPassword body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("resetPassword error: $e");
      return false;
    }
  }

  // 🧾 مواعيد الأدمن (جميع المواعيد)
  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/admin/appointments");
      final res = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("🛡️ Admin appointments status: ${res.statusCode}");
      print("🛡️ Admin appointments body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
        return [];
      }
      return [];
    } catch (e) {
      print("getAdminAppointments error: $e");
      return [];
    }
  }

  // 👥 جلب جميع المستخدمين (خاصة بالأدمن)
  static Future<List<dynamic>> getAllUsers() async {
    await loadToken();
    if (token == null) return [];

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/admin/users");
      final res = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("🧾 getAllUsers status: ${res.statusCode}");
      print("🧾 getAllUsers body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) {
          return List<dynamic>.from(data['items']);
        }
      }
      return [];
    } catch (e) {
      print("getAllUsers error: $e");
      return [];
    }
  }

  // ❌ إلغاء موعد
  static Future<bool> cancelAppointment(dynamic id) async {
    await loadToken();
    if (token == null) return false;

    int? intId;
    if (id is int) {
      intId = id;
    } else if (id is String) {
      intId = int.tryParse(id);
    }
    if (intId == null) return false;

    try {
      final url =
          Uri.parse("${AppConfig.apiBaseUrl}/appointments/$intId/cancel");
      final res =
          await http.post(url, headers: {"Authorization": "Bearer $token"});
      print("❌ cancelAppointment status: ${res.statusCode}");
      print("❌ cancelAppointment body: ${res.body}");
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("cancelAppointment error: $e");
      return false;
    }
  }

  // ========== Helpers ==========
  static Map<String, String> _jsonHeaders({bool withAuth = false}) {
    final h = {"Content-Type": "application/json"};
    if (withAuth && token != null) h["Authorization"] = "Bearer $token";
    return h;
  }

  // ========== Admin: Stats ==========
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/admin/stats");
      final res = await http.get(url, headers: _jsonHeaders(withAuth: true));
      print("📊 getAdminStats status: ${res.statusCode}");
      print("📊 getAdminStats body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {}

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

  // ========== Admin: Lists ==========
  static Future<List<dynamic>> getAllDoctors() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
      final res = await http.get(url, headers: _jsonHeaders());
      print("👨‍⚕️ getAllDoctors status: ${res.statusCode}");
      print("👨‍⚕️ getAllDoctors body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (e) {
      print("getAllDoctors error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getAllPatients() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/admin/patients");
      final res = await http.get(url, headers: _jsonHeaders(withAuth: true));
      print("👥 getAllPatients status: ${res.statusCode}");
      print("👥 getAllPatients body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (e) {
      print("getAllPatients error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getAllAppointments() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/admin/appointments");
      final res = await http.get(url, headers: _jsonHeaders(withAuth: true));
      print("📅 getAllAppointments status: ${res.statusCode}");
      print("📅 getAllAppointments body: ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
        if (data is Map && data['items'] is List) return data['items'];
      }
    } catch (e) {
      print("getAllAppointments error: $e");
    }
    return [];
  }
}
