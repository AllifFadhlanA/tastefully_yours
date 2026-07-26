class IngredientModel {
  final int id;
  final int recipeId;
  final String name;
  final String amount;

  const IngredientModel({
    required this.id,
    required this.recipeId,
    required this.name,
    required this.amount,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'] as int,
      recipeId: json['recipe_id'] as int,
      name: json['name'] as String,
      amount: json['amount'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipe_id': recipeId,
        'name': name,
        'amount': amount,
      };
}
