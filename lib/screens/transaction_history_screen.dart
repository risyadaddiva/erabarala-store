import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as model;
import '../models/transaction_detail.dart';
import '../widgets/currency_formatter.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                color: AppTheme.primaryYellow, size: 24),
            const SizedBox(width: 8),
            const Text('Riwayat Transaksi'),
          ],
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 72, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada transaksi',
                    style:
                        TextStyle(fontSize: 18, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final tx = provider.transactions[index];
              return _TransactionTile(transaction: tx, index: index);
            },
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final model.Transaction transaction;
  final int index;

  const _TransactionTile({required this.transaction, required this.index});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isCash = transaction.paymentMethod == 'Cash';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCash
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.purple.withValues(alpha: 0.2),
          child: Icon(
            isCash ? Icons.money : Icons.qr_code,
            color: isCash ? Colors.green : Colors.purple,
            size: 20,
          ),
        ),
        title: Text(
          formatRupiah(transaction.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(transaction.dateTime)} | ${transaction.paymentMethod}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
        onTap: () => _showTransactionDetail(context),
      ),
    );
  }

  Future<void> _showTransactionDetail(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final details = await provider.getTransactionDetails(transaction.id!);
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
    final isCash = transaction.paymentMethod == 'Cash';
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          transaction.paymentMethod,
                          style: TextStyle(
                            color: isCash
                                ? Colors.green.shade900
                                : Colors.purple.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: isCash
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.purple.withValues(alpha: 0.2),
                        side: BorderSide.none,
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
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryYellow.withValues(alpha: 0.15),
                      radius: 18,
                      child: Text(
                        '${detail.quantity}x',
                        style: TextStyle(
                          color: AppTheme.primaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      detail.itemName ?? 'Item #${detail.itemId}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${detail.quantity} x ${formatRupiah(detail.itemPrice ?? 0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      formatRupiah(detail.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                      ),
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
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatRupiah(transaction.totalAmount),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _printReceipt(context),
                      icon: const Icon(Icons.print_rounded),
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
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
