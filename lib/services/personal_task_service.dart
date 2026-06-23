import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PersonalTaskService {
  final String baseUrl = "http://3.104.52.205/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<List<Map<String, dynamic>>> getPersonalTasks() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/mahasiswa/personal-tasks'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>?> createPersonalTask({
    required String title,
    required String due,
    String dueTime = '23:59:00',
    String course = '',
    String description = '',
    String priority = 'medium',
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/mahasiswa/personal-tasks'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'due': due,
        'dueTime': dueTime,
        'course': course,
        'description': description,
        'priority': priority,
        'status': 'pending',
        'progress': 0,
        'subtasks': [],
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> updatePersonalTask(int id, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.put(
      Uri.parse('$baseUrl/mahasiswa/personal-tasks/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> deletePersonalTask(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/mahasiswa/personal-tasks/$id'),
      headers: _headers(token),
    );

    return response.statusCode == 200;
  }
}
