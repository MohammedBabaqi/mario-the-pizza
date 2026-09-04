import 'package:equatable/equatable.dart';

/// Represents a pizza menu item.
class PizzaModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final List<String> ingredients;
  final String category;
  final String imageUrl;
  final bool isPopular;
  final bool isRecommended;

  const PizzaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.ingredients,
    required this.category,
    required this.imageUrl,
    this.isPopular = false,
    this.isRecommended = false,
  });

  factory PizzaModel.fromJson(Map<String, dynamic> json) {
    return PizzaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      calories: json['calories'] as int,
      protein: json['protein'] as int,
      fat: json['fat'] as int,
      carbs: json['carbs'] as int,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      isPopular: json['isPopular'] as bool? ?? false,
      isRecommended: json['isRecommended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'rating': rating,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'ingredients': ingredients,
      'category': category,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'isRecommended': isRecommended,
    };
  }

  PizzaModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? rating,
    int? calories,
    int? protein,
    int? fat,
    int? carbs,
    List<String>? ingredients,
    String? category,
    String? imageUrl,
    bool? isPopular,
    bool? isRecommended,
  }) {
    return PizzaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      ingredients: ingredients ?? this.ingredients,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isPopular: isPopular ?? this.isPopular,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, price, rating, calories,
        protein, fat, carbs, ingredients, category, imageUrl,
        isPopular, isRecommended,
      ];

  /// Base pizza template for "Craft Your Own" master customization.
  static const PizzaModel craftYourOwn = PizzaModel(
    id: 'craft_pizza',
    name: 'Craft Your Masterpiece 🎨',
    description: 'Build your custom artisanal pizza from scratch with your favorite crust, sauce, cheeses, and toppings!',
    price: 7.99,
    rating: 5.0,
    calories: 550,
    protein: 20,
    fat: 16,
    carbs: 70,
    ingredients: ['Fresh Artisan Dough', 'Extra Virgin Olive Oil'],
    category: 'special',
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
    isPopular: true,
    isRecommended: true,
  );
}
