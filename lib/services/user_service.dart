import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service untuk cache data user (nama & foto) secara global,
/// sehingga perubahan foto langsung terlihat di semua layar.
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  String _name = '';
  String? _photoUrl;

  String get name => _name;
  String? get photoUrl => _photoUrl;

  final _supabase = Supabase.instance.client;

  Future<void> loadUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('users')
          .select('name, photo_url')
          .eq('id', user.id)
          .single();
      _name = data['name'] ?? '';
      _photoUrl = data['photo_url'] as String?;
      notifyListeners();
    } catch (e) {
      _name = user.userMetadata?['name'] ?? '';
      notifyListeners();
    }
  }

  Future<String?> uploadPhoto(List<int> bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final path = '${user.id}/avatar.$extension';
    await _supabase.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    // Tambah timestamp agar URL tidak di-cache browser
    final urlWithTs = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    // Update kolom photo_url di tabel users
    await _supabase
        .from('users')
        .update({'photo_url': urlWithTs})
        .eq('id', user.id);
    _photoUrl = urlWithTs;
    notifyListeners();
    return urlWithTs;
  }

  void clear() {
    _name = '';
    _photoUrl = null;
    notifyListeners();
  }
}
