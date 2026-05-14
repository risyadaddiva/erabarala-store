import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/transaction.dart' as model;
import '../models/transaction_detail.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('erabarala_store.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_time TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items (id)
      )
    ''');
  }

  // ── Item CRUD ──

  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final result = await db.query('items', orderBy: 'name ASC');
    return result.map((map) => Item.fromMap(map)).toList();
  }

  Future<Item?> getItem(int id) async {
    final db = await database;
    final result = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Item.fromMap(result.first);
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Transaction Operations ──

  Future<int> insertTransaction(
    model.Transaction transaction,
    List<TransactionDetail> details,
  ) async {
    final db = await database;
    int transactionId = 0;
    await db.transaction((txn) async {
      transactionId = await txn.insert('transactions', transaction.toMap());
      for (final detail in details) {
        final detailMap = detail.toMap();
        detailMap['transaction_id'] = transactionId;
        await txn.insert('transaction_details', detailMap);
      }
    });
    return transactionId;
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await database;
    final result =
        await db.query('transactions', orderBy: 'date_time DESC');
    return result.map((map) => model.Transaction.fromMap(map)).toList();
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date_time DESC',
    );
    return result.map((map) => model.Transaction.fromMap(map)).toList();
  }

  Future<List<TransactionDetail>> getTransactionDetails(
      int transactionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT td.*, i.name as item_name, i.price as item_price
      FROM transaction_details td
      LEFT JOIN items i ON td.item_id = i.id
      WHERE td.transaction_id = ?
    ''', [transactionId]);
    return result.map((map) => TransactionDetail.fromMap(map)).toList();
  }

  Future<double> getTotalRevenue(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM transactions WHERE date_time >= ? AND date_time <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getTransactionCount(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE date_time >= ? AND date_time <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['count'] as int);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
