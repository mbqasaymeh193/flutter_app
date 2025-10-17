import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static String? token;

  // تسجيل الدخول
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$apiBaseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return data;
    } else {
      return null;
    }
  }

  // جلب قائمة الأطباء
  static Future<List<dynamic>> getDoctors() async {
    final url = Uri.parse('$apiBaseUrl/doctors');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في تحميل الأطباء');
    }
  }

  // حجز موعد
  static Future<bool> bookAppointment(Map<String, dynamic> appointment) async {
    final url = Uri.parse('$apiBaseUrl/appointments/book');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(appointment),
    );
    return response.statusCode == 201;
  }
}
