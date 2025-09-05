// lib/screeens/waiter_order_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaiterOrderDetailScreen extends StatefulWidget {
  const WaiterOrderDetailScreen({super.key, required this.orderRef});
  final DocumentReference<Map<String, dynamic>> orderRef;

  @override
  State<WaiterOrderDetailScreen> createState() => _WaiterOrderDetailScreenState();
}

class _WaiterOrderDetailScreenState extends State<WaiterOrderDetailScreen> {
  String _method = 'efectivo'; // 'efectivo' | 'yape'
  final _cashCtrl = TextEditingController();
  final _yapeRefCtrl = TextEditingController();
  final _manualTotalCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _yapeRefCtrl.dispose();
    _manualTotalCtrl.dispose();
    super.dispose();
  }

  String _pen(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

  int? _totalFromData(Map<String, dynamic> data) {
    final t = data['totalCents'];
    if (t is int) return t;
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    int sum = 0;
    bool hasLines = false;
    for (final it in items) {
      if (it['lineCents'] is int) {
        sum += it['lineCents'] as int;
        hasLines = true;
      }
    }
    return hasLines ? sum : null;
  }

  int _toCents(String v) {
    final d = double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;
    return (d * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: widget.orderRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!.data() ?? {};
        final table = (data['table'] ?? '').toString();
        final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        final totalFromDoc = _totalFromData(data);
        final paymentStatus = (data['paymentStatus'] ?? 'pendiente').toString();
        final status = (data['status'] ?? 'pendiente').toString();

        if (totalFromDoc == null && _manualTotalCtrl.text.isEmpty) {
          _manualTotalCtrl.text = '';
        }

        final totalCents = totalFromDoc ?? (_manualTotalCtrl.text.isEmpty ? null : _toCents(_manualTotalCtrl.text));

        int changeCents = 0;
        if (_method == 'efectivo' && totalCents != null) {
          final cash = _toCents(_cashCtrl.text);
          changeCents = (cash - totalCents).clamp(0, 1 << 31);
        }

        final isPending = paymentStatus != 'pagado' && status == 'pendiente';

        return Scaffold(
          appBar: AppBar(title: const Text('Detalle del pedido')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Row(children: [
                  Expanded(child: Text('Mesa $table', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  Chip(label: Text(isPending ? 'pendiente' : status)),
                ]),
                const SizedBox(height: 12),
                const Text('Ítems', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final it in items)
                        ListTile(
                          dense: true,
                          title: Text(it['name']?.toString() ?? ''),
                          subtitle: it['unitCents'] is int
                              ? Text('${it['qty'] ?? 1} x ${_pen(it['unitCents'] as int)}')
                              : Text('Cantidad: ${it['qty'] ?? 1}'),
                          trailing: it['lineCents'] is int ? Text(_pen(it['lineCents'] as int)) : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (totalFromDoc == null) ...[
                  const Text('Total (no encontrado en el pedido)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _manualTotalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Total S/', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                ] else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Total: ', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(_pen(totalFromDoc), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                const SizedBox(height: 16),
                if (isPending) ...[
                  const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: const Text('Efectivo'), selected: _method == 'efectivo', onSelected: (_) => setState(() => _method = 'efectivo')),
                      ChoiceChip(label: const Text('Yape'), selected: _method == 'yape', onSelected: (_) => setState(() => _method = 'yape')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_method == 'efectivo') ...[
                    TextField(
                      controller: _cashCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Recibido S/', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    if (totalCents != null)
                      Align(alignment: Alignment.centerRight, child: Text('Vuelto: ${_pen(changeCents)}')),
                  ] else ...[
                    TextField(controller: _yapeRefCtrl, decoration: const InputDecoration(labelText: 'Referencia Yape', border: OutlineInputBorder())),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _cancelPending,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancelar pendiente'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: (_canConfirm(totalCents)) ? () => _confirmPayment(data, totalCents!, changeCents) : null,
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Cobrar'),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text('Pedido finalizado', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canConfirm(int? totalCents) {
    if (_saving) return false;
    if (totalCents == null) return false;
    if (_method == 'efectivo') {
      final cash = _toCents(_cashCtrl.text);
      return cash >= totalCents;
    } else {
      return _yapeRefCtrl.text.trim().isNotEmpty;
    }
  }

  Future<void> _cancelPending() async {
    setState(() => _saving = true);
    try {
      await widget.orderRef.update({
        'status': 'anulado',
        'paymentStatus': 'cancelado',
        'canceledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido cancelado')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmPayment(Map<String, dynamic> data, int totalCents, int changeCents) async {
    setState(() => _saving = true);
    try {
      final payment = {
        'method': _method,
        'amountCents': totalCents,
        'cashReceivedCents': _method == 'efectivo' ? _toCents(_cashCtrl.text) : 0,
        'changeCents': _method == 'efectivo' ? changeCents : 0,
        'yapeRef': _method == 'yape' ? _yapeRefCtrl.text.trim() : null,
      };

      await widget.orderRef.update({
        'paymentStatus': 'pagado',
        'status': 'cancelado', // “cancelar” en sentido de pagar/cerrar
        'totalCents': totalCents,
        'payment': payment,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await FirebaseFirestore.instance.collection('payments').add({
          'orderId': widget.orderRef.id,
          'table': data['table'],
          'amountCents': totalCents,
          'method': _method,
          'items': (data['items'] ?? []),
          'paidAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}