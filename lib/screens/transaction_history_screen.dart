import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../models/transaction_detail.dart';
import '../widgets/currency_formatter.dart';
import '../services/printer_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.transactions.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada transaksi.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final tx = provider.transactions[index];
              return _TransactionTile(transaction: tx);
            },
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final model.Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.paymentMethod == 'Cash'
              ? Colors.green.shade100
              : Colors.purple.shade100,
          child: Icon(
            transaction.paymentMethod == 'Cash'
                ? Icons.money
                : Icons.qr_code,
            color: transaction.paymentMethod == 'Cash'
                ? Colors.green
                : Colors.purple,
          ),
        ),
        title: Text(
          formatRupiah(transaction.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(transaction.dateTime)} | ${transaction.paymentMethod}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showTransactionDetail(context),
      ),
    );
  }

  Future<void> _showTransactionDetail(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final details =
        await provider.getTransactionDetails(transaction.id!);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TransactionDetailSheet(
        transaction: transaction,
        details: details,
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final model.Transaction transaction;
  final List<TransactionDetail> details;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi #${transaction.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(transaction.paymentMethod),
                        backgroundColor:
                            transaction.paymentMethod == 'Cash'
                                ? Colors.green.shade100
                                : Colors.purple.shade100,
                      ),
                    ],
                  ),
                  Text(
                    dateFormat.format(transaction.dateTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: details.length,
                itemBuilder: (context, index) {
                  final detail = details[index];
                  return ListTile(
                    title: Text(detail.itemName ?? 'Item #${detail.itemId}'),
                    subtitle: Text(
                      '${detail.quantity} x ${formatRupiah(detail.itemPrice ?? 0)}',
                    ),
                    trailing: Text(
                      formatRupiah(detail.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatRupiah(transaction.totalAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _printReceipt(context),
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Nota'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final connected = await PrinterService.instance.isConnected();
      if (!connected) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Printer tidak terhubung. Hubungkan di menu Printer.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await PrinterService.instance.printReceipt(transaction, details);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota berhasil dicetak!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
