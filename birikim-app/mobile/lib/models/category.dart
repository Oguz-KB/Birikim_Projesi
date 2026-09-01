class Category {
  final String id;
  final String? userId;
  final String name;
  final bool isGuiltyPleasure;
  final String penaltyMultiplier;

  Category({
    required this.id,
    this.userId,
    required this.name,
    required this.isGuiltyPleasure,
    required this.penaltyMultiplier,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      name: json['name'].toString(),
      isGuiltyPleasure: json['is_guilty_pleasure'] == true || json['is_guilty_pleasure'] == 1,
      penaltyMultiplier: json['penalty_multiplier'].toString(),
    );
  }
}

class CategoryCreate {
  final String name;
  final bool isGuiltyPleasure;
  final String penaltyMultiplier;

  CategoryCreate({
    required this.name,
    this.isGuiltyPleasure = false,
    this.penaltyMultiplier = '1.00',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_guilty_pleasure': isGuiltyPleasure,
      'penalty_multiplier': penaltyMultiplier,
    };
  }
}

class CategoryUpdate {
  final String? name;
  final bool? isGuiltyPleasure;
  final String? penaltyMultiplier;

  CategoryUpdate({
    this.name,
    this.isGuiltyPleasure,
    this.penaltyMultiplier,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (isGuiltyPleasure != null) data['is_guilty_pleasure'] = isGuiltyPleasure;
    if (penaltyMultiplier != null) data['penalty_multiplier'] = penaltyMultiplier;
    return data;
  }
}
