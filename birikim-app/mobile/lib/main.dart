import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/expense_entry/expense_entry_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/waiting_room/waiting_room_screen.dart';
import 'services/api_client.dart';
import 'models/transaction.dart';
import 'models/pending_purchase.dart';
import 'models/goal.dart';
import 'models/analytics_summary.dart';
import 'screens/analytics/analytics_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BirikimApp());
}

class BirikimApp extends StatelessWidget {
  const BirikimApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birikim',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  List<TransactionOut> _transactions = [];
  List<PendingPurchaseOut> _pendingPurchases = [];
  GoalOut? _activeGoal;
  AnalyticsSummary? _analyticsSummary;
  double _totalSavings = 0.0;
  bool _isLoading = true;
  int _currentIndex = 0;

  final List<String> _tips = [
    "💡 Dışarıda kahve içmek yerine evde hazırlayarak ayda ortalama 1.500 TL biriktirebileceğini biliyor muydun?",
    "💡 Bekleme odası kuralları, plansız harcamaların %40'ını engeller.",
    "💡 Küsüratları yuvarlayarak hiç fark etmeden büyük birikimler yapabilirsin.",
    "💡 Hedefine ulaştığını hayal et, motivasyonun düşmesine izin verme!"
  ];
  late String _currentTip;

  @override
  void initState() {
    super.initState();
    _currentTip = _tips[Random().nextInt(_tips.length)];
    _apiClient.syncQueue().then((_) => _loadData());
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        _apiClient.syncQueue().then((_) => _loadData());
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final txs = await _apiClient.getTransactions();
    final pendings = await _apiClient.getPendingPurchases();
    final goals = await _apiClient.getGoals();
    
    double calculatedSavings = 0.0;
    for (var tx in txs) {
      calculatedSavings += double.tryParse(tx.totalDiverted) ?? 0.0;
    }

    if (mounted) {
      setState(() {
        _transactions = txs.reversed.toList(); // Newest first
        _pendingPurchases = pendings.reversed.toList();
        _activeGoal = goals.isNotEmpty ? goals.first : null;
        _totalSavings = calculatedSavings;
        _isLoading = false;
      });

      try {
        final summary = await _apiClient.getAnalyticsSummary();
        if (mounted) {
          setState(() {
            _analyticsSummary = summary;
          });
        }
      } catch (e) {
        // Ignore analytics fetch error
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _openExpenseEntry() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
    );
    // Refresh after coming back
    _loadData();
  }

  // History moved to HistoryScreen
  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HistoryScreen(transactions: _transactions)),
    );
  }

  Future<void> _resolvePending(String id, String decision) async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.resolvePendingPurchase(id, decision);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decision == 'purchased' ? 'Karar: Dayanamadım, Aldım (Ceza İşlendi)' : 'Tebrikler! Vazgeçtin, paran birikimde kaldı! 🚀'),
            backgroundColor: decision == 'purchased' ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openWaitingRoom() async {
    final shouldRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaitingRoomScreen(
          pendingPurchases: _pendingPurchases,
          onResolve: _resolvePending,
        ),
      ),
    );
    if (shouldRefresh == true) {
      _loadData();
    }
  }

  Widget _buildRecordsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRecordCard(
            title: 'Geçmiş Harcamalar',
            subtitle: 'Tüm harcamalarını ve kesilen cezaları gör.',
            icon: Icons.history,
            color: Colors.blue,
            onTap: _openHistory,
          ),
          const SizedBox(height: 16),
          _buildRecordCard(
            title: 'Bekleme Odası',
            subtitle: 'Ertelenen büyük harcamaların burada.',
            icon: Icons.hourglass_empty,
            color: Colors.orange,
            onTap: _openWaitingRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 30, child: Icon(icon, color: color, size: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog({GoalOut? existingGoal}) {
    final nameCtrl = TextEditingController(text: existingGoal?.name ?? '');
    final amountCtrl = TextEditingController(text: existingGoal?.targetAmount.toStringAsFixed(0) ?? '');
    final imageCtrl = TextEditingController(text: existingGoal?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingGoal == null ? 'Yeni Bir Hedef Belirle 🎯' : 'Hedefi Düzenle 🎯'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Ne için biriktiriyorsun? (Örn: PS5)'),
                      validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Hedef Tutar (TL)', suffixText: 'TL'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(labelText: 'Hedef Görseli (URL) - İsteğe Bağlı'),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);
                      try {
                        if (existingGoal == null) {
                          await _apiClient.createGoal(GoalCreate(
                            name: nameCtrl.text,
                            targetAmount: double.parse(amountCtrl.text),
                            imageUrl: imageCtrl.text.isNotEmpty ? imageCtrl.text : null,
                          ));
                        } else {
                          await _apiClient.updateGoal(existingGoal.id, GoalUpdate(
                            name: nameCtrl.text,
                            targetAmount: double.parse(amountCtrl.text),
                            imageUrl: imageCtrl.text.isNotEmpty ? imageCtrl.text : null,
                          ));
                        }
                        if (mounted) Navigator.pop(context);
                        _loadData();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    }
                  },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleGoalAction(String action) async {
    if (_activeGoal == null) return;
    
    if (action == 'edit') {
      _showGoalDialog(existingGoal: _activeGoal);
    } else if (action == 'delete') {
      await _apiClient.deleteGoal(_activeGoal!.id);
      _loadData();
    } else if (action == 'purchase') {
      if (_totalSavings >= _activeGoal!.targetAmount) {
        // Buy goal
        setState(() => _isLoading = true);
        try {
          await _apiClient.withdrawSavings(_activeGoal!.targetAmount, goalId: _activeGoal!.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tebrikler! Hedefine ulaştın ve satın aldın! 🎉'), backgroundColor: Colors.green));
          }
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu hedefi almak için henüz yeterli birikimin yok! 😢')));
      }
    }
  }

  Widget _buildGamificationSection() {
    if (_activeGoal == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.purple, size: 36),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Birikimlerini Taçlandır!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                  Text('Kendine bir hedef belirle ve motive ol.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showGoalDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              child: const Text('Hedef Koy'),
            ),
          ],
        ),
      );
    }

    final double progress = (_totalSavings / _activeGoal!.targetAmount).clamp(0.0, 1.0);
    
    String estimationText = _analyticsSummary?.projectionText ?? '';
    
    if (progress >= 1.0) {
      estimationText = '🎉 Tebrikler! Hedefine ulaştın! Menüden hedefini satın alabilirsin.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeGoal!.imageUrl != null && _activeGoal!.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                _activeGoal!.imageUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 40,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Hedefim: ${_activeGoal!.name} 🎯', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Text('%${(progress * 100).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                    PopupMenuButton<String>(
                      onSelected: _handleGoalAction,
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                          if (progress >= 1.0)
                            const PopupMenuItem(value: 'purchase', child: Text('Satın Aldım! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              color: progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_totalSavings.toStringAsFixed(0)} TL', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text('${_activeGoal!.targetAmount.toStringAsFixed(0)} TL', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          if (estimationText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                estimationText,
                style: TextStyle(color: Colors.blue.shade900, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Birikimden Para Çek 💸'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Topladığın birikimlerden harcamak istediğin tutarı gir. Bu işlem toplam birikimini düşürecektir.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Çekilecek Tutar (TL)', suffixText: 'TL'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Boş bırakılamaz';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Geçerli bir tutar girin';
                        if (val > _totalSavings) return 'Yetersiz bakiye';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);
                      try {
                        await _apiClient.withdrawSavings(double.parse(amountCtrl.text));
                        if (mounted) Navigator.pop(context);
                        _loadData();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                      }
                    }
                  },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Onayla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSavingsDashboard() {
    return InkWell(
      onTap: _showWithdrawDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Toplam Birikim',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalSavings.toStringAsFixed(2)} TL',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Kuralların seni zenginleştiriyor! 🚀',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentTip.substring(2).trim(), // Strip the bulb emoji as we have one outside
              style: TextStyle(color: Colors.amber.shade900, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSavingsDashboard(),
          _buildTipsSection(),
          _buildGamificationSection(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 1 ? null : AppBar(
        title: Text(_currentIndex == 0 ? 'Ana Ekran' : 'Kayıtlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _currentIndex == 0 
              ? _buildHomeTab() 
              : _currentIndex == 1
                  ? (_analyticsSummary != null ? AnalyticsScreen(summary: _analyticsSummary!) : const Center(child: CircularProgressIndicator()))
                  : _buildRecordsTab(),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _openExpenseEntry,
        child: const Icon(Icons.add),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Ekran'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'İstatistik'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Kayıtlar'),
        ],
      ),
    );
  }
}
