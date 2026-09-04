import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';

/// MVVM ViewModel for shopping cart.
class CartViewModel extends ChangeNotifier {
  List<CartItemModel> _items = [];
  String? _errorMessage;
  String? _successMessage;

  List<CartItemModel> get items => _items;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => _items.length;
  bool get hasItems => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.itemTotal);
  double get deliveryFee => subtotal >= 25.00 ? 0.0 : 2.99;
  double get total => (subtotal + deliveryFee).clamp(0.0, double.infinity);

  // ── Actions ──────────────────────────────────────────────────────

  void addItem(CartItemModel item) {
    final existingIndex = _items.indexWhere((i) => i.hasSameConfiguration(item));
    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      _items = List.from(_items)
        ..[existingIndex] = existing.copyWith(quantity: existing.quantity + item.quantity);
      _successMessage = 'Updated ${item.pizza.name} quantity in cart! 🍕';
    } else {
      _items = List.from(_items)..add(item);
      _successMessage = '${item.pizza.name} added to cart!';
    }
    _errorMessage = null;
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items = _items.where((item) => item.id != itemId).toList();
    _errorMessage = null;
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    _items = _items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  void clearCart() {
    _items = [];
    notifyListeners();
  }

  void clear() => clearCart();

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
