import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../state/inventory_state.dart';
import '../shared_widgets/custom_app_bar.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? existingProduct;

  const AddEditProductScreen({super.key, this.existingProduct});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _retailPriceController;

  int _stockQuantity = 50;
  final int _lowStockThreshold = 5;
  String _selectedCategory = 'Packaged Goods / Tea';
  final String _selectedUnit = 'Pack';
  bool _trackExpiry = false;

  static const List<String> _categories = [
    'Packaged Goods / Tea',
    'Dairy & Milk',
    'Cooking Oil & Ghee',
    'Snacks & Biscuits',
    'Beverages & Drinks',
    'Spices & Condiments',
    'Bakery & Bread',
    'Household Goods',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _nameController = TextEditingController(text: p?.title ?? '');
    _costPriceController = TextEditingController(
      text: p != null ? p.costPrice.toStringAsFixed(0) : '',
    );
    _retailPriceController = TextEditingController(
      text: p != null ? p.salePrice.toStringAsFixed(0) : '',
    );
    if (p != null) {
      _stockQuantity = p.stockQty;
      _selectedCategory = p.category;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product name')),
      );
      return;
    }

    final newProd = ProductModel(
      id: widget.existingProduct?.id ??
          'p_${DateTime.now().millisecondsSinceEpoch}',
      barcode: _barcodeController.text.trim(),
      title: title,
      costPrice: _costPrice,
      salePrice: _retailPrice,
      stockQty: _stockQuantity,
      category: _selectedCategory,
    );

    if (_isEditing) {
      InventoryState.instance.updateProduct(newProd);
    } else {
      InventoryState.instance.addProduct(newProd);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title saved to inventory!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Product' : 'Add New Product',
        showLogo: true,
        actions: [
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
            // CARD 1: PRODUCT IDENTIFICATION
            _buildProductIdentificationCard(),

            const SizedBox(height: 12),

            // CARD 2: PRICING & RETAIL MARGIN
            _buildPricingMarginCard(),

            const SizedBox(height: 12),

            // CARD 3: INITIAL STOCK & ALERTS
            _buildInitialStockAlertsCard(),

            const SizedBox(height: 12),

            // CARD 4: TRACK EXPIRY & BATCH SWITCH
            _buildTrackExpiryCard(),

            const SizedBox(height: 20),

            // Primary Save Button
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

            const SizedBox(height: 10),

            // Footer note
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
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final scanned = await Navigator.pushNamed(
                          context, AppRoutes.posScanner);
                      if (scanned != null && scanned is String) {
                        setState(() => _barcodeController.text = scanned);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
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

          // Category Selector
          _fieldLabel('Category'),
          const SizedBox(height: 5),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                items: _categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Unit chip (static)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 11, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      'Unit: $_selectedUnit',
                      style: const TextStyle(
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
                'INITIAL STOCK & ALERTS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Primary Warehouse',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _fieldLabel('Opening Stock Quantity'),
          const SizedBox(height: 8),

          // Stepper
          Row(
            children: [
              // Minus
              GestureDetector(
                onTap: () {
                  if (_stockQuantity > 0) setState(() => _stockQuantity--);
                },
                child: Container(
                  width: 54,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.remove, size: 20, color: Color(0xFF0F172A)),
                  ),
                ),
              ),

              // Count display
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_stockQuantity',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'PACKS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Plus
              GestureDetector(
                onTap: () => setState(() => _stockQuantity++),
                child: Container(
                  width: 54,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick increment chips
          Row(
            children: [10, 25, 50, 100].map((val) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _stockQuantity += val),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '+$val',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Low stock threshold info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 15, color: Color(0xFFC2410C)),
                    SizedBox(width: 5),
                    Text(
                      'Low Stock Threshold',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Center(
                    child: Text(
                      '$_lowStockThreshold',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Text(
            'SmartKhata will alert for reordering at $_lowStockThreshold units.',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
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
