import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/app_toast.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../state/inventory_state.dart';
import '../../state/shop_state.dart';
import '../shared_widgets/custom_app_bar.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? existingProduct;
  final String? initialBarcode;

  const AddEditProductScreen({
    super.key,
    this.existingProduct,
    this.initialBarcode,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;

  int _stockQuantity = 50;
  int _lowStockThreshold = 5;
  String _selectedCategory = 'General Store & Kiryana';
  String _selectedUnit = 'Pcs';
  bool _trackExpiry = false;

  static const List<String> _units = [
    'Pcs',
    'Kg',
    'Gram',
    'Mann (40kg)',
    'Bori / Bag',
    'Carton / Box',
    'Pack',
    'Dozen',
    'Liter',
    'Meter',
    'Pair',
    'Roll / Than',
    'Other',
  ];

  static const List<String> _categories = [
    'General Store & Kiryana',
    'Auto Spare Parts',
    'Hardware & Sanitary',
    'Mobile & Electronics',
    'Garments & Fabrics',
    'Medicines & Pharmacy',
    'Grains & Mandi (غلہ منڈی)',
    'Fruits & Vegetables (سبزی منڈی)',
    'Cosmetics & Perfumes',
    'Dairy & Bakery',
    'Wholesale & Bulk',
    'Packaged Goods / Tea',
    'Cooking Oil & Ghee',
    'Snacks & Beverages',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    final barcode = p?.barcode ?? widget.initialBarcode ?? '';
    _barcodeController = TextEditingController(text: barcode);
    _nameController = TextEditingController(text: p?.title ?? '');
    _costPriceController = TextEditingController(
      text: p != null ? p.costPrice.toStringAsFixed(0) : '',
    );
    _retailPriceController = TextEditingController(
      text: p != null ? p.salePrice.toStringAsFixed(0) : '',
    );
    if (p != null) {
      _stockQuantity = p.stockQty;
      _lowStockThreshold = p.minStockAlert;
      _selectedCategory = p.category;
      if (p.unit.isNotEmpty) {
        _selectedUnit = p.unit;
      }
    }
    _stockController = TextEditingController(text: '$_stockQuantity');
    _lowStockController = TextEditingController(text: '$_lowStockThreshold');
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  double get _costPrice => double.tryParse(_costPriceController.text) ?? 0.0;
  double get _retailPrice =>
      double.tryParse(_retailPriceController.text) ?? 0.0;
  double get _profitPerUnit =>
      (_retailPrice - _costPrice).clamp(0.0, double.infinity);
  double get _markupPercent =>
      _costPrice > 0 ? ((_retailPrice - _costPrice) / _costPrice) * 100 : 0.0;

  bool get _isEditing => widget.existingProduct != null;

  void _onSaveProduct() {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      AppToast.showWarning(context, 'Please enter product name');
      return;
    }

    final barcodeVal = _barcodeController.text.trim();
    if (barcodeVal.isNotEmpty) {
      final existingWithBarcode = InventoryState.instance.findByBarcode(barcodeVal);
      if (existingWithBarcode != null && existingWithBarcode.id != (widget.existingProduct?.id ?? '')) {
        AppToast.showError(context, 'Barcode already in use by "${existingWithBarcode.name}"');
        return;
      }
    }

    final stockVal = int.tryParse(_stockController.text.trim()) ?? _stockQuantity;
    final lowStockVal = int.tryParse(_lowStockController.text.trim()) ?? _lowStockThreshold;

    final newProd = ProductModel(
      id: widget.existingProduct?.id ??
          'p_${DateTime.now().millisecondsSinceEpoch}',
      barcode: _barcodeController.text.trim(),
      title: title,
      costPrice: _costPrice,
      salePrice: _retailPrice,
      stockQty: stockVal,
      category: _selectedCategory,
      unit: _selectedUnit,
      shopId: widget.existingProduct?.shopId ?? ShopState.instance.activeShopId,
      minStockAlert: lowStockVal,
    );

    if (_isEditing) {
      InventoryState.instance.updateProduct(newProd);
    } else {
      InventoryState.instance.addProduct(newProd);
    }

    AppToast.showSuccess(context, '$title saved to inventory!');
    Navigator.pop(context);
  }

  void _onDeleteProduct() async {
    final title = widget.existingProduct?.name ?? 'this product';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "$title" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (widget.existingProduct != null) {
        InventoryState.instance.deleteProduct(widget.existingProduct!.id);
      }
      if (context.mounted) {
        AppToast.showSuccess(context, '"$title" deleted from inventory');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.inventoryList);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: _isEditing ? 'Edit Product' : 'Add New Product',
          showLogo: true,
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.inventoryList);
            }
          },
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
              tooltip: 'Delete Product',
              onPressed: _onDeleteProduct,
            ),
          TextButton(
            onPressed: _onSaveProduct,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductIdentificationCard(),
            const SizedBox(height: 12),
            _buildPricingMarginCard(),
            const SizedBox(height: 12),
            _buildInitialStockAlertsCard(),
            const SizedBox(height: 12),
            _buildTrackExpiryCard(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onSaveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Update Product' : 'Save Product to Inventory',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF16A34A)),
                SizedBox(width: 4),
                Text(
                  'Item will be instantly available in POS Quick Billing',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  // ── CARD 1: PRODUCT IDENTIFICATION ─────────────────────────────────────────
  Widget _buildProductIdentificationCard() {
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
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRODUCT IDENTIFICATION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'Auto-detected',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barcode label
          _fieldLabel('Barcode / EAN-13'),
          const SizedBox(height: 5),

          // Barcode field with scan button
          TextField(
            controller: _barcodeController,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 6901234567890',
              hintStyle: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(AppAssets.barcodeIcon, width: 20, height: 20),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () async {
                      final scanned = await Navigator.pushNamed(
                        context,
                        AppRoutes.posScanner,
                        arguments: {'mode': 'barcode_capture'},
                      );
                      if (scanned != null && scanned is String) {
                        setState(() => _barcodeController.text = scanned);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 13, color: Color(0xFF15803D)),
                          SizedBox(width: 4),
                          Text(
                            'Scan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                borderSide:
                    const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 11, color: Color(0xFF94A3B8)),
              SizedBox(width: 4),
              Text(
                'Point phone camera or scan with barcode gun',
                style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Product Name label
          _fieldLabel('Product Name & Variant'),
          const SizedBox(height: 5),

          TextField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Lipton Yellow Label 190g',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide:
                    const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Category'),
                    const SizedBox(height: 5),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _categories.contains(_selectedCategory)
                              ? _selectedCategory
                              : _categories.first,
                          isExpanded: true,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Color(0xFF64748B)),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: _categories
                              .map(
                                  (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Unit (UOM)'),
                    const SizedBox(height: 5),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _units.contains(_selectedUnit)
                              ? _selectedUnit
                              : _units.first,
                          isExpanded: true,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Color(0xFF64748B)),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: _units
                              .map(
                                  (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUnit = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CARD 2: PRICING & RETAIL MARGIN ─────────────────────────────────────────
  Widget _buildPricingMarginCard() {
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
          const Text(
            'PRICING & RETAIL MARGIN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Cost & Retail price fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Cost Price'),
                    const SizedBox(height: 5),
                    _priceField(
                      controller: _costPriceController,
                      hint: '0',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Retail Price'),
                    const SizedBox(height: 5),
                    _priceField(
                      controller: _retailPriceController,
                      hint: '0',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Profit banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF86EFAC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF15803D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.trending_up, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit: PKR ${_profitPerUnit.toStringAsFixed(0)} per unit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                        ),
                      ),
                      const Text(
                        'Net markup based on retail',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${_markupPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 10,
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
    );
  }

  // ── CARD 3: INITIAL STOCK & ALERTS ──────────────────────────────────────────
  Widget _buildInitialStockAlertsCard() {
    final unitLabel = _selectedUnit.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INITIAL STOCK & ALERTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 11, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text(
                      'Primary Warehouse',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Opening Stock Quantity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Tap number to edit',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Modern Stepper & Centered Large Number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large Minus Button
              Material(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final curr = int.tryParse(_stockController.text.trim()) ??
                        _stockQuantity;
                    if (curr > 0) {
                      final newVal = curr - 1;
                      setState(() {
                        _stockQuantity = newVal;
                        _stockController.text = '$newVal';
                      });
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Icon(Icons.remove,
                          size: 22, color: Color(0xFF334155)),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Centered Number Display & Editable Field
              Expanded(
                child: Container(
                  height: 64,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: '0',
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val.trim());
                            if (parsed != null) {
                              _stockQuantity = parsed;
                            }
                          },
                        ),
                      ),
                      Text(
                        unitLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Large Plus Button
              Material(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final curr = int.tryParse(_stockController.text.trim()) ??
                        _stockQuantity;
                    final newVal = curr + 1;
                    setState(() {
                      _stockQuantity = newVal;
                      _stockController.text = '$newVal';
                    });
                  },
                  child: Container(
                    width: 52,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 24, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Action Increment & Decrement Pills
          Row(
            children: [
              // Decrement pill -10
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final curr = int.tryParse(_stockController.text.trim()) ??
                        _stockQuantity;
                    final newVal = (curr - 10).clamp(0, 999999);
                    setState(() {
                      _stockQuantity = newVal;
                      _stockController.text = '$newVal';
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: const Center(
                      child: Text(
                        '-10',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ...[10, 25, 50, 100].map((val) {
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final curr = int.tryParse(_stockController.text.trim()) ??
                          _stockQuantity;
                      final newVal = curr + val;
                      setState(() {
                        _stockQuantity = newVal;
                        _stockController.text = '$newVal';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Center(
                        child: Text(
                          '+$val',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 14),

          // Low stock threshold card with unified stepper pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Low Stock Threshold',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Alert when stock falls below this',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Unified Stepper Pill: [-] 5 [+]
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFFECACA), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20)),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final curr =
                              int.tryParse(_lowStockController.text.trim()) ??
                                  _lowStockThreshold;
                          if (curr > 0) {
                            final newVal = curr - 1;
                            setState(() {
                              _lowStockThreshold = newVal;
                              _lowStockController.text = '$newVal';
                            });
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9, vertical: 7),
                          child: Icon(Icons.remove,
                              size: 15, color: Color(0xFF0F172A)),
                        ),
                      ),

                      // Editable threshold input box inside pill
                      SizedBox(
                        width: 38,
                        child: TextField(
                          controller: _lowStockController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC2626),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: '5',
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val.trim());
                            setState(() {
                              _lowStockThreshold = parsed ?? 5;
                            });
                          },
                        ),
                      ),

                      // Plus
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(20)),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final curr =
                              int.tryParse(_lowStockController.text.trim()) ??
                                  _lowStockThreshold;
                          final newVal = curr + 1;
                          setState(() {
                            _lowStockThreshold = newVal;
                            _lowStockController.text = '$newVal';
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9, vertical: 7),
                          child:
                              Icon(Icons.add, size: 15, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Text(
            'SmartKhata will alert for reordering at $_lowStockThreshold units.',
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ── CARD 4: TRACK EXPIRY & BATCH ────────────────────────────────────────────
  Widget _buildTrackExpiryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_note_outlined,
                size: 18, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Expiry & Batch',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Recommended for perishables & milk',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _trackExpiry,
              activeTrackColor: const Color(0xFF16A34A),
              onChanged: (val) => setState(() => _trackExpiry = val),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10.5,
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _priceField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFCBD5E1),
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1.0,
            child: Text(
              'PKR',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
          borderSide:
              const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
    );
  }
}
