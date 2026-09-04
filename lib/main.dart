import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/api_service.dart';
import 'services/local_db_service.dart';
import 'services/prefs_service.dart';

/// MARIO — Premium Pizza Delivery App
/// MVVM Architecture with Go Backend, SQLite, and SharedPreferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences (LocalStorage requirement: SharedPref)
  final sharedPreferences = await SharedPreferences.getInstance();
  final prefsService = PrefsService(sharedPreferences);

  // Initialize SQLite database (LocalStorage requirement: sqlite)
  final localDbService = LocalDbService(prefsService);
  if (!kIsWeb) {
    await localDbService.database;
  }

  // Initialize API service (Go backend API)
  final apiService = ApiService();
  final savedToken = prefsService.getAuthToken();
  if (savedToken != null) {
    apiService.setToken(savedToken);
  }

  // Run the app with Dependency Injection via Providers
  runApp(
    MarioApp(
      prefsService: prefsService,
      apiService: apiService,
      localDbService: localDbService,
    ),
  );
}
