import 'package:flutter/material.dart';
import '../models/pizza_model.dart';
import '../services/prefs_service.dart';

/// Sort options for search results.
enum PizzaSortOption {
  popular('Popular 🔥'),
  priceLowToHigh('Price: Low to High 🏷️'),
  priceHighToLow('Price: High to Low 💎'),
  rating('Top Rated ⭐');

  final String label;
  const PizzaSortOption(this.label);
}

/// MVVM ViewModel for search with SharedPreferences-based recent searches.
class SearchViewModel extends ChangeNotifier {
  final List<PizzaModel> _allPizzas;
  final PrefsService _prefs;

  SearchViewModel(this._allPizzas, this._prefs) {
    _recentSearches = _prefs.getRecentSearches();
    _applyFilterAndSort();
  }

  String _query = '';
  String _selectedCategory = 'all';
  PizzaSortOption _sortOption = PizzaSortOption.popular;
  List<PizzaModel> _results = [];
  List<String> _recentSearches = [];

  String get query => _query;
  String get selectedCategory => _selectedCategory;
  PizzaSortOption get sortOption => _sortOption;
  List<PizzaModel> get results => _results;
  List<String> get recentSearches => _recentSearches;

  void updateQuery(String query) {
    _query = query;
    _applyFilterAndSort();
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _applyFilterAndSort();
    notifyListeners();
  }

  void setSortOption(PizzaSortOption option) {
    _sortOption = option;
    _applyFilterAndSort();
    notifyListeners();
  }

  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final current = List<String>.from(_recentSearches);
    current.remove(query);
    current.insert(0, query);
    if (current.length > 6) current.removeLast();
    _recentSearches = current;
    notifyListeners();
    await _prefs.setRecentSearches(current);
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    notifyListeners();
    await _prefs.clearRecentSearches();
  }

  void _applyFilterAndSort() {
    List<PizzaModel> filtered = _allPizzas.where((pizza) {
      final q = _query.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          pizza.name.toLowerCase().contains(q) ||
          pizza.category.toLowerCase().contains(q) ||
          pizza.ingredients.any((ing) => ing.toLowerCase().contains(q));
      final matchesCategory = _selectedCategory == 'all' ||
          pizza.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case PizzaSortOption.popular:
        filtered.sort((a, b) {
          if (a.isPopular != b.isPopular) return b.isPopular ? 1 : -1;
          return b.rating.compareTo(a.rating);
        });
      case PizzaSortOption.priceLowToHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case PizzaSortOption.priceHighToLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case PizzaSortOption.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    _results = filtered;
  }
}
