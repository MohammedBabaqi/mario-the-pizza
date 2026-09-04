import 'package:flutter/material.dart';
import '../models/pizza_model.dart';
import '../models/category_model.dart';
import '../services/pizza_service.dart';

/// Status for data-loading operations.
enum ViewModelStatus { initial, loading, success, failure }

/// MVVM ViewModel for pizza menu data.
class PizzaViewModel extends ChangeNotifier {
  final PizzaService _pizzaService;

  PizzaViewModel(this._pizzaService);

  // ── State ────────────────────────────────────────────────────────

  ViewModelStatus _status = ViewModelStatus.initial;
  List<PizzaModel> _pizzas = [];
  List<CategoryModel> _categories = [];
  String _selectedCategoryId = 'all';
  String? _errorMessage;

  ViewModelStatus get status => _status;
  List<PizzaModel> get pizzas => _pizzas;
  List<CategoryModel> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == ViewModelStatus.loading;
  bool get hasError => _status == ViewModelStatus.failure;

  List<PizzaModel> get popularPizzas =>
      _pizzas.where((p) => p.isPopular).toList();

  List<PizzaModel> get recommendedPizzas =>
      _pizzas.where((p) => p.isRecommended).toList();

  // ── Actions ──────────────────────────────────────────────────────

  /// Fetch all pizzas and categories.
  Future<void> loadPizzas() async {
    _status = ViewModelStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _pizzaService.getPizzas(),
        _pizzaService.getCategories(),
      ]);

      _pizzas = results[0] as List<PizzaModel>;
      _categories = results[1] as List<CategoryModel>;
      _selectedCategoryId = 'all';
      _status = ViewModelStatus.success;
    } catch (e) {
      _status = ViewModelStatus.failure;
      _errorMessage = 'Our menu is taking a pizza break 🍕 Try again!';
    }
    notifyListeners();
  }

  /// Add a new real food item/pizza into SQLite and refresh state.
  Future<void> addPizza(PizzaModel pizza) async {
    await _pizzaService.addPizza(pizza);
    await loadPizzas();
  }

  /// Update an existing food item in SQLite and refresh state.
  Future<void> updatePizza(PizzaModel pizza) async {
    await _pizzaService.updatePizza(pizza);
    await loadPizzas();
  }

  /// Delete a food item from SQLite and refresh state.
  Future<void> deletePizza(String id) async {
    await _pizzaService.deletePizza(id);
    await loadPizzas();
  }

  /// Filter pizzas by category.
  Future<void> loadPizzasByCategory(String categoryId) async {
    _status = ViewModelStatus.loading;
    _selectedCategoryId = categoryId;
    _errorMessage = null;
    notifyListeners();

    try {
      final pizzas = await _pizzaService.getPizzasByCategory(categoryId);
      _pizzas = pizzas;
      _status = ViewModelStatus.success;
    } catch (e) {
      _status = ViewModelStatus.failure;
      _errorMessage = 'Couldn\'t load pizzas. Please try again';
    }
    notifyListeners();
  }

  /// Get a single pizza by ID from the current list or custom craft template.
  PizzaModel? getPizzaById(String id) {
    if (id == 'craft_pizza' || id == 'custom_pizza') {
      return PizzaModel.craftYourOwn;
    }
    try {
      return _pizzas.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch a single pizza from the service (for detail screen).
  Future<PizzaModel?> fetchPizzaById(String id) async {
    if (id == 'craft_pizza' || id == 'custom_pizza') {
      return PizzaModel.craftYourOwn;
    }
    final cached = getPizzaById(id);
    if (cached != null) return cached;

    try {
      return await _pizzaService.getPizzaById(id);
    } catch (_) {
      return null;
    }
  }
}
