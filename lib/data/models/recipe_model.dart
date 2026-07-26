import 'category_model.dart';
import 'ingredient_model.dart';
import 'instruction_model.dart';

class RecipeModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String? image;
  final int? cookTime;
  final String? difficulty;
  final int? servings;
  final int? calories;
  final CategoryModel? category;
  final List<IngredientModel> ingredients;
  final List<InstructionModel> instructions;
  final bool isFavorited;
  final String? userName;

  const RecipeModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.image,
    this.cookTime,
    this.difficulty,
    this.servings,
    this.calories,
    this.category,
    this.ingredients = const [],
    this.instructions = const [],
    this.isFavorited = false,
    this.userName,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    if (json['category'] != null && json['category'] is Map<String, dynamic>) {
      cat = CategoryModel.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['categories'] != null &&
        json['categories'] is List &&
        (json['categories'] as List).isNotEmpty) {
      cat = CategoryModel.fromJson(
          (json['categories'] as List).first as Map<String, dynamic>);
    }

    return RecipeModel(
      id: _toInt(json['id'])!,
      userId: _toInt(json['user_id'])!,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      cookTime: _toInt(json['cook_time']),
      difficulty: json['difficulty'] as String?,
      servings: _toInt(json['servings']),
      calories: _toInt(json['calories']),
      category: cat,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((i) => IngredientModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>? ?? [])
          .map((s) => InstructionModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      isFavorited: json['is_favorited'] as bool? ?? false,
      userName: json['user']?['name'] as String?,
    );
  }

// Helper: parse int dari dynamic yang bisa berupa int ATAU String
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  RecipeModel copyWith({
    bool? isFavorited,
  }) {
    return RecipeModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      image: image,
      cookTime: cookTime,
      difficulty: difficulty,
      servings: servings,
      calories: calories,
      category: category,
      ingredients: ingredients,
      instructions: instructions,
      isFavorited: isFavorited ?? this.isFavorited,
      userName: userName,
    );
  }

  String get categoryLabel => category?.name ?? 'General';

  String get difficultyLabel => difficulty ?? 'Easy';

  String get cookTimeLabel {
    if (cookTime == null) return '-';
    if (cookTime! >= 60) {
      final h = cookTime! ~/ 60;
      final m = cookTime! % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${cookTime}min';
  }
}
