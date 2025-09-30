// =============================
// file: lib/models/menu_models.dart
// =============================
class MenuCategory {
  final String id;        // ej: 'carne', 'combinados_carne'
  final String name;      // etiqueta visible
  final int sort;         // orden
  const MenuCategory({required this.id, required this.name, required this.sort});
  Map<String, dynamic> toMap() => {'name': name, 'sort': sort};
}

class MenuItemModel {
  final String id;            // slug único: ej 'arroz-chaufa'
  final String name;          // nombre visible
  final String categoryId;    // referencia a MenuCategory.id
  final int priceCents;       // precio en céntimos PEN para evitar flotantes (900 = S/ 9.00)
  final List<String> tags;    // ej: ['carne','combo','tortilla']
  final bool available;
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.priceCents,
    this.tags = const [],
    this.available = true,
  });
  Map<String, dynamic> toMap() => {
    'name': name,
    'categoryId': categoryId,
    'priceCents': priceCents,
    'currency': 'PEN',
    'tags': tags,
    'available': available,
    'createdAt': DateTime.now().toIso8601String(),
  };
}

String formatPEN(int cents) {
  final soles = cents ~/ 100;
  final resto = (cents % 100).toString().padLeft(2, '0');
  return 'S/ $soles.$resto';
}
