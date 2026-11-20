import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../services/csv_export_service.dart';
import '../../state/inventory_state.dart';
import '../../state/shop_state.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/notification_bell_button.dart';
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
  String _sortBy = 'Restock Priority';
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
    var filtered = all.where((item) {
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

    if (_sortBy == 'Restock Priority') {
      filtered.sort((a, b) => a.stock.compareTo(b.stock));
    } else if (_sortBy == 'Name (A to Z)') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortBy == 'Price: High to Low') {
      filtered.sort((a, b) => b.sale.compareTo(a.sale));
    } else if (_sortBy == 'Stock: High to Low') {
      filtered.sort((a, b) => b.stock.compareTo(a.stock));
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sort Inventory Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              ...[
                'Restock Priority',
                'Name (A to Z)',
                'Price: High to Low',
                'Stock: High to Low',
              ].map((s) {
                final isSelected = _sortBy == s;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  title: Text(
                    s,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  onTap: () {
                    setState(() => _sortBy = s);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showBarcodeStickerDialog(ProductModel product) {
    int count = 24;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.qr_code_2, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Print Barcode Stickers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Barcode: ${product.barcode.isNotEmpty ? product.barcode : product.id} • Rs. ${product.salePrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Number of Stickers (A4 Sheet):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [12, 24, 48, 72].map((c) {
                      final isSelected = count == c;
                      return ChoiceChip(
                        label: Text('$c Stickers'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        onSelected: (val) {
                          if (val) setDialogState(() => count = c);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    PrintingAndSharingService.instance.exportBarcodeStickersPdf(
                      shop: ShopState.instance.activeShop,
                      product: product,
                      stickerCount: count,
                    );
                  },
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Generate & Print'),
                ),
              ],
            );
          },
        );
      },
    );
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
                      AppToast.showSuccess(
                        context,
                        'Added $qtyToAdd units to ${item.title} (New Total: ${item.stock + qtyToAdd})',
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const SmartKhataDrawer(currentRoute: AppRoutes.inventoryList),
      appBar: CustomAppBar(
        title: 'SmartKhata Store',
        subtitle: 'Inventory Catalog',
        showLogo: true,
        showMenu: true,
        actions: [
          const NotificationBellButton(),
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
                  _buildTitleRow(context),

                  const SizedBox(height: 10),

                  _buildMetricsRow(),

                  const SizedBox(height: 12),

                  _buildSearchField(),

                  const SizedBox(height: 10),

                  _buildFilterChips(),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CATALOG ITEMS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: Text.rich(
                          TextSpan(
                            text: 'Sort by: ',
                            style:
                                const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            children: [
                              TextSpan(
                                text: _sortBy,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

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

      bottomNavigationBar: const SmartBottomNavigationBar(
        currentRoute: AppRoutes.inventoryList,
      ),
    ),
    );
  }

  // ── Title Row ───────────────────────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Stock & Products',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'All Items';
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    AppToast.showInfo(context, 'Showing all ${_inventoryState.products.length} products');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    child: Text(
                      '${_inventoryState.products.length} Items',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stock Inward (Purchase Bill / مال کی خریداری)
            _actionIconBtn(
              icon: Icons.post_add_rounded,
              tooltip: 'Stock Inward / Purchase Bill (مال خریداری)',
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              onTap: () => Navigator.pushNamed(context, AppRoutes.purchaseInward),
            ),
            const SizedBox(width: 6),
            // Export CSV button
            _actionIconBtn(
              icon: Icons.table_view_rounded,
              tooltip: 'Export Stock to Excel / CSV',
              iconColor: const Color(0xFF16A34A),
              onTap: () async {
                if (_inventoryState.products.isEmpty) {
                  AppToast.showWarning(context, 'No products to export');
                  return;
                }
                AppToast.showInfo(context, 'Exporting inventory to CSV...');
                try {
                  final file = await CsvExportService.instance.generateInventoryCsv(
                    products: _inventoryState.products,
                    shop: ShopState.instance.activeShop,
                  );
                  await CsvExportService.instance.shareCsvFile(
                    file,
                    subject: 'Inventory Stock Export - ${ShopState.instance.activeShop.name}',
                  );
                } catch (e) {
                  if (context.mounted) AppToast.showError(context, 'Export failed: $e');
                }
              },
            ),
            const SizedBox(width: 6),
            // Export PDF button
            _actionIconBtn(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: 'Export Catalog PDF',
              iconColor: const Color(0xFFDC2626),
              onTap: () {
                if (_inventoryState.products.isEmpty) {
                  AppToast.showWarning(context, 'No products to export');
                  return;
                }
                AppToast.showInfo(context, 'Generating Catalog PDF...');
                PrintingAndSharingService.instance.exportInventoryCatalog(
                  products: _inventoryState.products,
                  shop: ShopState.instance.activeShop,
                );
              },
            ),
            const SizedBox(width: 6),
            // Filter button
            _actionIconBtn(
              icon: Icons.tune_rounded,
              tooltip: 'Filter & Sort Products',
              iconColor: const Color(0xFF475569),
              onTap: _showFilterBottomSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? iconColor,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Icon(icon, size: 18, color: iconColor ?? const Color(0xFF475569)),
            ),
          ),
        ),
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
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 16, color: Color(0xFF64748B)),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, size: 18, color: Color(0xFF2563EB)),
              tooltip: 'Scan barcode',
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.posScanner,
                  arguments: {'mode': 'lookup'},
                );
                if (!mounted) return;
                if (result is String && result.isNotEmpty) {
                  setState(() {
                    _searchController.text = result;
                    _searchQuery = result;
                  });
                }
              },
            ),
          ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.addEditProduct,
            arguments: _inventoryState.products.firstWhere((p) => p.id == item.id),
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final p = _inventoryState.products.where((prod) => prod.id == item.id).firstOrNull;
                      if (p != null) _showBarcodeStickerDialog(p);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2, size: 13, color: Color(0xFF2563EB)),
                          SizedBox(width: 3),
                          Text('Sticker', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _restockBtn(
      InventoryProductItem item, String label, Color bg, Color textColor,
      {Color? borderColor}) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _showRestockDialog(item),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
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
              AppToast.showSuccess(context, 'Reconciliation Audit Complete. In Sync!');
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
