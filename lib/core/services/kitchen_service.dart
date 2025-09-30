// lib/services/kitchen_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kitchen_models.dart';

class KitchenService {
  final _orders = FirebaseFirestore.instance.collection('orders');

  /// 1 card por ítem de cada pedido, ordenado por createdAt asc.
  /// Filtramos en cliente para evitar índices compuestos.
  Stream<List<KitchenLine>> watchPendingItemCards() {
    return _orders
        .orderBy('createdAt', descending: false)
        .limit(500)
        .snapshots()
        .map((snap) {
      final List<KitchenLine> lines = [];
      for (final d in snap.docs) {
        final data = d.data();

        final status = (data['status'] ?? '').toString();
        if (status != 'pendiente') continue;

        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ??
            (data['updatedAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final items =
            (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

        final takeout = (data['takeout'] ?? false) as bool;
        final table = (data['table'] ?? '').toString();

        for (final it in items) {
          // si ya está listo, no se muestra en el feed
          if ((it['kitchenReady'] ?? false) == true) continue;

          final itemId = (it['itemId'] ?? '').toString();
          if (itemId.isEmpty) continue;

          final name = (it['name'] ?? '').toString();
          final qty = (it['qty'] is int) ? it['qty'] as int : ((it['qty'] is num) ? (it['qty'] as num).toInt() : 1);
          final specs = (it['specs'] ?? '').toString();

          lines.add(KitchenLine(
            orderId: d.id,
            itemId: itemId,
            name: name,
            qty: qty,
            createdAt: createdAt,
            orderRef: d.reference,
            specs: specs,
            takeout: takeout,
            table: table,
          ));
        }
      }

      lines.sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        if (c != 0) return c;
        final o = a.orderId.compareTo(b.orderId);
        if (o != 0) return o;
        return a.itemId.compareTo(b.itemId);
      });

      return lines;
    });
  }

  /// Marca un ítem como listo y lo guarda en el historial del pedido.
  Future<void> markItemReady(KitchenLine line) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(line.orderRef);
      final data = snap.data()!;
      final items = ((data['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .toList();

      final idx = items.indexWhere((m) =>
      (m['itemId'] ?? '') == line.itemId &&
          (m['kitchenReady'] ?? false) != true);
      if (idx == -1) return; // ya estaba listo o no existe

      items[idx]['kitchenReady'] = true;

      tx.update(line.orderRef, {
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final histRef = line.orderRef.collection('kitchen_history').doc();
      tx.set(histRef, {
        'orderId': line.orderId,
        'itemId': line.itemId,
        'name': line.name,
        'qty': line.qty,
        'table': line.table,
        'takeout': line.takeout,
        'specs': line.specs,
        'orderCreatedAt': data['createdAt'], // Timestamp original del pedido
        'readyAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
