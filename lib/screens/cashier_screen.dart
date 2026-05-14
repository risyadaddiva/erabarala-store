import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/currency_formatter.dart';
import '../services/printer_service.dart';
import '../database/database_helper.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Badge(
                label: Text('${cart.itemCount}'),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: cart.itemCount > 0
                      ? () => _showCartSheet(context)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Cart summary bar
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.itemCount == 0) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Text(
                      '${cart.itemCount} item',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      formatRupiah(cart.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _showCartSheet(context),
                      child: const Text('Bayar'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Item list
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada barang.\nTambahkan di menu Kelola Barang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          formatRupiah(item.price),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, size: 32),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            context.read<CartProvider>().addToCart(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${item.name} ditambahkan ke keranjang'),
                                duration: const Duration(milliseconds: 800),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          context.read<CartProvider>().addToCart(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${item.name} ditambahkan ke keranjang'),
                              duration: const Duration(milliseconds: 800),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Keranjang',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Kosongkan',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: cart.cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cart.cartItems[index];
                        return ListTile(
                          title: Text(cartItem.item.name),
                          subtitle: Text(formatRupiah(cartItem.subtotal)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => cart.decrementQuantity(
                                    cartItem.item.id!),
                              ),
                              Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    cart.incrementQuantity(cartItem.item.id!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () =>
                                    cart.removeFromCart(cartItem.item.id!),
                              ),
                            ],
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
                              formatRupiah(cart.totalAmount),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: cart.cartItems.isNotEmpty
                                    ? () => _processPayment(context, 'Cash')
                                    : null,
                                icon: const Icon(Icons.money),
                                label: const Text('Cash'),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: cart.cartItems.isNotEmpty
                                    ? () => _processPayment(context, 'QRIS')
                                    : null,
                                icon: const Icon(Icons.qr_code),
                                label: const Text('QRIS'),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, String method) async {
    final cart = context.read<CartProvider>();
    final txProvider = context.read<TransactionProvider>();

    final transactionId = await txProvider.checkout(
      cart.cartItems,
      cart.totalAmount,
      method,
    );

    // Try to print receipt
    try {
      final printerConnected = await PrinterService.instance.isConnected();
      if (printerConnected) {
        final details = await DatabaseHelper.instance
            .getTransactionDetails(transactionId);
        final transactions = await DatabaseHelper.instance.getAllTransactions();
        final transaction =
            transactions.firstWhere((t) => t.id == transactionId);
        await PrinterService.instance.printReceipt(transaction, details);
      }
    } catch (_) {
      // Printer not connected, skip silently
    }

    cart.clearCart();

    if (context.mounted) {
      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi #$transactionId berhasil! ($method)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
