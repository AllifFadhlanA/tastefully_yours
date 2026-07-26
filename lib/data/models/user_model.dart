class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? createdAt;
  final int? recipesCount;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.createdAt,
    this.recipesCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      createdAt: json['created_at'] as String?,
      recipesCount: json['recipes_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }

  String get memberSinceYear {
    if (createdAt == null) return '';
    return DateTime.parse(createdAt!).year.toString();
  }
}
