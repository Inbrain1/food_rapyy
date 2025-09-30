import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? icon; // <-- AÑADIMOS EL ICONO

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.icon, // <-- AÑADIMOS EL ICONO
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon) : null, // <-- USAMOS EL ICONO
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)), // Bordes más redondeados
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}