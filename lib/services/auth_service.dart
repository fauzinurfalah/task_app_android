import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.session != null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal terhubung ke server.');
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Pendaftaran gagal. Coba lagi.');
      }

      // Insert user details into the 'users' table
      await _supabase.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'password': password,
        'photo_url': null,
        'points': 0,
      });

      return true;
    } on AuthException catch (e) {
      // Supabase error, e.g. "User already registered"
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      // Database insert error, e.g. duplicate key in 'users' table
      throw Exception('Gagal menyimpan data: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan. Periksa koneksi Anda.');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
