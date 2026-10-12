
import 'package:sqflite/sqflite.dart';
import 'local_database_service.dart';

class PresentationDataSeeder {
static Future<void> seedIfEmpty() async {
final db = await LocalDatabaseService.instance.database;

await db.transaction((txn) async {
final itemCount = Sqflite.firstIntValue(
await txn.rawQuery('SELECT COUNT(*) FROM presentation_items'),
);

if (itemCount == 0) {
await txn.insert('presentation_items', {
'id': 'item_rice',
'name': 'Rice',
'category': 'Food',
'imageUrl': '',
});

await txn.insert('presentation_items', {
'id': 'item_beans',
'name': 'Beans',
'category': 'Food',
'imageUrl': '',
});

await txn.insert('presentation_items', {
'id': 'item_notebook',
'name': 'Notebook',
'category': 'Stationery',
'imageUrl': '',
});

await txn.insert('presentation_items', {
'id': 'item_bread',
'name': 'Bread',
'category': 'Food',
'imageUrl': '',
});
}

final shopCount = Sqflite.firstIntValue(
await txn.rawQuery('SELECT COUNT(*) FROM presentation_shops'),
);

if (shopCount == 0) {
await txn.insert('presentation_shops', {
'id': 'shop_campus_mart',
'name': 'Campus Mart',
'university': 'UDUS',
'campus': 'Main Campus',
'location': 'Near the campus gate',
'isVerified': 1,
'createdBy': 'presentation_admin',
'isPotentialDuplicate': 0,
});

await txn.insert('presentation_shops', {
'id': 'shop_student_store',
'name': 'Student Store',
'university': 'UDUS',
'campus': 'Main Campus',
'location': 'Student area',
'isVerified': 1,
'createdBy': 'presentation_admin',
'isPotentialDuplicate': 0,
});
}

final priceCount = Sqflite.firstIntValue(
await txn.rawQuery('SELECT COUNT(*) FROM presentation_prices'),
);

if (priceCount == 0) {
final now = DateTime.now().toIso8601String();

await txn.insert('presentation_prices', {
'id': 'price_rice_mart',
'itemId': 'item_rice',
'shopId': 'shop_campus_mart',
'price': 1500.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
});

await txn.insert('presentation_prices', {
'id': 'price_rice_store',
'itemId': 'item_rice',
'shopId': 'shop_student_store',
'price': 1700.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
});

await txn.insert('presentation_prices', {
'id': 'price_beans_mart',
'itemId': 'item_beans',
'shopId': 'shop_campus_mart',
'price': 2200.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
});

await txn.insert('presentation_prices', {
'id': 'price_notebook_store',
'itemId': 'item_notebook',
'shopId': 'shop_student_store',
'price': 800.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
});

await txn.insert('presentation_prices', {
'id': 'price_bread_mart',
'itemId': 'item_bread',
'shopId': 'shop_campus_mart',
'price': 700.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
});
}
});
}
}

