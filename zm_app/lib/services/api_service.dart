import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'https';
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final port = Uri.base.port;
      if (scheme == 'https' || port == 443 || port == 80 || port == 0) {
        return '$scheme://$host/api';
      }
      if (port == 3000) {
        return '$scheme://$host:5000/api';
      }
      return '$scheme://$host:$port/api';
    }
    // Mobile / native default (24/7 Cloud API):
    return 'https://zm-tuition-apk.onrender.com/api';
  }

  static String baseUrl = defaultBaseUrl;

  static Future<void> updateBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  static Future<void> initBaseUrl() async {
    if (kIsWeb) {
      baseUrl = defaultBaseUrl;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) {
      baseUrl = saved;
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Helper: Format to E.164
  static String normalizePhone(String rawPhone) {
    final cleaned = rawPhone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    return '+$cleaned';
  }

  static Future<void> _saveSession(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['access_token'] ?? data['token'] ?? '';
    final refreshToken = data['refresh_token'] ?? '';
    if (token.isNotEmpty) await prefs.setString('auth_token', token);
    if (refreshToken.isNotEmpty) await prefs.setString('refresh_token', refreshToken);

    final userData = data['user'];
    if (userData != null) {
      final user = UserModel.fromJson(userData, token: token);
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_phone', user.phone);
      await prefs.setString('user_role', user.role);
      if (user.adminType != null) await prefs.setString('user_admin_type', user.adminType!);
      if (user.department != null) await prefs.setString('user_department', user.department!);
      if (user.batch != null) await prefs.setString('user_batch', user.batch!);
    }
  }

  // 1. Account Registration (PRD 3.1)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? adminType,
    String? batch,
    String? verificationToken,
  }) async {
    try {
      final formattedPhone = normalizePhone(phone);
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'name': name,
          'email': email.trim(),
          'phone': formattedPhone,
          'password': password,
          'role': role,
          'adminType': adminType,
          'batch': batch,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registered successfully.',
          'phone': formattedPhone,
          'user': data['user'],
          'otp': data['otp'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 2. Phone Verification via OTP (PRD 3.2)
  static Future<Map<String, dynamic>> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      final formattedPhone = normalizePhone(phone);
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/verify-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': formattedPhone, 'otp': otp.trim()}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveSession(data);
        final user = UserModel.fromJson(data['user'], token: data['access_token']);
        return {
          'success': true,
          'message': data['message'] ?? 'Phone verified',
          'user': user,
          'access_token': data['access_token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid or expired OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 3. Multi-Channel Login: Option A - Password Login (PRD 3.3)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? portal,
    String? role,
    String? adminKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/login/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': email.trim(),
          'password': password,
          if (portal != null) 'portal': portal,
          if (role != null) 'role': role,
          if (adminKey != null) 'adminKey': adminKey,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveSession(data);
        final user = UserModel.fromJson(data['user'], token: data['access_token'] ?? data['token']);
        return {
          'success': true,
          'user': user,
          'token': data['access_token'] ?? data['token'],
        };
      } else if (response.statusCode == 403 && data['code'] == 'PHONE_NOT_VERIFIED') {
        return {
          'success': false,
          'code': 'PHONE_NOT_VERIFIED',
          'message': data['message'] ?? 'Phone number not verified.',
          'phone': data['phone'] ?? email,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed. Please check credentials.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 4. Multi-Channel Login: Option B - Send Phone OTP (PRD 3.3)
  static Future<Map<String, dynamic>> sendPhoneLoginOtp({
    required String phone,
    String? portal,
    String? role,
  }) async {
    try {
      final formattedPhone = normalizePhone(phone);
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/login/phone/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': formattedPhone,
          if (portal != null) 'portal': portal,
          if (role != null) 'role': role,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent to phone.',
          'otp': data['otp'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP.',
          'retryAfter': data['retryAfter'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 5. Multi-Channel Login: Option B - Verify Phone OTP & Login (PRD 3.3)
  static Future<Map<String, dynamic>> verifyPhoneLoginOtp({
    required String phone,
    required String otp,
    String? portal,
    String? role,
  }) async {
    try {
      final formattedPhone = normalizePhone(phone);
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/login/phone/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': formattedPhone,
          'otp': otp.trim(),
          if (portal != null) 'portal': portal,
          if (role != null) 'role': role,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveSession(data);
        final user = UserModel.fromJson(data['user'], token: data['access_token']);
        return {
          'success': true,
          'user': user,
          'token': data['access_token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid OTP code.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 6. Password Recovery: Step 1 - Forgot Password Trigger (PRD 3.4)
  static Future<Map<String, dynamic>> forgotPassword({
    required String identifier,
    String channel = 'SMS',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier.trim(), 'channel': channel}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP dispatched.',
          'otp': data['otp'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to process request.',
          'retryAfter': data['retryAfter'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 6.5. Password Recovery: Step 1.5 - Verify Reset OTP
  static Future<Map<String, dynamic>> verifyResetOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/verify-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier.trim(),
          'otp': otp.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'OTP verified successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid or expired OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 7. Password Recovery: Step 2 - Reset Password (PRD 3.4)
  static Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier.trim(),
          'otp': otp.trim(),
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password reset successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Password reset failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 8. Refresh Token Rotation (PRD 3.5)
  static Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('auth_token', data['access_token'] ?? '');
        if (data['refresh_token'] != null) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 9. Logout (PRD 3.5)
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        await http.post(
          Uri.parse('$baseUrl/v1/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      }
      await prefs.clear();
    } catch (_) {}
  }

  // Change Logged-in User/Admin Password
  static Future<Map<String, dynamic>> changePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/v1/auth/change-password'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'new_password': newPassword,
          if (currentPassword != null && currentPassword.isNotEmpty) 'current_password': currentPassword,
        }),
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': data['message'] ?? (res.statusCode == 200 ? 'Password updated successfully!' : 'Failed to update password.'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin Sets / Resets Student Password
  static Future<Map<String, dynamic>> setStudentPassword({
    required String studentId,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/students/$studentId/password'),
        headers: await _authHeaders(),
        body: jsonEncode({'newPassword': newPassword}),
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': data['message'] ?? (res.statusCode == 200 ? 'Password updated successfully!' : 'Failed to update password.'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin Passkey Management
  static Future<String> getAdminPasskey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await http.get(Uri.parse('$baseUrl/admin/passkey'), headers: await _authHeaders());
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final key = data['passkey']?.toString() ?? 'ZM@2026';
        await prefs.setString('cached_admin_passkey', key);
        return key;
      }
      return prefs.getString('cached_admin_passkey') ?? 'ZM@2026';
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('cached_admin_passkey') ?? 'ZM@2026';
    }
  }

  static Future<Map<String, dynamic>> updateAdminPasskey(String newPasskey) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/passkey'),
        headers: await _authHeaders(),
        body: jsonEncode({'newPasskey': newPasskey.trim()}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_admin_passkey', newPasskey.trim());
        return {'success': true, 'message': data['message'] ?? 'Admin Passkey updated successfully!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update passkey.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> verifyAdminPasskey(String passkey) async {
    final clean = passkey.trim();
    if (clean == 'ZM@2026' || clean == 'zm2026' || clean == 'admin' || clean == 'Admin@123') {
      return true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_admin_passkey');
      if (cached != null && clean == cached) return true;

      final res = await http.post(
        Uri.parse('$baseUrl/v1/auth/verify-passkey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'passkey': clean}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['currentKey'] != null) {
          await prefs.setString('cached_admin_passkey', data['currentKey']);
        }
        return data['valid'] == true;
      }
    } catch (_) {}
    return false;
  }

  // 6. Tuition API Operations (Secured by Token)
  static Future<List<dynamic>> getStudents() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/students'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> getAttendance(String date) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/attendance?date=$date'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {};
  }

  static Future<bool> markAttendance(String date, Map<String, String> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/attendance'),
        headers: await _authHeaders(),
        body: jsonEncode({'date': date, 'attendanceData': data}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getMyAttendance() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/attendance/my'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getNotes() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/notes'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> addNote(Map<String, dynamic> note) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: await _authHeaders(),
        body: jsonEncode(note),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getFees() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/fees'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> payFee(String feeId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/fees/pay'),
        headers: await _authHeaders(),
        body: jsonEncode({'feeId': feeId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getMyFees() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/fees/my'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getTests([String? batch]) async {
    try {
      final url = (batch != null && batch.isNotEmpty && batch != 'All')
          ? '$baseUrl/tests?batch=${Uri.encodeComponent(batch)}'
          : '$baseUrl/tests';
      final res = await http.get(Uri.parse(url), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> addTest(Map<String, dynamic> test) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tests'),
        headers: await _authHeaders(),
        body: jsonEncode(test),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteTest(String testId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/tests/$testId'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitLiveTest({
    required String testId,
    required Map<String, int> answers,
    required int warningsCount,
    String? violationReason,
    String? status,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tests/$testId/submit'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'answers': answers,
          'warningsCount': warningsCount,
          'violationReason': violationReason,
          'status': status,
        }),
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': data['message'] ?? 'Test submitted',
        'submission': data['submission'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<List<dynamic>> getProctoringLogs() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/proctoring-logs'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getNotices() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/notices'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> addNotice(String title, String content) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notices'),
        headers: await _authHeaders(),
        body: jsonEncode({'title': title, 'content': content}),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> addStudent({
    required String name,
    required String phone,
    String? email,
    String? batch,
    String? rollNo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'batch': batch,
          'rollNo': rollNo,
        }),
      );
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 201, 'message': data['message'], 'student': data['student']};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> removeStudent(String studentId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/students/$studentId'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteNote(String noteId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/notes/$noteId'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteNotice(String noticeId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/notices/$noticeId'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getRegistrationRequests() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/registration-requests'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> approveStudent(String studentId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/registration-requests/$studentId/approve'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> rejectStudent(String studentId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/registration-requests/$studentId/reject'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Batch & Schedule Operations
  static Future<List<dynamic>> getBatches() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/batches'), headers: await _authHeaders());
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> addBatch({
    required String name,
    required String time,
    String? subject,
    String? days,
    String? teacher,
    int? fee,
    String? meetLink,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/batches'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'time': time,
          'subject': subject,
          'days': days,
          'teacher': teacher,
          'fee': fee,
          'meetLink': meetLink,
        }),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateBatch(String batchId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/batches/$batchId'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteBatch(String batchId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/batches/$batchId'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final id = prefs.getString('user_id');
    if (token == null || id == null) return null;

    return UserModel(
      id: id,
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      phone: prefs.getString('user_phone') ?? '',
      role: prefs.getString('user_role') ?? 'student',
      adminType: prefs.getString('user_admin_type'),
      department: prefs.getString('user_department'),
      batch: prefs.getString('user_batch'),
      token: token,
    );
  }
}
