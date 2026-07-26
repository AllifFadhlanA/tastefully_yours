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
  final List<CategoryModel> categories;
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
    this.categories = const [],
    this.ingredients = const [],
    this.instructions = const [],
    this.isFavorited = false,
    this.userName,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      cookTime: json['cook_time'] as int?,
      difficulty: json['difficulty'] as String?,
      servings: json['servings'] as int?,
      calories: json['calories'] as int?,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
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
      categories: categories,
      ingredients: ingredients,
      instructions: instructions,
      isFavorited: isFavorited ?? this.isFavorited,
      userName: userName,
    );
  }

  String get categoryLabel {
    if (categories.isEmpty) return 'General';
    return categories.first.name;
  }

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
