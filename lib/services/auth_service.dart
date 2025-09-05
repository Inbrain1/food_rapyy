// =============================
// file: lib/services/auth_service.dart
// =============================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> currentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(user.uid, doc.data()!);
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String role, // 'mozo' | 'cocinero'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final appUser = AppUser(uid: uid, email: email, role: role);
    await _db.collection('users').doc(uid).set(appUser.toMap());
    return appUser;
  }

  Future<AppUser> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      // fallback: crea doc con rol mozo por defecto (no debería pasar si registras correctamente)
      final appUser = AppUser(uid: uid, email: cred.user!.email ?? email, role: 'mozo');
      await _db.collection('users').doc(uid).set(appUser.toMap());
      return appUser;
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> logout() => _auth.signOut();
}
