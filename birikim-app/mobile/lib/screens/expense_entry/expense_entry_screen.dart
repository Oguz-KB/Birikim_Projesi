import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/pending_purchase.dart';
import '../../services/api_client.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  String _amountString = "";

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _apiClient.getCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  void _appendAmount(String val) {
    setState(() {
      if (_amountString == "0" && val != ".") {
         _amountString = val;
      } else {
        _amountString += val;
      }
    });
  }

  void _saveExpense() async {
    if (_selectedCategory == null || _amountString.isEmpty) return;
    
    final tx = TransactionCreate(
      categoryId: _selectedCategory!.id,
      rawAmount: _amountString,
    );

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    navigator.pop(); // Pop immediately for fast feeling

    final result = await _apiClient.createTransaction(tx);

    if (result is PendingPurchaseOut) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bu harcama 24 saat bekleme odasında! Vazgeçersen birikime eklenecek.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (result is TransactionOut) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Harcama kaydedildi (Kurallar işlendi)'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result is Map && result['status'] == 'queued') {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Bağlantı yok. Harcama sıraya alındı (Offline)'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hızlı Harcama Gir')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedCategory == null) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('1. Kategori Seç', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cat.isGuiltyPleasure ? Colors.red.shade100 : Colors.blue.shade100,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Text(cat.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black)),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Seçilen: ${_selectedCategory!.name}', style: const TextStyle(fontSize: 20)),
                  ),
                  Text(
                    '₺ $_amountString',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (var i = 1; i <= 9; i++)
                          TextButton(onPressed: () => _appendAmount(i.toString()), child: Text('$i', style: const TextStyle(fontSize: 24))),
                        TextButton(onPressed: () => _appendAmount('.'), child: const Text('.', style: TextStyle(fontSize: 24))),
                        TextButton(onPressed: () => _appendAmount('0'), child: const Text('0', style: TextStyle(fontSize: 24))),
                        TextButton(
                          onPressed: () {
                            if (_amountString.isNotEmpty) {
                              setState(() {
                                _amountString = _amountString.substring(0, _amountString.length - 1);
                              });
                            }
                          },
                          child: const Icon(Icons.backspace),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _saveExpense,
                        child: const Text('KAYDET', style: TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                    ),
                  )
                ]
              ],
            ),
    );
  }
}
