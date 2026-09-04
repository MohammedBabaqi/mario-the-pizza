import 'package:equatable/equatable.dart';

/// Type of ingredient for customization.
enum IngredientType { topping, sauce, cheese, base }

/// Represents a customization ingredient.
class IngredientModel extends Equatable {
  final String id;
  final String name;
  final IngredientType type;
  final double priceModifier;
  final int calorieModifier;
  final String emoji;

  const IngredientModel({
    required this.id,
    required this.name,
    required this.type,
    this.priceModifier = 0.0,
    this.calorieModifier = 0,
    this.emoji = '🍕',
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: IngredientType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IngredientType.topping,
      ),
      priceModifier: (json['priceModifier'] as num?)?.toDouble() ?? 0.0,
      calorieModifier: json['calorieModifier'] as int? ?? 0,
      emoji: json['emoji'] as String? ?? '🍕',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'priceModifier': priceModifier,
        'calorieModifier': calorieModifier,
        'emoji': emoji,
      };

  @override
  List<Object?> get props => [id, name, type, priceModifier, calorieModifier, emoji];
}
