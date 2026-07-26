import 'package:flutter/material.dart';
import '../data/models/recipe_model.dart';
import '../data/models/category_model.dart';
import '../data/services/recipe_service.dart';

enum RecipeLoadState { idle, loading, loaded, error }

class RecipeProvider extends ChangeNotifier {
  List<RecipeModel> _recipes = [];
  List<RecipeModel> _myRecipes = [];
  List<CategoryModel> _categories = [];
  RecipeLoadState _homeState = RecipeLoadState.idle;
  RecipeLoadState _myRecipesState = RecipeLoadState.idle;
  String? _errorMessage;
  String _searchQuery = '';
  int? _selectedCategoryId;

  List<RecipeModel> get recipes => _recipes;
  List<RecipeModel> get myRecipes => _myRecipes;
  List<CategoryModel> get categories => _categories;
  RecipeLoadState get homeState => _homeState;
  RecipeLoadState get myRecipesState => _myRecipesState;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;

  /// Load home recipes (with current search + filter)
  Future<void> loadRecipes() async {
    _homeState = RecipeLoadState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _recipes = await RecipeService.getRecipes(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
      );
      _homeState = RecipeLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _homeState = RecipeLoadState.error;
    }
    notifyListeners();
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await RecipeService.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  /// Load my recipes
  Future<void> loadMyRecipes() async {
    _myRecipesState = RecipeLoadState.loading;
    notifyListeners();
    try {
      _myRecipes = await RecipeService.getMyRecipes();
      _myRecipesState = RecipeLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _myRecipesState = RecipeLoadState.error;
    }
    notifyListeners();
  }

  /// Search recipes
  void setSearch(String query) {
    _searchQuery = query;
    loadRecipes();
  }

  /// Filter by category
  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadRecipes();
  }

  /// Delete a recipe from my recipes
  Future<bool> deleteRecipe(int id) async {
    try {
      await RecipeService.deleteRecipe(id);
      _myRecipes.removeWhere((r) => r.id == id);
      _recipes.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Update favorite status in local list
  void updateFavoriteStatus(int recipeId, bool isFavorited) {
    final index = _recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      _recipes[index] = _recipes[index].copyWith(isFavorited: isFavorited);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
