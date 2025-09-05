// lib/screeens/register_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.auth, required this.onRegistered});
  final AuthService auth;
  final void Function(AppUser) onRegistered;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'mozo';
  bool _loading = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();
    final conf = _confirm.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('Completa todos los campos');
      return;
    }
    if (pass != conf) {
      _snack('Las contraseñas no coinciden');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await widget.auth.register(email: email, password: pass, role: _role);
      if (!mounted) return;
      widget.onRegistered(user);
    } on FirebaseAuthException catch (e) {
      _snack(_mapRegError(e));
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rol'),
                    RadioListTile<String>(value: 'mozo', groupValue: _role, onChanged: (v) => setState(() => _role = v!), title: const Text('Mozo'), contentPadding: EdgeInsets.zero),
                    RadioListTile<String>(value: 'cocinero', groupValue: _role, onChanged: (v) => setState(() => _role = v!), title: const Text('Cocinero'), contentPadding: EdgeInsets.zero),
                  ]),
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrarme'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _mapRegError(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'El correo ya está en uso';
    case 'weak-password':
      return 'La contraseña es débil';
    case 'invalid-email':
      return 'Email inválido';
    default:
      return 'Auth error: ${e.code}';
  }
}
