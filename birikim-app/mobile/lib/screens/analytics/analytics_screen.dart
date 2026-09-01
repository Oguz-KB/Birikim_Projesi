import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/analytics_summary.dart';

class AnalyticsScreen extends StatelessWidget {
  final AnalyticsSummary summary;

  const AnalyticsScreen({Key? key, required this.summary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistik ve Analiz'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(context),
            const SizedBox(height: 24),
            const Text(
              'Zaafların (Hangi kategoriye ne kadar ceza ödedin?)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (summary.categoryBreakdown.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Henüz hiç ceza ödememişsin! Harika irade! 🎉', textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontSize: 16)),
                ),
              )
            else
              _buildPieChart(),
            const SizedBox(height: 24),
            if (summary.categoryBreakdown.isNotEmpty)
              _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            'Günlük Ortalama Birikim',
            '₺ ${summary.dailyAverage.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            'Uygulama Kullanım Süresi',
            '${summary.daysActive} Gün',
            Icons.access_time,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  static final List<Color> _chartColors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
  ];

  Widget _buildPieChart() {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: summary.categoryBreakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final isLarge = cat.totalTaxPaid > (summary.totalSavings * 0.1);
            
            return PieChartSectionData(
              color: _chartColors[index % _chartColors.length],
              value: cat.totalTaxPaid,
              title: '₺${cat.totalTaxPaid.toStringAsFixed(0)}',
              showTitle: false, // Hide titles to prevent overlap, legend shows values
              radius: isLarge ? 60 : 50,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: summary.categoryBreakdown.asMap().entries.map((entry) {
        final index = entry.key;
        final cat = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _chartColors[index % _chartColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('${cat.categoryName} (₺${cat.totalTaxPaid.toStringAsFixed(0)})', style: const TextStyle(fontSize: 14)),
          ],
        );
      }).toList(),
    );
  }
}
