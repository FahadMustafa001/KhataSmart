import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/esc_pos_service.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../state/cart_state.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../shared_widgets/barcode_visual_widget.dart';
import '../shared_widgets/custom_app_bar.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final OrderModel? order;

  const ReceiptPreviewScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    final activeShop = ShopState.instance.activeShop;
    OrderModel? actualOrder = order;

    // 1. If not provided directly, check if KhataState has orders with items
    if ((actualOrder == null || actualOrder.items.isEmpty) &&
        KhataState.instance.orders.isNotEmpty) {
      try {
        actualOrder =
            KhataState.instance.orders.firstWhere((o) => o.items.isNotEmpty);
      } catch (_) {}
    }

    // 2. If no completed orders exist, but CartState currently has items, create a live preview from cart
    if ((actualOrder == null || actualOrder.items.isEmpty) &&
        CartState.instance.items.isNotEmpty) {
      actualOrder = OrderModel(
        invoiceNo: 'SK-${DateTime.now().millisecondsSinceEpoch % 10000}',
        date: DateTime.now(),
        items: List.from(CartState.instance.items),
        subtotal: CartState.instance.subtotal,
        discount: CartState.instance.discount,
        total: CartState.instance.netPayable,
        paymentMode: PaymentMode.cash,
        shopId: activeShop.id,
      );
    }

    // 3. If still null or empty (e.g. fresh app preview without any cart or order), generate realistic demo products from Inventory
    if (actualOrder == null || actualOrder.items.isEmpty) {
      final availableProducts = InventoryState.instance.products;
      final List<CartItemModel> sampleItems = [];
      if (availableProducts.isNotEmpty) {
        for (var i = 0; i < availableProducts.take(3).length; i++) {
          sampleItems.add(CartItemModel(product: availableProducts[i], quantity: i + 1));
        }
      } else {
        // High quality realistic retail products
        final sampleProd1 = ProductModel(
          id: 'sample_1',
          barcode: '896400012345',
          title: 'Olpers Milk 1 Litre (UHT)',
          salePrice: 290.0,
          costPrice: 260.0,
          stockQty: 50,
          category: 'Dairy',
          shopId: activeShop.id,
        );
        final sampleProd2 = ProductModel(
          id: 'sample_2',
          barcode: '896400067890',
          title: 'Tapal Danedar Tea 450g',
          salePrice: 680.0,
          costPrice: 620.0,
          stockQty: 30,
          category: 'Grocery',
          shopId: activeShop.id,
        );
        final sampleProd3 = ProductModel(
          id: 'sample_3',
          barcode: '896400098765',
          title: 'Habib Cooking Oil 1 Litre Pouch',
          salePrice: 540.0,
          costPrice: 495.0,
          stockQty: 40,
          category: 'Cooking Essentials',
          shopId: activeShop.id,
        );
        sampleItems.add(CartItemModel(product: sampleProd1, quantity: 2));
        sampleItems.add(CartItemModel(product: sampleProd2, quantity: 1));
        sampleItems.add(CartItemModel(product: sampleProd3, quantity: 1));
      }

      final sub = sampleItems.fold(0.0, (s, i) => s + (i.product.salePrice * i.quantity));
      final disc = 40.0;
      actualOrder = OrderModel(
        invoiceNo: 'SK-519',
        date: DateTime.now(),
        items: sampleItems,
        subtotal: sub,
        discount: disc,
        total: (sub - disc).clamp(0.0, double.infinity),
        paymentMode: PaymentMode.cash,
        shopId: activeShop.id,
      );
    }

    final invoiceNumber = actualOrder.invoiceNo.isNotEmpty
        ? actualOrder.invoiceNo
        : 'SK-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final items = actualOrder.items;
    final subtotal = actualOrder.subtotal;
    final discount = actualOrder.discount;
    final netPayable = actualOrder.total;
    final effectiveOrder = actualOrder;
    final isUdhaar = actualOrder.paymentMode == PaymentMode.udhaar;
    final hasSplit =
        (actualOrder.creditAmount > 0 && actualOrder.paidAmount > 0);
    final tenderedAmount = isUdhaar
        ? 0.0
        : (hasSplit
            ? actualOrder.paidAmount
            : (netPayable > 0
                ? (netPayable < 1000
                    ? 1000.0
                    : ((netPayable / 500).ceil() * 500.0))
                : 0.0));
    final changeAmount =
        isUdhaar || hasSplit ? 0.0 : (tenderedAmount - netPayable);
    final paymentTag = isUdhaar
        ? 'STORE CREDIT'
        : (hasSplit
            ? 'SPLIT PAYMENT'
            : 'PAID • ${actualOrder.paymentMode.name.toUpperCase()}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.posCart);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Receipt Preview',
          subtitle: invoiceNumber,
          showLogo: true,
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.posCart);
            }
          },
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF1E293B)),
            tooltip: 'Share Digital Receipt PDF',
            onPressed: () {
              PrintingAndSharingService.instance.printOrShareReceipt(
                order: effectiveOrder,
                shop: ShopState.instance.activeShop,
                isDirectPrint: false,
              );
            },
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Sale Completed Successfully Pill Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Sale Completed Successfully',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // REF: #SK-8942
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                children: [
                  const TextSpan(text: 'REF : '),
                  TextSpan(
                    text: '#$invoiceNumber',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            const Text(
              'Transaction saved to local ledger & synced to cloud',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 14),

            // Realistic Thermal Receipt Paper Card (58mm Style)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Opacity(
                        opacity: 0.05,
                        child: Image.asset(
                          AppAssets.receiptWatermark,
                          width: 170,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 16.0),
                    child: Column(
                      children: [
                        // Top store logo badge
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            AppAssets.appLogo,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Store Details
                        Text(
                          activeShop.name.isNotEmpty
                              ? activeShop.name.toUpperCase()
                              : 'SMARTKHATA RETAIL POS',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${activeShop.ownerName.isNotEmpty ? "${activeShop.ownerName}'s Store • " : ""}Counter POS Terminal 01\n'
                          '${activeShop.address.isNotEmpty ? "${activeShop.address}\n" : ""}'
                          '${activeShop.phone.isNotEmpty ? "Ph: ${activeShop.phone} • " : ""}'
                          'Cashier: ${activeShop.ownerName.isNotEmpty ? activeShop.ownerName : "Cash Counter"}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                        if (actualOrder.customer != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              'Customer: ${actualOrder.customer!.name}${actualOrder.customer!.phone.isNotEmpty ? " (${actualOrder.customer!.phone})" : ""}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Date & Bill Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormatter.format(
                                  actualOrder.dateTime),
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: Color(0xFF334155)),
                            ),
                            Text(
                              'Bill: $invoiceNumber',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        const Text(
                          '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                          style: TextStyle(color: Colors.black26, fontSize: 10),
                        ),
                        const SizedBox(height: 4),

                        // Table Headers
                        const Row(
                          children: [
                            Expanded(
                                flex: 5,
                                child: Text('ITEM',
                                    style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('QTY',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('RATE',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 3,
                                child: Text('TOTAL',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Line Items
                        if (items.isNotEmpty)
                          ...items.map(
                            (i) => _buildReceiptRow(
                              i.product.name.isNotEmpty ? i.product.name : i.product.title,
                              '${i.quantity}',
                              CurrencyFormatter.format(i.product.salePrice),
                              CurrencyFormatter.format(i.product.salePrice * i.quantity),
                            ),
                          )
                        else
                          _buildReceiptRow('No items billed', '-', '0', '0.00'),

                        const SizedBox(height: 4),
                        const Text(
                          '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                          style: TextStyle(color: Colors.black26, fontSize: 10),
                        ),
                        const SizedBox(height: 4),

                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    color: Color(0xFF334155))),
                            Text('PKR ${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A))),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Promo Discount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Promo Discount (SAVER)',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A))),
                            Text('- PKR ${discount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A))),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Line counts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Lines: ${items.length}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    color: Color(0xFF64748B))),
                            Text(
                                'Total Units: ${items.fold(0, (sum, i) => sum + i.quantity)}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    color: Color(0xFF64748B))),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // NET PAYABLE Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'NET PAYABLE',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'PKR ${netPayable.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF15803D),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      paymentTag,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isUdhaar
                                        ? 'Payment: Store Credit'
                                        : (hasSplit
                                            ? 'Paid: ${CurrencyFormatter.format(actualOrder.paidAmount)}'
                                            : 'Tendered: ${CurrencyFormatter.format(tenderedAmount)}'),
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: Color(0xFF475569)),
                                  ),
                                  Text(
                                    isUdhaar
                                        ? 'Balance Due: ${CurrencyFormatter.format(netPayable)}'
                                        : (hasSplit
                                            ? 'Udhar Due: ${CurrencyFormatter.format(actualOrder.creditAmount)}'
                                            : 'Change: ${CurrencyFormatter.format(changeAmount)}'),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (isUdhaar || hasSplit)
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Barcode & Raast QR Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Barcode
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const BarcodeVisualWidget(
                                    height: 36, width: 140),
                                const SizedBox(height: 3),
                                Text(
                                  '*$invoiceNumber*',
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8.5,
                                      color: Colors.black54),
                                ),
                              ],
                            ),

                            // Raast QR Box
                            Column(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black87, width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.qr_code_2,
                                      size: 36, color: Colors.black87),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'RAAST VERIFIED',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Receipt Footnotes
                        Text(
                          activeShop.receiptFooter.isNotEmpty
                              ? activeShop.receiptFooter
                              : '*** Thank you for shopping with us! ***\nGoods once sold can be exchanged within 3 days with receipt.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 10, color: Color(0xFF94A3B8)),
                            SizedBox(width: 3),
                            Text(
                              'Powered by SmartKhata POS v2.4',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Primary Action Button: Send via WhatsApp
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  PrintingAndSharingService.instance.sendReceiptViaWhatsApp(
                    order: effectiveOrder,
                    shop: ShopState.instance.activeShop,
                  );
                },
                icon:
                    Image.asset(AppAssets.whatsappIcon, width: 40, height: 40),
                label: const Text(
                  'Send via WhatsApp',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF15803D), // Forest WhatsApp Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Secondary Row: Print Slip & SMS Receipt
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final activeShop = ShopState.instance.activeShop;
                          final printerUrl = activeShop.preferredPrinterUrl;
                          if (printerUrl != null) {
                            try {
                              final printers = await EscPosService.instance.getAvailablePrinters();
                              final targetList = printers.where((dynamic p) => p.url == printerUrl).toList();
                              if (targetList.isNotEmpty) {
                                await EscPosService.instance.directPrintReceipt(
                                  order: effectiveOrder,
                                  shop: activeShop,
                                  printer: targetList.first,
                                );
                                return;
                              }
                            } catch (e) {
                              debugPrint('Direct printer connection error: $e');
                            }
                          }
                          await PrintingAndSharingService.instance.printOrShareReceipt(
                            order: effectiveOrder,
                            shop: activeShop,
                            isDirectPrint: true,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(AppAssets.printerIcon,
                                width: 20, height: 20),
                            const SizedBox(width: 6),
                            const Text(
                              'Print Slip',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          PrintingAndSharingService.instance.sendReceiptViaSms(
                            order: effectiveOrder,
                            shop: ShopState.instance.activeShop,
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sms_outlined,
                                size: 16, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 6),
                            Text(
                              'SMS Receipt',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 5. Download digital PDF copy
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    PrintingAndSharingService.instance.printOrShareReceipt(
                      order: effectiveOrder,
                      shop: ShopState.instance.activeShop,
                      isDirectPrint: false,
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined,
                              size: 18, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text(
                            'Download digital PDF copy',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.file_download_outlined,
                          size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Next Customer (New Sale) Link
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  CartState.instance.clear();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.posCart,
                    (route) => route.settings.name == AppRoutes.dashboard,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next Customer (New Sale)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  static Widget _buildReceiptRow(
      String item, String qty, String rate, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rate,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              total,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
