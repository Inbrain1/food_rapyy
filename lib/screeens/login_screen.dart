// lib/screeens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, required this.onLogged});
  final AuthService auth;
  final void Function(AppUser) onLogged;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('Completa email y contraseña');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await widget.auth.login(email: email, password: pass);
      if (!mounted) return;
      widget.onLogged(user);
    } on FirebaseAuthException catch (e) {
      _snack(_mapAuthError(e));
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Entrar'))),
                const SizedBox(height: 8),
                TextButton(onPressed: _loading ? null : () => Navigator.of(context).pushNamed('/register'), child: const Text('Crear cuenta')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _mapAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'Usuario no encontrado';
    case 'wrong-password':
      return 'Contraseña incorrecta';
    case 'invalid-email':
      return 'Email inválido';
    default:
      return 'Auth error: ${e.code}';
  }
}