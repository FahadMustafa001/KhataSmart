import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../state/inventory_state.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/smart_khata_drawer.dart';
import '../shared_widgets/smart_bottom_navigation_bar.dart';
import 'widgets/stock_badge.dart';

class InventoryProductItem {
  final String id;
  final String title;
  final String category;
  final String barcode;
  final int stock;
  final double cost;
  final double sale;
  final bool isLowStock;
  final bool isOutOfStock;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const InventoryProductItem({
    required this.id,
    required this.title,
    required this.category,
    required this.barcode,
    required this.stock,
    required this.cost,
    required this.sale,
    this.isLowStock = false,
    this.isOutOfStock = false,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  double get margin => sale - cost;
  double get marginPercent => cost > 0 ? ((sale - cost) / cost) * 100 : 0;
}

InventoryProductItem _toItem(ProductModel p) {
  final cat = p.category.toLowerCase();

  final (icon, iconColor, iconBg) = switch (cat) {
    _ when cat.contains('tea') || cat.contains('beverage') => (
        Icons.emoji_food_beverage_outlined,
        const Color(0xFFB45309),
        const Color(0xFFFDE68A),
      ),
    _ when cat.contains('oil') || cat.contains('ghee') => (
        Icons.water_drop_outlined,
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
      ),
    _ when cat.contains('dairy') || cat.contains('milk') => (
        Icons.local_drink_outlined,
        const Color(0xFF2563EB),
        const Color(0xFFDBEAFE),
      ),
    _ when cat.contains('spice') || cat.contains('condiment') => (
        Icons.restaurant_outlined,
        const Color(0xFFDC2626),
        const Color(0xFFFEE2E2),
      ),
    _ when cat.contains('bakery') || cat.contains('bread') => (
        Icons.bakery_dining_outlined,
        const Color(0xFF9A3412),
        const Color(0xFFFFEDD5),
      ),
    _ => (
        Icons.shopping_bag_outlined,
        const Color(0xFF16A34A),
        const Color(0xFFDCFCE7),
      ),
  };

  return InventoryProductItem(
    id: p.id,
    title: p.title,
    category: p.category.toUpperCase(),
    barcode: p.barcode,
    stock: p.stockQty,
    cost: p.costPrice,
    sale: p.salePrice,
    isLowStock: p.stockQty > 0 && p.stockQty <= 5,
    isOutOfStock: p.stockQty == 0,
    icon: icon,
    iconColor: iconColor,
    iconBgColor: iconBg,
  );
}

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _inventoryState = InventoryState.instance;
  String _selectedCategory = 'All Items';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inventoryState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _inventoryState.removeListener(_rebuild);
    _searchController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  List<InventoryProductItem> get _filteredList {
    final all = _inventoryState.products.map(_toItem).toList();
    return all.where((item) {
      final matchesSearch =
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.barcode.contains(_searchQuery);
      if (!matchesSearch) return false;

      if (_selectedCategory == 'Low Stock (<5)') {
        return item.isLowStock || item.isOutOfStock;
      }
      if (_selectedCategory != 'All Items') {
        return item.category
            .toLowerCase()
            .contains(_selectedCategory.toLowerCase());
      }
      return true;
    }).toList();
  }

  void _showRestockDialog(InventoryProductItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int qtyToAdd = 10;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Restock SKU',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            item.title,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Stock Units:',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                      Text(
                        '${item.stock} Units',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Units to Add:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (qtyToAdd > 1) {
                                setModalState(() => qtyToAdd--);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+$qtyToAdd',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setModalState(() => qtyToAdd++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _inventoryState.addStock(item.id, qtyToAdd);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Added $qtyToAdd units to ${item.title} (New Total: ${item.stock + qtyToAdd})'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Confirm Restock (+PKR ${(qtyToAdd * item.cost).toStringAsFixed(0)})',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const SmartKhataDrawer(currentRoute: AppRoutes.inventoryList),
      appBar: CustomAppBar(
        title: 'SmartKhata Store',
        subtitle: 'Inventory Catalog',
        showLogo: true,
        showMenu: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    size: 22, color: Color(0xFF334155)),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row: Stock & Products count + action buttons
                  _buildTitleRow(context),

                  const SizedBox(height: 10),

                  // Metrics Banner: Total Valuation & Low Stock Alerts
                  _buildMetricsRow(),

                  const SizedBox(height: 12),

                  // Search field
                  _buildSearchField(),

                  const SizedBox(height: 10),

                  // Horizontal Filter Chips
                  _buildFilterChips(),

                  const SizedBox(height: 12),

                  // Section heading
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CATALOG ITEMS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Sort by: ',
                          style:
                              TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          children: [
                            TextSpan(
                              text: 'Restock Priority',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Product list or empty state
                  if (products.isEmpty)
                    _buildEmptyState()
                  else ...[
                    ...products.map((item) => _buildProductCard(item)),
                    const SizedBox(height: 10),
                    _buildQuickReconciliationCard(),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // FAB: Add Product
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.addEditProduct),
          child: const Icon(Icons.add, size: 28),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: const SmartBottomNavigationBar(
        currentRoute: AppRoutes.inventoryList,
      ),
    );
  }

  // ── Title Row ───────────────────────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Stock & Products',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_inventoryState.products.length} Items',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Export button
            _actionIconBtn(
              icon: Icons.file_download_outlined,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Exporting Stock Catalog to Excel...')),
              ),
            ),
            const SizedBox(width: 8),
            // Filter button
            _actionIconBtn(icon: Icons.tune, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _actionIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF475569)),
      ),
    );
  }

  // ── Metrics Row ─────────────────────────────────────────────────────────────
  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Total Valuation
        Expanded(
          child: _metricCard(
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFDBEAFE),
            iconBg: const Color(0xFFDBEAFE),
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF2563EB),
            label: 'Total Valuation',
            labelColor: const Color(0xFF64748B),
            value: 'PKR ${_inventoryState.totalValuation.toStringAsFixed(0)}',
            valueColor: const Color(0xFF0F172A),
            footer: const Row(
              children: [
                Icon(Icons.north_east, size: 11, color: Color(0xFF16A34A)),
                SizedBox(width: 3),
                Text(
                  '+4.2% vs last wk',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Low Stock Alerts
        Expanded(
          child: _metricCard(
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFEE2E2),
            iconBg: const Color(0xFFFEE2E2),
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFDC2626),
            label: 'Low Stock Alerts',
            labelColor: const Color(0xFFDC2626),
            value: '${_inventoryState.lowStockCount} Items',
            valueColor: const Color(0xFF7F1D1D),
            footer: const Text(
              'Reorder urgently',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String value,
    required Color valueColor,
    required Widget footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 3),
          footer,
        ],
      ),
    );
  }

  // ── Search Field ────────────────────────────────────────────────────────────
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search product name or scan barcode...',
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        prefixIcon:
            const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
        suffixIcon: GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.posScanner),
          child: const Icon(Icons.qr_code_scanner,
              size: 18, color: Color(0xFF2563EB)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  // ── Filter Chips ────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final categories = [
      {'name': 'All Items', 'badge': '${_inventoryState.products.length}'},
      {'name': 'Low Stock (<5)', 'badge': '${_inventoryState.lowStockCount}'},
      {'name': 'Snacks', 'badge': null},
      {'name': 'Dairy', 'badge': null},
      {'name': 'Beverages', 'badge': null},
      {'name': 'Cooking Oil', 'badge': null},
      {'name': 'Condiments', 'badge': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          final isAlert = cat['name'] == 'Low Stock (<5)';

          Color bgColor = const Color(0xFFF1F5F9);
          Color textColor = const Color(0xFF475569);
          Color badgeBg = const Color(0xFFE2E8F0);
          Color badgeText = const Color(0xFF334155);

          if (isSelected) {
            bgColor = const Color(0xFF0F172A);
            textColor = Colors.white;
            badgeBg = const Color(0xFF334155);
            badgeText = Colors.white;
          } else if (isAlert) {
            bgColor = const Color(0xFFFEF2F2);
            textColor = const Color(0xFFDC2626);
            badgeBg = const Color(0xFFDC2626);
            badgeText = Colors.white;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : (isAlert
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAlert) ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat['name']!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (cat['badge'] != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cat['badge']!,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      imageAsset: AppAssets.emptyState,
      icon: Icons.inventory_2_outlined,
      title: 'No Products in Inventory',
      subtitle: 'Tap the "+" button below to add your first store product.',
    );
  }

  // ── Product Card ────────────────────────────────────────────────────────────
  Widget _buildProductCard(InventoryProductItem item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.addEditProduct,
        arguments: _inventoryState.products.firstWhere((p) => p.id == item.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top: icon, title, badges, restock button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(item.icon, size: 24, color: item.iconColor),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Status badge
                            StockBadge(qty: item.stock),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Barcode, category tag, restock button
                        Row(
                          children: [
                            const Icon(Icons.qr_code,
                                size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 3),
                            Text(
                              item.barcode.isNotEmpty ? item.barcode : '—',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (item.isOutOfStock)
                              _restockBtn(
                                  item,
                                  'Reorder Now',
                                  const Color(0xFFFFEDD5),
                                  const Color(0xFFC2410C))
                            else if (item.isLowStock)
                              _restockBtn(
                                  item,
                                  '+ Restock',
                                  const Color(0xFFEFF6FF),
                                  const Color(0xFF1D4ED8),
                                  borderColor: const Color(0xFFDBEAFE)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: cost, sale, margin pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Text(
                    'Cost: Rs. ${item.cost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child:
                        Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                  ),
                  Text(
                    'Sale: Rs. ${item.sale.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  if (item.isOutOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Missed Revenue',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+Rs. ${item.margin.toStringAsFixed(0)} (${item.marginPercent.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _restockBtn(
      InventoryProductItem item, String label, Color bg, Color textColor,
      {Color? borderColor}) {
    return GestureDetector(
      onTap: () => _showRestockDialog(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ── Quick Reconciliation Card ────────────────────────────────────────────────
  Widget _buildQuickReconciliationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.sync, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Reconciliation',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Synced 4 mins ago • Cloud DB',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Reconciliation Audit Complete. In Sync!')),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Audit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
