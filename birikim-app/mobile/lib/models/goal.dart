class GoalOut {
  final String id;
  final String name;
  final double targetAmount;
  final String? imageUrl;
  final bool isCompleted;
  final String createdAt;

  GoalOut({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.imageUrl,
    required this.isCompleted,
    required this.createdAt,
  });

  factory GoalOut.fromJson(Map<String, dynamic> json) {
    return GoalOut(
      id: json['id'],
      name: json['name'],
      targetAmount: double.tryParse(json['target_amount'].toString()) ?? 0.0,
      imageUrl: json['image_url'],
      isCompleted: json['is_completed'] ?? false,
      createdAt: json['created_at'],
    );
  }
}

class GoalCreate {
  final String name;
  final double targetAmount;
  final String? imageUrl;

  GoalCreate({
    required this.name,
    required this.targetAmount,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target_amount': targetAmount,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class GoalUpdate {
  final String? name;
  final double? targetAmount;
  final String? imageUrl;
  final bool? isCompleted;

  GoalUpdate({
    this.name,
    this.targetAmount,
    this.imageUrl,
    this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (targetAmount != null) data['target_amount'] = targetAmount;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (isCompleted != null) data['is_completed'] = isCompleted;
    return data;
  }
}
