class PendingPurchaseOut {
  final String id;
  final String userId;
  final String categoryId;
  final String amount;
  final String createdAt;
  final String expiresAt;
  final String resolution;
  final String? resolvedAt;
  final String? resultingTransactionId;

  PendingPurchaseOut({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.createdAt,
    required this.expiresAt,
    required this.resolution,
    this.resolvedAt,
    this.resultingTransactionId,
  });

  factory PendingPurchaseOut.fromJson(Map<String, dynamic> json) {
    return PendingPurchaseOut(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: json['amount'].toString(),
      createdAt: json['created_at'],
      expiresAt: json['expires_at'],
      resolution: json['resolution'],
      resolvedAt: json['resolved_at'],
      resultingTransactionId: json['resulting_transaction_id'],
    );
  }
}
