import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/item.dart';

class ItemProvider extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await _db.getAllItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(Item item) async {
    final id = await _db.insertItem(item);
    _items.add(item.copyWith(id: id));
    _items.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _items.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
