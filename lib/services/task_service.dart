import 'dart:convert';
import 'dart:io';
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
          task['submission'] = e['submission'];
          return task;
        }).toList();
      }
      return data;
    }
    return [];
  }

  /// Detail tugas beserta submission (untuk mahasiswa)
  Future<Map<String, dynamic>> getTaskDetail(int taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String role = prefs.getString('role') ?? 'mahasiswa';

    final response = await http.get(
      Uri.parse('$baseUrl/$role/tasks/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    return data as Map<String, dynamic>;
  }

  /// Upload file tugas (mahasiswa)
  Future<Map<String, dynamic>> submitTaskFile(int taskId, dynamic pickedFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    var uri = Uri.parse('$baseUrl/mahasiswa/tasks/$taskId/submit');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    if (kIsWeb) {
      // Web: pickedFile adalah XFile, baca bytes
      final bytes = await pickedFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: pickedFile.name,
      ));
    } else {
      // Mobile/Desktop: pickedFile adalah XFile juga
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        pickedFile.path,
        filename: pickedFile.name,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body) as Map<String, dynamic>;
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

  /// List submissions untuk dosen (per task)
  Future<List> getSubmissions(int taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/dosen/submissions?task_id=$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    return data is List ? data : [];
  }

  /// Beri nilai submission (dosen)
  Future<Map<String, dynamic>> gradeSubmission(int submissionId, int grade, String feedback) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/dosen/submissions/$submissionId/grade'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'grade': grade, 'feedback': feedback}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Mengembalikan Map: {'events': {'2026-06-21': [...tasks]}, 'summary': {'2026-06-21': 2}}
  Future<Map<String, dynamic>> getCalendarEvents({int? month, int? year}) async {
    try {
      final tasks = await getTasks();
      final Map<String, List<Map<String, dynamic>>> parsed = {};
      for (var t in tasks) {
        if (t is Map<String, dynamic>) {
          String? deadlineStr = t['deadline']?.toString();
          if (deadlineStr != null && deadlineStr.length >= 10) {
            String dateKey = deadlineStr.substring(0, 10);
            if (parsed[dateKey] == null) {
              parsed[dateKey] = [];
            }
            parsed[dateKey]!.add(t);
          }
        }
      }
      return {'events': parsed, 'summary': {}};
    } catch (e) {
      return {'events': {}, 'summary': {}};
    }
  }
}