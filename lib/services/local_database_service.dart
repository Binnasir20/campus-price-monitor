
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
static final LocalDatabaseService instance =
LocalDatabaseService._internal();

static Database? _database;

LocalDatabaseService._internal();

Future<Database> get database async {
if (_database != null) {
return _database!;
}

_database = await _initDatabase();
return _database!;
}

Future<Database> _initDatabase() async {
final databasePath = await getDatabasesPath();
final path = join(databasePath, 'campus_price_monitor.db');

return openDatabase(
path,
version: 3,
onCreate: (db, version) async {
await _createTables(db);
await _seedPresentationDataIfEmpty(db);
},
onUpgrade: (db, oldVersion, newVersion) async {
if (oldVersion < 2) {
await db.execute('''
            ALTER TABLE presentation_prices
            ADD COLUMN reportedBy TEXT NOT NULL DEFAULT ''
          ''');

await db.execute('''
            ALTER TABLE presentation_price_reports
            RENAME TO presentation_price_reports_v1
          ''');

await db.execute('''
            CREATE TABLE presentation_price_reports (
              id TEXT PRIMARY KEY,
              itemId TEXT NOT NULL,
              shopId TEXT NOT NULL,
              university TEXT NOT NULL,
              price REAL NOT NULL,
              reportedBy TEXT NOT NULL,
              reportedAt TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              assignedAdminId TEXT
            )
          ''');

await db.execute('''
            INSERT INTO presentation_price_reports (
              id, itemId, shopId, university, price,
              reportedBy, reportedAt, status, assignedAdminId
            )
            SELECT
              id, itemId, shopId, 'UDUS', reportedPrice,
              reportedBy, createdAt, status, NULL
            FROM presentation_price_reports_v1
          ''');

await db.execute('''
            DROP TABLE presentation_price_reports_v1
          ''');
}

if (oldVersion < 3) {
await db.execute('''
            ALTER TABLE presentation_items
            ADD COLUMN imageUrl TEXT NOT NULL DEFAULT ''
          ''');

await db.execute('''
            ALTER TABLE presentation_shops
            ADD COLUMN location TEXT NOT NULL DEFAULT ''
          ''');

await db.execute('''
            ALTER TABLE presentation_shops
            ADD COLUMN isVerified INTEGER NOT NULL DEFAULT 1
          ''');

await db.execute('''
            ALTER TABLE presentation_shops
            ADD COLUMN createdBy TEXT NOT NULL DEFAULT 'admin'
          ''');

await db.execute('''
            ALTER TABLE presentation_shops
            ADD COLUMN latitude REAL
          ''');

await db.execute('''
            ALTER TABLE presentation_shops
            ADD COLUMN longitude REAL
          ''');

await db.execute('''
            ALTER TABLE presentation_shops
            ADD COLUMN isPotentialDuplicate INTEGER NOT NULL DEFAULT 0
          ''');
}
},
);
}

Future<void> _createTables(Database db) async {
await db.execute('''
      CREATE TABLE presentation_users (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        university TEXT NOT NULL,
        campus TEXT NOT NULL,
        isAdmin INTEGER NOT NULL DEFAULT 0
      )
    ''');

await db.execute('''
      CREATE TABLE presentation_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        imageUrl TEXT NOT NULL DEFAULT ''
      )
    ''');

await db.execute('''
      CREATE TABLE presentation_shops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        university TEXT NOT NULL,
        campus TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT '',
        isVerified INTEGER NOT NULL DEFAULT 1,
        createdBy TEXT NOT NULL DEFAULT 'admin',
        latitude REAL,
        longitude REAL,
        isPotentialDuplicate INTEGER NOT NULL DEFAULT 0
      )
    ''');

await db.execute('''
      CREATE TABLE presentation_prices (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        shopId TEXT NOT NULL,
        price REAL NOT NULL,
        university TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        reportedBy TEXT NOT NULL DEFAULT ''
      )
    ''');

await db.execute('''
      CREATE TABLE presentation_price_reports (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        shopId TEXT NOT NULL,
        university TEXT NOT NULL,
        price REAL NOT NULL,
        reportedBy TEXT NOT NULL,
        reportedAt TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        assignedAdminId TEXT
      )
    ''');

await db.execute('''
      CREATE TABLE presentation_complaints (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        shopId TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL
      )
    ''');
}

/// Public method: call when entering Offline Presentation Mode.
/// Seeds only empty tables and preserves existing records.
Future<void> seedPresentationDataIfEmpty() async {
final db = await database;
await _seedPresentationDataIfEmpty(db);
}

Future<void> _seedPresentationDataIfEmpty(Database db) async {
await db.transaction((txn) async {
// Users
final userCount = Sqflite.firstIntValue(
await txn.rawQuery(
'SELECT COUNT(*) FROM presentation_users',
),
) ??
0;

if (userCount == 0) {
await txn.insert('presentation_users', {
'uid': 'presentation_admin',
'name': 'Presentation Admin',
'email': 'admin@campus.local',
'university': 'UDUS',
'campus': 'Main Campus',
'isAdmin': 1,
});

await txn.insert('presentation_users', {
'uid': 'presentation_student',
'name': 'Presentation Student',
'email': 'student@campus.local',
'university': 'UDUS',
'campus': 'Main Campus',
'isAdmin': 0,
});
}

// Items
final itemCount = Sqflite.firstIntValue(
await txn.rawQuery(
'SELECT COUNT(*) FROM presentation_items',
),
) ??
0;

if (itemCount == 0) {
final items = [
{
'id': 'item_rice',
'name': 'Rice',
'category': 'Food',
'imageUrl': '',
},
{
'id': 'item_beans',
'name': 'Beans',
'category': 'Food',
'imageUrl': '',
},
{
'id': 'item_notebook',
'name': 'Notebook',
'category': 'Stationery',
'imageUrl': '',
},
{
'id': 'item_bread',
'name': 'Bread',
'category': 'Food',
'imageUrl': '',
},
];

for (final item in items) {
await txn.insert('presentation_items', item);
}
}

// Shops
final shopCount = Sqflite.firstIntValue(
await txn.rawQuery(
'SELECT COUNT(*) FROM presentation_shops',
),
) ??
0;

if (shopCount == 0) {
await txn.insert('presentation_shops', {
'id': 'shop_campus_mart',
'name': 'Campus Mart',
'university': 'UDUS',
'campus': 'Main Campus',
'location': 'Near the campus gate',
'isVerified': 1,
'createdBy': 'presentation_admin',
});

await txn.insert('presentation_shops', {
'id': 'shop_student_store',
'name': 'Student Store',
'university': 'UDUS',
'campus': 'Main Campus',
'location': 'Student area',
'isVerified': 1,
'createdBy': 'presentation_admin',
});
}

// Prices
final priceCount = Sqflite.firstIntValue(
await txn.rawQuery(
'SELECT COUNT(*) FROM presentation_prices',
),
) ??
0;

if (priceCount == 0) {
final now = DateTime.now().toIso8601String();

final prices = [
{
'id': 'price_rice_mart',
'itemId': 'item_rice',
'shopId': 'shop_campus_mart',
'price': 1500.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
},
{
'id': 'price_rice_store',
'itemId': 'item_rice',
'shopId': 'shop_student_store',
'price': 1700.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
},
{
'id': 'price_beans_mart',
'itemId': 'item_beans',
'shopId': 'shop_campus_mart',
'price': 2200.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
},
{
'id': 'price_notebook_store',
'itemId': 'item_notebook',
'shopId': 'shop_student_store',
'price': 800.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
},
{
'id': 'price_bread_mart',
'itemId': 'item_bread',
'shopId': 'shop_campus_mart',
'price': 700.0,
'university': 'UDUS',
'updatedAt': now,
'reportedBy': 'presentation_admin',
},
];

for (final price in prices) {
await txn.insert('presentation_prices', price);
}
}

// Student reports
final reportCount = Sqflite.firstIntValue(
await txn.rawQuery(
'SELECT COUNT(*) FROM presentation_price_reports',
),
) ??
0;

if (reportCount == 0) {
final now = DateTime.now().toIso8601String();

final reports = [
{
'id': 'report_rice_student',
'itemId': 'item_rice',
'shopId': 'shop_campus_mart',
'university': 'UDUS',
'price': 1600.0,
'reportedBy': 'presentation_student',
'reportedAt': now,
'status': 'pending',
'assignedAdminId': 'presentation_admin',
},
{
'id': 'report_beans_student',
'itemId': 'item_beans',
'shopId': 'shop_student_store',
'university': 'UDUS',
'price': 2300.0,
'reportedBy': 'presentation_student',
'reportedAt': now,
'status': 'approved',
'assignedAdminId': 'presentation_admin',
},
];

for (final report in reports) {
await txn.insert(
'presentation_price_reports',
report,
);
}
}
});
}
}