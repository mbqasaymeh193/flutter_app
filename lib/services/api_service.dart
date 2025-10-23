import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static String? token;

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/login");
      print("🔵 Login Request URL: $url");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("🟢 Login Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'];
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print("🔴 Login Error: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getDoctors() async {
    try {
      final url = Uri.parse("${AppConfig.apiBaseUrl}/doctors");
      print("🔵 Fetching doctors from $url");

      final response = await http.get(url);

      print("🟢 Doctors Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("🔴 Doctors Error: $e");
      return [];
    }
  }
}
