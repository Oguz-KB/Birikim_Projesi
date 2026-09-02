import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../models/rule_settings.dart';
import '../../main.dart';
import 'categories_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _taxRateCtrl;
  late TextEditingController _thresholdCtrl;
  late TextEditingController _hoursCtrl;
  
  bool _roundupEnabled = false;
  double _selectedRoundupUnit = 10.0;
  final List<double> _roundupOptions = [10.0, 50.0, 100.0];
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _taxRateCtrl = TextEditingController();
    _thresholdCtrl = TextEditingController();
    _hoursCtrl = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _apiClient.getUserSettings();
      final prefs = await SharedPreferences.getInstance();
      final themeMode = prefs.getString('themeMode') ?? 'system';

      if (mounted) {
        setState(() {
          _taxRateCtrl.text = (settings.selfTaxRate * 100).toStringAsFixed(0);
          _thresholdCtrl.text = settings.waitingRoomThreshold.toStringAsFixed(0);
          _hoursCtrl.text = settings.waitingRoomHours.toString();
          
          _selectedRoundupUnit = settings.roundupUnit;
          if (!_roundupOptions.contains(_selectedRoundupUnit)) {
            _selectedRoundupUnit = 10.0;
          }
          _roundupEnabled = settings.roundupEnabled;
          _selectedTheme = themeMode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayarlar yüklenemedi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      final update = UserRuleSettingsUpdate(
        selfTaxRate: double.parse(_taxRateCtrl.text) / 100,
        waitingRoomThreshold: double.parse(_thresholdCtrl.text),
        waitingRoomHours: int.parse(_hoursCtrl.text),
        roundupUnit: _selectedRoundupUnit,
        roundupEnabled: _roundupEnabled,
      );

      await _apiClient.updateUserSettings(update);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar başarıyla kaydedildi! ⚙️'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilirken hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _taxRateCtrl.dispose();
    _thresholdCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title, Color color, String infoText) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.info_outline, color: color, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(title, style: TextStyle(color: color)),
                content: Text(infoText),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anladım'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuralları Kişiselleştir'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedTheme,
                      decoration: const InputDecoration(
                        labelText: 'Görünüm Teması',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.brightness_6),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('Sistem Varsayılanı')),
                        DropdownMenuItem(value: 'light', child: Text('Açık Tema')),
                        DropdownMenuItem(value: 'dark', child: Text('Koyu Tema')),
                      ],
                      onChanged: (val) async {
                        if (val != null) {
                          setState(() => _selectedTheme = val);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('themeMode', val);
                          if (val == 'light') themeNotifier.value = ThemeMode.light;
                          if (val == 'dark') themeNotifier.value = ThemeMode.dark;
                          if (val == 'system') themeNotifier.value = ThemeMode.system;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.category, color: Colors.blue),
                        ),
                        title: const Text('Kategorileri ve Zaafları Yönet'),
                        subtitle: const Text('Kendi harcama kategorilerini ve ceza çarpanlarını belirle.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CategoriesSettingsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Ceza ve Birikim Oranları', 
                      Colors.green,
                      'Bu oran, yaptığın harcamalarda veya bekleme odasından almayı seçtiğin ürünlerde sana ne kadar ceza (kendine vergi) kesileceğini belirler. Örneğin %10 seçersen, 100 TL harcadığında 10 TL kumbarana gider.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxRateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ceza Oranı Yüzdesi (%)',
                        hintText: 'Örn: 10',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Bu alan boş bırakılamaz';
                        if (double.tryParse(value) == null) return 'Geçerli bir sayı girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Bekleme Odası Kuralları', 
                      Colors.orange,
                      'Pahalı harcamaları anında yapmak yerine bir süre ertelemek iradeni güçlendirir. Belirlediğin limitin (Örn: 200 TL) üzerindeki her harcama, belirlediğin saat (Örn: 24) boyunca bekleme odasına alınır. Bu süre sonunda vazgeçersen paran kurtulur!',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _thresholdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bekleme Odası Limiti (TL)',
                        hintText: 'Örn: 200',
                        border: OutlineInputBorder(),
                        suffixText: 'TL',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hoursCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bekleme Süresi (Saat)',
                        hintText: 'Örn: 24',
                        border: OutlineInputBorder(),
                        suffixText: 'Saat',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Yuvarlama (Round-up) Ayarları', 
                      Colors.blue,
                      'Harcamalarının küsüratlarını belirlediğin birime (10, 50 veya 100 TL) tamamlar. Örneğin 10 TL katlarına yuvarlamayı seçersen, 43 TL harcadığında kartından 50 TL çekilmiş gibi sayılır ve aradaki 7 TL doğrudan birikimine aktarılır.',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Küsüratları Yuvarla'),
                      subtitle: const Text('Fazlalığı birikime atar.'),
                      value: _roundupEnabled,
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool value) {
                        setState(() => _roundupEnabled = value);
                      },
                    ),
                    if (_roundupEnabled) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<double>(
                        value: _selectedRoundupUnit,
                        decoration: const InputDecoration(
                          labelText: 'Yuvarlama Birimi (TL)',
                          border: OutlineInputBorder(),
                        ),
                        items: _roundupOptions.map((double value) {
                          return DropdownMenuItem<double>(
                            value: value,
                            child: Text('${value.toStringAsFixed(0)} TL ve katlarına yuvarla'),
                          );
                        }).toList(),
                        onChanged: (double? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedRoundupUnit = newValue);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : _saveSettings,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Ayarları Kaydet', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Tehlikeli Alan', 
                      Colors.red,
                      'Bu işlem tüm harcama geçmişini ve birikimlerini kalıcı olarak siler!',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Tüm Verileri Sıfırla?'),
                              content: const Text('Geçmişteki tüm harcamaların, birikimlerin ve bekleme odandaki ürünler silinecek. Bu işlem geri alınamaz! Emin misin?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    setState(() => _isSaving = true);
                                    try {
                                      await _apiClient.resetUserData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm veriler sıfırlandı!')));
                                        Navigator.pop(context); // Go back to Home
                                      }
                                    } catch (e) {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                                    } finally {
                                      if (mounted) setState(() => _isSaving = false);
                                    }
                                  },
                                  child: const Text('Evet, Her Şeyi Sil'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Uygulamayı Sıfırla (Reset)'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
