import 'package:equatable/equatable.dart';
import 'pizza_model.dart';

/// Size options for a pizza.
enum PizzaSize {
  small('Small', 0.0),
  medium('Medium', 2.00),
  large('Large', 4.00);

  const PizzaSize(this.label, this.priceModifier);
  final String label;
  final double priceModifier;
}

/// Crust options for a pizza.
enum CrustType {
  classic('Classic', 0.0),
  thin('Thin', 0.0),
  cheesy('Cheesy', 1.50),
  stuffed('Stuffed', 2.50);

  const CrustType(this.label, this.priceModifier);
  final String label;
  final double priceModifier;
}

/// Sauce options for a pizza.
enum SauceType {
  tomato('Tomato', 0.0),
  spicy('Spicy', 0.50),
  creamy('Creamy', 0.50);

  const SauceType(this.label, this.priceModifier);
  final String label;
  final double priceModifier;
}

/// Represents a single item in the shopping cart.
class CartItemModel extends Equatable {
  final String id;
  final PizzaModel pizza;
  final int quantity;
  final PizzaSize size;
  final CrustType crust;
  final SauceType sauce;
  final List<String> extraToppings;

  const CartItemModel({
    required this.id,
    required this.pizza,
    this.quantity = 1,
    this.size = PizzaSize.medium,
    this.crust = CrustType.classic,
    this.sauce = SauceType.tomato,
    this.extraToppings = const [],
  });

  double get itemTotal {
    final basePrice = pizza.price;
    final sizeExtra = size.priceModifier;
    final crustExtra = crust.priceModifier;
    final sauceExtra = sauce.priceModifier;
    final toppingsExtra = extraToppings.length * 1.00;
    return (basePrice + sizeExtra + crustExtra + sauceExtra + toppingsExtra) *
        quantity;
  }

  String get customizationSummary {
    final parts = <String>[size.label, crust.label, sauce.label];
    if (extraToppings.isNotEmpty) {
      parts.add('+${extraToppings.length} toppings');
    }
    return parts.join(' · ');
  }

  CartItemModel copyWith({
    String? id,
    PizzaModel? pizza,
    int? quantity,
    PizzaSize? size,
    CrustType? crust,
    SauceType? sauce,
    List<String>? extraToppings,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      pizza: pizza ?? this.pizza,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      crust: crust ?? this.crust,
      sauce: sauce ?? this.sauce,
      extraToppings: extraToppings ?? this.extraToppings,
    );
  }

  bool hasSameConfiguration(CartItemModel other) {
    if (pizza.id != other.pizza.id) return false;
    if (size != other.size) return false;
    if (crust != other.crust) return false;
    if (sauce != other.sauce) return false;
    if (extraToppings.length != other.extraToppings.length) return false;
    final s1 = Set<String>.from(extraToppings);
    final s2 = Set<String>.from(other.extraToppings);
    return s1.containsAll(s2) && s2.containsAll(s1);
  }

  @override
  List<Object?> get props => [id, pizza, quantity, size, crust, sauce, extraToppings];
}
