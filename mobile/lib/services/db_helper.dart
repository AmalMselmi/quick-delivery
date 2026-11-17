import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cart_item.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'cart.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cart(
            id INTEGER PRIMARY KEY,
            restaurantId INTEGER NOT NULL DEFAULT 0,
            name TEXT,
            price REAL,
            quantity INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE cart ADD COLUMN restaurantId INTEGER NOT NULL DEFAULT 0');
          await db.delete('cart');
        }
      },
    );
  }

  Future<List<CartItem>> getCartItems() async {
    final dbClient = await db;
    final res = await dbClient.query('cart');
    return res.map((e) => CartItem.fromMap(e)).toList();
  }

  Future<void> insertItem(CartItem item) async {
    final dbClient = await db;
    await dbClient.insert('cart', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(CartItem item) async {
    final dbClient = await db;
    await dbClient
        .update('cart', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(int id) async {
    final dbClient = await db;
    await dbClient.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart() async {
    final dbClient = await db;
    await dbClient.delete('cart');
  }
}