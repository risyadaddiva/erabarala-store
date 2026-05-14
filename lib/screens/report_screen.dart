import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../widgets/currency_formatter.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  double _totalRevenue = 0;
  int _transactionCount = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  DateTimeRange _getDateRange() {
    final now = _selectedDate;
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1)).subtract(
            const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.weekly:
        final weekday = now.weekday;
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        final end = start.add(const Duration(days: 7)).subtract(
            const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(
            const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final provider = context.read<TransactionProvider>();
    final range = _getDateRange();
    _totalRevenue =
        await provider.getTotalRevenue(range.start, range.end);
    _transactionCount =
        await provider.getTransactionCount(range.start, range.end);
    setState(() => _isLoading = false);
  }

  String _getPeriodLabel() {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final range = _getDateRange();
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return dateFormat.format(range.start);
      case ReportPeriod.weekly:
        return '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}';
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy', 'id_ID').format(range.start);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(
                  value: ReportPeriod.daily,
                  label: Text('Harian'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment(
                  value: ReportPeriod.weekly,
                  label: Text('Mingguan'),
                  icon: Icon(Icons.date_range),
                ),
                ButtonSegment(
                  value: ReportPeriod.monthly,
                  label: Text('Bulanan'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (selection) {
                setState(() => _selectedPeriod = selection.first);
                _loadReport();
              },
            ),
          ),

          // Date navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      switch (_selectedPeriod) {
                        case ReportPeriod.daily:
                          _selectedDate = _selectedDate
                              .subtract(const Duration(days: 1));
                          break;
                        case ReportPeriod.weekly:
                          _selectedDate = _selectedDate
                              .subtract(const Duration(days: 7));
                          break;
                        case ReportPeriod.monthly:
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month - 1,
                            1,
                          );
                          break;
                      }
                    });
                    _loadReport();
                  },
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadReport();
                    }
                  },
                  child: Text(
                    _getPeriodLabel(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      switch (_selectedPeriod) {
                        case ReportPeriod.daily:
                          _selectedDate =
                              _selectedDate.add(const Duration(days: 1));
                          break;
                        case ReportPeriod.weekly:
                          _selectedDate =
                              _selectedDate.add(const Duration(days: 7));
                          break;
                        case ReportPeriod.monthly:
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month + 1,
                            1,
                          );
                          break;
                      }
                    });
                    _loadReport();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary cards
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 48,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pendapatan Kotor',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(_totalRevenue),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Jumlah Transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_transactionCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rata-rata per Transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _transactionCount > 0
                                  ? formatRupiah(
                                      _totalRevenue / _transactionCount)
                                  : '-',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
