import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart'; // Necesitarás este paquete

class AddOrderCard extends StatelessWidget {
  const AddOrderCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        color: colorScheme.primary,
        strokeWidth: 2,
        dashPattern: const [8, 6],
        radius: const Radius.circular(12),
        borderType: BorderType.RRect,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, size: 42, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text('Nuevo Pedido', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}