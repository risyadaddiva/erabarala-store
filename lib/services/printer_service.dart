import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../models/transaction_detail.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._init();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  PrinterService._init();

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await _printer.getBondedDevices();
  }

  Future<bool> isConnected() async {
    return await _printer.isConnected ?? false;
  }

  Future<void> connect(BluetoothDevice device) async {
    await _printer.connect(device);
  }

  Future<void> disconnect() async {
    await _printer.disconnect();
  }

  Future<void> printReceipt(
    model.Transaction transaction,
    List<TransactionDetail> details,
  ) async {
    final connected = await isConnected();
    if (!connected) {
      throw Exception('Printer tidak terhubung');
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    _printer.printNewLine();
    _printer.printCustom('ERABARALA STORE', 3, 1);
    _printer.printCustom('================================', 1, 1);
    _printer.printNewLine();

    _printer.printCustom(
      'Tanggal: ${dateFormat.format(transaction.dateTime)}',
      1,
      0,
    );
    _printer.printCustom('No: #${transaction.id}', 1, 0);
    _printer.printCustom(
      'Bayar: ${transaction.paymentMethod}',
      1,
      0,
    );
    _printer.printCustom('--------------------------------', 1, 0);

    for (final detail in details) {
      final name = detail.itemName ?? 'Item #${detail.itemId}';
      _printer.printCustom(name, 1, 0);
      _printer.printCustom(
        '  ${detail.quantity} x ${currencyFormat.format(detail.itemPrice ?? 0)} = ${currencyFormat.format(detail.subtotal)}',
        1,
        0,
      );
    }

    _printer.printCustom('--------------------------------', 1, 0);
    _printer.printCustom(
      'TOTAL: ${currencyFormat.format(transaction.totalAmount)}',
      2,
      2,
    );
    _printer.printCustom('================================', 1, 1);
    _printer.printCustom('Terima kasih!', 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.printNewLine();
  }
}
