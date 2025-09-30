import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/orders_service.dart';
import '../../../utils/money.dart';
import '../view_models/history_view_model.dart';

class WaiterHistoryScreen extends StatelessWidget {
  const WaiterHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HistoryViewModel(ctx.read<OrdersService>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial de Pedidos')),
        body: Consumer<HistoryViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (viewModel.historyDays.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aún no hay pedidos pagados', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            final days = viewModel.historyDays;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              itemBuilder: (_, idx) {
                final day = days[idx];
                // Envolvemos la tarjeta en un widget de animación
                return _AnimatedFadeIn(
                  delay: Duration(milliseconds: 100 * idx),
                  child: _HistoryDayCard(day: day),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- WIDGET DE TARJETA REDISEÑADO CON EXPANSIONTILE ---
class _HistoryDayCard extends StatelessWidget {
  const _HistoryDayCard({required this.day});
  final HistoryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // El encabezado que siempre es visible
        title: Text(
          _formatDay(day.date),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Total del día: ${formatPEN(day.totalCents)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        // El contenido que se muestra al expandir
        children: day.orders.map((orderDoc) {
          final data = orderDoc.data();
          final table = (data['table'] ?? '').toString();
          final isTakeout = (data['takeout'] ?? false) as bool;
          final total = (data['totalCents'] ?? 0) as int;
          final paidAt = (data['paidAt'] as Timestamp).toDate().toLocal();
          final method = (data['payment']?['method'] ?? 'yape').toString();

          return ListTile(
            leading: Icon(method == 'cash' ? Icons.money_rounded : Icons.phone_iphone_rounded),
            title: Text(isTakeout ? 'Para Llevar' : 'Mesa $table'),
            subtitle: Text('Pagado a las ${_hhmm(paidAt)}'),
            trailing: Text(formatPEN(total), style: const TextStyle(fontWeight: FontWeight.bold)),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  String _formatDay(DateTime d) {
    // Podríamos usar un paquete como `intl` para un formato más robusto
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _hhmm(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// --- WIDGET GENÉRICO PARA ANIMACIÓN DE ENTRADA ---
class _AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedFadeIn({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}