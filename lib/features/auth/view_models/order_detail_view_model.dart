import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/orders_service.dart';

class OrderDetailViewModel extends ChangeNotifier {
  final OrdersService _ordersService;
  final DocumentReference<Map<String, dynamic>> _orderRef;
  StreamSubscription? _subscription;
  bool _isDisposed = false;

  DocumentSnapshot<Map<String, dynamic>>? _orderSnapshot;
  bool _isLoading = true;
  String _paymentMethod = 'cash';
  String _cashReceivedInput = '';

  DocumentSnapshot<Map<String, dynamic>>? get orderSnapshot => _orderSnapshot;
  bool get isLoading => _isLoading;
  String get paymentMethod => _paymentMethod;
  String get cashReceivedInput => _cashReceivedInput;
  Map<String, dynamic> get orderData => _orderSnapshot?.data() ?? {};
  bool get isPending => (orderData['status'] ?? '') == 'pendiente';
  int get totalCents => (orderData['totalCents'] ?? 0) as int;
  int get cashReceivedCents => _parseSolesToCents(_cashReceivedInput);
  int get changeCents => (cashReceivedCents - totalCents) < 0 ? 0 : cashReceivedCents - totalCents;
  bool get canCharge => isPending && (_paymentMethod == 'yape' || cashReceivedCents >= totalCents);

  OrderDetailViewModel(this._ordersService, this._orderRef) {
    _listenToOrder();
  }

  void _listenToOrder() {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    _subscription = _orderRef.snapshots().listen((snapshot) {
      _orderSnapshot = snapshot;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }, onError: (error) {
      print("Error en OrderDetailViewModel: $error");
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    });
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    if(!_isDisposed) notifyListeners();
  }

  void updateCashReceived(String value) {
    _cashReceivedInput = value;
    if(!_isDisposed) notifyListeners();
  }

  Future<void> removeItem(Map<String, dynamic> lineItem) async {
    await _ordersService.removeLine(ref: _orderRef, itemId: lineItem['itemId'] ?? '');
  }

  Future<void> cancelOrder() async {
    await _ordersService.cancelOrder(_orderRef);
  }

  Future<void> chargeOrder() async {
    await _ordersService.charge(
      ref: _orderRef,
      method: _paymentMethod,
      totalCents: totalCents,
      cashReceivedCents: cashReceivedCents,
      changeCents: changeCents,
      yapeRef: null,
    );
  }

  int _parseSolesToCents(String input) {
    final t = input.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    if (v == null) return 0;
    return (v * 100).round();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}