import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  final String baseUrl = kIsWeb ? "http://localhost:8000/api" : "http://10.0.2.2:8000/api";

  Future<Map<String, dynamic>> getDashboardStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String role = prefs.getString('role') ?? 'mahasiswa';

    final response = await http.get(
      Uri.parse('$baseUrl/$role/dashboard-stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List> getTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String role = prefs.getString('role') ?? 'mahasiswa';

    final response = await http.get(
      Uri.parse('$baseUrl/$role/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (data is List) {
      if (role == 'mahasiswa') {
        return data.map((e) {
          final task = e['task'] as Map<String, dynamic>? ?? {};
          task['status'] = e['status'];
          return task;
        }).toList();
      }
      return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> joinTask(String kodeTugas) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/mahasiswa/tasks/join'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'kode_tugas': kodeTugas}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTask({
    required String namaTugas,
    required String namaMatkul,
    required String deadline,
    String? jam,
    String? deskripsi,
    String? tags,
    String? tipe,
    String? prioritas,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String role = prefs.getString('role') ?? 'dosen';

    final response = await http.post(
      Uri.parse('$baseUrl/$role/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nama_tugas': namaTugas,
        'nama_matkul': namaMatkul,
        'deadline': deadline,
        'jam': jam ?? '23:59',
        'deskripsi': deskripsi ?? '',
        'tags': tags ?? '',
        'tipe': tipe ?? 'individu',
        'prioritas': prioritas ?? 'sedang',
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}