import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/currency_formatter.dart';
import '../services/printer_service.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Erabarala Gas Stove'),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      RotationTransition(turns: anim, child: child),
                  child: Icon(
                    themeProvider.isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    key: ValueKey(themeProvider.isDark),
                  ),
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Badge(
                label: Text(
                  '${cart.itemCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                isLabelVisible: cart.itemCount > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_rounded),
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
          // Cart summary bar (animated)
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: cart.itemCount > 0 ? 56 : 0,
                curve: Curves.easeInOut,
                child: cart.itemCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryYellow.withValues(alpha: 0.2),
                              AppTheme.accentGold.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shopping_bag_rounded,
                                color: AppTheme.primaryYellow, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${cart.itemCount} item',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const Spacer(),
                            Text(
                              formatRupiah(cart.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.primaryYellow,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () => _showCartSheet(context),
                              child: const Text('Bayar'),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          // Item grid
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded,
                            size: 72, color: Colors.grey.shade600),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada barang',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan di menu Barang',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return _ItemCard(
                      name: item.name,
                      price: item.price,
                      imagePath: item.imagePath,
                      onTap: () {
                        context.read<CartProvider>().addToCart(item);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('${item.name} +1'),
                              ],
                            ),
                            duration: const Duration(milliseconds: 600),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      },
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
                  // Handle bar
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
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_rounded,
                            color: AppTheme.primaryYellow),
                        const SizedBox(width: 8),
                        const Text(
                          'Keranjang',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_sweep,
                              color: Colors.redAccent, size: 18),
                          label: const Text('Kosongkan',
                              style: TextStyle(color: Colors.redAccent)),
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
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: ListTile(
                            title: Text(
                              cartItem.item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              formatRupiah(cartItem.subtotal),
                              style: TextStyle(color: AppTheme.primaryYellow),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CircleButton(
                                  icon: Icons.remove,
                                  onTap: () => cart
                                      .decrementQuantity(cartItem.item.id!),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _CircleButton(
                                  icon: Icons.add,
                                  onTap: () => cart
                                      .incrementQuantity(cartItem.item.id!),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      cart.removeFromCart(cartItem.item.id!),
                                ),
                              ],
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
                              formatRupiah(cart.totalAmount),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
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
    } catch (_) {}

    cart.clearCart();

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Transaksi #$transactionId berhasil! ($method)'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }
}

class _ItemCard extends StatelessWidget {
  final String name;
  final double price;
  final String? imagePath;
  final VoidCallback onTap;

  const _ItemCard({
    required this.name,
    required this.price,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && File(imagePath!).existsSync();
    final cardColor = Theme.of(context).cardTheme.color ?? AppTheme.cardDark;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryYellow.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.primaryYellow.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: hasImage ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              formatRupiah(price),
                              style: TextStyle(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add_rounded,
                                size: 18, color: AppTheme.primaryYellow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryYellow.withValues(alpha: 0.2),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryYellow),
      ),
    );
  }
}
