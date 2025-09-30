// lib/widgets/kitchen_item_card.dart
import 'package:flutter/material.dart';
import '../../../core/models/kitchen_models.dart';

class KitchenItemCard extends StatelessWidget {
  const KitchenItemCard({
    super.key,
    required this.line,
    required this.onReady,
  });

  final KitchenLine line;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      key: ValueKey(line.stableKey),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_menu, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          line.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (line.takeout)
                        Chip(label: const Text('Para llevar'), visualDensity: VisualDensity.compact)
                      else if (line.table.isNotEmpty)
                        Chip(label: Text('Mesa ${line.table}'), visualDensity: VisualDensity.compact)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'x${line.qty}',
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (line.specs.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      line.specs,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Listo'),
              onPressed: onReady,
            ),
          ],
        ),
      ),
    );
  }
}
