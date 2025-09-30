import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/orders_service.dart';
import '../../../utils/bloacking_loader.dart';
import '../../../utils/money.dart';
import '../view_models/order_detail_view_model.dart';

class WaiterOrderDetailScreen extends StatelessWidget {
  const WaiterOrderDetailScreen({super.key, required this.orderRef});
  final DocumentReference<Map<String, dynamic>> orderRef;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => OrderDetailViewModel(ctx.read<OrdersService>(), orderRef),
      child: Consumer<OrderDetailViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detalle y Cobro'),
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            ),
            body: _buildBody(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.orderSnapshot == null || !viewModel.orderSnapshot!.exists) {
      return const Center(child: Text('Este pedido ya no está disponible.'));
    }

    // Usamos un ListView para que la pantalla sea scrollable en móviles pequeños
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _OrderHeader(viewModel: viewModel),
        const Divider(height: 24),
        const Text('Ítems del Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _ItemsList(viewModel: viewModel),
        const SizedBox(height: 24),
        _OrderTotalSection(viewModel: viewModel), // Nueva sección de totales
        const SizedBox(height: 24),
        if (viewModel.isPending) ...[
          _PaymentSection(viewModel: viewModel),
          const SizedBox(height: 24),
          _ActionButtons(viewModel: viewModel),
        ] else
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Este pedido ya ha sido finalizado.', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
      ],
    );
  }
}


// --- Widgets Internos Rediseñados ---

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.viewModel});
  final OrderDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final data = viewModel.orderData;
    final table = (data['table'] ?? '').toString();
    final takeout = (data['takeout'] ?? false) as bool;
    final status = (data['status'] ?? '').toString();
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          takeout ? Icons.takeout_dining_rounded : Icons.table_restaurant_rounded,
          color: theme.colorScheme.primary,
          size: 32,
        ),
        const SizedBox(width: 12),
        Text(
          takeout ? 'Pedido Para Llevar' : 'Mesa $table',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Chip(
          label: Text(status),
          backgroundColor: status == 'pagado' ? Colors.green.shade100 : theme.chipTheme.backgroundColor,
          labelStyle: TextStyle(color: status == 'pagado' ? Colors.green.shade900 : theme.chipTheme.labelStyle?.color),
        ),
      ],
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.viewModel});
  final OrderDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final items = ((viewModel.orderData['items'] as List?) ?? []).cast<Map<String, dynamic>>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            title: Text((it['name'] ?? '').toString()),
            subtitle: Text('${it['qty'] ?? 1} x ${formatPEN((it['unitCents'] ?? 0) as int)}'),
            trailing: Text(formatPEN((it['lineCents'] ?? 0) as int), style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}

class _OrderTotalSection extends StatelessWidget {
  const _OrderTotalSection({required this.viewModel});
  final OrderDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TOTAL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              formatPEN(viewModel.totalCents),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.viewModel});
  final OrderDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'cash', label: Text('Efectivo'), icon: Icon(Icons.money_rounded)),
            ButtonSegment(value: 'yape', label: Text('Yape/Plin'), icon: Icon(Icons.phone_iphone_rounded)),
          ],
          selected: {viewModel.paymentMethod},
          onSelectionChanged: (selection) => viewModel.setPaymentMethod(selection.first),
        ),
        const SizedBox(height: 16),
        if (viewModel.paymentMethod == 'cash')
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: viewModel.updateCashReceived,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Recibido (S/)',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Vuelto', style: TextStyle(fontSize: 12)),
                          Text(formatPEN(viewModel.changeCents), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  )
              ),
            ],
          )
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.viewModel});
  final OrderDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    Future<void> _chargeOrder() async {
      await runWithBlockingLoader(context, viewModel.chargeOrder);
      if (context.mounted) Navigator.pop(context);
    }

    return Row(
      children: [
        // Botón de Cancelar ahora es menos prominente
        TextButton(
          onPressed: () { /* Lógica para cancelar todo el pedido si se necesita */ },
          child: const Text('Cancelar Pedido'),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: viewModel.canCharge ? _chargeOrder : null,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Confirmar Cobro'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}