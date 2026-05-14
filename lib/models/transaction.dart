class Transaction {
  final int? id;
  final DateTime dateTime;
  final double totalAmount;
  final String paymentMethod; // 'Cash' or 'QRIS'

  Transaction({
    this.id,
    required this.dateTime,
    required this.totalAmount,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date_time': dateTime.toIso8601String(),
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      dateTime: DateTime.parse(map['date_time'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
    );
  }
}
