// =============================
// file: lib/screens/kitchen_screen.dart
// =============================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final orders = FirebaseFirestore.instance.collection('orders');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cocina'),
        actions: [IconButton(onPressed: () => auth.logout(), icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: orders
              .where('status', whereIn: ['pendiente', 'preparando', 'listo'])
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No hay pedidos en curso'));
            final docs = snap.data!.docs;
            return ListView.separated(
              itemBuilder: (context, i) => _KitchenOrderTile(doc: docs[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: docs.length,
            );
          },
        ),
      ),
    );
  }
}

class _KitchenOrderTile extends StatelessWidget {
  const _KitchenOrderTile({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final table = (data['table'] ?? '').toString();
    final status = (data['status'] ?? 'pendiente').toString();
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    Future<void> _update(String s) async {
      await doc.reference.update({'status': s, 'updatedAt': FieldValue.serverTimestamp()});
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Mesa $table', style: const TextStyle(fontWeight: FontWeight.bold))),
            Chip(label: Text(status)),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: -8, children: [
            for (final it in items) Chip(label: Text('${it['name']} x${it['qty'] ?? 1}')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (status != 'preparando' && status != 'listo' && status != 'entregado')
              Expanded(child: OutlinedButton(onPressed: () => _update('preparando'), child: const Text('Preparando'))),
            const SizedBox(width: 8),
            if (status != 'listo' && status != 'entregado')
              Expanded(child: OutlinedButton(onPressed: () => _update('listo'), child: const Text('Listo'))),
            const SizedBox(width: 8),
            if (status != 'entregado')
              Expanded(child: FilledButton(onPressed: () => _update('entregado'), child: const Text('Entregar'))),
          ]),
        ]),
      ),
    );
  }
}