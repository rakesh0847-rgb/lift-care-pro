
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _signedInKey = 'liftcare_signed_in';
  static const String _emailKey = 'liftcare_user_email';

  bool _isSignedIn = false;
  String _email = '';

  bool get isSignedIn => _isSignedIn;

  String get email => _email;

  String get companyName => 'PR Lifts';

  String get companyCode => 'PR-LIFTS';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _isSignedIn = prefs.getBool(_signedInKey) ?? false;
    _email = prefs.getString(_emailKey) ?? '';
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    // Cloud authentication will be connected
    // through Supabase in the next backend phase.
    throw Exception(
      'Cloud login is not configured yet. '
      'Please complete the Supabase setup.',
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_signedInKey, false);
    await prefs.remove(_emailKey);

    _isSignedIn = false;
    _email = '';
  }
}
