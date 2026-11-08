import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../models/cart_item_model.dart';
import '../../routes/app_routes.dart';
import '../../state/cart_state.dart';
import '../../state/inventory_state.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/smart_khata_drawer.dart';
import '../shared_widgets/smart_bottom_navigation_bar.dart';

class PosCartScreen extends StatefulWidget {
  const PosCartScreen({super.key});

  @override
  State<PosCartScreen> createState() => _PosCartScreenState();
}

class _PosCartItem {
  final String id;
  final String title;
  final String barcode;
  final double unitPrice;
  final String unitName;
  double qty;
  final bool isLoose;
  final Color iconBg;
  final IconData icon;

  _PosCartItem({
    required this.id,
    required this.title,
    required this.barcode,
    required this.unitPrice,
    required this.unitName,
    required this.qty,
    this.isLoose = false,
    required this.iconBg,
    required this.icon,
  });

  double get subtotal => unitPrice * qty;
}

class _PosCartScreenState extends State<PosCartScreen> {
  final _cartState = CartState.instance;
  String _selectedPaymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _cartState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _cartState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  _PosCartItem _cartModelToPosItem(CartItemModel m) {
    IconData icon = Icons.shopping_bag_outlined;
    Color iconBg = const Color(0xFFEFF6FF);
    final cat = m.product.category.toLowerCase();
    if (cat.contains('dairy') || cat.contains('milk')) {
      icon = Icons.local_drink_outlined;
      iconBg = const Color(0xFFEFF6FF);
    } else if (cat.contains('spice') || cat.contains('biryani')) {
      icon = Icons.soup_kitchen_outlined;
      iconBg = const Color(0xFFFFFBEB);
    } else if (cat.contains('tea') || cat.contains('beverage')) {
      icon = Icons.emoji_food_beverage_outlined;
      iconBg = const Color(0xFFFEF3C7);
    } else if (cat.contains('grocery') ||
        cat.contains('flour') ||
        cat.contains('atta') ||
        cat.contains('basmati')) {
      icon = Icons.grain;
      iconBg = const Color(0xFFF1F5F9);
    }

    return _PosCartItem(
      id: m.product.id,
      title: m.product.title,
      barcode: m.product.barcode,
      unitPrice: m.product.salePrice,
      unitName: 'unit',
      qty: m.quantity.toDouble(),
      isLoose: m.product.category.toLowerCase().contains('grocery') ||
          m.product.title.toLowerCase().contains('atta'),
      iconBg: iconBg,
      icon: icon,
    );
  }

  List<_PosCartItem> get _items =>
      _cartState.items.map(_cartModelToPosItem).toList();
  double get _subtotal => _cartState.subtotal;
  double get _discount => _cartState.discount;
  double get _netPayable => _cartState.netPayable;

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const SmartKhataDrawer(currentRoute: AppRoutes.posCart),
      appBar: CustomAppBar(
        title: 'Counter Billing',
        subtitle: 'SmartKhata POS',
        showLogo: true,
        showMenu: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _items.clear());
            },
            child: const Text(
              'Clear Cart',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scan Barcode via Camera Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.barcodeIcon,
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Barcode via Camera',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.volume_up_outlined,
                                      size: 12, color: Color(0xFF64748B)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Beep sound active • F2 hotkey',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AUTO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.posScanner),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search Item & Loose/Weight Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search item name or code',
                            hintStyle: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF16A34A), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.scale_outlined,
                                size: 15, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 4),
                            Text(
                              'Loose / Weight',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Section Header: ITEM DETAILS & STEPPERS
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ITEM DETAILS & STEPPERS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'SWIPE TO DELETE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Cart Items List
                  if (_items.isEmpty)
                    EmptyStateWidget(
                      imageAsset: AppAssets.emptyState,
                      icon: Icons.shopping_cart_outlined,
                      title: 'Cart is Empty',
                      subtitle:
                          'Scan barcode or add products from catalog to start billing.',
                      buttonText: 'Add Sample Products',
                      onButtonPressed: () {
                        final prods = InventoryState.instance.products;
                        if (prods.isNotEmpty) {
                          _cartState.addItem(prods[0]);
                          if (prods.length > 1) _cartState.addItem(prods[1]);
                        }
                      },
                    )
                  else
                    ..._items.map((item) => _buildCartTile(item)),

                  const SizedBox(height: 12),

                  // Active Customer Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Customer',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Walk-in Cash Customer',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.khataDirectory),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_add_alt,
                                    size: 13, color: Color(0xFF1E3A8A)),
                                SizedBox(width: 4),
                                Text(
                                  'Add Khata',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Bottom Sticky Checkout Sheet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Little drag pill
                  Container(
                    width: 36,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtotal Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal (${_items.length} items)',
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      Text(
                        'PKR ${_subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Special Discount Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Special Discount',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF475569)),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              size: 13, color: Color(0xFF64748B)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '- PKR ${_discount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBE123C),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // GST Row
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GST / Retail Tax (0%)',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      Text(
                        'PKR 0',
                        style:
                            TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Net Payable Big Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Payable',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Total saved:',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'PKR ${_netPayable.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Payment Mode Pills (Cash, JazzCash, Ledger Due)
                  Row(
                    children: [
                      _buildPaymentPill(
                        icon: Icons.payments_outlined,
                        label: 'Cash',
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentPill(
                        icon: Icons.mobile_friendly,
                        label: 'JazzCash',
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentPill(
                        icon: Icons.receipt_long,
                        label: 'Ledger Due',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Big Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.receiptPreview),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F), // Deep Navy
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'PKR ${_netPayable.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 16),
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
        ],
      ),
      bottomNavigationBar: const SmartBottomNavigationBar(
        currentRoute: AppRoutes.posCart,
      ),
    ),
    );
  }

  Widget _buildCartTile(_PosCartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail / Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(item.icon, color: const Color(0xFF1E293B), size: 22),
              ),

              const SizedBox(width: 10),

              // Title & Barcode Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (item.isLoose) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LOOSE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item.isLoose
                              ? 'CODE: ${item.barcode}'
                              : 'BARCODE: ${item.barcode}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• PKR ${item.unitPrice.toStringAsFixed(0)} / ${item.unitName}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              GestureDetector(
                onTap: () {
                  final matches = _cartState.items
                      .where((i) => i.product.id == item.id)
                      .toList();
                  if (matches.isNotEmpty) {
                    _cartState.removeItem(matches.first.product);
                  }
                },
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Stepper & Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stepper Pill [-] Qty [+]
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final matches = _cartState.items
                            .where((i) => i.product.id == item.id)
                            .toList();
                        if (matches.isNotEmpty) {
                          _cartState.decrement(matches.first.product);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove,
                            size: 14, color: Color(0xFF1E293B)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        item.isLoose
                            ? '${item.qty.toStringAsFixed(1)} kg'
                            : '${item.qty.toInt()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final matches = _cartState.items
                            .where((i) => i.product.id == item.id)
                            .toList();
                        if (matches.isNotEmpty) {
                          _cartState.increment(matches.first.product);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Item Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'SUBTOTAL',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'PKR ${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill({
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedPaymentMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMode = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
