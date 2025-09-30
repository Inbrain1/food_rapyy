import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/orders_service.dart';

class HistoryDay {
  final DateTime date;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> orders;
  final int totalCents;

  HistoryDay({
    required this.date,
    required this.orders,
    required this.totalCents,
  });
}

class HistoryViewModel extends ChangeNotifier {
  final OrdersService _ordersService;
  StreamSubscription? _subscription;
  bool _isDisposed = false;

  List<HistoryDay> _historyDays = [];
  bool _isLoading = true;

  List<HistoryDay> get historyDays => _historyDays;
  bool get isLoading => _isLoading;

  HistoryViewModel(this._ordersService) {
    _listenToHistory();
  }

  void _listenToHistory() {
    _isLoading = true;
    if(!_isDisposed) notifyListeners();

    _subscription = _ordersService.watchRecent(limit: 500).listen((snapshot) {
      _processHistory(snapshot.docs);
    }, onError: (error) {
      print("Error en HistoryViewModel: $error");
      _isLoading = false;
      if(!_isDisposed) notifyListeners();
    });
  }

  void _processHistory(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final paid = docs.where((d) {
      final data = d.data();
      return (data['status'] ?? '') == 'pagado' && data['paidAt'] is Timestamp;
    }).toList();

    final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay = {};
    for (final d in paid) {
      final ts = d['paidAt'] as Timestamp;
      final dt = ts.toDate().toLocal();
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      byDay.putIfAbsent(dayKey, () => []).add(d);
    }

    _historyDays = byDay.entries.map((entry) {
      final total = entry.value.fold<int>(0, (sum, doc) {
        return sum + ((doc.data()['totalCents'] ?? 0) as int);
      });
      return HistoryDay(date: entry.key, orders: entry.value, totalCents: total);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    if(!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}