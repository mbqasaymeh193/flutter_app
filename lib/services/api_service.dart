// ignore_for_file: unused_import, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/doctor_profile.dart';

class ApiService {
  static String? token;

  // ✅ مفاتيح موحّدة (وتدعم القديم أيضًا)
  static const String _kTokenNew = 'token';
  static const String _kTokenOld = 'jwt_token';

  static const String _kRole = 'role';
  static const String _kName = 'name';
  static const String _kUserId = 'userId';

  // ✅ Timeout لكل الطلبات
  static const Duration _timeout = Duration(seconds: 15);

  // ====================== BaseUrl ======================
  /// يدعم حالتين:
  /// 1) AppConfig.apiBaseUrl = http://host:port/api
  /// 2) AppConfig.apiBaseUrl = http://host:port  (نضيف /api تلقائياً)
  static String get baseUrl {
    String b = AppConfig.apiBaseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    if (b.toLowerCase().endsWith('/api')) return b;
    return '$b/api';
  }

  static Uri _url(String path, {Map<String, String>? query}) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$p').replace(queryParameters: query);
  }

  // ====================== Token (COMPAT) ======================

  /// ✅ موجودة لأن ملفاتك تستدعيها
  static Future<void> loadToken() async {
    if (token != null && token!.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kTokenNew) ?? prefs.getString(_kTokenOld);
  }

  /// ✅ تخزين التوكن (يكتب الجديد + القديم للتوافق)
  static Future<void> saveToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    token = newToken;
    await prefs.setString(_kTokenNew, newToken);
    await prefs.setString(_kTokenOld, newToken);
  }

  /// ✅ تخزين بيانات المستخدم الأساسية
  static Future<void> saveUserInfo({
    String? role,
    String? name,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (role != null) await prefs.setString(_kRole, role);
    if (name != null) await prefs.setString(_kName, name);
    if (userId != null) await prefs.setInt(_kUserId, userId);
  }

  /// ✅ حذف كل شيء عند تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    token = null;

    await prefs.remove(_kTokenNew);
    await prefs.remove(_kTokenOld);
    await prefs.remove(_kRole);
    await prefs.remove(_kName);
    await prefs.remove(_kUserId);
  }

  // ====================== Helpers ======================

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

  static Map<String, String> _authHeaders() => _jsonHeaders(withAuth: true);

  static dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String? _pickString(Map map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static int? _pickInt(Map map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final n = int.tryParse(v.toString());
      if (n != null) return n;
    }
    return null;
  }

  static bool _hasAnyKey(Map map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k)) return true;
    }
    return false;
  }

  static int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static Future<int?> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kUserId);
    if (v != null && v > 0) return v;
    final s = prefs.getString(_kUserId);
    final n = int.tryParse(s ?? '');
    if (n != null && n > 0) return n;
    return null;
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['appointments'] is List) return List<dynamic>.from(data['appointments']);
      if (data['items'] is List) return List<dynamic>.from(data['items']);
      if (data['data'] is List) return List<dynamic>.from(data['data']);
    }
    return [];
  }

  static Future<http.Response> _get(
    String path, {
    bool withAuth = false,
    Map<String, String>? query,
  }) async {
    // ✅ ملاحظة: loadToken لا يضر حتى لو الطلب بدون Auth
    await loadToken();
    return http
        .get(_url(path, query: query), headers: _jsonHeaders(withAuth: withAuth))
        .timeout(_timeout);
  }

  static Future<http.Response> _post(
    String path, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    await loadToken();
    return http
        .post(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> _put(
    String path, {
    bool withAuth = false,
    Map<String, dynamic>? body,
  }) async {
    await loadToken();
    return http
        .put(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
  }

  /// ✅ PUT يدعم Map أو List (مهم لـ working-hours)
  static Future<http.Response> _putAny(
    String path, {
    bool withAuth = false,
    Object? body,
  }) async {
    await loadToken();
    return http
        .put(
          _url(path),
          headers: _jsonHeaders(withAuth: withAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> _delete(
    String path, {
    bool withAuth = false,
  }) async {
    await loadToken();
    return http
        .delete(_url(path), headers: _jsonHeaders(withAuth: withAuth))
        .timeout(_timeout);
  }

  // ====================== Auth ======================

  /// ✅ POST /api/login
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await _post(
        "/login",
        body: {"email": email, "password": password},
      );

      final data = _tryDecode(res.body);

      if (res.statusCode == 200 && data is Map) {
        final map = Map<String, dynamic>.from(data);

        final t = _pickString(map, ["token", "Token"]);
        if (t != null && t.isNotEmpty) {
          await saveToken(t);
        }

        final role = _pickString(map, ["role", "Role"]) ?? "";
        final name = _pickString(map, ["fullName", "FullName", "name", "Name"]) ?? "";
        final userId = _pickInt(map, ["userId", "UserId", "id", "Id"]);

        await saveUserInfo(role: role, name: name, userId: userId);

        // لتوافق الشاشات
        map['name'] ??= name;
        map['fullName'] ??= name;
        if (map['userId'] == null && userId != null) map['userId'] = userId;

        return map;
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _splitName(String fullName) {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return {'firstName': '', 'lastName': ''};
    if (parts.length == 1) return {'firstName': parts.first, 'lastName': parts.first};
    return {'firstName': parts.first, 'lastName': parts.sublist(1).join(' ')};
  }

  /// ✅ POST /api/register
  /// قديم: يرجع bool (حتى لا تنكسر ملفاتك)
  static Future<bool> register({
    String? fullName,
    String? firstName,
    String? lastName,
    required String email,
    required String password,
    String? nationalId,
    String? phoneNumber,
    String role = "Patient",
    String? specialty,
  }) async {
    final res = await registerDetailed(
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      nationalId: nationalId,
      phoneNumber: phoneNumber,
      role: role,
      specialty: specialty,
    );
    return res != null;
  }

  /// ✅ نسخة “تفصيلية” (جديدة) ترجع Response Map إذا احتجتها
  static Future<Map<String, dynamic>?> registerDetailed({
    String? fullName,
    String? firstName,
    String? lastName,
    required String email,
    required String password,
    String? nationalId,
    String? phoneNumber,
    String role = "Patient",
    String? specialty,
  }) async {
    try {
      String fn = (firstName ?? '').trim();
      String ln = (lastName ?? '').trim();

      if ((fn.isEmpty || ln.isEmpty) && (fullName ?? '').trim().isNotEmpty) {
        final parts = _splitName(fullName!.trim());
        fn = parts['firstName'] ?? fn;
        ln = parts['lastName'] ?? ln;
      }

      if (fn.isEmpty || ln.isEmpty) return null;
      if ((nationalId ?? '').trim().isEmpty) return null;
      if ((phoneNumber ?? '').trim().isEmpty) return null;

      final body = <String, dynamic>{
        "firstName": fn,
        "lastName": ln,
        "email": email.trim(),
        "password": password,
        "role": role,
        "nationalId": nationalId!.trim(),
        "phoneNumber": phoneNumber!.trim(),
      };

      final isDoctor = role.toLowerCase() == 'doctor';
      if (isDoctor) {
        if ((specialty ?? '').trim().isEmpty) return null;
        body["specialty"] = specialty!.trim();
      }

      final res = await _post("/register", body: body);
      final data = _tryDecode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is Map) return Map<String, dynamic>.from(data);

      return null;
    } catch (_) {
      return null;
    }
  }

  /// ✅ POST /api/password/forgot
  static Future<bool> forgotPassword(String email) async {
    try {
      final res = await _post("/password/forgot", body: {"email": email.trim()});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// ✅ PUT /api/password/change (Auth)
  static Future<bool> changePassword(String oldPass, String newPass) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put(
        "/password/change",
        withAuth: true,
        body: {"oldPassword": oldPass, "newPassword": newPass},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ POST /api/password/reset
  static Future<bool> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await _post(
        "/password/reset",
        body: {"email": email.trim(), "code": code.trim(), "newPassword": newPassword},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// ✅ Compatibility (كان عندك)
  static Future<bool> resetPassword(
    String email,
    String newPassword, {
    String? code,
  }) async {
    if ((code ?? '').trim().isEmpty) return false;
    return resetPasswordWithCode(email: email, code: code!.trim(), newPassword: newPassword);
  }

  // ==================== Doctors =====================

  /// ✅ GET /api/doctors
  static Future<List<dynamic>> getDoctors() async {
    try {
      final res = await _get("/doctors");
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final list = await getDoctors();
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// ✅ GET /api/doctors/{doctorId}/available-slots?date=yyyy-MM-dd
  static Future<List<dynamic>> getDoctorAvailableSlots({
    required int doctorId,
    required DateTime date,
  }) async {
    try {
      final yyyy = date.year.toString().padLeft(4, '0');
      final mm = date.month.toString().padLeft(2, '0');
      final dd = date.day.toString().padLeft(2, '0');
      final dateStr = "$yyyy-$mm-$dd";

      final res = await _get(
        "/doctors/$doctorId/available-slots",
        query: {"date": dateStr},
      );

      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ================= Appointments ===================

  /// ✅ POST /api/appointments/book
  /// قديم: يرجع bool حتى لا تنكسر ملفاتك
  static Future<bool> bookAppointment({
    required dynamic doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await loadToken();
    if (token == null) return false;

    final int id = _safeInt(doctorId);
    if (id <= 0) return false;

    try {
      final res = await _post(
        "/appointments/book",
        withAuth: true,
        body: {
          "doctorId": id,
          "startsAt": startsAt.toIso8601String(),
          "endsAt": endsAt.toIso8601String(),
        },
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// ✅ نسخة تفصيلية ترجع Map (جديدة) إذا احتجتها لاحقاً
  static Future<Map<String, dynamic>?> bookAppointmentDetailed({
    required int doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await loadToken();
    if (token == null) return null;

    try {
      final res = await _post(
        "/appointments/book",
        withAuth: true,
        body: {
          "doctorId": doctorId,
          "startsAt": startsAt.toIso8601String(),
          "endsAt": endsAt.toIso8601String(),
        },
      );

      final data = _tryDecode(res.body);
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// ✅ GET /api/appointments/mine
  static Future<List<dynamic>> getMyAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/appointments/mine", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ GET /api/doctor/appointments
  static Future<List<dynamic>> getDoctorAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/doctor/appointments", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ===== Status normalize (supports int or String) =====

  static String _statusFromAny(dynamic v) {
    if (v is int) {
      switch (v) {
        case 0:
          return 'Pending';
        case 1:
          return 'Confirmed';
        case 2:
          return 'Rejected';
        default:
          return 'Pending';
      }
    }
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return 'Pending';
    final lower = s.toLowerCase();
    if (lower == 'confirmed' || lower == 'accepted') return 'Confirmed';
    if (lower == 'rejected') return 'Rejected';
    if (lower == 'pending') return 'Pending';
    return s;
  }

  /// ✅ PUT /api/appointments/{id}/status
  /// Body: { "status": "Confirmed" }
  ///
  /// ⭐ ثابت ومتوافق: يقبل status String أو int
  /// ويرسل للباك String دائمًا.
  static Future<bool> updateAppointmentStatus(dynamic id, dynamic status) async {
    await loadToken();
    if (token == null) return false;

    final int intId = _safeInt(id);
    if (intId <= 0) return false;

    // status could be int or string
    final String statusText = _statusFromAny(status);

    try {
      final res = await _put(
        "/appointments/$intId/status",
        withAuth: true,
        body: {"status": statusText},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ PUT /api/appointments/{id}/status (تفصيلي)
  /// يرجّع statusCode + message إن وُجدت.
  static Future<Map<String, dynamic>?> updateAppointmentStatusDetailed({
    required int appointmentId,
    required String status,
  }) async {
    await loadToken();
    if (token == null) return null;

    if (appointmentId <= 0) return null;

    try {
      final res = await _put(
        "/appointments/$appointmentId/status",
        withAuth: true,
        body: {"status": status},
      );

      final data = _tryDecode(res.body);
      final map = <String, dynamic>{
        "statusCode": res.statusCode,
        "ok": res.statusCode == 200 || res.statusCode == 204,
      };

      if (data is Map) {
        map.addAll(Map<String, dynamic>.from(data));
      } else if (data != null) {
        map["message"] = data.toString();
      }

      return map;
    } catch (_) {
      return null;
    }
  }

  // ================= Wallet =================

  /// ✅ GET /api/wallet/mine
  static Future<Map<String, dynamic>?> getMyWallet() async {
    await loadToken();
    if (token == null) return null;

    try {
      final res = await _get("/wallet/mine", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// ✅ GET /api/wallet/transactions
  static Future<List<dynamic>> getWalletTransactions() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/wallet/transactions", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ================= Payments =================

  /// ✅ POST /api/payments/checkout
  /// method: "wallet" | "card"
  /// (نقبل "visa" أيضاً للتوافق ونحوّلها إلى "card")
  ///
  /// ✅ تعديل مهم: نضمن وجود statusCode في كل الحالات
  static Future<Map<String, dynamic>?> checkoutPayment({
    required int appointmentId,
    required String method, // wallet/card/visa
    String? cardName,
    String? cardNumber,
    String? cardExp,
    String? cardCvv,
  }) async {
    await loadToken();
    if (token == null) return null;

    String m = method.trim().toLowerCase();
    if (m == 'visa') m = 'card';

    try {
      final res = await _post(
        "/payments/checkout",
        withAuth: true,
        body: {
          "appointmentId": appointmentId,
          "method": m,
          "cardName": cardName,
          "cardNumber": cardNumber,
          "cardExp": cardExp,
          "cardCvv": cardCvv,
        },
      );

      final data = _tryDecode(res.body);

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        map["statusCode"] = res.statusCode;
        return map;
      }

      return {"statusCode": res.statusCode, "raw": res.body};
    } catch (_) {
      return null;
    }
  }

  /// ✅ للتوافق مع الشاشات التي تتوقع bool بدل Map
  static Future<bool> checkoutPaymentOk({
    required int appointmentId,
    required String method,
    String? cardName,
    String? cardNumber,
    String? cardExp,
    String? cardCvv,
  }) async {
    final res = await checkoutPayment(
      appointmentId: appointmentId,
      method: method,
      cardName: cardName,
      cardNumber: cardNumber,
      cardExp: cardExp,
      cardCvv: cardCvv,
    );

    final code = res?["statusCode"];
    if (code is int) return code == 200 || code == 201;

    if (res?["success"] == true) return true;
    final st = (res?["status"] ?? "").toString().toLowerCase();
    if (st == "success" || st == "ok") return true;

    return false;
  }

  // ================= Doctor Rating =================

  /// ✅ POST /api/doctor-ratings
  static Future<bool> submitDoctorRating({
    required int appointmentId,
    required int stars,
    String? comment,
  }) async {
    final res = await submitDoctorRatingDetailed(
      appointmentId: appointmentId,
      stars: stars,
      comment: comment,
    );
    return res?['ok'] == true ||
        res?['statusCode'] == 200 ||
        res?['statusCode'] == 201;
  }

  /// ✅ POST /api/doctor-ratings (تفصيلي)
  static Future<Map<String, dynamic>?> submitDoctorRatingDetailed({
    required int appointmentId,
    required int stars,
    String? comment,
  }) async {
    await loadToken();
    if (token == null) return null;

    try {
      final res = await _post(
        "/doctor-ratings",
        withAuth: true,
        body: {"appointmentId": appointmentId, "stars": stars, "comment": comment},
      );

      final data = _tryDecode(res.body);
      final map = <String, dynamic>{
        "statusCode": res.statusCode,
        "ok": res.statusCode == 200 || res.statusCode == 201,
      };

      if (data is Map) {
        map.addAll(Map<String, dynamic>.from(data));
      } else if (data != null) {
        map["message"] = data.toString();
      }

      return map;
    } catch (_) {
      return null;
    }
  }

  // ================= Doctor Profile =================

  /// ✅ PUT /api/doctor/profile
  static Future<bool> updateDoctorProfile(Map<String, dynamic> data) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/doctor/profile", withAuth: true, body: data);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// (قديمة) GET غير موجودة في Swagger، نخليها fallback للتوافق
  static Future<DoctorProfile> getDoctorProfile() async {
    await loadToken();

    // Try if exists in your backend later:
    try {
      final res = await http
          .get(_url('/doctor/profile'), headers: _authHeaders())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return DoctorProfile.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}

    // fallback: from /doctors
    final all = await getAllDoctors();
    if (all.isNotEmpty) {
      final int? userId = await _loadUserId();
      Map<String, dynamic>? found;

      if (userId != null) {
        for (final d in all) {
          final uid = _pickInt(d, ['userId', 'UserId', 'doctorUserId', 'DoctorUserId']);
          if (uid != null && uid == userId) {
            found = d;
            break;
          }
        }

        // As a very last resort, match id ONLY if no explicit userId keys exist
        if (found == null) {
          for (final d in all) {
            if (_hasAnyKey(d, ['userId', 'UserId', 'doctorUserId', 'DoctorUserId'])) {
              continue;
            }
            final id = _pickInt(d, ['id', 'Id']);
            if (id != null && id == userId) {
              found = d;
              break;
            }
          }
        }
      }

      // If still not found, only return a single doctor to avoid wrong data
      final selected = found ?? (all.length == 1 ? all.first : null);
      if (selected != null) {
        final normalized = Map<String, dynamic>.from(selected);
        final altUserId = _pickInt(normalized, ['UserId', 'doctorUserId', 'DoctorUserId']);
        if ((_safeInt(normalized['userId']) <= 0) && altUserId != null) {
          normalized['userId'] = altUserId;
        }
        return DoctorProfile.fromJson(normalized);
      }
    }

    throw Exception('Doctor profile endpoint not available yet.');
  }

  /// (قديمة) GET /doctors/{id} غير موجودة في Swagger غالباً، نخليها fallback
  static Future<DoctorProfile> getDoctorDetails(int doctorId) async {
    try {
      final res = await http.get(_url('/doctors/$doctorId')).timeout(_timeout);
      if (res.statusCode == 200) {
        return DoctorProfile.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}

    final all = await getAllDoctors();
    final found = all.firstWhere(
      (d) {
        final id = _pickInt(d, ['doctorId', 'DoctorId', 'id', 'Id']);
        return id != null && id == doctorId;
      },
      orElse: () => <String, dynamic>{},
    );

    if (found.isNotEmpty) return DoctorProfile.fromJson(found);
    throw Exception('Doctor not found');
  }

  // ================= Doctor Patients =================

  /// ✅ GET /api/doctor/patients
  static Future<List<dynamic>> getDoctorPatients() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/doctor/patients", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ Compatibility: derive patients list from /doctor/appointments
  /// Returns: List of { id, fullName, phoneNumber }
  static Future<List<Map<String, dynamic>>> getPatientsFromDoctorAppointments() async {
    final apps = await getDoctorAppointments();
    if (apps.isEmpty) return [];

    final Map<int, Map<String, dynamic>> byId = {};

    for (final a in apps) {
      if (a is! Map) continue;

      final patientObj = a['patient'];
      int id = 0;
      String name = '';
      String? phone;

      if (patientObj is Map) {
        id = _pickInt(patientObj, ['id', 'Id', 'patientId', 'PatientId']) ?? 0;
        name = _pickString(
              patientObj,
              ['fullName', 'FullName', 'name', 'Name', 'patientName', 'PatientName'],
            ) ??
            '';
        phone = _pickString(patientObj, ['phoneNumber', 'PhoneNumber', 'phone', 'Phone']);
      }

      if (id <= 0) {
        id = _safeInt(a['patientId']);
      }

      if (name.trim().isEmpty) {
        name = _pickString(a, ['patientName', 'fullName', 'name']) ?? '';
      }

      if ((phone ?? '').trim().isEmpty) {
        phone = _pickString(a, ['patientPhone', 'phoneNumber', 'phone']);
      }

      if (id <= 0) continue;

      // Merge with existing entry if we already saw this patient
      final existing = byId[id];
      if (existing == null) {
        byId[id] = {
          'id': id,
          'fullName': name.trim().isEmpty ? 'Patient' : name.trim(),
          'phoneNumber': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
        };
      } else {
        if ((existing['fullName'] ?? '').toString().trim().isEmpty &&
            name.trim().isNotEmpty) {
          existing['fullName'] = name.trim();
        }
        if ((existing['phoneNumber'] ?? '').toString().trim().isEmpty &&
            (phone ?? '').trim().isNotEmpty) {
          existing['phoneNumber'] = phone!.trim();
        }
      }
    }

    return byId.values.toList();
  }

  // ================= Doctor Working Hours =================

  /// ✅ GET /api/doctor/working-hours
  static Future<List<dynamic>> getDoctorWorkingHours() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/doctor/working-hours", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ PUT /api/doctor/working-hours (List body)
  static Future<bool> updateDoctorWorkingHours(List<Map<String, dynamic>> items) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _putAny("/doctor/working-hours", withAuth: true, body: items);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ================= Medical Records =================

  /// ✅ POST /api/medical-records
  ///
  /// ✅ تعديل مهم جداً للتوافق:
  /// appointmentId صار OPTIONAL لأن بعض شاشاتك تستدعيه بدون appointmentId
  /// وسنرسله للباك فقط لو كان موجود.
  static Future<bool> createMedicalRecord({
    required int patientId,
    int? appointmentId,
    required String diagnosis,
    required String notes,
    String? medication,
    String? allergies,
    String? sideEffects,
  }) async {
    await loadToken();
    if (token == null) return false;

    try {
      final body = <String, dynamic>{
        "patientId": patientId,
        "diagnosis": diagnosis,
        "notes": notes,
        "medication": medication,
        "allergies": allergies,
        "sideEffects": sideEffects,
      };

      // ✅ لا نرسل appointmentId إلا إذا كان موجود
      if (appointmentId != null) {
        body["appointmentId"] = appointmentId;
      }

      final res = await _post("/medical-records", withAuth: true, body: body);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// ✅ PUT /api/medical-records/{id}
  static Future<bool> updateMedicalRecord({
    required int recordId,
    required String diagnosis,
    required String notes,
    String? medication,
    String? allergies,
    String? sideEffects,
  }) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put(
        "/medical-records/$recordId",
        withAuth: true,
        body: {
          "diagnosis": diagnosis,
          "notes": notes,
          "medication": medication,
          "allergies": allergies,
          "sideEffects": sideEffects,
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ GET /api/medical-records/patient/{patientId}
  static Future<List<dynamic>> getMedicalRecordsForPatient(int patientId) async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/medical-records/patient/$patientId", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ GET /api/medical-records/mine
  static Future<List<dynamic>> getMyMedicalRecords() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/medical-records/mine", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Compatibility
  static Future<List<dynamic>> getPatientMedicalRecords(int patientId) async {
    return getMedicalRecordsForPatient(patientId);
  }

  // ================= Notifications =================

  /// ✅ GET /api/notifications/mine
  static Future<List<dynamic>> getMyNotifications() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/notifications/mine", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ GET /api/notifications/unread-count  => { unread: 3 }
  static Future<int> getUnreadCount() async {
    await loadToken();
    if (token == null) return 0;

    try {
      final res = await _get("/notifications/unread-count", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        if (data is Map) {
          final v = data['unread'] ?? data['count'];
          return int.tryParse(v?.toString() ?? '') ?? 0;
        }
        if (data is int) return data;
        if (data is String) return int.tryParse(data) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// ✅ PUT /api/notifications/{id}/read
  static Future<bool> markNotificationRead(int id) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/notifications/$id/read", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ PUT /api/notifications/read-all
  static Future<bool> markAllNotificationsRead() async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/notifications/read-all", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ================= Admin =================

  /// ✅ GET /api/admin/users
  static Future<List<dynamic>> getAllUsers() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/admin/users", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ GET /api/admin/doctors/pending
  static Future<List<Map<String, dynamic>>> getPendingDoctors() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/admin/doctors/pending", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        final list = _extractList(data);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ PUT /api/admin/doctors/{doctorId}/approve
  static Future<bool> approveDoctor(int doctorId) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/admin/doctors/$doctorId/approve", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ PUT /api/admin/doctors/{doctorId}/reject
  static Future<bool> rejectDoctor(int doctorId) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put("/admin/doctors/$doctorId/reject", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ GET /api/admin/appointments
  static Future<List<dynamic>> getAdminAppointments() async {
    await loadToken();
    if (token == null) return [];

    try {
      final res = await _get("/admin/appointments", withAuth: true);
      if (res.statusCode == 200) {
        final data = _tryDecode(res.body);
        return _extractList(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// ✅ PUT /api/admin/users/{id}/set-active
  static Future<bool> setUserActive(int userId, bool isActive) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _put(
        "/admin/users/$userId/set-active",
        withAuth: true,
        body: {"isActive": isActive},
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ DELETE /api/admin/users/{id}
  static Future<bool> softDeleteUser(int userId) async {
    await loadToken();
    if (token == null) return false;

    try {
      final res = await _delete("/admin/users/$userId", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// ✅ GET /api/admin/stats
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
      final res = await _get("/admin/stats", withAuth: true);
      final data = _tryDecode(res.body);
      if (res.statusCode == 200 && data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}

    return {
      "appointments": 0,
      "confirmed": 0,
      "rejected": 0,
      "pending": 0,
      "doctors": 0,
      "patients": 0,
    };
  }

  // ================= Extra Compatibility (keep) =================

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final users = await getAllUsers();
    return users
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((u) => (u['role'] ?? '').toString().toLowerCase() == 'patient')
        .toList();
  }

  /// (قديم) Cancel ليس في Swagger، نخليه بدون كسر إن كان مستخدم في شاشات قديمة
  static Future<bool> cancelAppointment(dynamic id) async {
    await loadToken();
    if (token == null) return false;

    final int intId = _safeInt(id);
    if (intId <= 0) return false;

    try {
      final res = await _delete("/appointments/$intId", withAuth: true);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
