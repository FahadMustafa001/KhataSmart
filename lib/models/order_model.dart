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

  OrderModel({
    required this.invoiceNo,
    this.customer,
    required this.items,
    required this.total,
    double? subtotal,
    this.discount = 0.0,
    required this.paymentMode,
    required this.date,
  }) : subtotal = subtotal ?? (total + discount);

  DateTime get dateTime => date;
  String get id => invoiceNo;
}

