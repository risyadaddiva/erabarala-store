class TransactionDetail {
  final int? id;
  final int transactionId;
  final int itemId;
  final int quantity;
  final double subtotal;
  final String? itemName;
  final double? itemPrice;

  TransactionDetail({
    this.id,
    required this.transactionId,
    required this.itemId,
    required this.quantity,
    required this.subtotal,
    this.itemName,
    this.itemPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'item_id': itemId,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    return TransactionDetail(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      itemId: map['item_id'] as int,
      quantity: map['quantity'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
      itemName: map['item_name'] as String?,
      itemPrice: map['item_price'] != null
          ? (map['item_price'] as num).toDouble()
          : null,
    );
  }
}
