import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  double get totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(Item item) {
    final index = _cartItems.indexWhere((ci) => ci.item.id == item.id);
    if (index != -1) {
      _cartItems[index].quantity++;
    } else {
      _cartItems.add(CartItem(item: item));
    }
    notifyListeners();
  }

  void removeFromCart(int itemId) {
    _cartItems.removeWhere((ci) => ci.item.id == itemId);
    notifyListeners();
  }

  void incrementQuantity(int itemId) {
    final index = _cartItems.indexWhere((ci) => ci.item.id == itemId);
    if (index != -1) {
      _cartItems[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int itemId) {
    final index = _cartItems.indexWhere((ci) => ci.item.id == itemId);
    if (index != -1) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
