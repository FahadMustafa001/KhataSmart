import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../models/ledger_entry_model.dart';
import '../../models/party_model.dart';
import '../../routes/app_routes.dart';
import '../../services/printing_and_sharing_service.dart';
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
  Timer? _dateRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KhataState.instance.addListener(_refresh);
    ShopState.instance.addListener(_refresh);
    _dateRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    KhataState.instance.removeListener(_refresh);
    ShopState.instance.removeListener(_refresh);
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
    final totalSales = filteredOrders.fold(0.0, (sum, o) => sum + o.total);

    // Real Profit: (Item sale price - Item sale-time cost price) * quantity
    double totalCost = 0.0;
    for (var o in filteredOrders) {
      for (var item in o.items) {
        totalCost += (item.costPriceAtSale * item.quantity);
      }
    }
    final netProfit = totalSales - totalCost;

    // Real Wasooli: Cash Sales + Ledger received entries
    final ledgerWasooli = filteredEntries
        .where((e) => e.type == LedgerType.got)
        .fold(0.0, (sum, e) => sum + e.amount);
    final cashSales = filteredOrders
        .where((o) => o.paymentMode != PaymentMode.udhaar)
        .fold(0.0, (sum, o) => sum + o.total);
    final totalWasooli = ledgerWasooli + cashSales;

    // Real Udhaar Given: Credit Sales + Manual Ledger given entries to customers (excluding auto-generated order bills)
    final allParties = KhataState.instance.allPartiesForDatabase;
    final Map<String, PartyType> partyTypeMap = {for (var p in allParties) p.id: p.type};

    final creditSales = filteredOrders
        .where((o) => o.paymentMode == PaymentMode.udhaar)
        .fold(0.0, (sum, o) => sum + o.total);

    final manualCreditGiven = filteredEntries
        .where((e) =>
            e.type == LedgerType.gave &&
            partyTypeMap[e.partyId] == PartyType.customer &&
            !RegExp(r'^Bill\s*#\s*INV', caseSensitive: false).hasMatch(e.note))
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalUdhaar = creditSales + manualCreditGiven;

    // Operating expenses (supplier payouts and expense entries)
    final operatingExpenses = filteredEntries
        .where((e) =>
            e.type == LedgerType.gave &&
            (partyTypeMap[e.partyId] == PartyType.supplier ||
                e.note.toLowerCase().contains('expense') ||
                e.note.toLowerCase().contains('bill # electricity') ||
                e.note.toLowerCase().contains('rent') ||
                e.note.toLowerCase().contains('utility')))
        .fold(0.0, (sum, e) => sum + e.amount);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
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
                  totalExpenses: operatingExpenses,
                  cashSales: cashSales,
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
            // 1. TIME PERIOD SELECTOR
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

            // 2. MAIN 100% REAL KPI CARDS
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Gross Revenue',
                    subtitle: 'Kul Bikri',
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
                    subtitle: 'Saafi Munafa',
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
                    title: 'Total Wasooli',
                    subtitle: 'Cash In',
                    amount: totalWasooli,
                    color: const Color(0xFF0D9488),
                    icon: Icons.input_rounded,
                    bgColor: const Color(0xFFCCFBF1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Udhaar Given',
                    subtitle: 'Market Credit',
                    amount: totalUdhaar,
                    color: const Color(0xFFE11D48),
                    icon: Icons.outbox_rounded,
                    bgColor: const Color(0xFFFFE4E6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. 100% REAL EARNINGS TREND GRAPH
            _buildRealChartCard(filteredOrders),
            const SizedBox(height: 20),

            // 4. REAL PAYMENT MODE BREAKDOWN
            _buildPaymentBreakdownCard(filteredOrders),
            const SizedBox(height: 20),

            // 5. DETAILED INVOICES & BILLS LIST FOR THIS PERIOD
            _buildDetailedBillsSection(filteredOrders),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
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
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
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

  Widget _buildPaymentBreakdownCard(List<OrderModel> orders) {
    final cash = orders.where((o) => o.paymentMode == PaymentMode.cash).fold(0.0, (s, o) => s + o.total);
    final udhaar = orders.where((o) => o.paymentMode == PaymentMode.udhaar).fold(0.0, (s, o) => s + o.total);
    final online = orders.where((o) => o.paymentMode == PaymentMode.online || o.paymentMode == PaymentMode.raast || o.paymentMode == PaymentMode.digital).fold(0.0, (s, o) => s + o.total);
    final total = (cash + udhaar + online);

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
            'Real Payment Distribution',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildPaymentRow('Cash Counter', cash, total, const Color(0xFF16A34A)),
          const SizedBox(height: 10),
          _buildPaymentRow('Udhaar / Credit', udhaar, total, const Color(0xFFE11D48)),
          const SizedBox(height: 10),
          _buildPaymentRow('Online / Raast', online, total, const Color(0xFF2563EB)),
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
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(CurrencyFormatter.format(amount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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

  Widget _buildDetailedBillsSection(List<OrderModel> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bills & Invoices in Selected Period',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              '${orders.length} real bills',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'No bills generated yet for this period',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ...orders.map((o) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: o.paymentMode == PaymentMode.udhaar
                          ? const Color(0xFFFFE4E6)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      o.paymentMode == PaymentMode.udhaar
                          ? Icons.pending_actions_rounded
                          : Icons.receipt_rounded,
                      color: o.paymentMode == PaymentMode.udhaar
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice #${o.invoiceNo}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${o.items.length} items • ${o.paymentMode.name.toUpperCase()} • ${o.customer?.name ?? "Walk-in"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(o.total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
