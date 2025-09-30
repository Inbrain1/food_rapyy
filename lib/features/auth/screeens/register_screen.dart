import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.auth, required this.onRegistered});
  final AuthService auth;
  final void Function(AppUser) onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = AppUser.roleWaiter;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final user = await widget.auth.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _role,
        );
        if (mounted) {
          widget.onRegistered(user);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error en el registro: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nueva Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, ingresa un email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Por favor, ingresa un email válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, ingresa una contraseña';
                      if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirmar contraseña',
                    icon: Icons.lock_person_outlined,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, confirma tu contraseña';
                      if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('  Selecciona tu rol:', style: TextStyle(fontWeight: FontWeight.bold)),
                          RadioListTile<String>(
                            title: const Text('Mozo'),
                            value: AppUser.roleWaiter,
                            groupValue: _role,
                            onChanged: (value) {
                              if (value != null) setState(() => _role = value);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Cocinero'),
                            value: AppUser.roleKitchen,
                            groupValue: _role,
                            onChanged: (value) {
                              if (value != null) setState(() => _role = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthButton(
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading,
                    text: 'Registrarme',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}