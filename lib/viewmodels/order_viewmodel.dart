import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/order_service.dart';

import '../services/prefs_service.dart';

/// Status for order list loading.
enum OrderListStatus { initial, loading, success, failure }

/// MVVM ViewModel for orders with local and backend synchronization.
class OrderViewModel extends ChangeNotifier {
  final OrderService _orderService;
  final PrefsService? _prefs;

  OrderViewModel(this._orderService, [this._prefs]);

  // ── Order History ─────────────────────────────────────────────────

  OrderListStatus _listStatus = OrderListStatus.initial;
  List<OrderModel> _orders = [];
  String? _listError;

  OrderListStatus get listStatus => _listStatus;
  List<OrderModel> get orders => _orders;
  String? get listError => _listError;
  bool get isListLoading => _listStatus == OrderListStatus.loading;

  Future<void> loadOrders() async {
    _listStatus = OrderListStatus.loading;
    _listError = null;
    notifyListeners();

    // 1. First retrieve any locally persisted orders
    final localJsonList = _prefs?.getPersistedOrdersJson() ?? [];
    final List<OrderModel> localOrders = localJsonList
        .map((j) {
          try {
            return OrderModel.fromJson(j);
          } catch (_) {
            return null;
          }
        })
        .whereType<OrderModel>()
        .toList();

    try {
      final fetched = await _orderService.getOrders();
      // Combine fetched API orders + local orders, unique by ID
      final Map<String, OrderModel> map = {};
      for (final o in localOrders) {
        map[o.id] = o;
      }
      for (final o in fetched) {
        map[o.id] = o;
      }
      _orders = map.values.toList();
      if (_orders.isEmpty) {
        _orders = _defaultMockOrders();
      }
      _listStatus = OrderListStatus.success;
    } catch (e) {
      if (localOrders.isNotEmpty) {
        _orders = localOrders;
      } else if (_orders.isEmpty) {
        _orders = _defaultMockOrders();
      }
      _listStatus = OrderListStatus.success;
    }
    notifyListeners();
  }

  void addOrder(OrderModel order) {
    _orders = [order, ..._orders.where((o) => o.id != order.id)];
    _saveLocalOrders();
    notifyListeners();
  }

  void _saveLocalOrders() {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList = _orders.map((o) => o.toJson()).toList();
    prefs.savePersistedOrdersJson(jsonList);
  }

  // ── Order Tracking ────────────────────────────────────────────────

  OrderModel? _trackedOrder;
  OrderModel? get trackedOrder => _trackedOrder;

  Future<void> loadOrder(String orderId) async {
    try {
      final fetched = await _orderService.getOrderById(orderId);
      if (fetched != null) {
        _trackedOrder = fetched;
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Try from local list
    try {
      _trackedOrder = _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      try {
        _trackedOrder = _defaultMockOrders().firstWhere((o) => o.id == orderId);
      } catch (_) {
        _trackedOrder = null;
      }
    }
    notifyListeners();
  }

  static List<OrderModel> _defaultMockOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'ORD-98422',
        userId: 'user_demo_mario',
        items: const [
          OrderItemModel(
            id: 'item_bbq_1',
            pizzaId: 'bbq_chicken',
            pizzaName: 'BBQ Chicken',
            pizzaImageUrl: 'https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=600&h=600&fit=crop',
            pizzaPrice: 13.99,
            quantity: 1,
            size: 'Large',
            crust: 'Cheese Stuffed',
            sauce: 'BBQ',
            extraToppings: ['Extra Cheese', 'Onions'],
            itemTotal: 15.99,
          ),
        ],
        status: OrderStatus.outForDelivery,
        subtotal: 15.99,
        deliveryFee: 0.0,
        discount: 0.0,
        total: 15.99,
        deliveryAddress: 'Hadda St, Building 14, Sanaa',
        paymentMethod: 'Credit / Debit Card',
        createdAt: now.subtract(const Duration(minutes: 25)),
        estimatedDelivery: now.add(const Duration(minutes: 15)),
      ),
      OrderModel(
        id: 'ORD-98421',
        userId: 'user_demo_mario',
        items: const [
          OrderItemModel(
            id: 'item_pep_1',
            pizzaId: 'pepperoni',
            pizzaName: 'Pepperoni',
            pizzaImageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&h=600&fit=crop',
            pizzaPrice: 10.99,
            quantity: 1,
            size: 'Medium',
            crust: 'Classic',
            sauce: 'Tomato',
            extraToppings: [],
            itemTotal: 10.99,
          ),
          OrderItemModel(
            id: 'item_mar_1',
            pizzaId: 'margherita',
            pizzaName: 'Margherita',
            pizzaImageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&h=600&fit=crop',
            pizzaPrice: 8.99,
            quantity: 1,
            size: 'Medium',
            crust: 'Thin Crust',
            sauce: 'Tomato',
            extraToppings: ['Fresh Basil'],
            itemTotal: 9.99,
          ),
        ],
        status: OrderStatus.delivered,
        subtotal: 20.98,
        deliveryFee: 2.0,
        discount: 0.0,
        total: 22.98,
        deliveryAddress: 'Hadda St, Building 14, Sanaa',
        paymentMethod: 'Cash on Delivery',
        createdAt: now.subtract(const Duration(days: 1)),
        estimatedDelivery: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

/// Checkout status.
enum CheckoutStatus { initial, loading, success, failure }

/// MVVM ViewModel for checkout flow.
class CheckoutViewModel extends ChangeNotifier {
  final OrderService _orderService;

  CheckoutViewModel(this._orderService);

  CheckoutStatus _status = CheckoutStatus.initial;
  String _deliveryAddress = '';
  String _phoneNumber = '';
  String _paymentMethod = 'Cash on Delivery';
  OrderModel? _order;
  String? _errorMessage;

  CheckoutStatus get status => _status;
  String get deliveryAddress => _deliveryAddress;
  String get phoneNumber => _phoneNumber;
  String get paymentMethod => _paymentMethod;
  OrderModel? get order => _order;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == CheckoutStatus.loading;
  bool get isSuccess => _status == CheckoutStatus.success;

  void onAddressChanged(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void onPhoneChanged(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  void onPaymentMethodChanged(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<void> placeOrder({
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double total,
  }) async {
    if (cartItems.isEmpty) {
      _status = CheckoutStatus.failure;
      _errorMessage = 'Your cart is empty!';
      notifyListeners();
      return;
    }

    if (_deliveryAddress.trim().isEmpty) {
      _status = CheckoutStatus.failure;
      _errorMessage = 'Please enter a delivery address.';
      notifyListeners();
      return;
    }

    if (_phoneNumber.trim().isEmpty) {
      _status = CheckoutStatus.failure;
      _errorMessage = 'Please enter your contact phone number.';
      notifyListeners();
      return;
    }

    _status = CheckoutStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderItems = cartItems.map((item) => OrderItemModel(
            id: item.id,
            pizzaId: item.pizza.id,
            pizzaName: item.pizza.name,
            pizzaImageUrl: item.pizza.imageUrl,
            pizzaPrice: item.pizza.price,
            quantity: item.quantity,
            size: item.size.label,
            crust: item.crust.label,
            sauce: item.sauce.label,
            extraToppings: item.extraToppings,
            itemTotal: item.itemTotal,
          )).toList();

      final fullAddress = _phoneNumber.isNotEmpty
          ? '$_deliveryAddress · 📞 $_phoneNumber'
          : _deliveryAddress;

      _order = await _orderService.placeOrder(
        items: orderItems,
        deliveryAddress: fullAddress,
        paymentMethod: _paymentMethod,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: 0,
        total: total,
      );
      _status = CheckoutStatus.success;
    } catch (e) {
      _status = CheckoutStatus.failure;
      _errorMessage = 'Order failed. Please try again';
    }
    notifyListeners();
  }

  void reset() {
    _status = CheckoutStatus.initial;
    _deliveryAddress = '';
    _phoneNumber = '';
    _paymentMethod = 'Cash on Delivery';
    _order = null;
    _errorMessage = null;
    notifyListeners();
  }
}
