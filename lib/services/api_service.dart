import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🌐 عنوان الـ API (تأكد من تغييره إذا كنت على سيرفر فعلي)
  static const String baseUrl = "http://10.0.2.2:7000/api";
  static String? token;

  // ✅ تخزين التوكن بعد تسجيل الدخول
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    token = newToken;
    await prefs.setString('jwt_token', newToken);
  }

  // ✅ تحميل التوكن عند تشغيل التطبيق
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
  }

  // ✅ تسجيل الخروج (حذف التوكن)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;
    await prefs.remove('jwt_token');
  }

  // 🔐 تسجيل الدخول
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/login");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("🟢 Login Response: ${res.statusCode} | ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
      } else {
        print("🔴 Login failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Login error: $e");
      return null;
    }
  }

  // 🧾 إنشاء حساب جديد
  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = "Patient",
    String specialty = "General",
  }) async {
    try {
      final url = Uri.parse("$baseUrl/register");
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

      print("🟢 Register Response: ${res.statusCode} | ${res.body}");
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("⚠️ Register error: $e");
      return false;
    }
  }

  // 👩‍⚕️ جلب قائمة الأطباء
  static Future<List<dynamic>> getDoctors() async {
    try {
      final url = Uri.parse("$baseUrl/doctors");
      final res = await http.get(url);
      print("🟢 getDoctors Response: ${res.statusCode}");
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        print("🔴 Failed to load doctors: ${res.body}");
        throw Exception("Failed to load doctors");
      }
    } catch (e) {
      print("⚠️ getDoctors error: $e");
      rethrow;
    }
  }

  // 📅 حجز موعد (للمريض)
  static Future<bool> bookAppointment({
    required int doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await loadToken();
    if (token == null) {
      print("🔴 Booking failed: token is null");
      return false;
    }

    final url = Uri.parse("$baseUrl/appointments/book");
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

    print("📅 Booking Response: ${res.statusCode} | ${res.body}");
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // 📋 مواعيد المريض
  static Future<List<dynamic>?> getMyAppointments() async {
    await loadToken();
    if (token == null) return null;

    final url = Uri.parse("$baseUrl/appointments/mine");
    final res = await http.get(url, headers: {"Authorization": "Bearer $token"});

    print("🟢 getMyAppointments: ${res.statusCode}");
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // 🩺 مواعيد الطبيب
  static Future<List<dynamic>?> getDoctorAppointments() async {
    await loadToken();
    if (token == null) return null;

    final url = Uri.parse("$baseUrl/appointments/doctor");
    final res = await http.get(url, headers: {"Authorization": "Bearer $token"});

    print("🟢 getDoctorAppointments: ${res.statusCode}");
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ✅ تحديث حالة الموعد (قبول / رفض)
  static Future<bool> updateAppointmentStatus(int id, String status) async {
    await loadToken();
    if (token == null) return false;

    final url = Uri.parse("$baseUrl/appointments/$id/status");
    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"status": status}), // ✅ التصحيح المهم هنا
    );

    print("🟢 updateAppointmentStatus: ${res.statusCode}");
    return res.statusCode == 200;
  }

  // 🔑 نسيت كلمة المرور
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final url = Uri.parse("$baseUrl/password/forgot");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      print("🟢 forgotPassword: ${res.statusCode}");
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("⚠️ forgotPassword error: $e");
      return null;
    }
  }

  // 🔒 تغيير كلمة المرور بعد تسجيل الدخول
  static Future<bool> changePassword(String oldPass, String newPass) async {
    await loadToken();
    if (token == null) return false;

    final url = Uri.parse("$baseUrl/password/change");
    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"oldPassword": oldPass, "newPassword": newPass}),
    );

    print("🟢 changePassword: ${res.statusCode}");
    return res.statusCode == 200;
  }

  // ♻️ إعادة تعيين كلمة المرور (من شاشة نسيت كلمة المرور)
  static Future<bool> resetPassword(String email, String newPassword) async {
    final url = Uri.parse("$baseUrl/password/reset");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "newPassword": newPassword}),
    );

    print("🟢 resetPassword: ${res.statusCode}");
    return res.statusCode == 200;
  }
}
