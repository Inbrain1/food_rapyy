import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/models/menu_models.dart';
import '../../../core/services/orders_service.dart';
import '../../../utils/bloacking_loader.dart';
import '../screeens/waiter_new_screen.dart';
import '../screeens/waiter_order_detail_screen.dart';

Future<void> showPendingTableSheet({
  required BuildContext context,
  required String table,
  required bool isTakeout,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> initialOrders,
}) async {
  final service = OrdersService();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final orders =
      List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(initialOrders);
      return StatefulBuilder(
        builder: (ctx, setStateBS) {
          Future<void> cancelOrder(
              QueryDocumentSnapshot<Map<String, dynamic>> d) async {
            final ok = await showDialog<bool>(
              context: ctx,
              builder: (dCtx) => AlertDialog(
                title: const Text('Cancelar pedido'),
                content: const Text('¿Seguro que deseas cancelar este pedido?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dCtx, false),
                      child: const Text('No')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dCtx, true),
                      child: const Text('Sí, cancelar')),
                ],
              ),
            );
            if (ok != true) return;

            await runWithBlockingLoader(ctx, () async {
              await service.cancelPending(d.reference);
            });
            setStateBS(() => orders.removeWhere((e) => e.id == d.id));
            if (orders.isEmpty && Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            isTakeout ? 'Para Llevar' : 'Mesa $table',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WaiterNewOrderScreen(
                                  initialTable: isTakeout ? null : table),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Sin pendientes')),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 20), // Separador entre pedidos
                        itemBuilder: (_, i) {
                          // --- TARJETA DE PEDIDO INDIVIDUAL ---
                          return _OrderDetailCard(
                            orderDoc: orders[i],
                            onCancel: () => cancelOrder(orders[i]),
                            onView: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WaiterOrderDetailScreen(
                                      orderRef: orders[i].reference),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// --- NUEVO WIDGET INTERNO PARA LA TARJETA DE PEDIDO ---
class _OrderDetailCard extends StatelessWidget {
  const _OrderDetailCard({
    required this.orderDoc,
    required this.onCancel,
    required this.onView,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> orderDoc;
  final VoidCallback onCancel;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = orderDoc.data();
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final notes = (data['notes'] ?? '').toString();
    final total = (data['totalCents'] ?? 0) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- LISTA DE ITEMS ---
        ...items.map((it) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text('${it['name']}', style: theme.textTheme.bodyLarge),
            trailing: Text('x${it['qty'] ?? 1}', style: theme.textTheme.bodyMedium),
          );
        }),
        if (notes.isNotEmpty) ...[
          const Divider(height: 16),
          Text(
            notes,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Divider(height: 24),
        // --- TOTAL Y BOTONES ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              formatPEN(total),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onView,
                  child: const Text('Ver / Cobrar'),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}