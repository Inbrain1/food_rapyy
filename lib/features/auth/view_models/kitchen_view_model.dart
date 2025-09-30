import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/kitchen_models.dart';
import '../../../core/services/kitchen_service.dart';

class KitchenViewModel extends ChangeNotifier {
  final KitchenService _kitchenService;
  StreamSubscription? _subscription;
  bool _isDisposed = false;

  List<KitchenLine> _pendingLines = [];
  bool _isLoading = true;

  List<KitchenLine> get pendingLines => _pendingLines;
  bool get isLoading => _isLoading;

  KitchenViewModel(this._kitchenService) {
    _listenToPendingItems();
  }

  void _listenToPendingItems() {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    _subscription = _kitchenService.watchPendingItemCards().listen((lines) {
      _pendingLines = lines;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }, onError: (error) {
      print("Error en KitchenViewModel: $error");
      _isLoading = false;
      _pendingLines = [];
      if (!_isDisposed) notifyListeners();
    });
  }

  Future<void> markItemAsReady(KitchenLine line) async {
    try {
      await _kitchenService.markItemReady(line);
    } catch (e) {
      print("Error al marcar el ítem como listo: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}