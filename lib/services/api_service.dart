import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static String? token;

  // 🔐 تسجيل الدخول
  static Future<Map<String, dynamic>?> login(String email, String password) async {
  try {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
    print("🔵 Login Request URL: $url");
    print("📧 Email: $email | 🔑 Password: $password");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("🟢 Login Response: ${response.statusCode}");
    print("📄 Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data["token"];
      return data;
    } else {
      return null;
    }
  } catch (e) {
    print("🔴 Login Error: $e");
    return null;
  }
}



  // 👩‍⚕️ جلب قائمة الأطباء
  static Future<List<dynamic>> getDoctors() async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load doctors');
    }
  }

  // 📅 حجز موعد
  static Future<bool> bookAppointment({
    required int doctorId,
    required String date,
    required String time,
  }) async {
    try {
      if (token == null) {
        print("🔴 Cannot book appointment: token is null!");
        return false;
      }

      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/book");
      print("📅 Booking Appointment URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctorId": doctorId,
          "date": date,
          "time": time,
        }),
      );

      print("🟢 Booking Response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("🔴 Booking Error: $e");
      return false;
    }
  }

  // 📋 جلب مواعيد المريض
  static Future<List<dynamic>?> getMyAppointments() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/mine");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("🔴 getMyAppointments Error: $e");
      return null;
    }
  }

  // 📋 جلب مواعيد الطبيب
  static Future<List<dynamic>?> getDoctorAppointments() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/doctor");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("🔴 getDoctorAppointments Error: $e");
      return null;
    }
  }

  // 🔄 تحديث حالة الموعد (قبول / رفض)
  static Future<bool> updateAppointmentStatus(int id, String status) async {
    try {
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
    } catch (e) {
      print("🔴 updateAppointmentStatus Error: $e");
      return false;
    }
  }

  // 📨 نسيت كلمة المرور
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/password/forgot");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("🔴 ForgotPassword failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("⚠️ ForgotPassword Error: $e");
      return null;
    }
  }

  // 🔑 إعادة تعيين كلمة المرور
  static Future<Map<String, dynamic>?> resetPassword(String token, String newPassword) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/password/reset");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("🔴 ResetPassword failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("⚠️ ResetPassword Error: $e");
      return null;
    }
  }

}
