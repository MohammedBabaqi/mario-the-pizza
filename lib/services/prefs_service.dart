import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences wrapper for app settings and auth persistence.
class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  // ── Auth ──────────────────────────────────────────────────────────

  static const _tokenKey = 'mario_auth_token';
  static const _userKey = 'mario_user_json';
  static const _rememberedEmailKey = 'mario_remembered_email';
  static const _savedUsersDbKey = 'mario_saved_users_db';

  String? getAuthToken() => _prefs.getString(_tokenKey);

  Future<void> setAuthToken(String token) =>
      _prefs.setString(_tokenKey, token);

  Future<void> setUserJson(Map<String, dynamic> json) =>
      _prefs.setString(_userKey, jsonEncode(json));

  Map<String, dynamic>? getUserJson() {
    final str = _prefs.getString(_userKey);
    if (str == null) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }

  String? getRememberedEmail() => _prefs.getString(_rememberedEmailKey);

  Future<void> setRememberedEmail(String email) =>
      _prefs.setString(_rememberedEmailKey, email);

  List<Map<String, dynamic>> getSavedUsersDb() {
    final raw = _prefs.getStringList(_savedUsersDbKey) ?? [];
    return raw
        .map((s) {
          try {
            return jsonDecode(s) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> saveUserInDb(Map<String, dynamic> userJson) async {
    final users = getSavedUsersDb();
    users.removeWhere((u) => u['email'] == userJson['email']);
    users.add(userJson);
    await _prefs.setStringList(
      _savedUsersDbKey,
      users.map((u) => jsonEncode(u)).toList(),
    );
  }

  Future<void> deleteUserInDb(String uid) async {
    final users = getSavedUsersDb();
    users.removeWhere((u) => u['uid'] == uid);
    await _prefs.setStringList(
      _savedUsersDbKey,
      users.map((u) => jsonEncode(u)).toList(),
    );
  }

  // ── Food / Pizzas Database Persistence (Requirement: SQLite Data on Web) ──

  static const _savedPizzasDbKey = 'mario_saved_pizzas_db';

  List<Map<String, dynamic>> getSavedPizzasDb() {
    final raw = _prefs.getStringList(_savedPizzasDbKey) ?? [];
    return raw
        .map((s) {
          try {
            return jsonDecode(s) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> savePizzaInDb(Map<String, dynamic> pizzaJson) async {
    final list = getSavedPizzasDb();
    list.removeWhere((p) => p['id'] == pizzaJson['id']);
    list.add(pizzaJson);
    await _prefs.setStringList(
      _savedPizzasDbKey,
      list.map((p) => jsonEncode(p)).toList(),
    );
  }

  Future<void> saveAllPizzasInDb(List<Map<String, dynamic>> pizzasJson) async {
    await _prefs.setStringList(
      _savedPizzasDbKey,
      pizzasJson.map((p) => jsonEncode(p)).toList(),
    );
  }

  Future<void> deletePizzaInDb(String id) async {
    final list = getSavedPizzasDb();
    list.removeWhere((p) => p['id'] == id);
    await _prefs.setStringList(
      _savedPizzasDbKey,
      list.map((p) => jsonEncode(p)).toList(),
    );
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  // ── Theme ─────────────────────────────────────────────────────────

  static const _themeKey = 'mario_theme_mode';

  String? getThemeMode() => _prefs.getString(_themeKey);

  Future<void> setThemeMode(String mode) =>
      _prefs.setString(_themeKey, mode);

  // ── Favorites ─────────────────────────────────────────────────────

  static const _favoritesKey = 'mario_favorite_ids';

  List<String> getFavoriteIds() =>
      _prefs.getStringList(_favoritesKey) ?? [];

  Future<void> setFavoriteIds(List<String> ids) =>
      _prefs.setStringList(_favoritesKey, ids);

  // ── Recent Searches ───────────────────────────────────────────────

  static const _recentSearchKey = 'mario_recent_searches';

  List<String> getRecentSearches() =>
      _prefs.getStringList(_recentSearchKey) ?? [];

  Future<void> setRecentSearches(List<String> searches) =>
      _prefs.setStringList(_recentSearchKey, searches);

  Future<void> clearRecentSearches() =>
      _prefs.remove(_recentSearchKey);

  // ── Placed Orders Persistence ──────────────────────────────────────

  static const _ordersKey = 'mario_persisted_orders';

  List<Map<String, dynamic>> getPersistedOrdersJson() {
    final rawList = _prefs.getStringList(_ordersKey) ?? [];
    return rawList
        .map((str) {
          try {
            return jsonDecode(str) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> savePersistedOrdersJson(List<Map<String, dynamic>> list) {
    final rawList = list.map((m) => jsonEncode(m)).toList();
    return _prefs.setStringList(_ordersKey, rawList);
  }
}
