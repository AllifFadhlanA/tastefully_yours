class ApiConstants {
  ApiConstants._();

  // Ganti IP ini saja kalau IP laptop berubah (cek lewat ipconfig)
  static const String host = 'http://192.168.1.9:8000';

  // Base URL
  static const String baseUrl = '$host/api';

  // Auth
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String profile = '$baseUrl/profile';

  // Recipes
  static const String recipes = '$baseUrl/recipes';
  static const String myRecipes = '$baseUrl/my-recipes';
  static String recipeDetail(int id) => '$baseUrl/recipes/$id';
  static String updateRecipe(int id) => '$baseUrl/recipes/$id';
  static String deleteRecipe(int id) => '$baseUrl/recipes/$id';

  // Favorites
  static const String favorites = '$baseUrl/favorites';
  static String toggleFavorite(int id) => '$baseUrl/favorites/$id';

  // Categories
  static const String categories = '$baseUrl/categories';

  // Storage (gambar)
  static const String storageUrl = '$host/api/images';
  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$storageUrl/$path';
  }
}
