import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static String? token;

  // 🔐 تسجيل الدخول
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("🔵 Login Request: ${response.statusCode}");
      print("📄 ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data["token"];
        return data;
      }
      return null;
    } catch (e) {
      print("🔴 Login Error: $e");
      return null;
    }
  }

  // 👩‍⚕️ جلب الأطباء
  static Future<List<dynamic>> getDoctors() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load doctors");
      }
    } catch (e) {
      print("🔴 getDoctors Error: $e");
      rethrow;
    }
  }

  // 📅 حجز موعد
  static Future<bool> bookAppointment({
    required int doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    if (token == null) {
      print("🔴 Missing token for booking");
      return false;
    }

    final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/book");
    final response = await http.post(
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

    print("📅 Booking Response: ${response.statusCode}");
    print(response.body);

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 🧍‍♂️ مواعيد المريض
  static Future<List<dynamic>?> getMyAppointments() async {
    if (token == null) return null;
    final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/mine");
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // 👨‍⚕️ مواعيد الطبيب
  static Future<List<dynamic>?> getDoctorAppointments() async {
    if (token == null) return null;
    final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/doctor");
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ✅ تحديث حالة الموعد
  static Future<bool> updateAppointmentStatus(int id, String status) async {
    if (token == null) return false;
    final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/$id/status");
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(status),
    );
    return response.statusCode == 200;
  }

  // 🔑 نسيت كلمة المرور
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/password/forgot");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ♻️ إعادة تعيين كلمة المرور
  static Future<Map<String, dynamic>?> resetPassword(String email, String newPassword) async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/password/reset");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // 🔒 تغيير كلمة المرور أثناء تسجيل الدخول
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (token == null) return false;
    final url = Uri.parse("${AppConfig.apiBaseUrl}/password/change");
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );
    return response.statusCode == 200;
  }
}
