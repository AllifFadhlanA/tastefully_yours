import 'dart:io';
import '../models/recipe_model.dart';
import '../models/category_model.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class RecipeService {
  /// Fetch all recipes (with optional search and category filter)
  static Future<List<RecipeModel>> getRecipes({
    String? search,
    int? categoryId,
  }) async {
    String url = ApiConstants.recipes;
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category'] = categoryId.toString();
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    }

    final response = await ApiService.get(url, withAuth: true);
    final data = response['data'] as List<dynamic>? ?? response['recipes'] as List<dynamic>? ?? [];
    return data.map((r) => RecipeModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Fetch single recipe detail
  static Future<RecipeModel> getRecipeDetail(int id) async {
    final response = await ApiService.get(ApiConstants.recipeDetail(id), withAuth: true);
    final data = response['data'] as Map<String, dynamic>? ?? response['recipe'] as Map<String, dynamic>?;
    return RecipeModel.fromJson(data!);
  }

  /// Fetch current user's recipes
  static Future<List<RecipeModel>> getMyRecipes() async {
    final response = await ApiService.get(ApiConstants.myRecipes, withAuth: true);
    final data = response['data'] as List<dynamic>? ?? response['recipes'] as List<dynamic>? ?? [];
    return data.map((r) => RecipeModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Create a new recipe (with optional image file)
  static Future<RecipeModel> createRecipe({
    required String title,
    String? description,
    File? imageFile,
    int? cookTime,
    String? difficulty,
    int? servings,
    int? calories,
    required List<int> categoryIds,
    required List<Map<String, String>> ingredients,
    required List<String> instructions,
  }) async {
    final fields = _buildFields(
      title: title,
      description: description,
      cookTime: cookTime,
      difficulty: difficulty,
      servings: servings,
      calories: calories,
      categoryIds: categoryIds,
      ingredients: ingredients,
      instructions: instructions,
    );

    final response = await ApiService.postMultipart(
      ApiConstants.recipes,
      fields: fields,
      imageFile: imageFile,
      withAuth: true,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response['recipe'] as Map<String, dynamic>?;
    return RecipeModel.fromJson(data!);
  }

  /// Update an existing recipe
  static Future<RecipeModel> updateRecipe({
    required int id,
    required String title,
    String? description,
    File? imageFile,
    int? cookTime,
    String? difficulty,
    int? servings,
    int? calories,
    required List<int> categoryIds,
    required List<Map<String, String>> ingredients,
    required List<String> instructions,
  }) async {
    final fields = _buildFields(
      title: title,
      description: description,
      cookTime: cookTime,
      difficulty: difficulty,
      servings: servings,
      calories: calories,
      categoryIds: categoryIds,
      ingredients: ingredients,
      instructions: instructions,
    );

    final response = await ApiService.postMultipart(
      ApiConstants.updateRecipe(id),
      fields: fields,
      imageFile: imageFile,
      withAuth: true,
      isPut: true,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response['recipe'] as Map<String, dynamic>?;
    return RecipeModel.fromJson(data!);
  }

  /// Delete a recipe
  static Future<void> deleteRecipe(int id) async {
    await ApiService.delete(ApiConstants.deleteRecipe(id), withAuth: true);
  }

  /// Fetch all categories
  static Future<List<CategoryModel>> getCategories() async {
    final response = await ApiService.get(ApiConstants.categories);
    final data = response['data'] as List<dynamic>? ?? response['categories'] as List<dynamic>? ?? [];
    return data.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  // Helper: build flat fields map for multipart
  static Map<String, String> _buildFields({
    required String title,
    String? description,
    int? cookTime,
    String? difficulty,
    int? servings,
    int? calories,
    required List<int> categoryIds,
    required List<Map<String, String>> ingredients,
    required List<String> instructions,
  }) {
    final fields = <String, String>{
      'title': title,
      if (description != null) 'description': description,
      if (cookTime != null) 'cook_time': cookTime.toString(),
      if (difficulty != null) 'difficulty': difficulty,
      if (servings != null) 'servings': servings.toString(),
      if (calories != null) 'calories': calories.toString(),
    };

    // categories[] array
    for (int i = 0; i < categoryIds.length; i++) {
      fields['categories[$i]'] = categoryIds[i].toString();
    }

    // ingredients[] array of objects
    for (int i = 0; i < ingredients.length; i++) {
      fields['ingredients[$i][name]'] = ingredients[i]['name'] ?? '';
      fields['ingredients[$i][amount]'] = ingredients[i]['amount'] ?? '';
    }

    // instructions[] array
    for (int i = 0; i < instructions.length; i++) {
      fields['instructions[$i][step_number]'] = (i + 1).toString();
      fields['instructions[$i][description]'] = instructions[i];
    }

    return fields;
  }
}
