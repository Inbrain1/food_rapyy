import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controller/cart_controller.dart';
import '../../../core/models/menu_models.dart';
import '../../../core/services/menu_services.dart';
import '../../../core/services/orders_service.dart';
import '../../../utils/bloacking_loader.dart';
import '../../../utils/money.dart' hide formatPEN;

class WaiterNewOrderScreen extends StatelessWidget {
  const WaiterNewOrderScreen({super.key, this.initialTable});
  final String? initialTable;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CartController(ctx.read<OrdersService>()),
      child: _WaiterNewOrderView(initialTable: initialTable),
    );
  }
}

class _WaiterNewOrderView extends StatefulWidget {
  const _WaiterNewOrderView({this.initialTable});
  final String? initialTable;

  @override
  State<_WaiterNewOrderView> createState() => _WaiterNewOrderViewState();
}

class _WaiterNewOrderViewState extends State<_WaiterNewOrderView> {
  final _menuService = MenuService();
  final _tableCtrl = TextEditingController();
  String? _categoryId;
  bool _isTakeout = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTable != null && widget.initialTable!.isNotEmpty) {
      _tableCtrl.text = widget.initialTable!;
      _isTakeout = false;
    }
  }

  @override
  void dispose() {
    _tableCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = context.read<CartController>();
    final table = _tableCtrl.text.trim();
    if (!_isTakeout && table.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa el número de mesa.')));
      return;
    }

    try {
      await runWithBlockingLoader(context, () async {
        await cart.submitOrder(table: table, isTakeout: _isTakeout);
      });
      if (mounted) {
        cart.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar el pedido: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Pedido')),
      bottomNavigationBar: _buildBottomBar(cart),
      body: Column(
        children: [
          _buildOrderTypeSelector(),
          const Divider(height: 1),
          _buildCategorySelector(),
          Expanded(child: _buildMenuItems()),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartController cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              blurRadius: 4, offset: Offset(0, -1), color: Colors.black12)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Total: ${formatPEN(cart.totalCents)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          FilledButton.icon(
            onPressed: cart.isEmpty ? null : _submit,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Enviar Pedido'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Mesa'), icon: Icon(Icons.table_restaurant_outlined)),
                ButtonSegment(value: true, label: Text('Para Llevar'), icon: Icon(Icons.takeout_dining_outlined)),
              ],
              selected: {_isTakeout},
              onSelectionChanged: (selection) {
                setState(() => _isTakeout = selection.first);
              },
            ),
          ),
          if (!_isTakeout) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _tableCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mesa #', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return StreamBuilder<List<MenuCategory>>(
      stream: _menuService.watchCategories(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 52);
        final cats = snap.data!;
        if (_categoryId == null && cats.isNotEmpty) {
          _categoryId = cats.first.id;
        }
        return SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: cats.length,
            itemBuilder: (c, i) {
              final cgy = cats[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cgy.name),
                  selected: cgy.id == _categoryId,
                  onSelected: (_) => setState(() => _categoryId = cgy.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    if (_categoryId == null) {
      return const Center(child: Text('Selecciona una categoría'));
    }
    return Container(
      color: Theme.of(context).colorScheme.background.withOpacity(0.5),
      child: StreamBuilder<List<MenuItemModel>>(
        stream: _menuService.watchItemsByCategory(_categoryId!),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No hay ítems en esta categoría'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (c, i) => _MenuItemTile(item: items[i]),
          );
        },
      ),
    );
  }
}

// --- WIDGET DE ITEM DE MENÚ REDISEÑADO ---
class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final qty = cart.qty(item.id);
    final hasItem = qty > 0;
    final theme = Theme.of(context);

    Future<void> showSpecsModal() async {
      final specController = TextEditingController(text: cart.getSpec(item.id));
      final newSpec = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notas para "${item.name}"', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: specController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Ej: sin ají, término medio',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => Navigator.pop(ctx, value),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, specController.text),
                    child: const Text('Guardar'),
                  ),
                ],
              )
            ],
          ),
        ),
      );
      if (newSpec != null) {
        cart.setSpec(item.id, newSpec);
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: hasItem ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasItem ? theme.colorScheme.primary : Colors.grey.shade300,
          width: hasItem ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          cart.add(item);
        },
        onLongPress: hasItem ? () {
          HapticFeedback.mediumImpact();
          showSpecsModal();
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(formatPEN(item.priceCents), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    if (cart.getSpec(item.id) != null && cart.getSpec(item.id)!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('"${cart.getSpec(item.id)}"', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              ),
              if (hasItem)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        cart.dec(item.id);
                      },
                      color: theme.colorScheme.error,
                    ),
                    Text('$qty', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        cart.add(item);
                      },
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}