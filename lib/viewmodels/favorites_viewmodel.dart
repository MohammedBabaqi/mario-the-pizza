import 'package:flutter/material.dart';
import '../services/prefs_service.dart';

/// MVVM ViewModel for favorites (SharedPreferences-based).
class FavoritesViewModel extends ChangeNotifier {
  final PrefsService _prefs;

  FavoritesViewModel(this._prefs);

  Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;
  bool isFavorite(String pizzaId) => _favoriteIds.contains(pizzaId);
  int get count => _favoriteIds.length;

  /// Load favorites from SharedPreferences.
  void loadFavorites() {
    _favoriteIds = Set<String>.from(_prefs.getFavoriteIds());
    notifyListeners();
  }

  /// Toggle favorite status for a pizza.
  Future<void> toggle(String pizzaId) async {
    final updated = Set<String>.from(_favoriteIds);
    if (updated.contains(pizzaId)) {
      updated.remove(pizzaId);
    } else {
      updated.add(pizzaId);
    }
    _favoriteIds = updated;
    notifyListeners();
    await _prefs.setFavoriteIds(updated.toList());
  }
}
