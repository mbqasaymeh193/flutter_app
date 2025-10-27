import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static String? token;

  // 🔹 تخزين التوكن بعد تسجيل الدخول
  static Future<void> _saveToken(String newToken) async {
    token = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', newToken);
  }

  // 🔹 تحميل التوكن المخزن عند تشغيل التطبيق
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
  }

  // 🔐 تسجيل الدخول
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 🧑‍⚕️ جلب قائمة الأطباء
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
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    try {
      if (token == null) await loadToken();

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

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Booking Error: $e");
      return false;
    }
  }

  // 🧾 مواعيد المريض
  static Future<List<dynamic>?> getMyAppointments() async {
    try {
      if (token == null) await loadToken();
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/mine");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("GetMyAppointments Error: $e");
      return null;
    }
  }

  // 🩺 مواعيد الطبيب
  static Future<List<dynamic>?> getDoctorAppointments() async {
    try {
      if (token == null) await loadToken();
      final url = Uri.parse("${AppConfig.apiBaseUrl}/appointments/doctor");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("GetDoctorAppointments Error: $e");
      return null;
    }
  }

  // ✅ تأكيد أو رفض موعد
  static Future<bool> updateAppointmentStatus(int id, String status) async {
    try {
      if (token == null) await loadToken();

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
      print("UpdateAppointmentStatus Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
  try {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return data; // يحتوي على token و role و name
    } else {
      return null;
    }
  } catch (e) {
    print("Login Error: $e");
    return null;
  }
}


  // 🔑 نسيان كلمة المرور
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/password/forgot");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // 🔑 إعادة تعيين كلمة المرور
  static Future<Map<String, dynamic>?> resetPassword(
      String email, String newPassword) async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/password/reset");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }
}
