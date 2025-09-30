import 'package:flutter/material.dart';

class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.isTakeout,
    required this.pendingCount,
    required this.items,
    required this.onOpen,
  });

  final String table;
  final bool isTakeout;
  final int pendingCount;
  final List<String> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxPreview = 3;
    final visibleItems = items.take(maxPreview).toList();
    final remainingItems = items.length - visibleItems.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Encabezado de la Tarjeta ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Alineación vertical
                children: [
                  Icon(isTakeout ? Icons.takeout_dining_rounded : Icons.table_restaurant_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    // --- CORRECCIÓN AQUÍ ---
                    // Envolvemos el Text en un FittedBox
                    child: FittedBox(
                      fit: BoxFit.scaleDown, // Encoge el texto si es necesario
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isTakeout ? 'Para Llevar' : 'Mesa $table',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('$pendingCount pendiente${pendingCount > 1 ? 's' : ''}'),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                    padding: const EdgeInsets.symmetric(horizontal: 4), // Reducimos el padding del chip
                  ),
                ],
              ),
              const Divider(height: 20),

              // --- Lista de Items ---
              if (items.isEmpty)
                const Expanded(child: Center(child: Text('Sin ítems pendientes')))
              else
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...visibleItems.map((item) => Text('• $item', overflow: TextOverflow.ellipsis)),
                      if (remainingItems > 0)
                        Text('+ $remainingItems más...', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.bottomRight,
                child: OutlinedButton(
                  onPressed: onOpen,
                  child: const Text('Ver / Cobrar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}