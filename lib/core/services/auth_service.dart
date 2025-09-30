import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> currentAppUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _users.doc(u.uid).get();
    final data = doc.data();
    if (data == null) return null;
    final role = (data['role'] ?? 'waiter').toString();
    return AppUser(uid: u.uid, email: u.email ?? '', role: role);
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String role, // 'waiter' | 'kitchen'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _users.doc(uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return AppUser(uid: uid, email: email, role: role);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _users.doc(uid).get();
    final role = (doc.data()?['role'] ?? 'waiter').toString();
    return AppUser(uid: uid, email: cred.user!.email ?? email, role: role);
  }

  Future<void> logout() => _auth.signOut();
}
