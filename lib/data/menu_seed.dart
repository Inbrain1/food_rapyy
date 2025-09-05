import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedMenuIfEmpty() async {
  final db = FirebaseFirestore.instance;
  final catSnap = await db.collection('menu_categories').limit(1).get();
  if (catSnap.docs.isNotEmpty) return;
  final batch = db.batch();
  final cats = [
    {'id': 'carne', 'name': 'Platos de Carne', 'sort': 1},
    {'id': 'combinados_carne', 'name': 'Combinados (Carne)', 'sort': 2},
    {'id': 'pollo', 'name': 'Platos de Pollo', 'sort': 3},
    {'id': 'combinados_pollo', 'name': 'Combinados de Pollo', 'sort': 4},
    {'id': 'tortilla', 'name': 'Platos con Tortilla', 'sort': 5},
    {'id': 'verdura', 'name': 'Platos con Verdura', 'sort': 6},
    {'id': 'carta', 'name': 'A la carta', 'sort': 7},
    {'id': 'bebidas', 'name': 'Bebidas', 'sort': 8},
  ];
  for (final c in cats) {
    batch.set(db.collection('menu_categories').doc(c['id'] as String), {'name': c['name'], 'sort': c['sort']});
  }
  final items = [
    {'id':'arroz-chaufa','name':'Arroz Chaufa','categoryId':'carne','priceCents':900,'tags':['carne'],'available':true},
    {'id':'tallarin-saltado','name':'Tallarín Saltado','categoryId':'carne','priceCents':1000,'tags':['carne'],'available':true},
    {'id':'combo-chaufa-lomo','name':'Arroz Chaufa con Lomo Saltado','categoryId':'combinados_carne','priceCents':1100,'tags':['carne','combo'],'available':true},
    {'id':'combo-chaufa-tallarin','name':'Arroz Chaufa con Tallarín Saltado','categoryId':'combinados_carne','priceCents':1100,'tags':['carne','combo'],'available':true},
    {'id':'combo-lomo-tallarin','name':'Lomo Saltado con Tallarín Saltado','categoryId':'combinados_carne','priceCents':1200,'tags':['carne','combo'],'available':true},
    {'id':'triple-carne','name':'Triple de Carne','categoryId':'combinados_carne','priceCents':1500,'tags':['carne','combo'],'available':true},
    {'id':'chaufa-pollo','name':'Arroz Chaufa de Pollo','categoryId':'pollo','priceCents':900,'tags':['pollo'],'available':true},
    {'id':'tallarin-pollo','name':'Tallarín Saltado de Pollo','categoryId':'pollo','priceCents':1000,'tags':['pollo'],'available':true},
    {'id':'combo-chaufa-saltado-pollo','name':'Arroz Chaufa con Saltado de Pollo','categoryId':'combinados_pollo','priceCents':1100,'tags':['pollo','combo'],'available':true},
    {'id':'combo-chaufa-tallarin-pollo','name':'Arroz Chaufa con Tallarín Saltado de Pollo','categoryId':'combinados_pollo','priceCents':1100,'tags':['pollo','combo'],'available':true},
    {'id':'combo-doble-tallarin-pollo','name':'Tallarín Saltado de Pollo con Tallarín de Pollo','categoryId':'combinados_pollo','priceCents':1200,'tags':['pollo','combo'],'available':true},
    {'id':'chaufa-carne-tortilla','name':'Chaufa de Carne con Tortilla','categoryId':'tortilla','priceCents':1100,'tags':['carne','tortilla'],'available':true},
    {'id':'chaufa-pollo-tortilla','name':'Chaufa de Pollo con Tortilla','categoryId':'tortilla','priceCents':1100,'tags':['pollo','tortilla'],'available':true},
    {'id':'chaufa-lomo-tortilla','name':'Chaufa con Lomo Saltado + Tortilla','categoryId':'tortilla','priceCents':1300,'tags':['carne','tortilla','combo'],'available':true},
    {'id':'chaufa-tallarin-tortilla','name':'Chaufa con Tallarín Saltado + Tortilla','categoryId':'tortilla','priceCents':1300,'tags':['carne','tortilla','combo'],'available':true},
    {'id':'chaufa-pollo-verdura','name':'Chaufa de Pollo con verduras','categoryId':'verdura','priceCents':1100,'tags':['pollo','verdura'],'available':true},
    {'id':'chaufa-carne-verdura','name':'Chaufa de Carne con verdura','categoryId':'verdura','priceCents':1100,'tags':['carne','verdura'],'available':true},
    {'id':'chaufa-pollo-tortilla-verdura','name':'Chaufa de Pollo con tortilla de verduras','categoryId':'verdura','priceCents':1300,'tags':['pollo','tortilla','verdura'],'available':true},
    {'id':'chaufa-carne-tortilla-verdura','name':'Chaufa de Carne con tortilla de verduras','categoryId':'verdura','priceCents':1300,'tags':['carne','tortilla','verdura'],'available':true},
    {'id':'pollo-broaster','name':'Pollo Broaster','categoryId':'carta','priceCents':1000,'tags':['pollo'],'available':true},
    {'id':'aeropuerto','name':'Aeropuerto','categoryId':'carta','priceCents':1200,'tags':['mixto'],'available':true},
    {'id':'aeropuerto-mixto','name':'Aeropuerto mixto','categoryId':'carta','priceCents':1300,'tags':['mixto'],'available':true},
    {'id':'chaufa-tortilla-pollo','name':'Chaufa con tortilla de pollo','categoryId':'carta','priceCents':1400,'tags':['pollo','tortilla'],'available':true},
    {'id':'chaufa-mixto','name':'Chaufa Mixto','categoryId':'carta','priceCents':1000,'tags':['mixto'],'available':true},
    {'id':'limonada-1l','name':'Limonada 1L','categoryId':'bebidas','priceCents':700,'tags':['bebida'],'available':true},
    {'id':'gaseosa-litro','name':'Gaseosa de litro','categoryId':'bebidas','priceCents':800,'tags':['bebida'],'available':true},
    {'id':'gaseosa-personal','name':'Gaseosa Personal','categoryId':'bebidas','priceCents':200,'tags':['bebida'],'available':true},
    {'id':'mates','name':'Mates','categoryId':'bebidas','priceCents':150,'tags':['bebida','caliente'],'available':true},
  ];
  for (final it in items) {
    batch.set(db.collection('menu_items').doc(it['id'] as String), {
      'name': it['name'],
      'categoryId': it['categoryId'],
      'priceCents': it['priceCents'],
      'currency': 'PEN',
      'tags': it['tags'],
      'available': it['available'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}
