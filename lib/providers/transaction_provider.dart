import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as model;
import '../models/transaction_detail.dart';
import '../models/cart_item.dart';

class TransactionProvider extends ChangeNotifier {
  List<model.Transaction> _transactions = [];
  bool _isLoading = false;

  List<model.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> checkout(
    List<CartItem> cartItems,
    double totalAmount,
    String paymentMethod,
  ) async {
    final transaction = model.Transaction(
      dateTime: DateTime.now(),
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
    );

    final details = cartItems.map((ci) {
      return TransactionDetail(
        transactionId: 0,
        itemId: ci.item.id!,
        quantity: ci.quantity,
        subtotal: ci.subtotal,
      );
    }).toList();

    final transactionId = await _db.insertTransaction(transaction, details);
    await loadTransactions();
    return transactionId;
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    _transactions = await _db.getAllTransactions();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _db.getTransactionsByDateRange(start, end);
  }

  Future<List<TransactionDetail>> getTransactionDetails(
      int transactionId) async {
    return await _db.getTransactionDetails(transactionId);
  }

  Future<double> getTotalRevenue(DateTime start, DateTime end) async {
    return await _db.getTotalRevenue(start, end);
  }

  Future<int> getTransactionCount(DateTime start, DateTime end) async {
    return await _db.getTransactionCount(start, end);
  }

  Future<int> getTotalQuantitySold(DateTime start, DateTime end) async {
    return await _db.getTotalQuantitySold(start, end);
  }

  Future<List<Map<String, dynamic>>> getItemSalesSummary(
      DateTime start, DateTime end) async {
    return await _db.getItemSalesSummary(start, end);
  }

  Future<List<model.Transaction>> getTransactionsByDateRangeAndItem(
    DateTime start,
    DateTime end,
    int itemId,
  ) async {
    return await _db.getTransactionsByDateRangeAndItem(start, end, itemId);
  }
}
