import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/item_provider.dart';
import '../models/transaction.dart' as model;
import '../widgets/currency_formatter.dart';
import '../theme/app_theme.dart';

enum ReportPeriod { daily, monthly, custom }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  double _totalRevenue = 0;
  int _transactionCount = 0;
  int _totalQuantitySold = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  DateTime? _customStart;
  DateTime? _customEnd;
  int? _selectedItemId;
  List<model.Transaction> _transactions = [];
  List<Map<String, dynamic>> _itemSales = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
      _loadReport();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  DateTimeRange _getDateRange() {
    final now = _selectedDate;
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.custom:
        final start = _customStart ?? DateTime(now.year, now.month, now.day);
        final end = _customEnd ??
            DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
        );
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    _animController.reset();
    try {
      final provider = context.read<TransactionProvider>();
      final range = _getDateRange();
      _totalRevenue = await provider.getTotalRevenue(range.start, range.end);
      _transactionCount =
          await provider.getTransactionCount(range.start, range.end);
      _totalQuantitySold =
          await provider.getTotalQuantitySold(range.start, range.end);
      _itemSales = await provider.getItemSalesSummary(range.start, range.end);

      if (_selectedItemId != null) {
        _transactions = await provider.getTransactionsByDateRangeAndItem(
            range.start, range.end, _selectedItemId!);
      } else {
        _transactions =
            await provider.getTransactionsByDateRange(range.start, range.end);
      }
    } catch (e) {
      _totalRevenue = 0;
      _transactionCount = 0;
      _totalQuantitySold = 0;
      _transactions = [];
      _itemSales = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  String _getPeriodLabel() {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final range = _getDateRange();
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return dateFormat.format(range.start);
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy', 'id_ID').format(range.start);
      case ReportPeriod.custom:
        return '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryYellow,
                  onPrimary: AppTheme.darkGray,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadReport();
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryYellow,
                  onPrimary: AppTheme.darkGray,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: AppTheme.primaryYellow, size: 24),
            const SizedBox(width: 8),
            const Text('Laporan Keuangan'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(
                  value: ReportPeriod.daily,
                  label: Text('Harian'),
                  icon: Icon(Icons.today, size: 18),
                ),
                ButtonSegment(
                  value: ReportPeriod.monthly,
                  label: Text('Bulanan'),
                  icon: Icon(Icons.calendar_month, size: 18),
                ),
                ButtonSegment(
                  value: ReportPeriod.custom,
                  label: Text('Custom'),
                  icon: Icon(Icons.date_range, size: 18),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (selection) {
                setState(() => _selectedPeriod = selection.first);
                if (selection.first == ReportPeriod.custom) {
                  _pickCustomDateRange();
                } else {
                  _loadReport();
                }
              },
            ),
          ),

          // Date navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedPeriod != ReportPeriod.custom)
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      setState(() {
                        switch (_selectedPeriod) {
                          case ReportPeriod.daily:
                            _selectedDate = _selectedDate
                                .subtract(const Duration(days: 1));
                            break;
                          case ReportPeriod.monthly:
                            _selectedDate = DateTime(
                                _selectedDate.year, _selectedDate.month - 1, 1);
                            break;
                          case ReportPeriod.custom:
                            break;
                        }
                      });
                      _loadReport();
                    },
                  )
                else
                  const SizedBox(width: 48),
                GestureDetector(
                  onTap: _selectedPeriod == ReportPeriod.custom
                      ? _pickCustomDateRange
                      : _pickDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: AppTheme.primaryYellow),
                        const SizedBox(width: 8),
                        Text(
                          _getPeriodLabel(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedPeriod != ReportPeriod.custom)
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () {
                      setState(() {
                        switch (_selectedPeriod) {
                          case ReportPeriod.daily:
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                            break;
                          case ReportPeriod.monthly:
                            _selectedDate = DateTime(
                                _selectedDate.year, _selectedDate.month + 1, 1);
                            break;
                          case ReportPeriod.custom:
                            break;
                        }
                      });
                      _loadReport();
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),

          // Item filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<ItemProvider>(
              builder: (context, itemProvider, _) {
                final items = itemProvider.items;
                return DropdownButtonFormField<int?>(
                  initialValue: _selectedItemId,
                  decoration: InputDecoration(
                    labelText: 'Filter Barang',
                    prefixIcon: const Icon(Icons.filter_list_rounded),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Barang'),
                    ),
                    ...items.map((item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedItemId = value);
                    _loadReport();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Content
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Summary row 1
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: Colors.green,
                              label: 'Pendapatan',
                              value: formatRupiah(_totalRevenue),
                              valueColor: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.receipt_long_rounded,
                              iconColor: Colors.blue,
                              label: 'Transaksi',
                              value: '$_transactionCount',
                              valueColor: Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Summary row 2
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.shopping_bag_rounded,
                              iconColor: Colors.orange,
                              label: 'Produk Terjual',
                              value: '$_totalQuantitySold',
                              valueColor: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.trending_up_rounded,
                              iconColor: AppTheme.primaryYellow,
                              label: 'Rata-rata/Transaksi',
                              value: _transactionCount > 0
                                  ? formatRupiah(
                                      _totalRevenue / _transactionCount)
                                  : 'Rp 0',
                              valueColor: AppTheme.primaryYellow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Item sales breakdown
                      if (_itemSales.isNotEmpty && _selectedItemId == null) ...[
                        Row(
                          children: [
                            const Text(
                              'Penjualan per Barang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_itemSales.where((s) => (s['qty_sold'] as num) > 0).length} barang terjual',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          _itemSales
                              .where((s) => (s['qty_sold'] as num) > 0)
                              .length,
                          (i) {
                            final sale = _itemSales
                                .where((s) => (s['qty_sold'] as num) > 0)
                                .toList()[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryYellow
                                      .withValues(alpha: 0.15),
                                  radius: 18,
                                  child: Text(
                                    '${sale['qty_sold']}',
                                    style: TextStyle(
                                      color: AppTheme.primaryYellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  sale['name'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                trailing: Text(
                                  formatRupiah(
                                      (sale['total_revenue'] as num)
                                          .toDouble()),
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Transaction list for the period
                      if (_transactions.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              'Detail Transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_transactions.length} transaksi',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_transactions.length, (i) {
                          final tx = _transactions[i];
                          final dateFormat = DateFormat('dd/MM HH:mm');
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300 + i * 50),
                            curve: Curves.easeOut,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      tx.paymentMethod == 'Cash'
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : Colors.purple
                                              .withValues(alpha: 0.2),
                                  child: Icon(
                                    tx.paymentMethod == 'Cash'
                                        ? Icons.money
                                        : Icons.qr_code,
                                    color: tx.paymentMethod == 'Cash'
                                        ? Colors.green
                                        : Colors.purple,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  formatRupiah(tx.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  dateFormat.format(tx.dateTime),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Chip(
                                  label: Text(
                                    tx.paymentMethod,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          );
                        }),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 64,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi\npada periode ini',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
