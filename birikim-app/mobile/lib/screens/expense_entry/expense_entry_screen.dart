import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/pending_purchase.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';

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

  Color _getColorForMultiplier(String multiplier) {
    double val = double.tryParse(multiplier) ?? 1.0;
    if (val <= 1.0) return Colors.green;
    if (val <= 1.5) return Colors.orange;
    if (val <= 2.0) return Colors.red;
    return Colors.purple;
  }

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
      // Bildirimi kur
      NotificationService().scheduleWaitingRoomExpiry(
        result.id.hashCode,
        _selectedCategory!.name,
        DateTime.parse(result.expiresAt),
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bu harcama bekleme odasında! Vazgeçersen birikime eklenecek.'),
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<Category>(
                    decoration: const InputDecoration(
                      labelText: 'Kategori Seç',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    hint: const Text('Lütfen bir kategori seçin'),
                    items: _categories.map((cat) {
                      final bool isCustom = cat.userId != null;
                      final Color catColor = _getColorForMultiplier(cat.penaltyMultiplier);
                      
                      return DropdownMenuItem<Category>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              cat.penaltyMultiplier != '1.00' ? Icons.warning_amber_rounded : Icons.category,
                              color: catColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(cat.name + (isCustom ? ' (Özel)' : '')),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                ),
                Text(
                  '₺ ${_amountString.isEmpty ? "0" : _amountString}',
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_selectedCategory == null || _amountString.isEmpty) 
                            ? Colors.grey 
                            : Colors.green,
                      ),
                      onPressed: (_selectedCategory == null || _amountString.isEmpty) ? null : _saveExpense,
                      child: const Text('KAYDET', style: TextStyle(fontSize: 24, color: Colors.white)),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
