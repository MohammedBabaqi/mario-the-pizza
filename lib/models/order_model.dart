import 'package:equatable/equatable.dart';

/// Order status lifecycle.
enum OrderStatus {
  confirmed('Order Confirmed', '📋'),
  preparing('Preparing Your Pizza', '👨‍🍳'),
  baking('Pizza in the Oven', '🔥'),
  outForDelivery('Out for Delivery', '🛵'),
  delivered('Delivered', '🎉');

  const OrderStatus(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Represents an order item (flattened pizza info for order history).
class OrderItemModel extends Equatable {
  final String id;
  final String pizzaId;
  final String pizzaName;
  final String pizzaImageUrl;
  final double pizzaPrice;
  final int quantity;
  final String size;
  final String crust;
  final String sauce;
  final List<String> extraToppings;
  final double itemTotal;

  const OrderItemModel({
    required this.id,
    required this.pizzaId,
    required this.pizzaName,
    required this.pizzaImageUrl,
    required this.pizzaPrice,
    this.quantity = 1,
    this.size = 'Medium',
    this.crust = 'Classic',
    this.sauce = 'Tomato',
    this.extraToppings = const [],
    required this.itemTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      pizzaId: json['pizzaId'] as String,
      pizzaName: json['pizzaName'] as String,
      pizzaImageUrl: json['pizzaImageUrl'] as String? ?? '',
      pizzaPrice: (json['pizzaPrice'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      size: json['size'] as String? ?? 'Medium',
      crust: json['crust'] as String? ?? 'Classic',
      sauce: json['sauce'] as String? ?? 'Tomato',
      extraToppings: List<String>.from(json['extraToppings'] ?? []),
      itemTotal: (json['itemTotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pizzaId': pizzaId,
        'pizzaName': pizzaName,
        'pizzaImageUrl': pizzaImageUrl,
        'pizzaPrice': pizzaPrice,
        'quantity': quantity,
        'size': size,
        'crust': crust,
        'sauce': sauce,
        'extraToppings': extraToppings,
        'itemTotal': itemTotal,
      };

  @override
  List<Object?> get props => [
        id, pizzaId, pizzaName, pizzaImageUrl, pizzaPrice,
        quantity, size, crust, sauce, extraToppings, itemTotal,
      ];
}

/// Represents a placed order.
class OrderModel extends Equatable {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String deliveryAddress;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.createdAt,
    this.estimatedDelivery,
  });

  int get estimatedMinutesRemaining {
    if (estimatedDelivery == null) return 0;
    final remaining = estimatedDelivery!.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  int get currentStepIndex => OrderStatus.values.indexOf(status);

  double get progress => (currentStepIndex + 1) / OrderStatus.values.length;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => OrderStatus.confirmed,
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'] as String,
      paymentMethod: json['paymentMethod'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'createdAt': createdAt.toIso8601String(),
        'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      };

  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItemModel>? items,
    OrderStatus? status,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    String? deliveryAddress,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? estimatedDelivery,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, items, status, subtotal, deliveryFee,
        discount, total, deliveryAddress, paymentMethod,
        createdAt, estimatedDelivery,
      ];
}
