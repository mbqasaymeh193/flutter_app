import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static String? token;

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getDoctors() async {
    final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load doctors');
    }
  }
    // حجز موعد فعلي في الباك إند
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

}
