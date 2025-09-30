import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/orders_service.dart';
import '../view_models/waiter_view_model.dart';
import '../widgets/add_order_card.dart';
import '../widgets/peding_table_sheet.dart';
import '../widgets/table_card.dart';
import 'waiter_new_screen.dart';

class WaiterScreen extends StatelessWidget {
  const WaiterScreen({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WaiterViewModel(context.read<OrdersService>()),
      child: Consumer<WaiterViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Gestión de Mesas'),
              actions: [
                IconButton(
                  tooltip: 'Historial',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/waiter/history'),
                  icon: const Icon(Icons.history_rounded),
                ),
                IconButton(
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            body: _buildBody(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WaiterViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tables = viewModel.tables;

    final List<Widget> gridItems = [
      AddOrderCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WaiterNewOrderScreen()),
        ),
      ),
      ...tables.map((t) => TableCard(
        table: t.tableNumber,
        isTakeout: t.isTakeout,
        pendingCount: t.orders.length,
        items: _topItems(t.aggregatedItems, 3),
        onOpen: () => showPendingTableSheet(
          context: context,
          table: t.tableNumber,
          isTakeout: t.isTakeout,
          initialOrders: t.orders,
        ),
      )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Mesas Activas',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          // --- LÓGICA DE CUADRÍCULA CORREGIDA ---
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350.0, // Cada elemento intentará tener este ancho MÁXIMO
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 1.0, // Ajusta esto si las tarjetas se ven muy altas o bajas
            ),
            itemCount: gridItems.length,
            itemBuilder: (_, i) => gridItems[i],
          ),
        ),
      ],
    );
  }

  List<String> _topItems(Map<String, int> map, int take) {
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(take).map((e) => '${e.key} x${e.value}').toList();
  }
}