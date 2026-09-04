import 'package:flutter/material.dart';
import '../models/pizza_model.dart';
import '../models/cart_item_model.dart';
import '../models/ingredient_model.dart';
import '../services/pizza_service.dart';

/// MVVM ViewModel for pizza customization (size, crust, sauce, toppings).
class CustomizationViewModel extends ChangeNotifier {
  PizzaModel? _pizza;
  PizzaSize _size = PizzaSize.medium;
  CrustType _crust = CrustType.classic;
  SauceType _sauce = SauceType.tomato;
  List<String> _extraToppings = [];
  double _basePrice = 0.0;

  List<IngredientModel> _availableIngredients = PizzaService.defaultIngredients;
  bool _isLoadingIngredients = false;

  PizzaModel? get pizza => _pizza;
  PizzaSize get size => _size;
  CrustType get crust => _crust;
  SauceType get sauce => _sauce;
  List<String> get extraToppings => List.unmodifiable(_extraToppings);
  double get basePrice => _basePrice;
  List<IngredientModel> get availableIngredients => _availableIngredients;
  bool get isLoadingIngredients => _isLoadingIngredients;

  List<IngredientModel> get toppingsList =>
      _availableIngredients.where((i) => i.type == IngredientType.topping).toList();

  List<IngredientModel> get cheesesList =>
      _availableIngredients.where((i) => i.type == IngredientType.cheese).toList();

  IngredientModel? getIngredientByName(String name) {
    try {
      return _availableIngredients.firstWhere(
        (i) => i.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  double get toppingsPrice {
    double sum = 0.0;
    for (final name in _extraToppings) {
      final ing = getIngredientByName(name);
      sum += ing != null ? ing.priceModifier : 1.00;
    }
    return sum;
  }

  int get extraCalories {
    int sum = 0;
    for (final name in _extraToppings) {
      final ing = getIngredientByName(name);
      sum += ing != null ? ing.calorieModifier : 50;
    }
    return sum;
  }

  int get totalCalories {
    final baseCal = _pizza?.calories ?? 650;
    final sizeMultiplier = _size == PizzaSize.small ? 0.75 : (_size == PizzaSize.large ? 1.35 : 1.0);
    return ((baseCal * sizeMultiplier) + extraCalories).round();
  }

  double get totalPrice {
    return _basePrice +
        _size.priceModifier +
        _crust.priceModifier +
        _sauce.priceModifier +
        toppingsPrice;
  }

  void initialize(PizzaModel pizza, [PizzaService? service]) {
    _pizza = pizza;
    _basePrice = pizza.price;
    _size = PizzaSize.medium;
    _crust = CrustType.classic;
    _sauce = SauceType.tomato;
    _extraToppings = [];
    if (service != null) {
      loadIngredients(service);
    }
    notifyListeners();
  }

  Future<void> loadIngredients(PizzaService service) async {
    _isLoadingIngredients = true;
    notifyListeners();
    try {
      final list = await service.getIngredients();
      if (list.isNotEmpty) {
        _availableIngredients = list;
      }
    } catch (_) {}
    _isLoadingIngredients = false;
    notifyListeners();
  }

  void selectSize(PizzaSize size) {
    _size = size;
    notifyListeners();
  }

  void selectCrust(CrustType crust) {
    _crust = crust;
    notifyListeners();
  }

  void selectSauce(SauceType sauce) {
    _sauce = sauce;
    notifyListeners();
  }

  void toggleTopping(String topping) {
    if (_extraToppings.contains(topping)) {
      _extraToppings = List.from(_extraToppings)..remove(topping);
    } else {
      _extraToppings = List.from(_extraToppings)..add(topping);
    }
    notifyListeners();
  }

  void reset() {
    if (_pizza != null) _basePrice = _pizza!.price;
    _size = PizzaSize.medium;
    _crust = CrustType.classic;
    _sauce = SauceType.tomato;
    _extraToppings = [];
    notifyListeners();
  }

  CartItemModel buildCartItem() {
    return CartItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pizza: _pizza!,
      size: _size,
      crust: _crust,
      sauce: _sauce,
      extraToppings: List.from(_extraToppings),
    );
  }
}
