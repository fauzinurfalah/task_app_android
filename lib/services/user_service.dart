import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service untuk cache data user (nama & foto) secara global,
/// sehingga perubahan foto langsung terlihat di semua layar.
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String _name = '';
  String? _photoUrl;
  String? _email;
  String? _nim;

  String get name => _name;
  String? get photoUrl => _photoUrl;
  String? get email => _email;
  String? get nim => _nim;

  final String baseUrl = "http://3.104.52.205/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Load user profile dari Laravel API /api/me
  Future<void> loadUser() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>? ?? {};
        _name = user['name'] ?? '';
        _email = user['email'] ?? '';
        _nim = user['nim'] as String?;
        // foto_profil_url adalah accessor dari model User Laravel
        _photoUrl = user['foto_profil_url'] as String?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UserService.loadUser error: $e');
      // Fallback ke SharedPreferences jika offline
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('name') ?? '';
      notifyListeners();
    }
  }

  /// Upload foto profil via multipart POST ke Laravel /api/profile
  /// [bytes] = bytes gambar, [extension] = ekstensi file (jpg/png/etc)
  Future<String?> uploadPhoto(List<int> bytes, String extension) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    // Gunakan _email dari cache; kalau kosong load dulu dari API
    if (_email == null || _email!.isEmpty) {
      await loadUser();
    }
    final name = _name.isNotEmpty ? _name : (prefs.getString('name') ?? 'User');
    final email = _email ?? '';

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Field wajib untuk updateProfile di Laravel
      request.fields['name'] = name.isNotEmpty ? name : 'User';
      request.fields['email'] = email;

      // File foto
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto_profil',
          Uint8List.fromList(bytes),
          filename: 'avatar.$extension',
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>? ?? {};
        _photoUrl = user['foto_profil_url'] as String?;
        // Tambah timestamp agar tidak di-cache
        if (_photoUrl != null) {
          _photoUrl = '$_photoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }
        notifyListeners();
        return _photoUrl;
      } else {
        debugPrint('uploadPhoto error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('UserService.uploadPhoto error: $e');
      return null;
    }
  }

  /// Update profile via multipart POST ke Laravel /api/profile
  Future<bool> updateProfileData(String newName, String newEmail, String newNim) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = newName;
      request.fields['email'] = newEmail;
      request.fields['nim'] = newNim;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>? ?? {};
        _name = user['name'] ?? newName;
        _email = user['email'] ?? newEmail;
        _nim = user['nim'] ?? newNim;
        // Simpan ke SharedPreferences
        await prefs.setString('name', _name);
        notifyListeners();
        return true;
      } else {
        debugPrint('updateProfile error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('UserService.updateProfile error: $e');
      return false;
    }
  }

  /// Logout: hapus token dari Laravel, bersihkan cache lokal
  Future<void> logout() async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (_) {}
    }
    await _clearLocal();
  }

  Future<void> _clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('role');
    await prefs.remove('email');
    await prefs.remove('boot_session_id'); // Hapus session ID agar tidak dipakai setelah logout
    clear();
  }

  void clear() {
    _name = '';
    _photoUrl = null;
    _email = null;
    notifyListeners();
  }
}
