import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication status.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Sign-in / Sign-up form status.
enum AuthFormStatus { initial, loading, success, failure }

/// MVVM ViewModel for authentication.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel(this._authService);

  // ── Auth State ──────────────────────────────────────────────────

  AuthStatus _authStatus = AuthStatus.unknown;
  UserModel? _user;

  AuthStatus get authStatus => _authStatus;
  UserModel? get user => _user;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  /// Initialize — check for stored token.
  Future<void> init() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        _authStatus = AuthStatus.authenticated;
      } else {
        _authStatus = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Sign-In Form ─────────────────────────────────────────────────

  String _signInEmail = '';
  String _signInPassword = '';
  AuthFormStatus _signInStatus = AuthFormStatus.initial;
  String? _signInError;

  String get signInEmail => _signInEmail;
  String get signInPassword => _signInPassword;
  AuthFormStatus get signInStatus => _signInStatus;
  String? get signInError => _signInError;

  bool get isSignInValid =>
      _signInEmail.contains('@') && _signInPassword.length >= 6;

  void onSignInEmailChanged(String email) {
    _signInEmail = email;
    _signInStatus = AuthFormStatus.initial;
    _signInError = null;
    notifyListeners();
  }

  void onSignInPasswordChanged(String password) {
    _signInPassword = password;
    _signInStatus = AuthFormStatus.initial;
    _signInError = null;
    notifyListeners();
  }

  Future<void> signIn() async {
    if (!isSignInValid) return;

    _signInStatus = AuthFormStatus.loading;
    _signInError = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(
        email: _signInEmail.trim(),
        password: _signInPassword,
      );
      _user = user;
      _authStatus = AuthStatus.authenticated;
      _signInStatus = AuthFormStatus.success;
    } catch (e) {
      _signInStatus = AuthFormStatus.failure;
      _signInError = e.toString();
    }
    notifyListeners();
  }

  void resetSignIn() {
    _signInEmail = '';
    _signInPassword = '';
    _signInStatus = AuthFormStatus.initial;
    _signInError = null;
    notifyListeners();
  }

  // ── Sign-Up Form ─────────────────────────────────────────────────

  String _signUpEmail = '';
  String _signUpPassword = '';
  String _signUpConfirmPassword = '';
  String _signUpDisplayName = '';
  AuthFormStatus _signUpStatus = AuthFormStatus.initial;
  String? _signUpError;

  String get signUpEmail => _signUpEmail;
  String get signUpPassword => _signUpPassword;
  String get signUpConfirmPassword => _signUpConfirmPassword;
  String get signUpDisplayName => _signUpDisplayName;
  AuthFormStatus get signUpStatus => _signUpStatus;
  String? get signUpError => _signUpError;

  bool get isSignUpValid =>
      _signUpEmail.contains('@') &&
      _signUpPassword.length >= 6 &&
      _signUpPassword == _signUpConfirmPassword &&
      _signUpDisplayName.isNotEmpty;

  void onSignUpEmailChanged(String v) {
    _signUpEmail = v;
    _signUpStatus = AuthFormStatus.initial;
    _signUpError = null;
    notifyListeners();
  }

  void onSignUpPasswordChanged(String v) {
    _signUpPassword = v;
    _signUpStatus = AuthFormStatus.initial;
    _signUpError = null;
    notifyListeners();
  }

  void onSignUpConfirmPasswordChanged(String v) {
    _signUpConfirmPassword = v;
    _signUpStatus = AuthFormStatus.initial;
    _signUpError = null;
    notifyListeners();
  }

  void onSignUpDisplayNameChanged(String v) {
    _signUpDisplayName = v;
    _signUpStatus = AuthFormStatus.initial;
    _signUpError = null;
    notifyListeners();
  }

  Future<void> signUp() async {
    if (!isSignUpValid) return;

    _signUpStatus = AuthFormStatus.loading;
    _signUpError = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(
        email: _signUpEmail.trim(),
        password: _signUpPassword,
        name: _signUpDisplayName.trim(),
      );
      _user = user;
      _authStatus = AuthStatus.authenticated;
      _signUpStatus = AuthFormStatus.success;
    } catch (e) {
      _signUpStatus = AuthFormStatus.failure;
      _signUpError = e.toString();
    }
    notifyListeners();
  }

  void resetSignUp() {
    _signUpEmail = '';
    _signUpPassword = '';
    _signUpConfirmPassword = '';
    _signUpDisplayName = '';
    _signUpStatus = AuthFormStatus.initial;
    _signUpError = null;
    notifyListeners();
  }

  // ── Sign Out ─────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _authStatus = AuthStatus.unauthenticated;
    resetSignIn();
    resetSignUp();
    notifyListeners();
  }

  // ── Convenience ──────────────────────────────────────────────────

  String get displayName {
    final name = _user?.displayName ?? '';
    return name.isNotEmpty ? name.split(' ').first : 'Chef';
  }

  /// Update user profile contact details (phone, default address)
  Future<void> updateProfile({String? phoneNumber, String? defaultAddress}) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      phoneNumber: phoneNumber ?? _user!.phoneNumber,
      defaultAddress: defaultAddress ?? _user!.defaultAddress,
    );
    _user = await _authService.updateUser(updated);
    notifyListeners();
  }
}
