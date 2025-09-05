// lib/screeens/waiter_history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaiterHistoryScreen extends StatelessWidget {
  const WaiterHistoryScreen({super.key});

  String _pen(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';
  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _dayLabel(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final payments = FirebaseFirestore.instance.collection('payments');
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: payments.orderBy('paidAt', descending: true).limit(300).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Sin pagos registrados.'));
          }

          final docs = snap.data!.docs;

          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay = {};
          final Map<String, int> dayTotals = {};

          for (final d in docs) {
            final m = d.data();
            final ts = (m['paidAt'] ?? m['createdAt']) as Timestamp?;
            if (ts == null) continue;
            final dt = ts.toDate().toLocal();
            final key = _dayKey(dt);
            byDay.putIfAbsent(key, () => []).add(d);
            final amount = (m['amountCents'] is int) ? m['amountCents'] as int : 0;
            dayTotals.update(key, (v) => v + amount, ifAbsent: () => amount);
          }

          final orderedKeys = byDay.keys.toList()
            ..sort((a, b) {
              final ap = a.split('-').map(int.parse).toList();
              final bp = b.split('-').map(int.parse).toList();
              final ad = DateTime(ap[0], ap[1], ap[2]).millisecondsSinceEpoch;
              final bd = DateTime(bp[0], bp[1], bp[2]).millisecondsSinceEpoch;
              return bd.compareTo(ad);
            });

          return ListView.builder(
            itemCount: orderedKeys.length,
            itemBuilder: (context, i) {
              final key = orderedKeys[i];
              final parts = key.split('-').map(int.parse).toList();
              final date = DateTime(parts[0], parts[1], parts[2]);
              final list = byDay[key]!;
              final total = dayTotals[key] ?? 0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(_dayLabel(date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      Text(_pen(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          for (final d in list)
                            _PaymentTile(doc: d, pen: _pen),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.doc, required this.pen});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String Function(int) pen;

  @override
  Widget build(BuildContext context) {
    final m = doc.data();
    final table = (m['table'] ?? '').toString();
    final method = (m['method'] ?? '').toString();
    final amount = (m['amountCents'] is int) ? m['amountCents'] as int : 0;
    final ts = (m['paidAt'] ?? m['createdAt']) as Timestamp?;
    final dt = ts?.toDate().toLocal();
    String hhmm = '';
    if (dt != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      hhmm = '${two(dt.hour)}:${two(dt.minute)}';
    }
    final items = (m['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return ListTile(
      title: Text('Mesa $table — ${pen(amount)}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$method${hhmm.isNotEmpty ? ' · $hhmm' : ''}'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: -8,
            children: [for (final it in items) Chip(label: Text('${it['name']} x${it['qty'] ?? 1}'))],
          ),
        ],
      ),
    );
  }
}