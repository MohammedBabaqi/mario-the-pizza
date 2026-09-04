import '../models/pizza_model.dart';
import '../models/category_model.dart';
import '../models/ingredient_model.dart';
import 'api_service.dart';
import 'local_db_service.dart';

/// Handles pizza data fetching from Go API with SQLite caching.
class PizzaService {
  final ApiService _api;
  final LocalDbService _db;

  PizzaService(this._api, this._db);

  /// Fetch all pizzas from SQLite as source of truth, sync with API.
  Future<List<PizzaModel>> getPizzas() async {
    final localPizzas = await _db.getCachedPizzas();
    try {
      final response = await _api.get('/pizzas');
      final apiPizzas = (response as List)
          .map((e) => PizzaModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final map = {for (final p in localPizzas) p.id: p};
      for (final p in apiPizzas) {
        map.putIfAbsent(p.id, () => p);
      }
      final merged = map.values.toList();
      await _db.cachePizzas(merged);
      return merged;
    } catch (_) {
      // Return real SQLite database records
      return localPizzas;
    }
  }

  /// Add a real pizza into SQLite
  Future<void> addPizza(PizzaModel pizza) async {
    await _db.insertPizza(pizza);
  }

  /// Update a pizza in SQLite
  Future<void> updatePizza(PizzaModel pizza) async {
    await _db.updatePizza(pizza);
  }

  /// Delete a pizza from SQLite
  Future<void> deletePizza(String id) async {
    await _db.deletePizza(id);
  }

  /// Fetch a single pizza by ID.
  Future<PizzaModel?> getPizzaById(String id) async {
    try {
      final response = await _api.get('/pizzas/$id');
      return PizzaModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      // Try from cache
      return await _db.getPizzaById(id);
    }
  }

  /// Fetch pizzas by category.
  Future<List<PizzaModel>> getPizzasByCategory(String categoryId) async {
    try {
      final endpoint = categoryId == 'all'
          ? '/pizzas'
          : '/pizzas?category=$categoryId';
      final response = await _api.get(endpoint);
      return (response as List)
          .map((e) => PizzaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = await _db.getCachedPizzas();
      if (categoryId == 'all') return cached;
      return cached.where((p) => p.category == categoryId).toList();
    }
  }

  /// Fetch categories.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _api.get('/pizzas/categories');
      return (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Return default categories
      return const [
        CategoryModel(id: 'all', name: 'All', emoji: '🍕', sortOrder: 0),
        CategoryModel(id: 'classic', name: 'Classic', emoji: '🇮🇹', sortOrder: 1),
        CategoryModel(id: 'spicy', name: 'Spicy', emoji: '🌶️', sortOrder: 2),
        CategoryModel(id: 'veggie', name: 'Veggie', emoji: '🥬', sortOrder: 3),
        CategoryModel(id: 'special', name: 'Special', emoji: '⭐', sortOrder: 4),
      ];
    }
  }

  /// Default ingredients fallback matching backend seed.
  static const List<IngredientModel> defaultIngredients = [
    IngredientModel(id: 'pepperoni', name: 'Pepperoni', type: IngredientType.topping, priceModifier: 1.00, calorieModifier: 80, emoji: '🍖'),
    IngredientModel(id: 'mushrooms', name: 'Mushrooms', type: IngredientType.topping, priceModifier: 1.00, calorieModifier: 15, emoji: '🍄'),
    IngredientModel(id: 'olives', name: 'Olives', type: IngredientType.topping, priceModifier: 0.75, calorieModifier: 25, emoji: '🫒'),
    IngredientModel(id: 'basil', name: 'Basil', type: IngredientType.topping, priceModifier: 0.50, calorieModifier: 5, emoji: '🌿'),
    IngredientModel(id: 'onions', name: 'Onions', type: IngredientType.topping, priceModifier: 0.50, calorieModifier: 20, emoji: '🧅'),
    IngredientModel(id: 'bell_pepper', name: 'Bell Pepper', type: IngredientType.topping, priceModifier: 0.75, calorieModifier: 15, emoji: '🫑'),
    IngredientModel(id: 'extra_cheese', name: 'Extra Cheese', type: IngredientType.cheese, priceModifier: 1.50, calorieModifier: 110, emoji: '🧀'),
    IngredientModel(id: 'parmesan', name: 'Parmesan', type: IngredientType.cheese, priceModifier: 1.25, calorieModifier: 90, emoji: '🧀'),
    IngredientModel(id: 'tomato_sauce', name: 'Tomato Sauce', type: IngredientType.sauce, priceModifier: 0.0, calorieModifier: 30, emoji: '🍅'),
    IngredientModel(id: 'spicy_sauce', name: 'Spicy Sauce', type: IngredientType.sauce, priceModifier: 0.50, calorieModifier: 25, emoji: '🌶️'),
    IngredientModel(id: 'creamy_sauce', name: 'Creamy Sauce', type: IngredientType.sauce, priceModifier: 0.50, calorieModifier: 60, emoji: '🥛'),
  ];

  /// Fetch available ingredients for customization from Go API with local fallback.
  Future<List<IngredientModel>> getIngredients() async {
    try {
      final response = await _api.get('/pizzas/ingredients');
      final list = (response as List)
          .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
      return defaultIngredients;
    } catch (_) {
      return defaultIngredients;
    }
  }
}
