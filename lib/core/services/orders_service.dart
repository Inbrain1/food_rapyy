import 'package:cloud_firestore/cloud_firestore.dart';


class OrdersService {
  final _col = FirebaseFirestore.instance.collection('orders');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecent({int limit = 200}) {
    return _col.orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  Future<void> createOrder({
    required String table,
    required bool isTakeout,
    required List<Map<String, dynamic>> items,
    required int totalCents,
    String notes = '',
  }) {
    return _col.add({
      'table': table,
      'takeout': isTakeout,
      'items': items,
      'subtotalCents': totalCents,
      'discountCents': 0,
      'totalCents': totalCents,
      'status': 'pendiente',
      'paymentStatus': 'pendiente',
      'payment': {
        'method': null,
        'amountCents': 0,
        'cashReceivedCents': 0,
        'changeCents': 0,
        'yapeRef': null
      },
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelPending(DocumentReference ref) {
    return ref.update({
      'status': 'cancelado',
      'paymentStatus': 'cancelado',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelOrder(DocumentReference<Map<String, dynamic>> ref) {
    return ref.update({
      'status': 'cancelado',
      'paymentStatus': 'cancelado',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeLine({
    required DocumentReference<Map<String, dynamic>> ref,
    required String itemId,
  }) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;
      final items = ((data['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .toList();

      final idx = items.indexWhere((m) => (m['itemId'] ?? '') == itemId);
      if (idx < 0) return;

      items.removeAt(idx);

      final newSubtotal = items.fold<int>(
        0,
            (s, it) =>
        s +
            ((it['lineCents'] ??
                ((it['unitCents'] ?? 0) * (it['qty'] ?? 1))) as int),
      );
      final discount = (data['discountCents'] ?? 0) as int;
      final rawTotal = newSubtotal - discount;
      final newTotal = rawTotal < 0 ? 0 : rawTotal;

      final update = <String, dynamic>{
        'items': items,
        'subtotalCents': newSubtotal,
        'totalCents': newTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (items.isEmpty) {
        update['status'] = 'cancelado';
        update['paymentStatus'] = 'cancelado';
      }

      tx.update(ref, update);
    });
  }

  Future<void> charge({
    required DocumentReference<Map<String, dynamic>> ref,
    required String method, // 'cash' | 'yape'
    required int totalCents,
    int cashReceivedCents = 0,
    int changeCents = 0,
    String? yapeRef,
  }) async {
    final paymentData = method == 'cash'
        ? {
      'method': 'cash',
      'amountCents': totalCents,
      'cashReceivedCents': cashReceivedCents,
      'changeCents': changeCents,
      'yapeRef': null,
    }
        : {
      'method': 'yape',
      'amountCents': totalCents,
      'cashReceivedCents': 0,
      'changeCents': 0,
      'yapeRef': yapeRef,
    };

    // --- LÓGICA DE TRANSACCIÓN CORREGIDA ---
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(ref);
      if (!orderSnapshot.exists) {
        throw Exception("El pedido no existe!");
      }

      // 1. Actualizar el pedido
      transaction.update(ref, {
        'status': 'pagado',
        'paymentStatus': 'pagado',
        'payment': paymentData,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Crear el registro de pago en la colección 'payments'
      final paymentDoc = FirebaseFirestore.instance.collection('payments').doc();
      final orderData = orderSnapshot.data()!;
      transaction.set(paymentDoc, {
        'orderId': ref.id,
        'table': orderData['table'],
        'takeout': orderData['takeout'] ?? false,
        'amountCents': totalCents,
        'method': method,
        'items': orderData['items'],
        'paidAt': FieldValue.serverTimestamp(),
      });
    });
  }
}