import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenLine {
  final String orderId;
  final String itemId;
  final String name;
  final int qty;
  final DateTime createdAt; // del pedido
  final DocumentReference<Map<String, dynamic>> orderRef;

  // Nuevos campos
  final String specs; // especificaciones del mozo (posible '')
  final bool takeout; // true = para llevar
  final String table; // texto de mesa (posible '')

  const KitchenLine({
    required this.orderId,
    required this.itemId,
    required this.name,
    required this.qty,
    required this.createdAt,
    required this.orderRef,
    required this.specs,
    required this.takeout,
    required this.table,
  });

  String get stableKey => '${orderId}_$itemId';
}
