import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

/// Professional ESC/POS Command Byte Generator & Thermal Printer Service
/// Supports standard 58mm (32 cols) and 80mm (48 cols) Bluetooth & USB printers.
class EscPosService {
  EscPosService._();
  static final EscPosService instance = EscPosService._();

  // ESC/POS Command Constants
  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  /// Discovers available system, USB, and paired Bluetooth thermal printers
  Future<List<Printer>> getAvailablePrinters() async {
    try {
      final list = await Printing.listPrinters();
      return list;
    } catch (e) {
      debugPrint('Error listing printers: $e');
      return [];
    }
  }

  /// Sends receipt directly to a specific Bluetooth/thermal printer without opening the OS print dialog
  Future<bool> directPrintReceipt({
    required OrderModel order,
    required ShopModel shop,
    Printer? printer,
  }) async {
    try {
      final is80mm = shop.paperSize.toLowerCase().contains('80');
      final rollFormat = is80mm
          ? PdfPageFormat.roll80
          : const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: rollFormat,
          margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  shop.name,
                  style: pw.TextStyle(
                    fontSize: is80mm ? 16 : 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (shop.address.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      shop.address,
                      style: pw.TextStyle(fontSize: is80mm ? 9 : 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                if (shop.phone.isNotEmpty)
                  pw.Text(
                    'Tel: ${shop.phone}',
                    style: pw.TextStyle(fontSize: is80mm ? 9 : 8),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'RETAIL INVOICE / CASH MEMO',
                  style: pw.TextStyle(
                    fontSize: is80mm ? 10 : 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(thickness: 0.8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Inv: #${order.invoiceNo}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(DateFormatter.formatDateTime(order.date), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (order.customerName != null && order.customerName!.isNotEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Customer: ${order.customerName}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.Divider(thickness: 0.8),
                pw.Row(
                  children: [
                    pw.Expanded(flex: 4, child: pw.Text('Item', style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text('Rate', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                ...order.items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 7.5), maxLines: 1),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 7.5),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            CurrencyFormatter.format(item.sellingPrice),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 7.5),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            CurrencyFormatter.format(item.totalPrice),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                pw.Divider(thickness: 0.8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(CurrencyFormatter.format(order.subtotal), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (order.discount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('-${CurrencyFormatter.format(order.discount)}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET TOTAL:', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(CurrencyFormatter.format(order.total), style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Payment Mode: ${order.paymentMode.name.toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
                pw.Divider(thickness: 0.8),
                if (shop.receiptFooter.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      shop.receiptFooter,
                      style: pw.TextStyle(fontSize: is80mm ? 8.5 : 7.5, fontStyle: pw.FontStyle.italic),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                pw.Text('KhataSmart POS', style: const pw.TextStyle(fontSize: 6.5)),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      if (printer != null) {
        return await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) async => pdfBytes,
          format: rollFormat,
          name: 'Invoice_${order.invoiceNo}',
        );
      } else {
        // Fallback: Opens system thermal print layout dialog
        return await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'Invoice_${order.invoiceNo}',
          format: rollFormat,
        );
      }
    } catch (e) {
      debugPrint('Direct thermal print error: $e');
      return false;
    }
  }

  /// Sends a quick alignment and connectivity test slip to the chosen printer
  Future<bool> printTestSlip({
    required ShopModel shop,
    Printer? printer,
  }) async {
    final testOrder = OrderModel(
      invoiceNo: 'TEST-${DateTime.now().millisecondsSinceEpoch % 1000}',
      items: [
        CartItemModel(
          product: ProductModel(
            id: 'test_1',
            barcode: '12345678',
            title: 'Sample Thermal Item A',
            costPrice: 100,
            salePrice: 150,
            stockQty: 10,
          ),
          quantity: 2,
        ),
        CartItemModel(
          product: ProductModel(
            id: 'test_2',
            barcode: '87654321',
            title: 'Sample Thermal Item B',
            costPrice: 350,
            salePrice: 500,
            stockQty: 5,
          ),
          quantity: 1,
        ),
      ],
      total: 800,
      subtotal: 800,
      paymentMode: PaymentMode.cash,
      date: DateTime.now(),
    );

    return directPrintReceipt(
      order: testOrder,
      shop: shop,
      printer: printer,
    );
  }

  /// Generates pure standard ESC/POS binary command bytes for Bluetooth raw socket transmission.
  Uint8List generateEscPosBytes(OrderModel order, ShopModel shop) {
    final is80mm = shop.paperSize.toLowerCase().contains('80');
    final maxCols = is80mm ? 48 : 32;
    final List<int> bytes = [];

    // 1. Initialize Printer (ESC @)
    bytes.addAll([_esc, 0x40]);

    // 2. Center alignment (ESC a 1)
    bytes.addAll([_esc, 0x61, 0x01]);

    // Double-height Bold Shop Name (GS ! 0x01, ESC E 1)
    bytes.addAll([_gs, 0x21, 0x01]);
    bytes.addAll([_esc, 0x45, 0x01]);
    bytes.addAll(utf8.encode('${shop.name}\n'));

    // Normal Font (GS ! 0x00, ESC E 0)
    bytes.addAll([_gs, 0x21, 0x00]);
    bytes.addAll([_esc, 0x45, 0x00]);

    if (shop.address.isNotEmpty) {
      bytes.addAll(utf8.encode('${shop.address}\n'));
    }
    if (shop.phone.isNotEmpty) {
      bytes.addAll(utf8.encode('Tel: ${shop.phone}\n'));
    }

    bytes.addAll(utf8.encode('RETAIL INVOICE\n'));
    bytes.addAll(utf8.encode('${"-" * maxCols}\n'));

    // 3. Left alignment (ESC a 0) for metadata
    bytes.addAll([_esc, 0x61, 0x00]);
    bytes.addAll(utf8.encode('Inv: #${order.invoiceNo}\n'));
    bytes.addAll(utf8.encode('Date: ${DateFormatter.formatDateTime(order.date)}\n'));
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      bytes.addAll(utf8.encode('Cust: ${order.customerName}\n'));
    }

    bytes.addAll(utf8.encode('${"-" * maxCols}\n'));

    // Table Header
    if (is80mm) {
      // 48 columns: Item(22) Qty(6) Rate(9) Total(11)
      bytes.addAll(utf8.encode('${_padRight('Item', 22)}${_padCenter('Qty', 6)}${_padLeft('Rate', 9)}${_padLeft('Total', 11)}\n'));
    } else {
      // 32 columns: Item(14) Qty(4) Rate(6) Total(8)
      bytes.addAll(utf8.encode('${_padRight('Item', 14)}${_padCenter('Qty', 4)}${_padLeft('Rate', 6)}${_padLeft('Total', 8)}\n'));
    }
    bytes.addAll(utf8.encode('${"-" * maxCols}\n'));

    // Items
    for (final item in order.items) {
      final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
      final rateStr = CurrencyFormatter.format(item.sellingPrice);
      final totStr = CurrencyFormatter.format(item.totalPrice);

      if (is80mm) {
        if (rateStr.length > 9 || totStr.length > 11 || qtyStr.length > 6 || item.productName.length > 21) {
          bytes.addAll(utf8.encode('${item.productName}\n'));
          bytes.addAll(utf8.encode('${_padRight('', 18)}${_padCenter(qtyStr, 8)}${_padLeft(rateStr, 11)}${_padLeft(totStr, 11)}\n'));
        } else {
          bytes.addAll(utf8.encode('${_padRight(item.productName, 22)}${_padCenter(qtyStr, 6)}${_padLeft(rateStr, 9)}${_padLeft(totStr, 11)}\n'));
        }
      } else {
        if (rateStr.length > 6 || totStr.length > 8 || qtyStr.length > 4 || item.productName.length > 13) {
          bytes.addAll(utf8.encode('${item.productName}\n'));
          bytes.addAll(utf8.encode('${_padRight('', 8)}${_padCenter(qtyStr, 6)}${_padLeft(rateStr, 8)}${_padLeft(totStr, 10)}\n'));
        } else {
          bytes.addAll(utf8.encode('${_padRight(item.productName, 14)}${_padCenter(qtyStr, 4)}${_padLeft(rateStr, 6)}${_padLeft(totStr, 8)}\n'));
        }
      }
    }

    bytes.addAll(utf8.encode('${"-" * maxCols}\n'));

    // Totals (Right aligned)
    bytes.addAll(utf8.encode('${_alignKeyValue('Subtotal:', CurrencyFormatter.format(order.subtotal), maxCols)}\n'));
    if (order.discount > 0) {
      bytes.addAll(utf8.encode('${_alignKeyValue('Discount:', '-${CurrencyFormatter.format(order.discount)}', maxCols)}\n'));
    }

    // Bold Net Total
    bytes.addAll([_esc, 0x45, 0x01]);
    bytes.addAll(utf8.encode('${_alignKeyValue('NET PAYABLE:', CurrencyFormatter.format(order.total), maxCols)}\n'));
    bytes.addAll([_esc, 0x45, 0x00]);

    bytes.addAll(utf8.encode('Pay Mode: ${order.paymentMode.name.toUpperCase()}\n'));
    bytes.addAll(utf8.encode('${"-" * maxCols}\n'));

    // Footer & Center Align
    bytes.addAll([_esc, 0x61, 0x01]);
    if (shop.receiptFooter.isNotEmpty) {
      bytes.addAll(utf8.encode('${shop.receiptFooter}\n'));
    }
    bytes.addAll(utf8.encode('*** Thank You! Visit Again ***\n'));

    // Feed lines & Cut Paper (ESC d 3, GS V 1)
    bytes.addAll([_esc, 0x64, 0x03]); // feed 3 lines
    bytes.addAll([_gs, 0x56, 0x01]); // partial paper cut

    return Uint8List.fromList(bytes);
  }

  // String column layout helpers
  String _padRight(String s, int width) => s.length >= width ? s.substring(0, width) : s.padRight(width);
  String _padLeft(String s, int width) => s.length >= width ? s : s.padLeft(width);
  String _padCenter(String s, int width) {
    if (s.length >= width) return s;
    final leftPadding = (width - s.length) ~/ 2;
    return s.padLeft(s.length + leftPadding).padRight(width);
  }

  String _alignKeyValue(String key, String value, int maxCols) {
    final available = maxCols - key.length;
    if (available <= 0) return '$key $value';
    return key + value.padLeft(available);
  }
}
