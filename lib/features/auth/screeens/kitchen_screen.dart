import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/kitchen_service.dart';
import '../view_models/kitchen_view_model.dart';
import '../widgets/kitchen_item_card.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => KitchenViewModel(ctx.read<KitchenService>()),
      child: Consumer<KitchenViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Comandas de Cocina'),
              actions: [
                IconButton(
                  tooltip: 'Cerrar Sesión',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () async {
                    await context.read<AuthService>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    }
                  },
                ),
              ],
            ),
            body: _buildBody(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, KitchenViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.pendingLines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('¡Todo al día!', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('No hay platos pendientes en la cocina.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final lines = viewModel.pendingLines;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      // --- LÓGICA DE CUADRÍCULA CORREGIDA ---
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450.0, // Las tarjetas de cocina son más anchas
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        mainAxisExtent: 120, // Les damos una altura fija
      ),
      itemCount: lines.length,
      itemBuilder: (_, i) {
        final line = lines[i];
        return KitchenItemCard(
          line: line,
          onReady: () => viewModel.markItemAsReady(line),
        );
      },
    );
  }
}