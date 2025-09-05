// lib/screeens/waiter_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'waiter_order_detail_screen.dart';

final _orders = FirebaseFirestore.instance.collection('orders');

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key, required this.auth});
  final AuthService auth;
  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
  final _tableCtrl = TextEditingController();
  final _itemsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _tableCtrl.dispose();
    _itemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final table = _tableCtrl.text.trim();
    final rawItems = _itemsCtrl.text.trim();
    if (table.isEmpty || rawItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa mesa e items.')));
      return;
    }
    final items = rawItems
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((name) => {'name': name, 'qty': 1})
        .toList();

    setState(() => _loading = true);
    try {
      await _orders.add({
        'table': table,
        'items': items,
        'status': 'pendiente',
        'paymentStatus': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _tableCtrl.clear();
      _itemsCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido enviado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mozo'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            onPressed: () => Navigator.of(context).pushNamed('/waiter/history'),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Nuevo pedido',
            onPressed: () => Navigator.of(context).pushNamed('/waiter/new'),
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
          IconButton(onPressed: () => widget.auth.logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Crear pedido (rápido)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _tableCtrl, decoration: const InputDecoration(labelText: 'Mesa', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _itemsCtrl, minLines: 1, maxLines: 3, decoration: const InputDecoration(labelText: 'Items (coma separada)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
              label: const Text('Enviar pedido'),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Pendientes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _orders.orderBy('createdAt', descending: true).limit(100).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('Sin pedidos'));
                // Solo status == 'pendiente'
                final pending = snap.data!.docs.where((d) => (d.data()['status'] ?? 'pendiente') == 'pendiente').toList();
                if (pending.isEmpty) return const Center(child: Text('No hay pedidos pendientes.'));
                return ListView.builder(
                  itemCount: pending.length,
                  itemBuilder: (context, i) {
                    final d = pending[i];
                    final data = d.data();
                    final table = (data['table'] ?? '').toString();
                    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => WaiterOrderDetailScreen(orderRef: d.reference)),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text('Mesa $table', style: const TextStyle(fontWeight: FontWeight.bold))),
                              const Chip(label: Text('pendiente')),
                            ]),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: -8,
                              children: [for (final it in items) Chip(label: Text('${it['name']} x${it['qty'] ?? 1}'))],
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}