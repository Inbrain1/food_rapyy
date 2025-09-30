import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/orders_service.dart';

class TableWithOrders {
  final String tableNumber;
  final bool isTakeout;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;
  final Map<String, int> aggregatedItems;

  TableWithOrders({
    required this.tableNumber,
    this.isTakeout = false,
    required this.orders,
    required this.aggregatedItems,
  });
}

class WaiterViewModel extends ChangeNotifier {
  final OrdersService _ordersService;
  StreamSubscription? _subscription;
  bool _isDisposed = false;

  List<TableWithOrders> _tables = [];
  bool _isLoading = true;

  List<TableWithOrders> get tables => _tables;
  bool get isLoading => _isLoading;

  WaiterViewModel(this._ordersService) {
    _listenToOrders();
  }

  void _listenToOrders() {
    _subscription = _ordersService.watchRecent().listen((snapshot) {
      _processOrders(snapshot.docs);
    });
  }

  void _processOrders(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    _isLoading = false;
    final pendingDocs = docs.where((d) => (d.data()['status'] ?? 'pendiente') == 'pendiente').toList();
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byTable = {};
    final Map<String, Map<String, int>> itemsByTable = {};

    for (final d in pendingDocs) {
      final data = d.data();
      final isTakeout = (data['takeout'] ?? false) as bool;
      final table = (data['table'] ?? '').toString();
      if (!isTakeout && table.isEmpty) continue;
      final key = isTakeout ? 'Para Llevar' : table;
      byTable.putIfAbsent(key, () => []).add(d);
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final map = itemsByTable.putIfAbsent(key, () => {});
      for (final it in items) {
        final name = (it['name'] ?? '').toString();
        final qty = (it['qty'] is int) ? it['qty'] as int : 1;
        if (name.isEmpty) continue;
        map.update(name, (v) => v + qty, ifAbsent: () => qty);
      }
    }

    _tables = byTable.keys.map((tableKey) {
      return TableWithOrders(
        tableNumber: tableKey,
        isTakeout: tableKey == 'Para Llevar',
        orders: byTable[tableKey]!,
        aggregatedItems: itemsByTable[tableKey]!,
      );
    }).toList()
      ..sort((a, b) {
        if (a.isTakeout) return -1;
        if (b.isTakeout) return 1;
        final ai = int.tryParse(a.tableNumber);
        final bi = int.tryParse(b.tableNumber);
        if (ai != null && bi != null) return ai.compareTo(bi);
        return a.tableNumber.compareTo(b.tableNumber);
      });

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}