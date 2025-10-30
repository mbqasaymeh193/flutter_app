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
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

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

  // 🧾 تسجيل مستخدم جديد
  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = "Patient",
    String specialty = "General",
  }) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/register");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "password": password,
          "role": role,
          "specialty": specialty
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  // 👩‍⚕️ جلب قائمة الأطباء
  static Future<List<dynamic>> getDoctors() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
      final res = await http.get(url);
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("getDoctors error: $e");
      return [];
    }
  }

  // 📅 حجز موعد
  static Future<bool> bookAppointment({
    required int doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await loadToken();
    if (token == null) return false;

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/book");
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctorId": doctorId,
          "startsAt": startsAt.toIso8601String(),
          "endsAt": endsAt.toIso8601String(),
        }),
      );
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
      final res = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("getMyAppointments error: $e");
      return [];
    }
  }

  // 🩺 مواعيد الطبيب
  static Future<List<dynamic>> getDoctorAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/doctor");
      final res = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      print("getDoctorAppointments error: $e");
      return [];
    }
  }

  // ✅ تحديث حالة الموعد
  static Future<bool> updateAppointmentStatus(int id, String status) async {
    await loadToken();
    if (token == null) return false;

    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/$id/status");
      final res = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": status}),
      );
      return res.statusCode == 200;
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
      return res.statusCode == 200;
    } catch (e) {
      print("resetPassword error: $e");
      return false;
    }
  }

  static Future getAdminAppointments() async {}
}
