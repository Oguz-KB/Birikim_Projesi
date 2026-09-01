import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/expense_entry/expense_entry_screen.dart';
import 'services/api_client.dart';
import 'models/transaction.dart';
import 'models/pending_purchase.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
    
    if (mounted) {
      setState(() {
        _transactions = txs.reversed.toList(); // Newest first
        _pendingPurchases = pendings.reversed.toList();
        _isLoading = false;
      });
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

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Henüz kaydedilmiş harcama yok.'));
    }
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text('Harcama: ${tx.rawAmount} TL'),
            subtitle: Text('Ceza/Vergi: ${tx.selfTaxAmount} TL\nBirikim: ${tx.totalDiverted} TL'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildPendingList() {
    if (_pendingPurchases.isEmpty) {
      return const Center(child: Text('Bekleme odası boş.'));
    }
    return ListView.builder(
      itemCount: _pendingPurchases.length,
      itemBuilder: (context, index) {
        final pending = _pendingPurchases[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.hourglass_bottom, color: Colors.white),
            ),
            title: Text('Bekleyen Harcama: ${pending.amount} TL'),
            subtitle: Text('Durum: ${pending.resolution}\nTarih: ${pending.createdAt.substring(0, 10)}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Birikim Ana Ekran'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
              Tab(icon: Icon(Icons.hourglass_empty), text: 'Bekleme Odası'),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildTransactionsList(),
                  _buildPendingList(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openExpenseEntry,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
