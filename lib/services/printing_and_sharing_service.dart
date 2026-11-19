import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ledger_entry_model.dart';
import '../models/order_model.dart';
import '../models/party_model.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

class PrintingAndSharingService {
  PrintingAndSharingService._();
  static final PrintingAndSharingService instance = PrintingAndSharingService._();

  // ── Helper: Format Pakistani Phone Numbers ────────────────────────────────
  static String formatPhoneForWhatsApp(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('0')) {
      clean = '92${clean.substring(1)}';
    } else if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }
    return clean;
  }

  // ── 1. Native Direct Call ─────────────────────────────────────────────────
  Future<bool> makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return false;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  // ── 2. WhatsApp Receipt Slip ──────────────────────────────────────────────
  Future<void> sendReceiptViaWhatsApp({
    required OrderModel order,
    required ShopModel shop,
    String? customerPhone,
  }) async {
    final phone = formatPhoneForWhatsApp(customerPhone ?? order.customer?.phone ?? '');
    final dateStr =
        '${order.date.day.toString().padLeft(2, '0')}/${order.date.month.toString().padLeft(2, '0')}/${order.date.year}';
    final timeStr =
        '${order.date.hour.toString().padLeft(2, '0')}:${order.date.minute.toString().padLeft(2, '0')}';

    final itemsBuffer = StringBuffer();
    for (final item in order.items) {
      final lineTotal = item.product.salePrice * item.quantity;
      itemsBuffer.writeln(
        '• ${item.product.name} (x${item.quantity}) = PKR ${lineTotal.toStringAsFixed(0)}',
      );
    }

    final message = '''
🧾 *${shop.name.toUpperCase()}*
${shop.address.isNotEmpty ? '${shop.address}\n' : ''}${shop.phone.isNotEmpty ? 'Helpline: ${shop.phone}\n' : ''}
*INVOICE / CASH MEMO*
----------------------------------------
Invoice #: ${order.invoiceNo}
Date: $dateStr  $timeStr
Payment Mode: ${order.paymentMode.name.toUpperCase()}
${order.customer != null ? 'Customer: ${order.customer!.name}\n' : ''}----------------------------------------
*ITEMS:*
${itemsBuffer.toString().trim()}
----------------------------------------
Subtotal: PKR ${order.subtotal.toStringAsFixed(0)}
${order.discount > 0 ? 'Discount: PKR ${order.discount.toStringAsFixed(0)}\n' : ''}*TOTAL AMOUNT: PKR ${order.total.toStringAsFixed(0)}*
----------------------------------------
${shop.receiptFooter}
_Powered by KhataSmart Retail POS_
''';

    if (phone.isNotEmpty) {
      final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
      try {
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched) {
          await Share.share(message, subject: 'Invoice #${order.invoiceNo}');
        }
      } catch (_) {
        await Share.share(message, subject: 'Invoice #${order.invoiceNo}');
      }
    } else {
      await Share.share(message, subject: 'Invoice #${order.invoiceNo}');
    }
  }

  // ── 3. SMS Receipt ────────────────────────────────────────────────────────
  Future<void> sendReceiptViaSms({
    required OrderModel order,
    required ShopModel shop,
    String? customerPhone,
  }) async {
    final phone = (customerPhone ?? order.customer?.phone ?? '').trim();
    final message =
        '${shop.name}: Bill #${order.invoiceNo} for PKR ${order.total.toStringAsFixed(0)} on ${order.date.day}/${order.date.month}/${order.date.year}. Mode: ${order.paymentMode.name.toUpperCase()}. Thank you!';

    if (phone.isNotEmpty) {
      final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    await Share.share(message, subject: 'Invoice #${order.invoiceNo}');
  }

  // ── 4. Thermal Print or PDF Save for POS Receipt ──────────────────────────
  Future<void> printOrShareReceipt({
    required OrderModel order,
    required ShopModel shop,
    bool isDirectPrint = true,
  }) async {
    final pdf = pw.Document();
    final is80mm = shop.paperSize.toLowerCase().contains('80');
    final rollFormat = is80mm ? PdfPageFormat.roll80 : PdfPageFormat.roll58;

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Shop Header
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
                  fontSize: is80mm ? 10 : 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(thickness: 0.8, color: PdfColors.grey700),

              // Metadata Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Inv #: ${order.invoiceNo}',
                      style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    '${order.date.day}/${order.date.month}/${order.date.year}',
                    style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment: ${order.paymentMode.name.toUpperCase()}',
                      style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5)),
                  pw.Text(
                    '${order.date.hour.toString().padLeft(2, '0')}:${order.date.minute.toString().padLeft(2, '0')}',
                    style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5),
                  ),
                ],
              ),
              if (order.customer != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Customer: ${order.customer!.name}',
                    style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),

              pw.Divider(thickness: 0.8, color: PdfColors.grey700),

              // Items Header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Item',
                        style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Qty x Price',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5, color: PdfColors.grey500),

              // Items List
              ...order.items.map((it) {
                final lineTotal = it.product.salePrice * it.quantity;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          it.product.name,
                          style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          '${it.quantity} x ${it.product.salePrice.toStringAsFixed(0)}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: is80mm ? 9 : 7.5),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          lineTotal.toStringAsFixed(0),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: is80mm ? 9 : 7.5, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.8, color: PdfColors.grey700),

              // Financial Totals
              if (order.discount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                    pw.Text('PKR ${order.subtotal.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                    pw.Text('- PKR ${order.discount.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                  ],
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL:',
                    style: pw.TextStyle(
                      fontSize: is80mm ? 12 : 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'PKR ${order.total.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontSize: is80mm ? 12 : 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.Divider(thickness: 0.8, color: PdfColors.grey700),

              // Barcode
              pw.SizedBox(height: 3),
              pw.Container(
                height: 28,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: order.invoiceNo,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                order.invoiceNo,
                style: pw.TextStyle(fontSize: is80mm ? 8 : 7),
              ),

              pw.SizedBox(height: 6),
              pw.Text(
                shop.receiptFooter,
                style: pw.TextStyle(fontSize: is80mm ? 8.5 : 7, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'KhataSmart POS Software',
                style: pw.TextStyle(fontSize: is80mm ? 7.5 : 6.5, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    if (isDirectPrint) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${order.invoiceNo}',
      );
    } else {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Receipt_${order.invoiceNo}.pdf',
      );
    }
  }

  // ── 5. WhatsApp Khata Balance Reminder ────────────────────────────────────
  Future<void> sendPartyLedgerViaWhatsApp({
    required PartyModel party,
    required ShopModel shop,
  }) async {
    final phone = formatPhoneForWhatsApp(party.phone);
    final isReceivable = party.balance >= 0;
    final statusWord = isReceivable ? 'Lene Hain (Receivable)' : 'Dene Hain (Payable)';

    final message = '''
السلام علیکم ${party.name} صاحب،

*${shop.name}* ki taraf se aap ke khata account ka baqaya hisab:

• Party Name: ${party.name}
• Current Balance: *PKR ${party.balance.abs().toStringAsFixed(0)}* ($statusWord)
${party.creditLimit != null ? '• Approved Credit Limit: PKR ${party.creditLimit!.toStringAsFixed(0)}\n' : ''}
Baraye meharbani hisab check kar ke wasooli karwa dein.

Shukriya!
*${shop.name}*
${shop.phone.isNotEmpty ? 'Contact: ${shop.phone}' : ''}
''';

    if (phone.isNotEmpty) {
      final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
      try {
        final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!ok) {
          await Share.share(message, subject: 'Khata Statement - ${party.name}');
        }
      } catch (_) {
        await Share.share(message, subject: 'Khata Statement - ${party.name}');
      }
    } else {
      await Share.share(message, subject: 'Khata Statement - ${party.name}');
    }
  }

  // ── 6. Full Party Ledger Statement PDF (A4 Format) ────────────────────────
  Future<void> printOrSharePartyLedgerStatement({
    required PartyModel party,
    required List<LedgerEntryModel> entries,
    required ShopModel shop,
    bool isDirectPrint = true,
  }) async {
    final pdf = pw.Document();

    // Sort entries chronologically
    final sortedEntries = List<LedgerEntryModel>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          double runningBalance = 0.0;
          return [
            // Shop Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shop.name,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    if (shop.address.isNotEmpty)
                      pw.Text(shop.address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    if (shop.phone.isNotEmpty)
                      pw.Text('Phone: ${shop.phone}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ACCOUNT STATEMENT',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 8),

            // Party Information Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Party: ${party.name} (${party.type == PartyType.customer ? "Customer" : "Supplier"})',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (party.phone.isNotEmpty)
                        pw.Text('Phone: ${party.phone}', style: const pw.TextStyle(fontSize: 10)),
                      if (party.city.isNotEmpty || party.area.isNotEmpty)
                        pw.Text('Location: ${[party.area, party.city].where((s) => s.isNotEmpty).join(", ")}',
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Net Balance Due:',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'PKR ${party.balance.abs().toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: party.balance >= 0 ? PdfColors.red800 : PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        party.balance >= 0 ? 'Lene Hain (Receivable)' : 'Dene Hain (Payable)',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Transactions Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(70),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('Date'),
                    _tableHeaderCell('Description / Note'),
                    _tableHeaderCell('Gave (Udhaar)', align: pw.TextAlign.right),
                    _tableHeaderCell('Got (Vasooli)', align: pw.TextAlign.right),
                    _tableHeaderCell('Balance (PKR)', align: pw.TextAlign.right),
                  ],
                ),
                ...sortedEntries.map((e) {
                  if (e.type == LedgerType.gave) {
                    runningBalance += e.amount;
                  } else {
                    runningBalance -= e.amount;
                  }
                  return pw.TableRow(
                    children: [
                      _tableBodyCell('${e.date.day}/${e.date.month}/${e.date.year}'),
                      _tableBodyCell(e.note.isNotEmpty ? e.note : (e.type == LedgerType.gave ? 'Udhaar' : 'Payment Received')),
                      _tableBodyCell(e.type == LedgerType.gave ? e.amount.toStringAsFixed(0) : '-', align: pw.TextAlign.right),
                      _tableBodyCell(e.type == LedgerType.got ? e.amount.toStringAsFixed(0) : '-', align: pw.TextAlign.right),
                      _tableBodyCell(runningBalance.toStringAsFixed(0),
                          align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),

            if (sortedEntries.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Center(
                  child: pw.Text('No transactions recorded yet.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                ),
              ),

            pw.SizedBox(height: 36),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature (${shop.name})', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    if (isDirectPrint) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Statement_${party.name.replaceAll(" ", "_")}',
      );
    } else {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Statement_${party.name.replaceAll(" ", "_")}.pdf',
      );
    }
  }

  // ── 7. Export Complete Khata Directory PDF ────────────────────────────────
  Future<void> exportKhataDirectoryPdf({
    required List<PartyModel> parties,
    required ShopModel shop,
  }) async {
    final pdf = pw.Document();
    final double totalReceivables = parties
        .where((p) => p.balance > 0)
        .fold(0.0, (sum, p) => sum + p.balance);
    final double totalPayables = parties
        .where((p) => p.balance < 0)
        .fold(0.0, (sum, p) => sum + p.balance.abs());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(shop.name,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Complete Khata Directory & Balances Report',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue900),
            pw.SizedBox(height: 6),

            // Summary Metrics
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.red200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL RECEIVABLE (LENE HAIN)',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                        pw.SizedBox(height: 2),
                        pw.Text('PKR ${totalReceivables.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.green200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL PAYABLE (DENE HAIN)',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        pw.SizedBox(height: 2),
                        pw.Text('PKR ${totalPayables.toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Directory Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('Party Name'),
                    _tableHeaderCell('Type'),
                    _tableHeaderCell('Phone'),
                    _tableHeaderCell('City / Area'),
                    _tableHeaderCell('Balance (PKR)', align: pw.TextAlign.right),
                  ],
                ),
                ...parties.map((p) {
                  return pw.TableRow(
                    children: [
                      _tableBodyCell(p.name, isBold: true),
                      _tableBodyCell(p.type == PartyType.customer ? 'Customer' : 'Supplier'),
                      _tableBodyCell(p.phone.isNotEmpty ? p.phone : '-'),
                      _tableBodyCell([p.area, p.city].where((s) => s.isNotEmpty).join(', ')),
                      _tableBodyCell(
                        '${p.balance.abs().toStringAsFixed(0)} ${p.balance > 0 ? "(Lene)" : p.balance < 0 ? "(Dene)" : "(Nill)"}',
                        align: pw.TextAlign.right,
                        isBold: true,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Khata_Directory_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // ── 8. Export Inventory Stock Catalog PDF ─────────────────────────────────
  Future<void> exportInventoryCatalog({
    required List<ProductModel> products,
    required ShopModel shop,
  }) async {
    final pdf = pw.Document();
    final double totalStockValue = products.fold(
      0.0,
      (sum, p) => sum + (p.costPrice * p.stock),
    );
    final double totalRetailValue = products.fold(
      0.0,
      (sum, p) => sum + (p.salePrice * p.stock),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(shop.name,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Stock Inventory Valuation Report',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue900),
            pw.SizedBox(height: 6),

            // Summary Metrics
            pw.Row(
              children: [
                pw.Expanded(
                  child: _metricBox(
                    'TOTAL SKU ITEMS',
                    products.length.toString(),
                    PdfColors.blue50,
                    PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox(
                    'STOCK ASSET VALUE',
                    'PKR ${totalStockValue.toStringAsFixed(0)}',
                    PdfColors.emerald50,
                    PdfColors.emerald800,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox(
                    'RETAIL VALUE',
                    'PKR ${totalRetailValue.toStringAsFixed(0)}',
                    PdfColors.purple50,
                    PdfColors.purple800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Inventory Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _tableHeaderCell('Product Name'),
                    _tableHeaderCell('Category'),
                    _tableHeaderCell('Barcode'),
                    _tableHeaderCell('Stock', align: pw.TextAlign.center),
                    _tableHeaderCell('Sale Price', align: pw.TextAlign.right),
                    _tableHeaderCell('Total Val.', align: pw.TextAlign.right),
                  ],
                ),
                ...products.map((p) {
                  final lineVal = p.salePrice * p.stock;
                  return pw.TableRow(
                    children: [
                      _tableBodyCell(p.name, isBold: true),
                      _tableBodyCell(p.category.isNotEmpty ? p.category : 'General'),
                      _tableBodyCell(p.barcode.isNotEmpty ? p.barcode : '-'),
                      _tableBodyCell(p.stock.toString(), align: pw.TextAlign.center),
                      _tableBodyCell('PKR ${p.salePrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
                      _tableBodyCell('PKR ${lineVal.toStringAsFixed(0)}',
                          align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventory_Catalog_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // ── 9. Export Financial Analytics P&L PDF ─────────────────────────────────
  Future<void> exportFinancialReportPdf({
    required ShopModel shop,
    required String periodName,
    required double totalSales,
    required double grossProfit,
    required double netProfit,
    required double totalExpenses,
    required double cashSales,
    required double creditSales,
    required int orderCount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shop.name,
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Financial Performance & P&L Statement ($periodName)',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 12),

              // KPI Cards Row
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _metricBox(
                      'TOTAL REVENUE',
                      'PKR ${totalSales.toStringAsFixed(0)}',
                      PdfColors.blue50,
                      PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _metricBox(
                      'NET PROFIT',
                      'PKR ${netProfit.toStringAsFixed(0)}',
                      PdfColors.emerald50,
                      PdfColors.emerald900,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _metricBox(
                      'TOTAL EXPENSES',
                      'PKR ${totalExpenses.toStringAsFixed(0)}',
                      PdfColors.amber50,
                      PdfColors.amber900,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // Detailed Financial Breakdown
              pw.Text(
                'Financial Breakdown ($periodName)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  _pnlRow('Total Orders / Invoices Billed', orderCount.toString(), isHeader: true),
                  _pnlRow('Total Gross Sales Turnover', 'PKR ${totalSales.toStringAsFixed(0)}'),
                  _pnlRow('Cash Sales Received', 'PKR ${cashSales.toStringAsFixed(0)}'),
                  _pnlRow('Credit / Udhaar Sales', 'PKR ${creditSales.toStringAsFixed(0)}'),
                  _pnlRow('Gross Trading Profit', 'PKR ${grossProfit.toStringAsFixed(0)}'),
                  _pnlRow('Operational & Ledger Expenses', 'PKR ${totalExpenses.toStringAsFixed(0)}'),
                  _pnlRow(
                    'ESTIMATED NET STORE PROFIT',
                    'PKR ${netProfit.toStringAsFixed(0)}',
                    isHighlight: true,
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
              pw.Text(
                'Generated automatically by KhataSmart Retail POS.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Financial_Report_${periodName.replaceAll(" ", "_")}',
    );
  }

  // ── Helper Table Cell Widgets ─────────────────────────────────────────────
  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _tableBodyCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.TableRow _pnlRow(String label, String value, {bool isHeader = false, bool isHighlight = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHighlight ? PdfColors.blue50 : (isHeader ? PdfColors.grey100 : PdfColors.white),
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isHighlight ? 11 : 9.5,
              fontWeight: isHighlight || isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: isHighlight ? 12 : 9.5,
              fontWeight: isHighlight || isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _metricBox(String label, String val, PdfColor bg, PdfColor textCol) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: textCol.flatten(background: PdfColors.white, amount: 0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textCol)),
          pw.SizedBox(height: 2),
          pw.Text(val, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }
}
