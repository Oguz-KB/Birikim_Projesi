class TransactionCreate {
  final String categoryId;
  final String rawAmount;

  TransactionCreate({required this.categoryId, required this.rawAmount});

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'raw_amount': rawAmount,
  };
}

class TransactionOut {
  final String id;
  final String userId;
  final String categoryId;
  final String rawAmount;
  final String selfTaxAmount;
  final String roundupAmount;
  final String totalDiverted;
  final String ruleSettingsId;
  final String? goalId;
  final String? reversalOf;
  final String createdAt;

  TransactionOut({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.rawAmount,
    required this.selfTaxAmount,
    required this.roundupAmount,
    required this.totalDiverted,
    required this.ruleSettingsId,
    this.goalId,
    this.reversalOf,
    required this.createdAt,
  });

  factory TransactionOut.fromJson(Map<String, dynamic> json) {
    return TransactionOut(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      rawAmount: json['raw_amount'].toString(),
      selfTaxAmount: json['self_tax_amount'].toString(),
      roundupAmount: json['roundup_amount'].toString(),
      totalDiverted: json['total_diverted'].toString(),
      ruleSettingsId: json['rule_settings_id'],
      goalId: json['goal_id'],
      reversalOf: json['reversal_of'],
      createdAt: json['created_at'],
    );
  }
}
