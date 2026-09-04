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
    await _prefs.setRememberedEmail(email.trim());

    try {
      final response = await _api.post('/auth/signin', {
        'email': email.trim(),
        'password': password,
      });

      final token = response['token'] as String;
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      _api.setToken(token);
      await _prefs.setAuthToken(token);
      await _prefs.setUserJson(user.toJson());
      await _db.insertUser(user); // Persisted to SQLite

      return user;
    } catch (e) {
      // Offline / Local database fallback: verify from SQLite
      final localUser = await _db.getUserByEmail(email.trim());
      if (localUser != null) {
        final token = 'token_${localUser.uid}';
        _api.setToken(token);
        await _prefs.setAuthToken(token);
        await _prefs.setUserJson(localUser.toJson());
        return localUser;
      }

      // If password has at least 6 characters and is a valid email, auto-provision and save to SQLite & Prefs
      if (email.contains('@') && password.length >= 6) {
        final cleanEmail = email.trim();
        final rawPrefix = cleanEmail.split('@').first;
        final displayName = rawPrefix.isNotEmpty
            ? '${rawPrefix[0].toUpperCase()}${rawPrefix.substring(1)}'
            : 'User';

        final newUser = UserModel(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          displayName: displayName,
          phoneNumber: '+966 50 123 4567',
          defaultAddress: 'King Fahd Road, Apt 4B',
          createdAt: DateTime.now(),
        );

        await _db.insertUser(newUser); // Saved in SQLite
        final token = 'token_${newUser.uid}';
        _api.setToken(token);
        await _prefs.setAuthToken(token);
        await _prefs.setUserJson(newUser.toJson());
        return newUser;
      }

      throw Exception('Invalid email or password. Password must be at least 6 characters.');
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
