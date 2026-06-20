import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  final String baseUrl = kIsWeb ? "http://127.0.0.1:8000/api" : "http://10.0.2.2:8000/api";

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

      return true;
    }

    return false;
  }
}