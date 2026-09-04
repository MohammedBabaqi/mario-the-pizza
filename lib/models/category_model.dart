import 'package:equatable/equatable.dart';

/// Pizza category.
class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [id, name, emoji, sortOrder];
}
