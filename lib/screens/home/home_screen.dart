import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/recipe_provider.dart';
import 'widgets/category_chip.dart';
import 'widgets/recipe_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recipeProvider = context.read<RecipeProvider>();
      recipeProvider.loadCategories();
      recipeProvider.loadRecipes();
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final recipeProvider = context.read<RecipeProvider>();
    await Future.wait([
      recipeProvider.loadCategories(),
      recipeProvider.loadRecipes(),
      context.read<FavoriteProvider>().loadFavorites(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    final user = authProvider.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar & Header Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tastefully Yours',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user != null ? 'Hello, ${user.name}! Ready to cook?' : 'Hello! Ready to cook?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Profile Avatar
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withAlpha(50),
                          backgroundImage: user?.avatar != null
                              ? CachedNetworkImageProvider(ApiConstants.imageUrl(user!.avatar))
                              : null,
                          child: user?.avatar == null
                              ? const Icon(Icons.person_rounded, color: AppColors.primary)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar & Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search Text Field
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => recipeProvider.setSearch(val),
                      decoration: InputDecoration(
                        hintText: 'Search delicious recipes...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textHint),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  recipeProvider.setSearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kategori Filter Chip list
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recipeProvider.categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isAllSelected = recipeProvider.selectedCategoryId == null;
                            return CategoryChip(
                              label: 'All',
                              isSelected: isAllSelected,
                              onTap: () => recipeProvider.setCategory(null),
                            );
                          }

                          final category = recipeProvider.categories[index - 1];
                          final isSelected = recipeProvider.selectedCategoryId == category.id;
                          return CategoryChip(
                            label: category.name,
                            isSelected: isSelected,
                            onTap: () => recipeProvider.setCategory(category.id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Recipe List Feed
            _buildRecipeFeed(recipeProvider, isDark),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-recipe'),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildRecipeFeed(RecipeProvider provider, bool isDark) {
    if (provider.homeState == RecipeLoadState.loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (provider.homeState == RecipeLoadState.error) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'Gagal memuat data, periksa koneksi',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadRecipes(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Resep tidak ditemukan, coba kata kunci lain',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = provider.recipes[index];
            return RecipeCard(
              recipe: recipe,
              onTap: () => context.push('/recipe/${recipe.id}'),
            );
          },
          childCount: provider.recipes.length,
        ),
      ),
    );
  }
}
