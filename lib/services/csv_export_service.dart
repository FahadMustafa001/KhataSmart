import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order_model.dart';
import '../models/party_model.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../core/utils/date_formatter.dart';

class CsvExportService {
  CsvExportService._();
  static final CsvExportService instance = CsvExportService._();

  String _sanitize(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  // 1. Export Inventory Products to CSV
  Future<File> generateInventoryCsv({
    required List<ProductModel> products,
    required ShopModel shop,
  }) async {
    final buffer = StringBuffer();

    // UTF-8 BOM for Microsoft Excel compatibility
    buffer.write('\uFEFF');

    // Header info
    buffer.writeln('${_sanitize(shop.name)} - Inventory Stock Report');
    buffer.writeln('Export Date,${DateFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('Total Items,${products.length}');
    buffer.writeln('');

    // Table Columns
    buffer.writeln([
      'Product Name',
      'Barcode',
      'Category',
      'Stock Quantity',
      'Unit',
      'Cost Price (PKR)',
      'Sale Price (PKR)',
      'Total Stock Value (Cost)',
      'Total Retail Value (Sale)',
      'Profit Margin (%)',
      'Stock Status',
    ].map(_sanitize).join(','));

    for (final p in products) {
      final totalCostVal = p.stockQty * p.costPrice;
      final totalSaleVal = p.stockQty * p.salePrice;
      final marginPct = p.costPrice > 0 ? (((p.salePrice - p.costPrice) / p.costPrice) * 100).toStringAsFixed(1) : '100.0';
      final status = p.stockQty <= 0
          ? 'Out of Stock'
          : (p.isLowStock || p.stockQty <= p.minStockAlert ? 'Low Stock' : 'In Stock');

      buffer.writeln([
        p.name,
        p.barcode.isNotEmpty ? p.barcode : 'N/A',
        p.category,
        p.stockQty.toStringAsFixed(0),
        p.unit,
        p.costPrice.toStringAsFixed(0),
        p.salePrice.toStringAsFixed(0),
        totalCostVal.toStringAsFixed(0),
        totalSaleVal.toStringAsFixed(0),
        '$marginPct%',
        status,
      ].map((v) => _sanitize(v.toString())).join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Inventory_${shop.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), encoding: utf8);
    return file;
  }

  // 2. Export Khata Parties to CSV
  Future<File> generateKhataPartiesCsv({
    required List<PartyModel> parties,
    required ShopModel shop,
    PartyType? filterType,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    final list = filterType != null ? parties.where((p) => p.type == filterType).toList() : parties;
    final typeLabel = filterType == null ? 'All Parties' : (filterType == PartyType.customer ? 'Customers' : 'Suppliers');

    buffer.writeln('${_sanitize(shop.name)} - Khata Accounts Report ($typeLabel)');
    buffer.writeln('Export Date,${DateFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('Total Accounts,${list.length}');
    buffer.writeln('');

    buffer.writeln([
      'Party Name',
      'Account Type',
      'Phone Number',
      'City',
      'Area',
      'Address',
      'National ID (CNIC)',
      'Approved Credit Limit (PKR)',
      'Current Balance (PKR)',
      'Balance Status',
    ].map(_sanitize).join(','));

    for (final p in list) {
      final status = p.balance > 0 ? 'Receivable (To Collect)' : (p.balance < 0 ? 'Payable (To Pay)' : 'Settled');
      buffer.writeln([
        p.name,
        p.type == PartyType.customer ? 'Customer' : 'Supplier',
        p.phone.isNotEmpty ? p.phone : 'N/A',
        p.city,
        p.area,
        p.address,
        p.cnic.isNotEmpty ? p.cnic : 'N/A',
        p.creditLimit?.toStringAsFixed(0) ?? 'N/A',
        p.balance.abs().toStringAsFixed(0),
        status,
      ].map((v) => _sanitize(v.toString())).join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Khata_${typeLabel}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), encoding: utf8);
    return file;
  }

  // 3. Export Sales History / Orders to CSV
  Future<File> generateSalesOrdersCsv({
    required List<OrderModel> orders,
    required ShopModel shop,
    String reportPeriod = 'All Time',
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    final totalRevenue = orders.fold(0.0, (sum, o) => sum + o.total);

    buffer.writeln('${_sanitize(shop.name)} - Sales & Billing Report ($reportPeriod)');
    buffer.writeln('Export Date,${DateFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('Total Orders,${orders.length}');
    buffer.writeln('Total Sales Revenue,PKR ${totalRevenue.toStringAsFixed(0)}');
    buffer.writeln('');

    buffer.writeln([
      'Invoice #',
      'Date',
      'Time',
      'Customer Name',
      'Payment Mode',
      'Items Count',
      'Subtotal (PKR)',
      'Discount (PKR)',
      'Total Amount (PKR)',
      'Items Detail',
    ].map(_sanitize).join(','));

    for (final o in orders) {
      final itemsSummary = o.items.map((i) => '${i.productName} x${i.quantity}').join('; ');
      buffer.writeln([
        o.invoiceNo,
        DateFormatter.formatShort(o.date),
        '${o.date.hour.toString().padLeft(2, '0')}:${o.date.minute.toString().padLeft(2, '0')}',
        o.customer?.name ?? 'Walk-in Customer',
        o.paymentMode.name.toUpperCase(),
        o.items.length.toString(),
        o.subtotal.toStringAsFixed(0),
        o.discount.toStringAsFixed(0),
        o.total.toStringAsFixed(0),
        itemsSummary,
      ].map((v) => _sanitize(v.toString())).join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), encoding: utf8);
    return file;
  }

  // Helper: Share or Save CSV File
  Future<void> shareCsvFile(File file, {required String subject}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: subject,
    );
  }
}
