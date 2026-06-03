import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    try {
      // Supabase Auth handles login securely and creates a session.
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.session != null;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Insert user details into the 'users' table including the password
        await _supabase.from('users').insert({
          'id': user.id,
          'name': name,
          'email': email,
          'password': password,
          'photo_url': null,
          'points': 0,
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
