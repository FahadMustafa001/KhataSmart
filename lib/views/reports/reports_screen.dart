import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../models/ledger_entry_model.dart';
import '../../models/purchase_invoice_model.dart';
import '../../routes/app_routes.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../services/csv_export_service.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../shared_widgets/smart_bottom_navigation_bar.dart';

enum ReportPeriod { today, week, month, year }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with WidgetsBindingObserver {
  ReportPeriod _selectedPeriod = ReportPeriod.today;
  int _selectedActivityTab = 0; // 0: Sales Bills, 1: Purchase Bills
  String _paymentFilter = 'All'; // All, Cash, Online / Digital, Udhar / Credit
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _dateRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KhataState.instance.addListener(_refresh);
    ShopState.instance.addListener(_refresh);
    InventoryState.instance.addListener(_refresh);
    _dateRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    KhataState.instance.removeListener(_refresh);
    ShopState.instance.removeListener(_refresh);
    InventoryState.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  static bool _isInCurrentCalendarWeek(DateTime date, DateTime now) {
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    return !date.isBefore(monday) && date.isBefore(nextMonday);
  }

  // Filter orders strictly for the active shop and selected time period
  List<OrderModel> _getFilteredOrders() {
    final now = DateTime.now();
    final allOrders = KhataState.instance.orders;

    return allOrders.where((o) {
      switch (_selectedPeriod) {
        case ReportPeriod.today:
          return o.date.year == now.year &&
              o.date.month == now.month &&
              o.date.day == now.day;
        case ReportPeriod.week:
          return _isInCurrentCalendarWeek(o.date, now);
        case ReportPeriod.month:
          return o.date.year == now.year && o.date.month == now.month;
        case ReportPeriod.year:
          return o.date.year == now.year;
      }
    }).toList();
  }

  // Filter purchase bills strictly for the active shop and selected time period
  List<PurchaseInvoiceModel> _getFilteredPurchases() {
    final now = DateTime.now();
    final allPurchases = InventoryState.instance.purchases;

    return allPurchases.where((p) {
      switch (_selectedPeriod) {
        case ReportPeriod.today:
          return p.date.year == now.year &&
              p.date.month == now.month &&
              p.date.day == now.day;
        case ReportPeriod.week:
          return _isInCurrentCalendarWeek(p.date, now);
        case ReportPeriod.month:
          return p.date.year == now.year && p.date.month == now.month;
        case ReportPeriod.year:
          return p.date.year == now.year;
      }
    }).toList();
  }

  // Filter ledger entries strictly for the active shop and selected period
  List<LedgerEntryModel> _getFilteredEntries() {
    final now = DateTime.now();
    final allEntries = KhataState.instance.entries;

    return allEntries.where((e) {
      switch (_selectedPeriod) {
        case ReportPeriod.today:
          return e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day;
        case ReportPeriod.week:
          return _isInCurrentCalendarWeek(e.date, now);
        case ReportPeriod.month:
          return e.date.year == now.year && e.date.month == now.month;
        case ReportPeriod.year:
          return e.date.year == now.year;
      }
    }).toList();
  }

  // Real breakdown calculation for graph bars
  List<Map<String, dynamic>> _calculateRealBarData(List<OrderModel> orders) {
    if (_selectedPeriod == ReportPeriod.today) {
      // 4 Time slots of the day
      double morning = 0, afternoon = 0, evening = 0, night = 0;
      for (var o in orders) {
        final h = o.date.hour;
        if (h >= 6 && h < 12) {
          morning += o.total;
        } else if (h >= 12 && h < 17) {
          afternoon += o.total;
        } else if (h >= 17 && h < 21) {
          evening += o.total;
        } else {
          night += o.total;
        }
      }
      return [
        {'label': 'Morning', 'amount': morning},
        {'label': 'Afternoon', 'amount': afternoon},
        {'label': 'Evening', 'amount': evening},
        {'label': 'Night', 'amount': night},
      ];
    } else if (_selectedPeriod == ReportPeriod.week) {
      // 7 days of the week: Mon to Sun
      final amounts = List<double>.filled(7, 0.0);
      for (var o in orders) {
        final dayIdx = (o.date.weekday - 1).clamp(0, 6);
        amounts[dayIdx] += o.total;
      }
      final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return List.generate(7, (i) => {'label': labels[i], 'amount': amounts[i]});
    } else if (_selectedPeriod == ReportPeriod.month) {
      // 4 Weeks of the month
      double w1 = 0, w2 = 0, w3 = 0, w4 = 0;
      for (var o in orders) {
        final d = o.date.day;
        if (d <= 7) {
          w1 += o.total;
        } else if (d <= 14) {
          w2 += o.total;
        } else if (d <= 21) {
          w3 += o.total;
        } else {
          w4 += o.total;
        }
      }
      return [
        {'label': 'Week 1', 'amount': w1},
        {'label': 'Week 2', 'amount': w2},
        {'label': 'Week 3', 'amount': w3},
        {'label': 'Week 4', 'amount': w4},
      ];
    } else {
      // 4 Quarters of the year
      double q1 = 0, q2 = 0, q3 = 0, q4 = 0;
      for (var o in orders) {
        final m = o.date.month;
        if (m <= 3) {
          q1 += o.total;
        } else if (m <= 6) {
          q2 += o.total;
        } else if (m <= 9) {
          q3 += o.total;
        } else {
          q4 += o.total;
        }
      }
      return [
        {'label': 'Q1 (Jan-Mar)', 'amount': q1},
        {'label': 'Q2 (Apr-Jun)', 'amount': q2},
        {'label': 'Q3 (Jul-Sep)', 'amount': q3},
        {'label': 'Q4 (Oct-Dec)', 'amount': q4},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeShop = ShopState.instance.activeShop;
    final filteredOrders = _getFilteredOrders();
    final filteredEntries = _getFilteredEntries();

    // 100% Real Calculations based on actual store data
    final filteredPurchases = _getFilteredPurchases();
    final totalSales = filteredOrders.fold(0.0, (sum, o) => sum + o.total);
    final totalPurchases = filteredPurchases.fold(0.0, (sum, p) => sum + p.totalAmount);
    final purchasesPaid = filteredPurchases.fold(0.0, (sum, p) => sum + p.paidAmount);
    final purchasesPending = filteredPurchases.fold(0.0, (sum, p) => sum + p.creditBalanceAdded);

    // Real Profit: (Item sale price - Item sale-time cost price) * quantity
    double totalCost = 0.0;
    for (var o in filteredOrders) {
      for (var item in o.items) {
        totalCost += (item.costPriceAtSale * item.quantity);
      }
    }
    final netProfit = totalSales - totalCost;

    // Real Payment Breakdown for Sales
    final cashSales = filteredOrders
        .where((o) => o.paymentMode == PaymentMode.cash)
        .fold(0.0, (sum, o) => sum + o.paidAmount);
    final onlineSales = filteredOrders
        .where((o) =>
            o.paymentMode == PaymentMode.raast ||
            o.paymentMode == PaymentMode.online ||
            o.paymentMode == PaymentMode.digital)
        .fold(0.0, (sum, o) => sum + o.paidAmount);
    final creditSales = filteredOrders.fold(0.0, (sum, o) => sum + o.creditAmount);

    // Total Recovered: Cash Sales + Online Sales + Ledger received entries
    final ledgerWasooli = filteredEntries
        .where((e) => e.type == LedgerType.got)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalWasooli = ledgerWasooli + cashSales + onlineSales;

    // Total Customer Udhar (Market Receivables)
    final customerReceivables = KhataState.instance.customers
        .where((c) => c.balance > 0)
        .fold(0.0, (sum, c) => sum + c.balance);

    // Total Supplier Payables (Outstanding Debts to Suppliers)
    final supplierPayables = KhataState.instance.suppliers
        .where((s) => s.balance < 0)
        .fold(0.0, (sum, s) => sum + s.balance.abs());

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports & Financial Analytics',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                activeShop.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A)),
              tooltip: 'Export Excel / CSV',
              onPressed: () async {
                final periodName = _selectedPeriod == ReportPeriod.today
                    ? 'Today'
                    : (_selectedPeriod == ReportPeriod.week
                        ? 'This Week'
                        : (_selectedPeriod == ReportPeriod.month ? 'This Month' : 'This Year'));
                final file = await CsvExportService.instance.generateSalesOrdersCsv(
                  orders: _getFilteredOrders(),
                  shop: activeShop,
                  reportPeriod: periodName,
                );
                await CsvExportService.instance.shareCsvFile(
                  file,
                  subject: 'Sales Report ($periodName) - ${activeShop.name}',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
              tooltip: 'Export Financial Report PDF',
              onPressed: () {
                final periodName = _selectedPeriod == ReportPeriod.today
                    ? 'Today'
                    : (_selectedPeriod == ReportPeriod.week
                        ? 'This Week'
                        : (_selectedPeriod == ReportPeriod.month ? 'This Month' : 'This Year'));
                PrintingAndSharingService.instance.exportFinancialReportPdf(
                  shop: activeShop,
                  periodName: periodName,
                  totalSales: totalSales,
                  grossProfit: netProfit,
                  netProfit: netProfit,
                  totalExpenses: purchasesPaid,
                  cashSales: cashSales + onlineSales,
                  creditSales: creditSales,
                  orderCount: filteredOrders.length,
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildPeriodTab('Today', ReportPeriod.today),
                  _buildPeriodTab('This Week', ReportPeriod.week),
                  _buildPeriodTab('This Month', ReportPeriod.month),
                  _buildPeriodTab('This Year', ReportPeriod.year),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Financial Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Gross Revenue',
                    subtitle: 'Total Sales',
                    amount: totalSales,
                    color: const Color(0xFF2563EB),
                    icon: Icons.payments_rounded,
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Net Profit',
                    subtitle: 'Sales - Cost',
                    amount: netProfit,
                    color: const Color(0xFF16A34A),
                    icon: Icons.trending_up_rounded,
                    bgColor: const Color(0xFFDCFCE7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Stock Purchases',
                    subtitle: 'Vendor Inward',
                    amount: totalPurchases,
                    color: const Color(0xFFEA580C),
                    icon: Icons.local_shipping_rounded,
                    bgColor: const Color(0xFFFFEDD5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Recovered',
                    subtitle: 'Cash & Online In',
                    amount: totalWasooli,
                    color: const Color(0xFF0D9488),
                    icon: Icons.account_balance_wallet_rounded,
                    bgColor: const Color(0xFFCCFBF1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Customer Udhar',
                    subtitle: 'Market Due',
                    amount: customerReceivables,
                    color: const Color(0xFFDC2626),
                    icon: Icons.arrow_outward_rounded,
                    bgColor: const Color(0xFFFEE2E2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Supplier Payable',
                    subtitle: 'Vendor Due',
                    amount: supplierPayables,
                    color: const Color(0xFF7C3AED),
                    icon: Icons.call_received_rounded,
                    bgColor: const Color(0xFFF3E8FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildRealChartCard(filteredOrders),
            const SizedBox(height: 20),

            _buildPaymentBreakdownCard(
              cashSales: cashSales,
              onlineSales: onlineSales,
              creditSales: creditSales,
              purchasesPaid: purchasesPaid,
              purchasesPending: purchasesPending,
            ),
            const SizedBox(height: 20),

            _buildDetailedBillsSection(
              orders: filteredOrders,
              purchases: filteredPurchases,
            ),
            const SizedBox(height: 30),
          ],
        ),
        bottomNavigationBar: const SmartBottomNavigationBar(
          currentRoute: AppRoutes.reports,
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, ReportPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRealChartCard(List<OrderModel> orders) {
    final barData = _calculateRealBarData(orders);
    final maxAmount = barData.fold(0.0, (max, item) {
      final a = (item['amount'] as num).toDouble();
      return a > max ? a : max;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Earnings Trend',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${orders.length} Bills',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (orders.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 30, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 6),
                  Text(
                    'No sales recorded yet for this period',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: barData.map((item) {
                  final label = item['label'] as String;
                  final amt = (item['amount'] as num).toDouble();
                  final proportion = maxAmount > 0 ? (amt / maxAmount) : 0.0;
                  final barHeight = amt > 0 ? (proportion * 90).clamp(10.0, 90.0) : 3.0;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (amt > 0)
                          Text(
                            CurrencyFormatter.format(amt),
                            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: amt > 0 ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownCard({
    required double cashSales,
    required double onlineSales,
    required double creditSales,
    required double purchasesPaid,
    required double purchasesPending,
  }) {
    final salesTotal = cashSales + onlineSales + creditSales;
    final purchasesTotal = purchasesPaid + purchasesPending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment & Settlement Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Sales Section
          const Row(
            children: [
              Icon(Icons.point_of_sale_rounded, size: 15, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Customer Sales Settlement',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPaymentRow('Cash Counter', cashSales, salesTotal, const Color(0xFF16A34A)),
          const SizedBox(height: 8),
          _buildPaymentRow('Online / Raast', onlineSales, salesTotal, const Color(0xFF2563EB)),
          const SizedBox(height: 8),
          _buildPaymentRow('Market Udhar (Credit)', creditSales, salesTotal, const Color(0xFFDC2626)),

          const Divider(height: 24),

          // Purchases Section
          const Row(
            children: [
              Icon(Icons.local_shipping_rounded, size: 15, color: Color(0xFFEA580C)),
              SizedBox(width: 6),
              Text(
                'Supplier Purchases Settlement',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPaymentRow('Paid to Suppliers (Cash/Bank)', purchasesPaid, purchasesTotal, const Color(0xFF0D9488)),
          const SizedBox(height: 8),
          _buildPaymentRow('Pending to Suppliers (Udhar)', purchasesPending, purchasesTotal, const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, double total, Color color) {
    final pct = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedBillsSection({
    required List<OrderModel> orders,
    required List<PurchaseInvoiceModel> purchases,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detailed Activity & Invoices',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${orders.length} Sales • ${purchases.length} Purchases',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tab Selector: Sales Bills vs Purchase Inwards
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedActivityTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedActivityTab == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _selectedActivityTab == 0
                          ? const [
                              BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2)),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Customer Sales (${orders.length})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedActivityTab == 0 ? FontWeight.bold : FontWeight.w600,
                        color: _selectedActivityTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    _selectedActivityTab = 1;
                    if (_paymentFilter == 'Online / Digital') {
                      _paymentFilter = 'All';
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedActivityTab == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _selectedActivityTab == 1
                          ? const [
                              BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2)),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Stock Inward (${purchases.length})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedActivityTab == 1 ? FontWeight.bold : FontWeight.w600,
                        color: _selectedActivityTab == 1 ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Search Bar for Bills & Transactions
        TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            isDense: true,
            hintText: _selectedActivityTab == 0
                ? 'Search sales by invoice #, customer, item...'
                : 'Search inward by invoice #, supplier, item...',
            hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Color(0xFF64748B)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 8),

        // Payment Mode Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: (_selectedActivityTab == 1
                    ? ['All', 'Cash', 'Udhar / Credit']
                    : ['All', 'Cash', 'Online / Digital', 'Udhar / Credit'])
                .map((chip) {
              final isSelected = _paymentFilter == chip;
              return GestureDetector(
                onTap: () => setState(() => _paymentFilter = chip),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    chip,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        if (_selectedActivityTab == 0) ...[
          // Sales Invoices List
          () {
            final filteredOrders = orders.where((o) {
              final q = _searchQuery.trim().toLowerCase();
              final matchesSearch = q.isEmpty ||
                  o.invoiceNo.toLowerCase().contains(q) ||
                  (o.customer?.name.toLowerCase().contains(q) ?? false) ||
                  o.total.toString().contains(q) ||
                  o.items.any((i) => i.product.title.toLowerCase().contains(q));
              if (!matchesSearch) return false;

              if (_paymentFilter == 'Cash') {
                return o.paymentMode == PaymentMode.cash && o.creditAmount == 0;
              }
              if (_paymentFilter == 'Online / Digital') {
                return (o.paymentMode == PaymentMode.online ||
                        o.paymentMode == PaymentMode.raast ||
                        o.paymentMode == PaymentMode.digital) &&
                    o.creditAmount == 0;
              }
              if (_paymentFilter == 'Udhar / Credit') {
                return o.paymentMode == PaymentMode.udhaar || o.creditAmount > 0;
              }
              return true;
            }).toList();

            if (filteredOrders.isEmpty) {
              return _buildEmptyState(
                _searchQuery.isNotEmpty || _paymentFilter != 'All'
                    ? 'No sales match "$_searchQuery" / $_paymentFilter'
                    : 'No sales bills generated yet for this period',
                Icons.receipt_long_outlined,
              );
            }

            return Column(
              children: filteredOrders.map((o) {
                final isUdhar =
                    o.paymentMode == PaymentMode.udhaar || o.creditAmount > 0;
                final customerTitle = o.customer?.name ?? 'Walk-in Customer';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.receiptPreview,
                          arguments: o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isUdhar
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isUdhar
                                    ? Icons.assignment_late_outlined
                                    : Icons.check_circle_outline,
                                color: isUdhar
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Invoice #${o.invoiceNo}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isUdhar
                                              ? const Color(0xFFFFE4E6)
                                              : const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          o.creditAmount > 0 && o.paidAmount > 0
                                              ? 'SPLIT'
                                              : o.paymentMode.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isUdhar
                                                ? const Color(0xFFBE123C)
                                                : const Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$customerTitle • ${o.items.length} items',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B)),
                                  ),
                                  if (o.creditAmount > 0)
                                    Text(
                                      'Paid: PKR ${o.paidAmount.toStringAsFixed(0)} • Udhar: PKR ${o.creditAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFDC2626)),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(o.total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 11, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }(),
        ] else ...[
          // Purchases List
          () {
            final filteredPurchases = purchases.where((p) {
              final q = _searchQuery.trim().toLowerCase();
              final matchesSearch = q.isEmpty ||
                  p.invoiceNo.toLowerCase().contains(q) ||
                  p.supplierName.toLowerCase().contains(q) ||
                  p.totalAmount.toString().contains(q) ||
                  p.items.any((i) => i.productName.toLowerCase().contains(q));
              if (!matchesSearch) return false;

              if (_paymentFilter == 'Cash') {
                return p.paidAmount > 0 && p.creditBalanceAdded == 0;
              }
              if (_paymentFilter == 'Udhar / Credit') {
                return p.creditBalanceAdded > 0;
              }
              if (_paymentFilter == 'Online / Digital') {
                return false;
              }
              return true;
            }).toList();

            if (filteredPurchases.isEmpty) {
              return _buildEmptyState(
                _searchQuery.isNotEmpty || _paymentFilter != 'All'
                    ? 'No purchases match "$_searchQuery" / $_paymentFilter'
                    : 'No purchase bills recorded yet for this period',
                Icons.local_shipping_outlined,
              );
            }

            return Column(
              children: filteredPurchases.map((p) {
                final isPending = p.creditBalanceAdded > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFF3E8FF)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPending
                              ? Icons.pending_actions_rounded
                              : Icons.inventory_rounded,
                          color: isPending
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p.invoiceNo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? const Color(0xFFF3E8FF)
                                        : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isPending ? 'UDHAR' : 'PAID',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isPending
                                          ? const Color(0xFF6D28D9)
                                          : const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.supplierName} • ${p.items.length} items',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            if (isPending)
                              Text(
                                'Paid: PKR ${p.paidAmount.toStringAsFixed(0)} • Payable: PKR ${p.creditBalanceAdded.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7C3AED)),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(p.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
