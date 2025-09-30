import 'package:flutter/material.dart';

class BlockingLoader extends StatelessWidget {
  const BlockingLoader({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Muestra un overlay bloqueante mientras corre [task].
Future<T> runWithBlockingLoader<T>(
    BuildContext context,
    Future<T> Function() task,
    ) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder: (_) => const BlockingLoader(),
  );
  try {
    return await task();
  } finally {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
