import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../models/party_model.dart';
import '../../routes/app_routes.dart';
import '../../state/cart_state.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../shared_widgets/custom_app_bar.dart';

class CheckoutSettlementScreen extends StatefulWidget {
  const CheckoutSettlementScreen({super.key});

  @override
  State<CheckoutSettlementScreen> createState() =>
      _CheckoutSettlementScreenState();
}

class _CheckoutSettlementScreenState extends State<CheckoutSettlementScreen> {
  final _cartState = CartState.instance;
  final _khataState = KhataState.instance;
  final _inventoryState = InventoryState.instance;

  String _selectedPaymentMethod = 'Cash'; // Cash, Store Credit, Raast QR
  late TextEditingController _cashReceivedController;

  double get _billAmount => _cartState.netPayable;
  double get _grossAmount => _cartState.subtotal;
  double get _discountAmount => _cartState.discount;

  PartyModel? get _customer {
    if (_khataState.customers.isNotEmpty) {
      return _khataState.customers.first;
    }
    return null;
  }

  double get _prevBalance => _customer?.balance ?? 0.0;

  bool _printerEnabled = true;
  bool _emailEnabled = false;
  bool _sendNotifications = true;

  double get _cashReceived =>
      double.tryParse(_cashReceivedController.text) ?? 0.0;
  double get _newUdhaar =>
      (_billAmount - _cashReceived).clamp(0.0, _billAmount);
  double get _newTotalBalance => _prevBalance + _newUdhaar;

  @override
  void initState() {
    super.initState();
    final bill = _cartState.netPayable;
    _cashReceivedController =
        TextEditingController(text: bill > 0 ? bill.toStringAsFixed(0) : '0');
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  void _onCompleteSale() {
    // 1. Deduct stock in inventory
    for (final item in _cartState.items) {
      _inventoryState.deductStock(item.product.id, item.quantity);
    }

    // 2. Build order model
    final invoiceNo = 'SK-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final paymentMode = _selectedPaymentMethod == 'Store Credit'
        ? PaymentMode.udhaar
        : (_selectedPaymentMethod == 'Raast QR'
            ? PaymentMode.raast
            : PaymentMode.cash);

    final order = OrderModel(
      invoiceNo: invoiceNo,
      date: DateTime.now(),
      customer: _selectedPaymentMethod == 'Store Credit' ? _customer : null,
      items: List.from(_cartState.items),
      subtotal: _grossAmount,
      discount: _discountAmount,
      total: _billAmount,
      paymentMode: paymentMode,
    );

    // 3. Add order to khata state
    _khataState.addOrder(order);

    // 4. Clear cart
    _cartState.clear();

    // 5. Navigate to receipt preview with order
    Navigator.pushReplacementNamed(context, AppRoutes.receiptPreview,
        arguments: order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Counter 01',
        subtitle: 'SmartKhata POS',
        showLogo: true,
        actions: [
          Padding(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_outlined,
                          size: 14, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 4),
                      Text(
                        'BILL #${DateTime.now().millisecondsSinceEpoch % 10000} • ${_cartState.totalItemCount} Items',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      _customer?.name ?? 'Counter Sale',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Grand Payable Total Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text(
                    'GRAND PAYABLE TOTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'PKR ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        TextSpan(
                          text:
                              CurrencyFormatter.format(_billAmount, prefix: ''),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Gross: ${_grossAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-PKR ${_discountAmount.toStringAsFixed(0)} OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBE123C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Method Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Split Capable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 3 Payment Method Cards (Cash, Store Credit, Raast QR)
            Row(
              children: [
                // Cash
                _buildMethodCard(
                  title: 'Cash',
                  subtitle: 'Direct Box',
                  icon: Icons.payments_outlined,
                  isSelected: _selectedPaymentMethod == 'Cash',
                  onTap: () => setState(() => _selectedPaymentMethod = 'Cash'),
                ),
                const SizedBox(width: 10),

                // Store Credit (Selected)
                _buildMethodCard(
                  title: 'Store Credit',
                  subtitle: 'Udhaar Book',
                  icon: Icons.menu_book,
                  isSelected: _selectedPaymentMethod == 'Store Credit',
                  isFeaturedDark: true,
                  onTap: () =>
                      setState(() => _selectedPaymentMethod = 'Store Credit'),
                ),
                const SizedBox(width: 10),

                // Raast QR
                _buildMethodCard(
                  title: 'Raast QR',
                  subtitle: '0% Fee',
                  icon: Icons.qr_code_2,
                  isSelected: _selectedPaymentMethod == 'Raast QR',
                  onTap: () =>
                      setState(() => _selectedPaymentMethod = 'Raast QR'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Customer Khata Ledger Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.import_contacts,
                              size: 16, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 6),
                          Text(
                            'Customer Khata Ledger',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle,
                                size: 5, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'Good Standing',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Selected Customer Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFCBD5E1),
                          child: Icon(Icons.person,
                              color: Color(0xFF334155), size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customer?.name ?? 'Counter Sale / Walk-in',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _customer != null
                                    ? '${_customer!.phone} • ID #${_customer!.id}'
                                    : 'No ledger account selected',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF475569)),
                                  children: [
                                    const TextSpan(text: 'Prev. Balance: '),
                                    TextSpan(
                                      text: _customer != null
                                          ? 'PKR ${_customer!.balance.toStringAsFixed(0)} ${_customer!.balance > 0 ? "(Due)" : ""}'
                                          : 'PKR 0',
                                      style: TextStyle(
                                        color: _prevBalance > 0
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz,
                              size: 18, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Search other customer & + New button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.search,
                                size: 16, color: Color(0xFF94A3B8)),
                            hintText: 'Search other customer...',
                            hintStyle: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF16A34A), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt,
                                size: 14, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 4),
                            Text(
                              '+ New',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Cash Received (Partial) Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.payments_outlined,
                                    size: 15, color: Color(0xFF15803D)),
                                SizedBox(width: 5),
                                Text(
                                  'Cash Received (Partial)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Bill: PKR ${_billAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Input Box: PKR | 1000
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PKR',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _cashReceivedController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Quick Amount Pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAmountPill(
                                'Exact (${_billAmount.toStringAsFixed(0)})',
                                _billAmount),
                            _buildQuickAmountPill('500', 500),
                            _buildQuickAmountPill('1,000', 1000),
                            _buildQuickAmountPill('2,000', 2000),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // New Udhaar (Credit to Post) Warning Box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active_outlined,
                                  color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'New Udhaar (Credit to Post)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF991B1B),
                                      ),
                                    ),
                                    Text(
                                      _customer != null
                                          ? "Will be added to ${_customer!.name}'s ledger. New total balance will be PKR ${_newTotalBalance.toStringAsFixed(0)}"
                                          : "New total balance will be PKR ${_newTotalBalance.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFB91C1C),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'PKR ${_newUdhaar.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const Text(
                                    'UNPAID BALANCE',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Send Instant SMS & WhatsApp Ledger Bill Checkbox
                        GestureDetector(
                          onTap: () => setState(
                              () => _sendNotifications = !_sendNotifications),
                          child: Row(
                            children: [
                              Icon(
                                _sendNotifications
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 18,
                                color: const Color(0xFF15803D),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '📱 Send Instant SMS & WhatsApp Ledger Bill',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Device & Print Toggles Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Row 1: 58mm Thermal Printer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.print_outlined,
                                size: 16, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '58mm Thermal Printer',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Bluetooth POS-58BT • Online',
                                style: TextStyle(
                                    fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: _printerEnabled,
                          activeTrackColor: const Color(0xFF16A34A),
                          onChanged: (val) =>
                              setState(() => _printerEnabled = val),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 12),

                  // Row 2: Email Digital Copy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mail_outline,
                                size: 16, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Digital Copy',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Send PDF copy to customer email',
                                style: TextStyle(
                                    fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: _emailEnabled,
                          activeTrackColor: const Color(0xFF16A34A),
                          onChanged: (val) =>
                              setState(() => _emailEnabled = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Status & Complete Sale Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    children: [
                      const TextSpan(text: 'Cash: '),
                      TextSpan(
                        text: 'PKR ${_cashReceived.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A)),
                      ),
                      const TextSpan(text: ' • Udhaar: '),
                      TextSpan(
                        text: 'PKR ${_newUdhaar.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'READY TO POST',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Primary Green Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onCompleteSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D), // Forest Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Complete Sale & Print',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PKR ${_billAmount.toStringAsFixed(0)} →',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF86EFAC),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Footer Tag: INSTANT SQLITE JOURNAL • LEDGER SYNCED
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 12, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'INSTANT SQLITE JOURNAL • LEDGER SYNCED',
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isFeaturedDark = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isFeaturedDark && isSelected
                ? const Color(0xFF0F172A) // Deep Navy Selected
                : (isSelected ? const Color(0xFFEFF6FF) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isFeaturedDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF2563EB))
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isFeaturedDark && isSelected)
                const Positioned(
                  top: -6,
                  right: -2,
                  child: Icon(Icons.check_circle,
                      size: 14, color: Color(0xFF22C55E)),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isFeaturedDark && isSelected
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isFeaturedDark && isSelected
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFeaturedDark && isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isFeaturedDark && isSelected
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountPill(String label, double amount) {
    final isSelected = _cashReceived == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          _cashReceivedController.text = amount.toStringAsFixed(0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color:
                isSelected ? const Color(0xFF15803D) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
