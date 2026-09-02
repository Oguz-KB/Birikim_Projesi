import 'package:flutter/material.dart' hide Badge;
import '../../models/badge.dart';
import '../../services/api_client.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final ApiClient _apiClient = ApiClient();
  List<BadgeCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final cats = await _apiClient.getBadges();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Color _getColorForTier(String tier) {
    switch (tier) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey.shade400;
      case 'bronze':
        return Colors.brown.shade400;
      default:
        return Colors.blue;
    }
  }

  Widget _buildBadgeCard(Badge badge, double currentValue, String unit) {
    final bool isEarned = badge.isEarned;
    final Color badgeColor = isEarned ? _getColorForTier(badge.tier) : Colors.grey.shade800;
    
    return Card(
      elevation: isEarned ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isEarned ? badgeColor.withOpacity(0.5) : Colors.transparent, width: 2),
      ),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEarned ? Icons.workspace_premium : Icons.lock_outline,
              size: 48,
              color: badgeColor,
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isEarned ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${badge.target.toStringAsFixed(0)} $unit',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            if (!isEarned) ...[
              LinearProgressIndicator(
                value: badge.progress,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blue,
              ),
              const SizedBox(height: 4),
              Text(
                '${currentValue.toStringAsFixed(0)} / ${badge.target.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozetler & Başarılar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBadges,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          cat.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          cat.description,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          itemCount: cat.badges.length,
                          itemBuilder: (context, bIndex) {
                            final badge = cat.badges[bIndex];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildBadgeCard(badge, cat.currentValue, cat.unit),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
