import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../state/cart_state.dart';
import '../../state/inventory_state.dart';
import '../shared_widgets/barcode_visual_widget.dart';

class PosScannerScreen extends StatefulWidget {
  const PosScannerScreen({super.key});

  @override
  State<PosScannerScreen> createState() => _PosScannerScreenState();
}

class _PosScannerScreenState extends State<PosScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  final _cartState = CartState.instance;
  final _inventoryState = InventoryState.instance;

  bool _flashOn = false;
  bool _continuousScan = true;
  int _scannedQty = 1;
  int _selectedProductIndex = 0;

  ProductModel get _currentProduct {
    if (_inventoryState.products.isEmpty) {
      return ProductModel(
        id: 'p_temp',
        barcode: '896400010023',
        title: 'Shan Biryani Masala 50g',
        costPrice: 110,
        salePrice: 130,
        stockQty: 45,
        category: 'Spices',
        unit: 'Pack',
        urduName: 'شان بریانی مصالحہ',
      );
    }
    final index = _selectedProductIndex % _inventoryState.products.length;
    return _inventoryState.products[index];
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _cartState.addListener(_rebuild);
    _inventoryState.addListener(_rebuild);
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cartState.removeListener(_rebuild);
    _inventoryState.removeListener(_rebuild);
    _laserController.dispose();
    super.dispose();
  }

  void _onScanCurrentProduct() {
    _cartState.addItem(_currentProduct);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scanned & added ${_currentProduct.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onScanNextSku() {
    if (_inventoryState.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products found in inventory'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedProductIndex =
          (_selectedProductIndex + 1) % _inventoryState.products.length;
      _scannedQty = 1;
    });

    _cartState.addItem(_currentProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scanned & added ${_currentProduct.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Controls Overlay
            _buildTopControls(context),

            // 2. Central Scanner Target Area (Auto-fits without overflow)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Target Frame Box
                      SizedBox(
                        width: 250,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Live item barcode in camera center
                            Container(
                              width: 175,
                              height: 105,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentProduct.name.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  BarcodeVisualWidget(
                                    height: 36,
                                    width: 145,
                                    barColor:
                                        Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentProduct.barcode,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9.5,
                                      color: Colors.white70,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 4 Corner Neon Green Brackets
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ScannerBracketPainter(),
                              ),
                            ),

                            // Glowing Animated Laser Line
                            AnimatedBuilder(
                              animation: _laserController,
                              builder: (context, child) {
                                return Positioned(
                                  top: 15 + (_laserController.value * 145),
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4ADE80),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF22C55E)
                                              .withValues(alpha: 0.9),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Interactive "Tap to Scan Barcode" button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _onScanCurrentProduct,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E)
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF14B8A6)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 15, color: Color(0xFF5EEAD4)),
                                SizedBox(width: 6),
                                Text(
                                  'Tap to Scan Barcode',
                                  style: TextStyle(
                                    color: Color(0xFF5EEAD4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Floating Detected Product Card at Bottom
            _buildBottomProductCard(context),
          ],
        ),
      ),
    );
  }

  // ── Top Controls ─────────────────────────────────────────────────────────────
  Widget _buildTopControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close (X) button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),

          // Center Pill: Align barcode within frame
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, size: 15, color: Color(0xFF4ADE80)),
                SizedBox(width: 6),
                Text(
                  'Align barcode within frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Flash button
          GestureDetector(
            onTap: () => setState(() => _flashOn = !_flashOn),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _flashOn
                    ? const Color(0xFFF59E0B)
                    : Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                _flashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Detected Product Card ─────────────────────────────────────────────
  Widget _buildBottomProductCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Product Title & Barcode Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _currentProduct.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Barcode Pill (Tappable to return/use barcode)
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => Navigator.pop(context, _currentProduct.barcode),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentProduct.barcode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.check,
                          size: 11, color: Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Price, Stepper & Added Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'PKR ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    TextSpan(
                      text: _currentProduct.salePrice.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(
                      text: ' / ${_currentProduct.unit}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Stepper [-] Qty [+]
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_scannedQty > 1) {
                          setState(() => _scannedQty--);
                          _cartState.decrement(_currentProduct);
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
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '$_scannedQty',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _scannedQty++);
                        _cartState.addItem(_currentProduct);
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

              // Added Confirmation Tag
              const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 13, color: Color(0xFF16A34A)),
                  SizedBox(width: 3),
                  Text(
                    'In Cart',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Deep Navy View Cart Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.posCart),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View Cart',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${_cartState.totalItemCount} items • PKR ${_cartState.netPayable.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 15),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Row 4: Scan Next SKU & Continuous Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _onScanNextSku,
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner,
                        size: 15, color: Color(0xFF1E293B)),
                    SizedBox(width: 6),
                    Text(
                      'Scan Next SKU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Continuous',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _continuousScan,
                      activeTrackColor: const Color(0xFF16A34A),
                      onChanged: (val) =>
                          setState(() => _continuousScan = val),
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
}

// 4 Corner Brackets for Neon Scanner Target Reticle
class _ScannerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arm = 24.0;
    const r = 8.0;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, arm)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(arm, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(size.width - arm, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, arm);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, size.height - arm)
      ..lineTo(0, size.height - r)
      ..quadraticBezierTo(0, size.height, r, size.height)
      ..lineTo(arm, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(size.width - arm, size.height)
      ..lineTo(size.width - r, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
      ..lineTo(size.width, size.height - arm);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
