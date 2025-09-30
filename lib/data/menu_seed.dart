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
  }final items = [
    // Platos de Carne
    {'id':'arroz-chaufa-carne','name':'Arroz Chaufa de Carne','categoryId':'carne','priceCents':900,'tags':['carne'],'available':true},
    {'id':'tallarin-saltado-carne','name':'Tallarín Saltado de Carne','categoryId':'carne','priceCents':1000,'tags':['carne'],'available':true},

    // Combinados de Carne
    {'id':'combo-chaufa-lomo','name':'Arroz Chaufa con lomo saltado','categoryId':'combinados_carne','priceCents':1000,'tags':['carne','combo'],'available':true},
    {'id':'combo-chaufa-tallarin-carne','name':'Arroz Chaufa con tallarin saltado','categoryId':'combinados_carne','priceCents':1100,'tags':['carne','combo'],'available':true},
    {'id':'combo-lomo-tallarin','name':'Lomo Saltado con Tallarin Saltado','categoryId':'combinados_carne','priceCents':1300,'tags':['carne','combo'],'available':true},
    {'id':'triple-carne','name':'Triple de Carne','categoryId':'combinados_carne','priceCents':1500,'tags':['carne','combo'],'available':true},

    // Platos de Pollo
    {'id':'chaufa-pollo','name':'Arroz Chaufa de Pollo','categoryId':'pollo','priceCents':900,'tags':['pollo'],'available':true},
    {'id':'tallarin-pollo','name':'Tallarin Saltado de Pollo','categoryId':'pollo','priceCents':1000,'tags':['pollo'],'available':true},

    // Combinados de Pollo
    {'id':'combo-chaufa-saltado-pollo','name':'Arroz Chaufa con saltado de Pollo','categoryId':'combinados_pollo','priceCents':1000,'tags':['pollo','combo'],'available':true},
    {'id':'combo-chaufa-tallarin-pollo','name':'Arroz Chaufa con tallarin saltado de Pollo','categoryId':'combinados_pollo','priceCents':1100,'tags':['pollo','combo'],'available':true},
    {'id':'combo-saltado-tallarin-pollo','name':'Saltado de Pollo con Tallarin de Pollo','categoryId':'combinados_pollo','priceCents':1300,'tags':['pollo','combo'],'available':true},
    {'id':'triple-pollo','name':'Triple de Pollo','categoryId':'combinados_pollo','priceCents':1500,'tags':['pollo','combo'],'available':true},

    // Platos con Tortilla
    {'id':'chaufa-carne-tortilla','name':'Chaufa de Carne con tortilla','categoryId':'tortilla','priceCents':1100,'tags':['carne','tortilla'],'available':true},
    {'id':'chaufa-pollo-tortilla','name':'Chaufa de Pollo con tortilla','categoryId':'tortilla','priceCents':1100,'tags':['pollo','tortilla'],'available':true},
    {'id':'chaufa-lomo-tortilla','name':'Chaufa con Lomo saltado + tortilla','categoryId':'tortilla','priceCents':1300,'tags':['carne','tortilla','combo'],'available':true},
    {'id':'chaufa-saltado-pollo-tortilla','name':'Chaufa con Saltado de Pollo + Tortilla','categoryId':'tortilla','priceCents':1300,'tags':['pollo','tortilla','combo'],'available':true},
    {'id':'chaufa-tallarin-saltado-tortilla','name':'Chaufa con tallarin saltado + tortilla','categoryId':'tortilla','priceCents':1300,'tags':['carne','tortilla','combo'],'available':true},

    // Platos con Verdura
    {'id':'chaufa-pollo-verdura','name':'Chaufa de Pollo con verduras','categoryId':'verdura','priceCents':1100,'tags':['pollo','verdura'],'available':true},
    {'id':'chaufa-carne-verdura','name':'Chaufa de Carne con verdura','categoryId':'verdura','priceCents':1100,'tags':['carne','verdura'],'available':true},
    {'id':'chaufa-pollo-tortilla-verdura','name':'Chaufa de Pollo con tortilla de verduras','categoryId':'verdura','priceCents':1300,'tags':['pollo','tortilla','verdura'],'available':true},
    {'id':'chaufa-carne-tortilla-verdura','name':'Chaufa Carne con Tortilla de Verduras','categoryId':'verdura','priceCents':1300,'tags':['carne','tortilla','verdura'],'available':true},

    // A la Carta
    {'id':'pollo-broaster','name':'Pollo Broaster','categoryId':'carta','priceCents':1000,'tags':['pollo'],'available':true},
    {'id':'aeropuerto-pollo','name':'Aeropuerto de Pollo','categoryId':'carta','priceCents':1200,'tags':['pollo'],'available':true},
    {'id':'aeropuerto-mixto','name':'Aeropuerto mixto','categoryId':'carta','priceCents':1300,'tags':['mixto'],'available':true},
    {'id':'chaufa-pollo-tortilla-pollo','name':'Chaufa de Pollo + Tortilla de pollo','categoryId':'carta','priceCents':1400,'tags':['pollo','tortilla'],'available':true},
    {'id':'chaufa-mixto','name':'Chaufa Mixto','categoryId':'carta','priceCents':1000,'tags':['mixto'],'available':true},

    // Bebidas
    {'id':'limonada-1l','name':'Limonada 1 Litro','categoryId':'bebidas','priceCents':700,'tags':['bebida'],'available':true},
    {'id':'gaseosa-litro','name':'Gaseosa de Litro','categoryId':'bebidas','priceCents':800,'tags':['bebida'],'available':true},
    {'id':'gaseosa-2l','name':'Gaseosa de 2 Litros','categoryId':'bebidas','priceCents':1100,'tags':['bebida'],'available':true},
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
