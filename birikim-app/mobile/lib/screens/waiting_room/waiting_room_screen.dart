import 'package:flutter/material.dart';
import '../../models/pending_purchase.dart';

class WaitingRoomScreen extends StatefulWidget {
  final List<PendingPurchaseOut> pendingPurchases;
  final Future<void> Function(String, String) onResolve;

  const WaitingRoomScreen({
    Key? key,
    required this.pendingPurchases,
    required this.onResolve,
  }) : super(key: key);

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool _isProcessing = false;

  Future<void> _handleResolve(String id, String resolution) async {
    setState(() => _isProcessing = true);
    try {
      await widget.onResolve(id, resolution);
      if (mounted) {
        Navigator.pop(context, true); // Pop with true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleme Odası'),
      ),
      body: Stack(
        children: [
          if (widget.pendingPurchases.isEmpty)
            const Center(child: Text('Bekleme odasında ürün yok. İyi gidiyorsun!'))
          else
            ListView.builder(
              itemCount: widget.pendingPurchases.length,
              itemBuilder: (context, index) {
                final pending = widget.pendingPurchases[index];
                final isPending = pending.resolution == 'pending';
                
                String durumText = pending.resolution;
                if (durumText == 'pending') durumText = 'Beklemede';
                if (durumText == 'purchased') durumText = 'Satın Alındı';
                if (durumText == 'abandoned') durumText = 'Vazgeçildi';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPending ? Colors.orange : Colors.grey,
                          child: Icon(isPending ? Icons.hourglass_bottom : Icons.check_circle, color: Colors.white),
                        ),
                        title: Text('Bekleyen Harcama: ${pending.amount} TL'),
                        subtitle: Text('Durum: $durumText\nTarih: ${pending.createdAt.substring(0, 10)}'),
                      ),
                      if (isPending)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.shopping_bag, color: Colors.red),
                                label: const Text('Aldım', style: TextStyle(color: Colors.red)),
                                onPressed: _isProcessing ? null : () => _handleResolve(pending.id, 'purchased'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.star, color: Colors.green),
                                label: const Text('Vazgeçtim!', style: TextStyle(color: Colors.green)),
                                onPressed: _isProcessing ? null : () => _handleResolve(pending.id, 'abandoned'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
