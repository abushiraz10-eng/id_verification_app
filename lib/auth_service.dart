import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // ── REGISTER ─────────────────────────────
  Future<String?> register(
    String name,
    String email,
    String password,
    String role,
    String adminCode,
  ) async {
    try {
      if (role == 'admin' && adminCode != 'GH_ADMIN') {
        return 'Invalid Admin Code';
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) return 'Registration failed';

      // Save user profile to users table
      await _supabase.from('users').insert({
        'id':         response.user!.id,
        'name':       name,
        'email':      email,
        'role':       role,
        'created_at': DateTime.now().toIso8601String(),
      });

      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }

  // ── LOGIN ────────────────────────────────
  Future<String?> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong';
    }
  }

  // ── LOGOUT ───────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ── GET USER PROFILE ─────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', uid)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }
}
