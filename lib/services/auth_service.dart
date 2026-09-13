import '../models/user_model.dart';
import 'api_service.dart';
import 'prefs_service.dart';
import 'local_db_service.dart';

/// Handles authentication via the Go backend API and local SQLite cache.
/// Requirement: LocalStorage (sqlite + SharedPref for users & auth).
class AuthService {
  final ApiService _api;
  final PrefsService _prefs;
  final LocalDbService _db;

  AuthService(this._api, this._prefs, this._db);

  static const Map<String, String> _offlineDemoPasswords = {
    'mario@pizza.com': 'pizza123',
    'm@gmail.com': '123456',
    'user@example.com': '123456',
    'demo@mario.com': '123456',
  };

  /// Sign up a new user. Returns the user and stores token in SharedPref & user in SQLite.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _api.post('/auth/signup', {
        'email': email,
        'password': password,
        'name': name,
      });

      final token = response['token'] as String;
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      _api.setToken(token);
      await _prefs.setAuthToken(token);
      await _prefs.setUserJson(user.toJson());
      await _db.insertUser(user); // Persisted to SQLite

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      // Offline fallback: register locally in SQLite
      final localUser = UserModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: name,
        createdAt: DateTime.now(),
      );
      await _db.insertUser(localUser); // Saved in SQLite
      final fakeToken = 'offline_token_${localUser.uid}';
      _api.setToken(fakeToken);
      await _prefs.setAuthToken(fakeToken);
      await _prefs.setUserJson(localUser.toJson());
      return localUser;
    }
  }

  /// Sign in an existing user.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    // Remember email for next login session (Requirement: remember for next login)
    final cleanEmail = email.trim().toLowerCase();
    await _prefs.setRememberedEmail(cleanEmail);

    try {
      final response = await _api.post('/auth/signin', {
        'email': cleanEmail,
        'password': password,
      });

      final token = response['token'] as String;
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      _api.setToken(token);
      await _prefs.setAuthToken(token);
      await _prefs.setUserJson(user.toJson());
      await _db.insertUser(user); // Persisted to SQLite

      return user;
    } on ApiException {
      // The backend answered, so authentication errors must not be treated as
      // an offline condition or bypassed through the local cache.
      rethrow;
    } catch (e) {
      // Offline fallback is intentionally limited to the built-in demo
      // accounts whose credentials are known locally. Remembered sessions are
      // restored separately by getCurrentUser().
      final localUser = await _db.getUserByEmail(cleanEmail);
      final expectedPassword = _offlineDemoPasswords[cleanEmail];
      if (localUser != null && expectedPassword == password) {
        final token = 'token_${localUser.uid}';
        _api.setToken(token);
        await _prefs.setAuthToken(token);
        await _prefs.setUserJson(localUser.toJson());
        return localUser;
      }

      throw Exception(
        'No internet connection. Use a built-in demo account for offline sign in.',
      );
    }
  }

  /// Get current user from stored token or SQLite.
  Future<UserModel?> getCurrentUser() async {
    final token = _prefs.getAuthToken();
    if (token == null) return null;

    _api.setToken(token);

    try {
      final response = await _api.get('/auth/me');
      final user = UserModel.fromJson(response as Map<String, dynamic>);
      await _db.insertUser(user); // Keep SQLite in sync
      return user;
    } catch (_) {
      // Offline fallback: load from SharedPreferences or SQLite
      final userJson = _prefs.getUserJson();
      if (userJson != null) {
        final user = UserModel.fromJson(userJson);
        final sqliteUser = await _db.getUserById(user.uid);
        return sqliteUser ?? user;
      }
      return null;
    }
  }

  /// Sign out — clear stored token and user data.
  Future<void> signOut() async {
    _api.clearToken();
    await _prefs.clearAuth();
  }

  /// Update user profile data (phone, address) locally and in preferences
  Future<UserModel> updateUser(UserModel updatedUser) async {
    await _prefs.setUserJson(updatedUser.toJson());
    await _db.insertUser(updatedUser);
    return updatedUser;
  }

  /// Check if user is logged in (has stored token).
  bool get isLoggedIn => _prefs.getAuthToken() != null;
}
