import 'package:flutter/material.dart';
import '../data/models/recipe_model.dart';
import '../data/services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<RecipeModel> _favorites = [];
  Set<int> _favoritedIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<RecipeModel> get favorites => _favorites;
  Set<int> get favoritedIds => _favoritedIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorited(int recipeId) => _favoritedIds.contains(recipeId);

  /// Load favorites from API
  Future<void> loadFavorites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _favorites = await FavoriteService.getFavorites();
      _favoritedIds = _favorites.map((r) => r.id).toSet();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(RecipeModel recipe) async {
    final wasAdded = !_favoritedIds.contains(recipe.id);

    // Optimistic update
    if (wasAdded) {
      _favoritedIds.add(recipe.id);
      _favorites.add(recipe.copyWith(isFavorited: true));
    } else {
      _favoritedIds.remove(recipe.id);
      _favorites.removeWhere((r) => r.id == recipe.id);
    }
    notifyListeners();

    try {
      await FavoriteService.toggleFavorite(recipe.id);
    } catch (_) {
      // Revert on failure
      if (wasAdded) {
        _favoritedIds.remove(recipe.id);
        _favorites.removeWhere((r) => r.id == recipe.id);
      } else {
        _favoritedIds.add(recipe.id);
        _favorites.add(recipe);
      }
      notifyListeners();
    }
  }

  void clear() {
    _favorites = [];
    _favoritedIds = {};
    notifyListeners();
  }
}
