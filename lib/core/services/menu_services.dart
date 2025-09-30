// lib/services/menu_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_models.dart';

class MenuService {
  final _db = FirebaseFirestore.instance;

  Stream<List<MenuCategory>> watchCategories() {
    return _db
        .collection('menu_categories')
        .orderBy('sort')
        .snapshots()
        .map((s) => s.docs
        .map((d) => MenuCategory(
      id: d.id,
      name: (d.data()['name'] ?? '') as String,
      sort: (d.data()['sort'] ?? 0) as int,
    ))
        .toList());
  }

  Stream<List<MenuItemModel>> watchItemsByCategory(String categoryId) {
    return _db
        .collection('menu_items')
        .where('categoryId', isEqualTo: categoryId)
        .where('available', isEqualTo: true)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => MenuItemModel(
        id: d.id,
        name: (d.data()['name'] ?? '') as String,
        categoryId: (d.data()['categoryId'] ?? '') as String,
        priceCents: (d.data()['priceCents'] ?? 0) as int,
        tags: ((d.data()['tags'] ?? []) as List).cast<String>(),
        available: (d.data()['available'] ?? true) as bool,
      ))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }
}