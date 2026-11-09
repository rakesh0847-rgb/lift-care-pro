
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _emailKey = 'admin_email';
  static const _passwordKey = 'admin_password_hash';
  static const _sessionKey = 'user_logged_in';
  static const _companyCodeKey = 'company_code';

  bool _isLoggedIn = false;
  String _email = '';
  String _companyCode = 'PRL-0001';

  bool get isLoggedIn => _isLoggedIn;

  // Compatibility with main.dart
  bool get isSignedIn => _isLoggedIn;

  String get email => _email;

  String get companyName => 'PR Lifts';

  String get companyCode => _companyCode;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _isLoggedIn = prefs.getBool(_sessionKey) ?? false;
    _email = prefs.getString(_emailKey) ?? '';

    _companyCode =
        prefs.getString(_companyCodeKey) ?? 'PRL-0001';

    await prefs.setString(_companyCodeKey, _companyCode);
  }

  Future<bool> get isAdminRegistered async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordKey);
  }

  Future<void> registerAdmin({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.length < 8) {
      throw Exception(
        'Enter email and password (minimum 8 characters)',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(_passwordKey)) {
      throw Exception('Admin account already exists');
    }

    await prefs.setString(_emailKey, email.trim());
    await prefs.setString(
      _passwordKey,
      _hashPassword(password),
    );

    _email = email.trim();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString(_emailKey);
    final savedHash = prefs.getString(_passwordKey);

    if (savedEmail == null || savedHash == null) {
      throw Exception('Please register admin account first');
    }

    if (savedEmail != email.trim() ||
        savedHash != _hashPassword(password)) {
      throw Exception('Invalid email or password');
    }

    await prefs.setBool(_sessionKey, true);

    _isLoggedIn = true;
    _email = savedEmail;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_sessionKey, false);

    _isLoggedIn = false;
    _email = '';
  }
}
