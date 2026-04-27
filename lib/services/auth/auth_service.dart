import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // SIGN UP
  Future<void> signUpWithEmailPassword(
      String email, String password) async {

    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;

    if (user != null) {
      await _supabase.from('users').insert({
        'id': user.id,
        'email': email,
        'role': null
      });
    }
  }

  // SIGN IN
  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // GET ROLE
  Future<String?> getRole() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    final data = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return data?['role'];
  }


      // Sign out 
      Future<void> signOut() async {
        await _supabase.auth.signOut();
      }

      // get user email

      String? getCurrentUserEmail() {
        final session = _supabase.auth.currentSession;
        final user = session?.user;
        return user?.email;
      }



}
