import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/recipe_model.dart';
import '../../data/services/recipe_service.dart';
import '../../providers/favorite_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  RecipeModel? _recipe;
  bool _isLoading = true;
  String? _errorMessage;

  // Track checked ingredients locally
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _loadRecipeDetail();
  }

  Future<void> _loadRecipeDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recipe = await RecipeService.getRecipeDetail(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoriteProvider = context.watch<FavoriteProvider>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe Detail')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null || _recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe Detail')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Gagal memuat resep.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRecipeDetail,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final recipe = _recipe!;
    final isFav = favoriteProvider.isFavorited(recipe.id);

    Color diffColor = AppColors.tagEasy;
    if (recipe.difficultyLabel.toLowerCase() == 'medium') {
      diffColor = AppColors.tagMedium;
    } else if (recipe.difficultyLabel.toLowerCase() == 'hard') {
      diffColor = AppColors.tagHard;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white70,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: isDark ? Colors.black54 : Colors.white70,
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.primary : null,
                    ),
                    onPressed: () => favoriteProvider.toggleFavorite(recipe),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: ApiConstants.imageUrl(recipe.image),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                  child: const Icon(Icons.restaurant_rounded, size: 60, color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Details List
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Author
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (recipe.userName != null)
                      Text(
                        'By Chef ${recipe.userName}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Nutrition Info Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.dividerDark : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientInfo(
                            icon: Icons.access_time_rounded,
                            value: recipe.cookTimeLabel,
                            label: 'Cook Time',
                          ),
                          _buildNutrientInfo(
                            icon: Icons.speed_rounded,
                            value: recipe.difficultyLabel,
                            label: 'Difficulty',
                            iconColor: diffColor,
                          ),
                          if (recipe.calories != null)
                            _buildNutrientInfo(
                              icon: Icons.local_fire_department_rounded,
                              value: '${recipe.calories} kcal',
                              label: 'Calories',
                              iconColor: AppColors.accent,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe.description!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ingredients Section
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (recipe.ingredients.isEmpty)
                      const Text(
                        'No ingredients listed.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: recipe.ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = recipe.ingredients[index];
                          final isChecked = _checkedIngredients.contains(ingredient.id);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              ingredient.name,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked
                                    ? AppColors.textHint
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                              ),
                            ),
                            subtitle: Text(
                              ingredient.amount,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isChecked ? AppColors.textHint : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: isChecked,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _checkedIngredients.add(ingredient.id);
                                } else {
                                  _checkedIngredients.remove(ingredient.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Instructions Section
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (recipe.instructions.isEmpty)
                      const Text(
                        'No instructions listed.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: recipe.instructions.length,
                        itemBuilder: (context, index) {
                          final step = recipe.instructions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step number badge
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${step.stepNumber}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Step Description
                                Expanded(
                                  child: Text(
                                    step.description,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      height: 1.5,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo({
    required IconData icon,
    required String value,
    required String label,
    Color iconColor = AppColors.primary,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
