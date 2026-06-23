import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AuthService {
  static const MethodChannel _channel = MethodChannel('com.example.task_app/boot');

  final String baseUrl = "http://3.104.52.205/api";

  Future<bool> login(String email, String password) async {

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);
      
      final role = data['user']?['role'] ?? data['role'];
      if (role == 'dosen') {
        throw Exception('khusus untuk Mahasiswa');
      }

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString('token', data['token']);
      await prefs.setString('name', data['user']?['name'] ?? data['name'] ?? '');
      await prefs.setString('role', data['user']?['role'] ?? 'mahasiswa');

      try {
        final bootSessionId = await _channel.invokeMethod('getBootSessionId');
        await prefs.setString('boot_session_id', bootSessionId);
      } catch (_) {}

      return true;
    }

    return false;
  }

  Future<bool> register(String name, String email, String password, String role, {String? nim}) async {

    final Map<String, dynamic> reqBody = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'role': role,
    };
    if (nim != null && nim.isNotEmpty) {
      reqBody['nim'] = nim;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(reqBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {

      final data = jsonDecode(response.body);

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString('token', data['token']);
      await prefs.setString('name', data['user']?['name'] ?? data['name'] ?? name);
      await prefs.setString('role', data['user']?['role'] ?? role);

      try {
        final bootSessionId = await _channel.invokeMethod('getBootSessionId');
        await prefs.setString('boot_session_id', bootSessionId);
      } catch (_) {}

      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>> sendPasswordResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Terjadi kesalahan.',
      };
    } catch (_) {
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-reset-code'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Terjadi kesalahan.',
      };
    } catch (_) {
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Terjadi kesalahan.',
      };
    } catch (_) {
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  /// Checks if the session is still valid based on the boot session ID.
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return false;

      final savedBootId = prefs.getString('boot_session_id');
      if (savedBootId != null) {
        final currentBootId = await _channel.invokeMethod('getBootSessionId');
        // If boot IDs do not match, the device has rebooted, so session is invalid
        if (savedBootId != currentBootId) {
          await prefs.remove('token');
          await prefs.remove('boot_session_id');
          return false;
        }
      }
      return true;
    } catch (_) {
      // Fallback if platform channel fails
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token') != null;
    }
  }
}