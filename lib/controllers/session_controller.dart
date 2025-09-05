// lib/controllers/session_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../data/menu_seed.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._auth) {
    _sub = _auth.authStateChanges().listen((user) async {
      _isLoggedIn = user != null;
      if (_isLoggedIn && !_seededOnce) {
        try {
          await seedMenuIfEmpty();
          _seededOnce = true;
        } catch (_) {}
      }
      notifyListeners();
    });
  }

  final AuthService _auth;
  late final StreamSubscription _sub;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _seededOnce = false;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}