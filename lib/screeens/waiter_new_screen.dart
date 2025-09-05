// lib/screeens/waiter_new_order_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/menu_services.dart';
import '../models/menu_models.dart';

class CartController extends ChangeNotifier {
  final Map<String, int> _qty = {};
  final Map<String, MenuItemModel> _items = {};
  void add(MenuItemModel item) {
    _items[item.id] = item;
    _qty.update(item.id, (v) => v + 1, ifAbsent: () => 1);
    notifyListeners();
  }
  void dec(String id) {
    if (!_qty.containsKey(id)) return;
    final v = _qty[id]! - 1;
    if (v <= 0) {
      _qty.remove(id);
      _items.remove(id);
    } else {
      _qty[id] = v;
    }
    notifyListeners();
  }
  int qty(String id) => _qty[id] ?? 0;
  int get totalCents => _qty.entries.fold(0, (s, e) => s + (_items[e.key]!.priceCents * e.value));
  List<Map<String, dynamic>> toOrderItems() => _qty.entries
      .map((e) => {
    'itemId': e.key,
    'name': _items[e.key]!.name,
    'unitCents': _items[e.key]!.priceCents,
    'qty': e.value,
    'lineCents': _items[e.key]!.priceCents * e.value,
  })
      .toList();
  void clear() {
    _qty.clear();
    _items.clear();
    notifyListeners();
  }
}

class WaiterNewOrderScreen extends StatefulWidget {
  const WaiterNewOrderScreen({super.key});
  @override
  State<WaiterNewOrderScreen> createState() => _WaiterNewOrderScreenState();
}

class _WaiterNewOrderScreenState extends State<WaiterNewOrderScreen> {
  final service = MenuService();
  String? _categoryId;
  final _tableCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  @override
  void dispose() {
    _tableCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CartController>(
      create: (_) => CartController(),
      child: Builder(builder: (context) {
        final cart = context.watch<CartController>();
        return Scaffold(
          appBar: AppBar(title: const Text('Nuevo pedido')),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: const [BoxShadow(blurRadius: 4, offset: Offset(0, -1), color: Colors.black12)]),
            child: Row(children: [
              Expanded(child: Text('Total: ${formatPEN(cart.totalCents)}', style: const TextStyle(fontWeight: FontWeight.bold))),
              FilledButton(onPressed: cart.totalCents == 0 ? null : () => _submit(context, cart), child: const Text('Enviar')),
            ]),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: TextField(controller: _tableCtrl, decoration: const InputDecoration(labelText: 'Mesa', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()))),
              ]),
            ),
            StreamBuilder<List<MenuCategory>>(
              stream: service.watchCategories(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(padding: const EdgeInsets.all(12), child: Text('Error categorías: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator());
                }
                final cats = snap.data!;
                _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
                return SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (c, i) {
                      final cgy = cats[i];
                      final sel = cgy.id == _categoryId;
                      return ChoiceChip(label: Text(cgy.name), selected: sel, onSelected: (_) => setState(() => _categoryId = cgy.id));
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: cats.length,
                  ),
                );
              },
            ),
            Expanded(
              child: _categoryId == null
                  ? const Center(child: Text('Sin categorías'))
                  : StreamBuilder<List<MenuItemModel>>(
                stream: service.watchItemsByCategory(_categoryId!),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error ítems: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data!;
                  if (items.isEmpty) return const Center(child: Text('Sin ítems'));
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (c, i) {
                      final it = items[i];
                      final q = cart.qty(it.id);
                      return ListTile(
                        title: Text(it.name),
                        subtitle: Text(formatPEN(it.priceCents)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: q > 0 ? () => cart.dec(it.id) : null, icon: const Icon(Icons.remove_circle_outline)),
                          Text(q.toString()),
                          IconButton(onPressed: () => cart.add(it), icon: const Icon(Icons.add_circle_outline)),
                        ]),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ]),
        );
      }),
    );
  }
  Future<void> _submit(BuildContext context, CartController cart) async {
    final table = _tableCtrl.text.trim();
    if (table.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa la mesa')));
      return;
    }
    final items = cart.toOrderItems();
    final total = cart.totalCents;
    final db = FirebaseFirestore.instance;
    await db.collection('orders').add({
      'table': table,
      'items': items,
      'subtotalCents': total,
      'discountCents': 0,
      'totalCents': total,
      'status': 'pendiente',
      'paymentStatus': 'pendiente',
      'payment': {'method': null, 'amountCents': 0, 'cashReceivedCents': 0, 'changeCents': 0, 'yapeRef': null},
      'notes': _notesCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    cart.clear();
    if (mounted) Navigator.pop(context);
  }
}
