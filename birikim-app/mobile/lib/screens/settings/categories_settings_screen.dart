import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/api_client.dart';

class CategoriesSettingsScreen extends StatefulWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  State<CategoriesSettingsScreen> createState() => _CategoriesSettingsScreenState();
}

class _CategoriesSettingsScreenState extends State<CategoriesSettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  Color _getColorForMultiplier(String multiplier) {
    double val = double.tryParse(multiplier) ?? 1.0;
    if (val <= 1.0) return Colors.green;
    if (val <= 1.5) return Colors.orange;
    if (val <= 2.0) return Colors.red;
    return Colors.purple;
  }

  // Available penalty multipliers
  final List<Map<String, dynamic>> _multiplierOptions = [
    {'label': 'Normal (1x)', 'value': '1.00'},
    {'label': 'Orta (1.5x)', 'value': '1.50'},
    {'label': 'Yüksek (2x)', 'value': '2.00'},
    {'label': 'Çok Yüksek (3x)', 'value': '3.00'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _apiClient.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sistem kategorilerini silemezsiniz!')),
      );
      return;
    }

    try {
      await _apiClient.deleteCategory(category.id);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori silindi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showCategoryDialog([Category? category]) {
    final bool isEditing = category != null;

    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedMultiplier = category?.penaltyMultiplier ?? '1.00';
    bool isGuiltyPleasure = category?.isGuiltyPleasure ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Kategori Adı'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Ceza Oranı (Tax)'),
                      value: _multiplierOptions.any((o) => o['value'] == selectedMultiplier) 
                          ? selectedMultiplier 
                          : '1.00',
                      items: _multiplierOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'] as String,
                          child: Text(option['label'] as String),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedMultiplier = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Bu bir zaaf kategorisi mi?'),
                      subtitle: const Text('Bu kategoride harcama yapmak kendime vergi (ceza) kessin.'),
                      value: isGuiltyPleasure,
                      onChanged: (val) {
                        setStateDialog(() {
                          isGuiltyPleasure = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    try {
                      if (isEditing) {
                        await _apiClient.updateCategory(
                          category.id,
                          CategoryUpdate(
                            name: nameController.text.trim(),
                            isGuiltyPleasure: isGuiltyPleasure,
                            penaltyMultiplier: selectedMultiplier,
                          ),
                        );
                      } else {
                        await _apiClient.createCategory(
                          CategoryCreate(
                            name: nameController.text.trim(),
                            isGuiltyPleasure: isGuiltyPleasure,
                            penaltyMultiplier: selectedMultiplier,
                          ),
                        );
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadCategories();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
            tooltip: 'Yeni Kategori Ekle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final bool isCustom = cat.userId != null;
                    final Color catColor = _getColorForMultiplier(cat.penaltyMultiplier);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: catColor.withOpacity(0.2),
                        child: Icon(
                          cat.penaltyMultiplier != '1.00' ? Icons.warning_amber_rounded : Icons.category,
                          color: catColor,
                        ),
                      ),
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ceza Çarpanı: ${cat.penaltyMultiplier}x'),
                          if (!isCustom)
                            Text('Sistem Kategorisi', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showCategoryDialog(cat),
                          ),
                          if (isCustom)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(cat),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
