import 'package:flutter/material.dart';
import '../../models/transaction.dart';

class HistoryScreen extends StatelessWidget {
  final List<TransactionOut> transactions;

  const HistoryScreen({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Harcamalar'),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('Henüz kaydedilmiş harcama yok.'))
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.receipt, color: Colors.white),
                    ),
                    title: Text('Harcama: ${tx.rawAmount} TL'),
                    subtitle: Text('Tarih: ${tx.createdAt.substring(0, 10)}\nBirikim (Ceza + Yuvarlama): ${tx.totalDiverted} TL'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${tx.rawAmount} TL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (double.tryParse(tx.selfTaxAmount) != null && double.parse(tx.selfTaxAmount) > 0)
                          Text('+${tx.selfTaxAmount} TL Ceza', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        if (double.tryParse(tx.roundupAmount) != null && double.parse(tx.roundupAmount) > 0)
                          Text('+${tx.roundupAmount} TL Yuvarlama', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
