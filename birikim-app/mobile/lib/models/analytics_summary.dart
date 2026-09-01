class CategoryTax {
  final String categoryName;
  final double totalTaxPaid;

  CategoryTax({
    required this.categoryName,
    required this.totalTaxPaid,
  });

  factory CategoryTax.fromJson(Map<String, dynamic> json) {
    return CategoryTax(
      categoryName: json['category_name'].toString(),
      totalTaxPaid: (json['total_tax_paid'] as num).toDouble(),
    );
  }
}

class AnalyticsSummary {
  final int daysActive;
  final double totalSavings;
  final double dailyAverage;
  final String projectionText;
  final List<CategoryTax> categoryBreakdown;

  AnalyticsSummary({
    required this.daysActive,
    required this.totalSavings,
    required this.dailyAverage,
    required this.projectionText,
    required this.categoryBreakdown,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    var breakdownList = json['category_breakdown'] as List;
    List<CategoryTax> breakdown = breakdownList.map((i) => CategoryTax.fromJson(i)).toList();

    return AnalyticsSummary(
      daysActive: json['days_active'] as int,
      totalSavings: (json['total_savings'] as num).toDouble(),
      dailyAverage: (json['daily_average'] as num).toDouble(),
      projectionText: json['projection_text'].toString(),
      categoryBreakdown: breakdown,
    );
  }
}
