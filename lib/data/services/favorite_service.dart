import '../models/recipe_model.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class FavoriteService {
  /// Get list of favorited recipes
  static Future<List<RecipeModel>> getFavorites() async {
    final response = await ApiService.get(ApiConstants.favorites, withAuth: true);
    final data = response['data'] as List<dynamic>? ?? response['favorites'] as List<dynamic>? ?? [];
    return data.map((r) => RecipeModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Toggle favorite (add if not favorited, remove if already favorited)
  static Future<bool> toggleFavorite(int recipeId) async {
    final response = await ApiService.post(
      ApiConstants.toggleFavorite(recipeId),
      withAuth: true,
    );
    // API returns { "favorited": true/false }
    return response['favorited'] as bool? ?? false;
  }
}
