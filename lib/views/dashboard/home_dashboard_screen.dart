import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../shared_widgets/smart_khata_drawer.dart';
import '../shared_widgets/smart_bottom_navigation_bar.dart';
import 'widgets/dashboard_metric_card.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/recent_sales_tile.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _khataState = KhataState.instance;
  final _inventoryState = InventoryState.instance;

  @override
  void initState() {
    super.initState();
    _khataState.addListener(_rebuild);
    _inventoryState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _khataState.removeListener(_rebuild);
    _inventoryState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final todaySales = _khataState.todaySales;
    final totalReceivable = _khataState.totalReceivable;
    final lowStockCount = _inventoryState.lowStockCount;
    final orders = _khataState.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      drawer: const SmartKhataDrawer(currentRoute: AppRoutes.dashboard),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Core Metrics: Today's Sales & Total Udhaar
              Row(
                children: [
                  Expanded(
                    child: DashboardMetricCard(
                      title: "Today's Sales",
                      amount: CurrencyFormatter.format(todaySales),
                      subtitle: orders.isNotEmpty
                          ? '${orders.length} Bills Today'
                          : '0 Bills Today',
                      badgeText: orders.isNotEmpty
                          ? '${orders.length} Bills Today'
                          : '0 Bills Today',
                      badgeBg: const Color(0xFFDCFCE7),
                      badgeColor: const Color(0xFF15803D),
                      backgroundColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFFBBF7D0),
                      icon: Icons.trending_up,
                      iconColor: const Color(0xFF16A34A),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.posCart),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardMetricCard(
                      title: 'To Collect (Udhaar)',
                      amount: CurrencyFormatter.format(totalReceivable),
                      subtitle:
                          '${_khataState.customers.where((c) => c.balance > 0).length} Overdue',
                      badgeText:
                          '${_khataState.customers.where((c) => c.balance > 0).length} Overdue',
                      badgeBg: const Color(0xFFFFE4E6),
                      badgeColor: const Color(0xFFBE123C),
                      backgroundColor: const Color(0xFFFFF1F2),
                      borderColor: const Color(0xFFFECDD3),
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFFE11D48),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.khataDirectory),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Quick Operations Section (4 Core Real Actions)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Operations',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Tap to launch',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Operations 2x2 Grid
              Row(
                children: [
                  // Action 1: New Sale (Featured POS Card)
                  Expanded(
                    child: QuickActionButton(
                      label: 'New Sale',
                      subtitle: 'Barcode POS scanner',
                      icon: Icons.qr_code_scanner,
                      color: Colors.white,
                      isFeatured: true,
                      badge: 'QUICK BILL',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.posCart),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action 2: Add Product
                  Expanded(
                    child: QuickActionButton(
                      label: 'Add Product',
                      subtitle: 'Add to inventory',
                      icon: Icons.add_box_outlined,
                      color: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.addEditProduct),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  // Action 3: Khata Ledger
                  Expanded(
                    child: QuickActionButton(
                      label: 'Khata Ledger',
                      subtitle: 'Customer balances',
                      icon: Icons.menu_book_outlined,
                      color: const Color(0xFF1E293B),
                      iconBg: const Color(0xFFF1F5F9),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.khataDirectory),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action 4: Inventory List
                  Expanded(
                    child: QuickActionButton(
                      label: 'Inventory',
                      subtitle:
                          '${_inventoryState.products.length} Products tracked',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFF0FDF4),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.inventoryList),
                    ),
                  ),
                ],
              ),

              // 4. Low Stock Alert (Conditional)
              if (lowStockCount > 0) ...[
                const SizedBox(height: 16),
                _buildLowStockBanner(context, lowStockCount),
              ],

              const SizedBox(height: 16),

              // 5. Today's Settlement Split
              _buildSettlementSplit(orders),

              const SizedBox(height: 16),

              // 6. Recent Invoices
              _buildRecentInvoicesSection(context, orders),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // 7. Executive 4-Tab Bottom Navigation Bar
      bottomNavigationBar: const SmartBottomNavigationBar(
        currentRoute: AppRoutes.dashboard,
      ),
    );
  }

  // Dashboard Standard AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      showMenu: true,
      showBack: false,
      showLogo: true,
      title: 'SmartKhata Store',
      subtitle: 'Online • Terminal 01',
      actions: [
        // Notification Icon with Red Badge
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B), size: 22),
              tooltip: 'Notifications',
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        // User Profile Avatar / Shop Setup Link
        Padding(
          padding: const EdgeInsets.only(right: 14.0, left: 2.0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.shopSetup),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF1E293B),
                child: Icon(Icons.storefront, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Low Stock Alert Banner
  Widget _buildLowStockBanner(BuildContext context, int lowStockCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE11D48), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$lowStockCount Items Low on Stock!',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF881337),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.inventoryList),
                      child: const Row(
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward,
                              size: 12, color: Color(0xFFBE123C)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_inventoryState.products.where((p) => p.isLowStock || p.stockQty == 0).take(3).map((p) => p.title).join(', ')} are reaching minimum threshold.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9F1239),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Settlement Split Widget
  Widget _buildSettlementSplit(List<OrderModel> orders) {
    final cashSales = orders
        .where((o) => o.paymentMode == PaymentMode.cash)
        .fold(0.0, (s, o) => s + o.total);
    final digitalSales = orders
        .where((o) =>
            o.paymentMode == PaymentMode.online ||
            o.paymentMode == PaymentMode.raast ||
            o.paymentMode == PaymentMode.digital)
        .fold(0.0, (s, o) => s + o.total);
    final udhaarSales = orders
        .where((o) => o.paymentMode == PaymentMode.udhaar)
        .fold(0.0, (s, o) => s + o.total);
    final totalOrders = cashSales + digitalSales + udhaarSales;

    final cashFlex = totalOrders > 0 && cashSales > 0
        ? (cashSales / totalOrders * 100).toInt()
        : 0;
    final digitalFlex = totalOrders > 0 && digitalSales > 0
        ? (digitalSales / totalOrders * 100).toInt()
        : 0;
    final udhaarFlex = totalOrders > 0 && udhaarSales > 0
        ? (udhaarSales / totalOrders * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(14),
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
                "Today's Settlement Split",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                totalOrders > 0
                    ? '${((cashSales / totalOrders) * 100).toInt()}% CASH'
                    : 'NO SETTLEMENTS YET',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: totalOrders > 0
                ? Row(
                    children: [
                      if (cashFlex > 0)
                        Expanded(
                            flex: cashFlex,
                            child: Container(
                                height: 8, color: const Color(0xFF15803D))),
                      if (digitalFlex > 0)
                        Expanded(
                            flex: digitalFlex,
                            child: Container(
                                height: 8, color: const Color(0xFF1D4ED8))),
                      if (udhaarFlex > 0)
                        Expanded(
                            flex: udhaarFlex,
                            child: Container(
                                height: 8, color: const Color(0xFF991B1B))),
                    ],
                  )
                : Container(height: 8, color: const Color(0xFFF1F5F9)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem(const Color(0xFF15803D),
                  'Cash (${CurrencyFormatter.format(cashSales)})'),
              _buildLegendItem(const Color(0xFF1D4ED8),
                  'Digital (${CurrencyFormatter.format(digitalSales)})'),
              _buildLegendItem(const Color(0xFF991B1B),
                  'Udhaar (${CurrencyFormatter.format(udhaarSales)})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  // Recent Invoices Section
  Widget _buildRecentInvoicesSection(
      BuildContext context, List<OrderModel> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Invoices',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.posCart),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (orders.isNotEmpty)
          ...orders.take(4).map(
                (ord) => RecentSalesTile(
                  order: ord,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.receiptPreview,
                    arguments: ord,
                  ),
                ),
              )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No recent invoices yet. Tap "New Sale" to create your first bill.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          ),
      ],
    );
  }
}
