class Category {
  final String id;
  final String name;
  final bool isGuiltyPleasure;
  final String penaltyMultiplier;

  Category({
    required this.id,
    required this.name,
    required this.isGuiltyPleasure,
    required this.penaltyMultiplier,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'].toString(),
      isGuiltyPleasure: json['is_guilty_pleasure'] == true || json['is_guilty_pleasure'] == 1,
      penaltyMultiplier: json['penalty_multiplier'].toString(),
    );
  }
}
