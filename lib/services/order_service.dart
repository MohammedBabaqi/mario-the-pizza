import '../models/order_model.dart';
import 'api_service.dart';

/// Handles order operations via the Go backend API.
class OrderService {
  final ApiService _api;

  OrderService(this._api);

  /// Place a new order.
  Future<OrderModel> placeOrder({
    required List<OrderItemModel> items,
    required String deliveryAddress,
    required String paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
  }) async {
    final response = await _api.post('/orders', {
      'items': items.map((e) => e.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
    });

    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  /// Get all orders for the current user.
  Future<List<OrderModel>> getOrders() async {
    final response = await _api.get('/orders');
    return (response as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single order by ID.
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _api.get('/orders/$orderId');
      return OrderModel.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
