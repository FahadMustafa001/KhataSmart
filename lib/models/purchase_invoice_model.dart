class PurchaseItemModel {
  final String productId;
  final String productName;
  final double quantity;
  final double costPrice;
  final String unit;

  PurchaseItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    this.unit = 'pcs',
  });

  double get subtotal => quantity * costPrice;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'costPrice': costPrice,
    'unit': unit,
  };

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) => PurchaseItemModel(
    productId: map['productId'] ?? '',
    productName: map['productName'] ?? '',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
    costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
    unit: map['unit'] ?? 'pcs',
  );
}

class PurchaseInvoiceModel {
  final String id;
  final String invoiceNo;
  final String supplierId;
  final String supplierName;
  final DateTime date;
  final List<PurchaseItemModel> items;
  final double totalAmount;
  final double paidAmount;
  final double creditBalanceAdded;
  final String note;
  final String shopId;

  PurchaseInvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.creditBalanceAdded,
    this.note = '',
    required this.shopId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoiceNo': invoiceNo,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toMap()).toList(),
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'creditBalanceAdded': creditBalanceAdded,
    'note': note,
    'shopId': shopId,
  };

  factory PurchaseInvoiceModel.fromMap(Map<String, dynamic> map) => PurchaseInvoiceModel(
    id: map['id'] ?? '',
    invoiceNo: map['invoiceNo'] ?? '',
    supplierId: map['supplierId'] ?? '',
    supplierName: map['supplierName'] ?? '',
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    items: (map['items'] as List<dynamic>?)
            ?.map((i) => PurchaseItemModel.fromMap(i as Map<String, dynamic>))
            .toList() ??
        [],
    totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
    creditBalanceAdded: (map['creditBalanceAdded'] as num?)?.toDouble() ?? 0.0,
    note: map['note'] ?? '',
    shopId: map['shopId'] ?? '',
  );
}
