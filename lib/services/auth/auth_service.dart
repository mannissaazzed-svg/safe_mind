import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── SIGN UP ──────────────────────────────────────────────────
  Future<void> signUpWithEmailPassword(String email, String password) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user != null) {
     
      await _supabase.from('users').insert({
        'id':    user.id,
        'email': email,
        
      });
    }
  }

  // ─── SIGN IN ──────────────────────────────────────────────────
  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ─── GET ROLE ─────────────────────────────────────────────────
  Future<String?> getRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return data?['role'] as String?;
  }

  // ─── GET FULL USER DATA ───────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }
  // ─── OAUTH (Google) ────────────────────────────────────────────
Future<void> signInWithGoogle() async {
  await _supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'io.supabase.flutter://login-callback/',
  );
}

// ─── OAUTH (Facebook) ──────────────────────────────────────────
Future<void> signInWithFacebook() async {
  await _supabase.auth.signInWithOAuth(
    OAuthProvider.facebook,
    redirectTo: 'io.supabase.flutter://login-callback/',
  );
}

// ─── OAUTH (Apple) ─────────────────────────────────────────────
Future<void> signInWithApple() async {
  await _supabase.auth.signInWithOAuth(
    OAuthProvider.apple,
    redirectTo: 'io.supabase.flutter://login-callback/',
  );
}

  // ─── SIGN OUT ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── GET EMAIL ────────────────────────────────────────────────
  String? getCurrentUserEmail() {
    return _supabase.auth.currentSession?.user.email;
  }

  // ─── CURRENT USER ID ─────────────────────────────────────────
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}
