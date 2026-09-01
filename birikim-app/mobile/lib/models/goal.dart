class GoalOut {
  final String id;
  final String name;
  final double targetAmount;
  final String createdAt;

  GoalOut({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
  });

  factory GoalOut.fromJson(Map<String, dynamic> json) {
    return GoalOut(
      id: json['id'],
      name: json['name'],
      targetAmount: double.tryParse(json['target_amount'].toString()) ?? 0.0,
      createdAt: json['created_at'],
    );
  }
}

class GoalCreate {
  final String name;
  final double targetAmount;

  GoalCreate({
    required this.name,
    required this.targetAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target_amount': targetAmount,
    };
  }
}
