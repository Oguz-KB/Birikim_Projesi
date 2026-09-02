class Badge {
  final String id;
  final String name;
  final String tier;
  final double target;
  final bool isEarned;
  final double progress;

  Badge({
    required this.id,
    required this.name,
    required this.tier,
    required this.target,
    required this.isEarned,
    required this.progress,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      tier: json['tier'],
      target: (json['target'] as num).toDouble(),
      isEarned: json['is_earned'],
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

class BadgeCategory {
  final String id;
  final String name;
  final String description;
  final double currentValue;
  final String unit;
  final List<Badge> badges;

  BadgeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.currentValue,
    required this.unit,
    required this.badges,
  });

  factory BadgeCategory.fromJson(Map<String, dynamic> json) {
    return BadgeCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      currentValue: (json['current_value'] as num).toDouble(),
      unit: json['unit'],
      badges: (json['badges'] as List).map((b) => Badge.fromJson(b)).toList(),
    );
  }
}
