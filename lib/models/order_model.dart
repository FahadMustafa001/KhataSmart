import 'cart_item_model.dart';
import 'party_model.dart';

enum PaymentMode { cash, udhaar, online, digital, raast }

class OrderModel {
  final String invoiceNo;
  final PartyModel? customer;
  final List<CartItemModel> items;
  final double total;
  final double subtotal;
  final double discount;
  final PaymentMode paymentMode;
  final DateTime date;
  final String shopId;

  OrderModel({
    required this.invoiceNo,
    this.customer,
    required this.items,
    required this.total,
    double? subtotal,
    this.discount = 0.0,
    required this.paymentMode,
    required this.date,
    this.shopId = 'shop_1',
  }) : subtotal = subtotal ?? (total + discount);

  DateTime get dateTime => date;
  String get id => invoiceNo;

  Map<String, dynamic> toMap() {
    return {
      'invoiceNo': invoiceNo,
      'customer': customer?.toMap(),
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'subtotal': subtotal,
      'discount': discount,
      'paymentMode': paymentMode.name,
      'date': date.toIso8601String(),
      'shopId': shopId,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    PaymentMode mode = PaymentMode.cash;
    for (var m in PaymentMode.values) {
      if (m.name == map['paymentMode']) {
        mode = m;
        break;
      }
    }

    return OrderModel(
      invoiceNo: map['invoiceNo'] ?? '',
      customer: map['customer'] != null ? PartyModel.fromMap(map['customer']) : null,
      items: (map['items'] as List<dynamic>?)
              ?.map((i) => CartItemModel.fromMap(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: mode,
      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),
      shopId: map['shopId'] ?? 'shop_1',
    );
  }
}

