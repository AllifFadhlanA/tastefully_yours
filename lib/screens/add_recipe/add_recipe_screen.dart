import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/services/recipe_service.dart';
import '../../providers/recipe_provider.dart';

class AddRecipeScreen extends StatefulWidget {
  final int? recipeId;

  const AddRecipeScreen({super.key, this.recipeId});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isInitLoading = false;

  // Form Fields
  File? _selectedImage;
  String? _existingImageUrl;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cookTimeCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  String _difficulty = 'Easy';

  final List<CategoryModel> _availableCategories = [];
  int? _selectedCategoryId;

  // Dynamic Fields
  final List<IngredientInputRow> _ingredients = [];
  final List<TextEditingController> _instructions = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.recipeId != null;
    _initData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cookTimeCtrl.dispose();
    _servingsCtrl.dispose();
    _caloriesCtrl.dispose();
    for (var row in _ingredients) {
      row.nameCtrl.dispose();
      row.amountCtrl.dispose();
    }
    for (var ctrl in _instructions) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isInitLoading = true);
    try {
      // Load categories first
      final categories = await RecipeService.getCategories();
      setState(() {
        _availableCategories.addAll(categories);
      });

      if (_isEditMode) {
        final recipe = await RecipeService.getRecipeDetail(widget.recipeId!);
        _titleCtrl.text = recipe.title;
        _descCtrl.text = recipe.description ?? '';
        _cookTimeCtrl.text = recipe.cookTime?.toString() ?? '';
        _servingsCtrl.text = recipe.servings?.toString() ?? '';
        _caloriesCtrl.text = recipe.calories?.toString() ?? '';
        _difficulty = recipe.difficultyLabel;
        _existingImageUrl = recipe.image;

        _selectedCategoryId = recipe.category?.id;

        for (var ing in recipe.ingredients) {
          _ingredients.add(
            IngredientInputRow(
              nameCtrl: TextEditingController(text: ing.name),
              amountCtrl: TextEditingController(text: ing.amount),
            ),
          );
        }

        // Sort instructions by step_number
        final sortedSteps = List<dynamic>.from(recipe.instructions)
          ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
        for (var step in sortedSteps) {
          _instructions.add(TextEditingController(text: step.description));
        }
      } else {
        // Add 1 initial row for ingredient and instruction if adding new
        _addIngredientRow();
        _addInstructionStep();
      }
    } catch (e) {
      _showSnackBar(
          'Gagal memuat detail resep: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true);
    } finally {
      setState(() => _isInitLoading = false);
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(
        IngredientInputRow(
          nameCtrl: TextEditingController(),
          amountCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredients.length <= 1) return;
    setState(() {
      final row = _ingredients.removeAt(index);
      row.nameCtrl.dispose();
      row.amountCtrl.dispose();
    });
  }

  void _addInstructionStep() {
    setState(() {
      _instructions.add(TextEditingController());
    });
  }

  void _removeInstructionStep(int index) {
    if (_instructions.length <= 1) return;
    setState(() {
      final ctrl = _instructions.removeAt(index);
      ctrl.dispose();
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (_) {
      _showSnackBar('Gagal mengambil gambar dari galeri.', isError: true);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnackBar('Pilih kategori resep.', isError: true);
      return;
    }
    if (!_isEditMode && _selectedImage == null) {
      _showSnackBar('Silakan pilih gambar resep.', isError: true);
      return;
    }

    // Extract ingredients Map
    final ingredientsList = _ingredients.map((ing) {
      return {
        'name': ing.nameCtrl.text.trim(),
        'amount': ing.amountCtrl.text.trim(),
      };
    }).toList();

    // Extract instructions List
    final instructionsList =
        _instructions.map((ctrl) => ctrl.text.trim()).toList();

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await RecipeService.updateRecipe(
          id: widget.recipeId!,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageFile: _selectedImage,
          cookTime: int.tryParse(_cookTimeCtrl.text.trim()),
          difficulty: _difficulty,
          servings: int.tryParse(_servingsCtrl.text.trim()),
          calories: int.tryParse(_caloriesCtrl.text.trim()),
          categoryId: _selectedCategoryId!,
          ingredients: ingredientsList,
          instructions: instructionsList,
        );
        _showSnackBar('Resep berhasil diperbarui!');
      } else {
        await RecipeService.createRecipe(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageFile: _selectedImage,
          cookTime: int.tryParse(_cookTimeCtrl.text.trim()),
          difficulty: _difficulty,
          servings: int.tryParse(_servingsCtrl.text.trim()),
          calories: int.tryParse(_caloriesCtrl.text.trim()),
          categoryId: _selectedCategoryId!,
          ingredients: ingredientsList,
          instructions: instructionsList,
        );
        _showSnackBar('Resep baru berhasil dipublikasikan!');
      }

      // Refresh home & my recipes lists
      if (mounted) {
        context.read<RecipeProvider>().loadRecipes();
        context.read<RecipeProvider>().loadMyRecipes();
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isInitLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditMode ? 'Edit Recipe' : 'New Recipe')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Recipe' : 'New Recipe'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.cardDark : AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.inputBorder,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : (_existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl:
                                    ApiConstants.imageUrl(_existingImageUrl),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded,
                                    size: 40, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload recipe photo',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              _buildLabel('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  hintText: 'e.g. Grandma\'s Apple Pie',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              _buildLabel('Description (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  hintText: 'Describe this recipe brief details...',
                ),
              ),
              const SizedBox(height: 16),

              // Category Chip Selector (SINGLE SELECT)
              _buildLabel('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text(
                      cat.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor:
                        isDark ? AppColors.cardDark : AppColors.backgroundWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.dividerDark
                                : AppColors.inputBorder),
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? cat.id : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Specific Stats Row (Cook Time, Servings, Calories)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Cook Time (min)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cookTimeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration:
                              const InputDecoration(hintText: 'e.g. 45'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Servings'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _servingsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: const InputDecoration(hintText: 'e.g. 4'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Calories (kcal)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _caloriesCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration:
                              const InputDecoration(hintText: 'e.g. 350'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Difficulty'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _difficulty,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                          iconEnabledColor: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                          ),
                          dropdownColor: isDark
                              ? AppColors.cardDark
                              : AppColors.backgroundWhite,
                          items: ['Easy', 'Medium', 'Hard'].map((diff) {
                            return DropdownMenuItem<String>(
                              value: diff,
                              child: Text(
                                diff,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _difficulty = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dynamic Ingredients
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Ingredients'),
                  TextButton.icon(
                    onPressed: _addIngredientRow,
                    icon:
                        const Icon(Icons.add_rounded, color: AppColors.primary),
                    label: const Text('Add Item',
                        style: TextStyle(
                            fontFamily: 'Poppins', color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final row = _ingredients[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: row.nameCtrl,
                            style: const TextStyle(fontFamily: 'Poppins'),
                            decoration: const InputDecoration(
                              hintText: 'Ingredient name',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: row.amountCtrl,
                            style: const TextStyle(fontFamily: 'Poppins'),
                            decoration: const InputDecoration(
                              hintText: 'Amount (e.g. 2 cups)',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_ingredients.length > 1)
                          IconButton(
                            icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: AppColors.error),
                            onPressed: () => _removeIngredientRow(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Dynamic Instructions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Instructions'),
                  TextButton.icon(
                    onPressed: _addInstructionStep,
                    icon:
                        const Icon(Icons.add_rounded, color: AppColors.primary),
                    label: const Text('Add Step',
                        style: TextStyle(
                            fontFamily: 'Poppins', color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _instructions.length,
                itemBuilder: (context, index) {
                  final ctrl = _instructions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: ctrl,
                            maxLines: 2,
                            style: const TextStyle(fontFamily: 'Poppins'),
                            decoration: const InputDecoration(
                              hintText: 'Describe this cooking step...',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_instructions.length > 1)
                          IconButton(
                            icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: AppColors.error),
                            onPressed: () => _removeInstructionStep(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Bottom Publish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditMode ? 'Save Changes' : 'Publish Recipe',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class IngredientInputRow {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;

  IngredientInputRow({required this.nameCtrl, required this.amountCtrl});
}
