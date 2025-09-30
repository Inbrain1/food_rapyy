import 'package:flutter/foundation.dart';

import '../core/models/menu_models.dart';
import '../core/services/orders_service.dart';

class CartController extends ChangeNotifier {
  final OrdersService _ordersService;

  CartController(this._ordersService);

  final Map<String, int> _qty = {};
  final Map<String, MenuItemModel> _items = {};
  final Map<String, String> _specs = {}; // specs por itemId

  // Métodos para leer el estado del carrito
  int qty(String id) => _qty[id] ?? 0;
  String? getSpec(String id) => _specs[id];
  int get totalCents => _qty.entries.fold(0, (s, e) => s + (_items[e.key]!.priceCents * e.value));
  bool get isEmpty => _items.isEmpty;

  // Métodos para modificar el estado del carrito
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
      _specs.remove(id);
    } else {
      _qty[id] = v;
    }
    notifyListeners();
  }

  void setSpec(String id, String? spec) {
    if (spec == null || spec.trim().isEmpty) {
      _specs.remove(id);
    } else {
      _specs[id] = spec.trim();
    }
    notifyListeners();
  }

  void clear() {
    _qty.clear();
    _items.clear();
    _specs.clear();
    notifyListeners();
  }

  // Lógica de negocio para enviar el pedido
  Future<void> submitOrder({
    required String table,
    required bool isTakeout,
  }) async {
    final orderItems = _qty.entries
        .map((e) => {
      'itemId': e.key,
      'name': _items[e.key]!.name,
      'unitCents': _items[e.key]!.priceCents,
      'qty': e.value,
      'lineCents': _items[e.key]!.priceCents * e.value,
      'specs': (_specs[e.key] ?? '').trim(),
    })
        .toList();

    await _ordersService.createOrder(
      table: isTakeout ? '' : table,
      isTakeout: isTakeout, // <-- CORREGIDO
      items: orderItems,
      totalCents: totalCents,
      notes: '',
    );
  }
}