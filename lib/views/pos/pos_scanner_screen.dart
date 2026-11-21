import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/app_toast.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../state/cart_state.dart';
import '../../state/inventory_state.dart';

class PosScannerScreen extends StatefulWidget {
  const PosScannerScreen({super.key});

  @override
  State<PosScannerScreen> createState() => _PosScannerScreenState();
}

class _PosScannerScreenState extends State<PosScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _laserController;

  final _cartState = CartState.instance;
  final _inventoryState = InventoryState.instance;

  bool _flashOn = false;
  bool _continuousScan = true;
  ProductModel? _lastScannedProduct;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;
  int _scannedQty = 1;
  bool _isCaptureMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map &&
        (args['mode'] == 'lookup' ||
            args['mode'] == 'barcode_capture' ||
            args['mode'] == 'entry')) {
      _isCaptureMode = true;
    } else if (args is String &&
        (args == 'barcode_capture' ||
            args == 'entry' ||
            args == 'lookup')) {
      _isCaptureMode = true;
    }
  }

  void _navigateBackWithResult([dynamic result]) {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.posCart);
    }
  }

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _cartState.addListener(_rebuild);
    _inventoryState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _cartState.removeListener(_rebuild);
    _inventoryState.removeListener(_rebuild);
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  // ── Handle Real Barcode Detection ──────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        _processBarcode(rawValue);
        break;
      }
    }
  }

  void _processBarcode(String code, {bool isManual = false}) {
    if (!mounted) return;
    if (!isManual && (ModalRoute.of(context)?.isCurrent != true)) {
      return;
    }

    final now = DateTime.now();
    // Debounce to prevent multi-triggering within 1.2s for identical code
    if (_lastScannedBarcode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1200) {
      return;
    }
    _lastScanTime = now;
    _lastScannedBarcode = code;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // In barcode capture / new product mode, return code directly to form or show create button
    if (_isCaptureMode) {
      _showNotification(
        title: 'Barcode Captured!',
        subtitle: code,
        isSuccess: true,
      );
      if (Navigator.canPop(context)) {
        _navigateBackWithResult(code);
      } else {
        setState(() {
          _lastScannedBarcode = code;
        });
      }
      return;
    }

    // Check inventory
    ProductModel? match;
    for (final p in _inventoryState.products) {
      if (p.barcode.trim().toLowerCase() == code.toLowerCase()) {
        match = p;
        break;
      }
    }

    if (match != null) {
      // 1. Found in inventory -> Add to Cart
      _cartState.addItem(match);
      final inCartItem = _cartState.items.where((i) => i.product.id == match!.id).firstOrNull;

      setState(() {
        _lastScannedProduct = match;
        _scannedQty = inCartItem?.quantity ?? 1;
      });

      _showNotification(
        title: 'Scanned: ${match.name}',
        subtitle: 'PKR ${match.salePrice.toStringAsFixed(0)} • Cart updated',
        isSuccess: true,
      );

      if (!_continuousScan) {
        // In single scan mode, return the barcode to caller
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateBackWithResult(code);
        });
      }
    } else {
      // 2. Not in inventory -> Prompt to add product or return barcode
      setState(() {
        _lastScannedProduct = null;
      });

      _showUnrecognizedBarcodeSheet(code);
    }
  }

  void _showNotification({
    required String title,
    required String subtitle,
    required bool isSuccess,
  }) {
    if (isSuccess) {
      AppToast.showSuccess(context, subtitle, title: title);
    } else {
      AppToast.showWarning(context, subtitle, title: title);
    }
  }

  void _showUnrecognizedBarcodeSheet(String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Naya Barcode Scan Hua!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Code: $code',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'This barcode was not found in your inventory. Would you like to add a new product with this barcode?',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateBackWithResult(code); // Return barcode directly
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Use Barcode'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.addEditProduct,
                          arguments: code,
                        );
                      },
                      icon: const Icon(Icons.add, size: 17, color: Colors.white),
                      label: const Text(
                        'Naya Product Banayein',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Manual Barcode Entry Dialog ───────────────────────────────────────────
  void _showManualInputDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.keyboard, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text(
                'Enter Barcode Manually',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type or paste barcode number:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 896400010023',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  prefixIcon: const Icon(Icons.qr_code, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = textController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(ctx);
                  _processBarcode(code, isManual: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Lookup & Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBackWithResult();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Live Camera Barcode Scanner View
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  return _buildScannerErrorView(error);
                },
              ),
            ),

            // 2. Translucent Viewfinder Overlay Mask with Target Window
            Positioned.fill(
              child: _buildScannerOverlay(),
            ),

            // 3. Top Action Controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildTopControls(context),
              ),
            ),

            // 4. Bottom Detected Product Card / Cart Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: _buildBottomProductCard(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overlay Mask & Viewfinder Box ──────────────────────────────────────────
  Widget _buildScannerOverlay() {
    final screenSize = MediaQuery.of(context).size;
    const boxWidth = 260.0;
    const boxHeight = 180.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Viewfinder Target Frame
        SizedBox(
          width: boxWidth,
          height: boxHeight,
          child: Stack(
            children: [
              // 4 Corner Neon Brackets
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScannerBracketPainter(),
                ),
              ),

              // Animated Laser Line
              AnimatedBuilder(
                animation: _laserController,
                builder: (context, child) {
                  return Positioned(
                    top: 10 + (_laserController.value * (boxHeight - 20)),
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.9),
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

        // Helper alignment guide pill
        Positioned(
          top: (screenSize.height / 2) + (boxHeight / 2) + 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, size: 14, color: Color(0xFF4ADE80)),
                const SizedBox(width: 6),
                Text(
                  _isCaptureMode
                      ? 'Point camera at barcode to capture for new product'
                      : 'Point camera at product barcode to add to bill',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Top Controls Bar ───────────────────────────────────────────────────────
  Widget _buildTopControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          Material(
            color: const Color(0x80000000),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _navigateBackWithResult(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Mode Switcher: Bill Scan vs Product Entry
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isCaptureMode = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: !_isCaptureMode ? const Color(0xFF16A34A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Bill Scan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: !_isCaptureMode ? FontWeight.bold : FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isCaptureMode = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isCaptureMode ? const Color(0xFF2563EB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Product Entry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _isCaptureMode ? FontWeight.bold : FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Flashlight, Camera Switch & Manual Input Actions
          Row(
            children: [
              // Manual Barcode entry button
              Material(
                color: const Color(0x80000000),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _showManualInputDialog,
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.keyboard_alt_outlined, color: Colors.white, size: 19),
                  ),
                ),
              ),

              // Switch camera button
              Material(
                color: const Color(0x80000000),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _scannerController.switchCamera(),
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.cameraswitch_outlined, color: Colors.white, size: 19),
                  ),
                ),
              ),

              // Flash / Torch button
              Material(
                color: _flashOn
                    ? const Color(0xFFF59E0B)
                    : const Color(0x80000000),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    await _scannerController.toggleTorch();
                    setState(() => _flashOn = !_flashOn);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Detected Product Card / Cart Bar ────────────────────────────────
  Widget _buildBottomProductCard(BuildContext context) {
    if (_isCaptureMode) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code,
                      color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Barcode Entry Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lastScannedBarcode != null
                            ? 'Code: $_lastScannedBarcode'
                            : 'Scan any product to capture its barcode',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily:
                              _lastScannedBarcode != null ? 'monospace' : null,
                          fontWeight: _lastScannedBarcode != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _lastScannedBarcode != null
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _lastScannedBarcode != null
                      ? 'Use Barcode ($_lastScannedBarcode)'
                      : 'Scan or Enter Manually',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (_lastScannedBarcode != null) {
                    _navigateBackWithResult(_lastScannedBarcode);
                  } else {
                    _showManualInputDialog();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    final product = _lastScannedProduct;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product != null) ...[
            // Row 1: Detected Product Name & Barcode Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.name,
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

                // Barcode Pill (Tappable to return code)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _navigateBackWithResult(product.barcode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.barcode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.check, size: 11, color: Color(0xFF16A34A)),
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
                        text: product.salePrice.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextSpan(
                        text: ' / ${product.unit}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            if (_scannedQty > 1) {
                              setState(() => _scannedQty--);
                              _cartState.decrement(product);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.remove, size: 14, color: Color(0xFF1E293B)),
                          ),
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
                      Material(
                        color: const Color(0xFF1E3A8A),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() => _scannedQty++);
                            _cartState.addItem(product);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // In Cart Status
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF16A34A)),
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
          ] else ...[
            // Default when no product scanned yet: Scanner Ready State
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Barcode Scanner Active',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Hold product barcode steadily in front of the camera',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
          ],

          // View Cart / Checkout Main Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.posCart),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
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
                        'View Cart & Checkout',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
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

          // Bottom Toggles: Manual Input & Continuous Scan Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showManualInputDialog,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.keyboard_alt_outlined, size: 15, color: Color(0xFF1E293B)),
                        SizedBox(width: 6),
                        Text(
                          'Manual Input',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Continuous',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _continuousScan,
                      activeTrackColor: const Color(0xFF16A34A),
                      onChanged: (val) => setState(() => _continuousScan = val),
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

  // ── Camera Error Builder ───────────────────────────────────────────────────
  Widget _buildScannerErrorView(MobileScannerException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Camera permission denied.\nPlease grant camera permission in your phone settings to scan barcodes.'
                  : 'Camera initialization error.\n(${error.errorDetails?.message ?? error.errorCode.name})',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _scannerController.start(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard, size: 16, color: Colors.white),
                  label: const Text('Manual Entry', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                  ),
                ),
              ],
            ),
          ],
        ),
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
