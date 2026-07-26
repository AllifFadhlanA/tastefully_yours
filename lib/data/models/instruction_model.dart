class InstructionModel {
  final int id;
  final int recipeId;
  final int stepNumber;
  final String description;

  const InstructionModel({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.description,
  });

  factory InstructionModel.fromJson(Map<String, dynamic> json) {
    return InstructionModel(
      id: json['id'] as int,
      recipeId: json['recipe_id'] as int,
      stepNumber: json['step_number'] as int,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipe_id': recipeId,
        'step_number': stepNumber,
        'description': description,
      };
}
