import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  final String baseUrl = "http://10.0.2.2:8000/api";

  Future<List> getTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    required String subject,
    required String deadline,
    String? description,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'subject': subject,
        'deadline': deadline,
        'description': description ?? '',
        'status': 'pending',
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}