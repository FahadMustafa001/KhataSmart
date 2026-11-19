import 'package:flutter/material.dart';
import '../../core/utils/app_toast.dart';
import '../../models/party_model.dart';
import '../../models/product_model.dart';
import '../../models/purchase_invoice_model.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../khata/widgets/add_party_sheet.dart';

class PurchaseInwardScreen extends StatefulWidget {
  const PurchaseInwardScreen({super.key});

  @override
  State<PurchaseInwardScreen> createState() => _PurchaseInwardScreenState();
}

class _PurchaseInwardScreenState extends State<PurchaseInwardScreen> {
  PartyModel? _selectedSupplier;
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();
  final List<PurchaseItemModel> _items = [];
  bool _updateCostPrice = true;
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _invoiceNoController.text = 'PUR-${now.year}${now.month.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalBill => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0.0;
  double get _remainingPayable => (_totalBill - _paidAmount).clamp(0.0, double.infinity);

  void _showAddProductSheet() {
    final products = InventoryState.instance.products;
    if (products.isEmpty) {
      AppToast.showWarning(context, 'No products available in inventory. Please add products first.');
      return;
    }

    ProductModel? selectedProduct = products.first;
    double cost = selectedProduct.costPrice > 0 ? selectedProduct.costPrice : selectedProduct.salePrice * 0.7;
    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController(text: cost % 1 == 0 ? cost.toInt().toString() : cost.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Item to Inward Bill',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ProductModel>(
                        isExpanded: true,
                        value: selectedProduct,
                        items: products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              '${p.name} (Stock: ${p.stockQty} ${p.unit})',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedProduct = val;
                              cost = val.costPrice;
                              costController.text = cost % 1 == 0 ? cost.toInt().toString() : cost.toString();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity Received', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                suffixText: selectedProduct?.unit ?? 'pcs',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Unit Cost Price (PKR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: costController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                prefixText: 'Rs. ',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (v) => cost = double.tryParse(v) ?? 0.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final parsedQty = double.tryParse(qtyController.text.trim());
                        final parsedCost = double.tryParse(costController.text.trim());

                        if (selectedProduct == null) return;
                        if (parsedQty == null || !parsedQty.isFinite || parsedQty <= 0 || parsedQty % 1 != 0) {
                          AppToast.showWarning(context, 'Please enter a valid whole-number quantity (e.g. 1, 5, 10)');
                          return;
                        }
                        if (parsedCost == null || !parsedCost.isFinite || parsedCost < 0) {
                          AppToast.showWarning(context, 'Please enter a valid positive cost price');
                          return;
                        }

                        setState(() {
                          _items.add(PurchaseItemModel(
                            productId: selectedProduct!.id,
                            productName: selectedProduct!.name,
                            quantity: parsedQty,
                            costPrice: parsedCost,
                            unit: selectedProduct!.unit,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add Item to List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onConfirmSave() {
    if (_items.isEmpty) {
      AppToast.showWarning(context, 'Please add at least one product to the purchase bill');
      return;
    }

    final paidText = _paidAmountController.text.trim();
    final double? parsedPaid = paidText.isEmpty ? 0.0 : double.tryParse(paidText);
    if (parsedPaid == null || !parsedPaid.isFinite || parsedPaid < 0) {
      AppToast.showWarning(context, 'Please enter a valid paid amount (0 or positive number)');
      return;
    }

    final remainingPayable = (_totalBill - parsedPaid).clamp(0.0, double.infinity);

    if (remainingPayable > 0 && (_selectedSupplier == null || _selectedSupplier!.id.isEmpty)) {
      AppToast.showWarning(context, 'Please select a supplier for purchases with an unpaid credit balance');
      return;
    }

    final invoice = PurchaseInvoiceModel(
      id: 'purch_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: _invoiceNoController.text.trim().isNotEmpty
          ? _invoiceNoController.text.trim()
          : 'PUR-${DateTime.now().millisecondsSinceEpoch}',
      supplierId: _selectedSupplier?.id ?? '',
      supplierName: _selectedSupplier?.name ?? 'Walk-in Vendor',
      date: _invoiceDate,
      items: _items,
      totalAmount: _totalBill,
      paidAmount: parsedPaid,
      creditBalanceAdded: remainingPayable,
      note: _notesController.text.trim(),
      shopId: ShopState.instance.activeShopId,
    );

    InventoryState.instance.processPurchaseInvoice(invoice, updateCostPrice: _updateCostPrice);

    Navigator.pop(context);

    AppToast.showSuccess(
      context,
      'Stock Inward Complete! Added ${_items.length} items to stock.${remainingPayable > 0 ? " (Rs. ${remainingPayable.toStringAsFixed(0)} posted to ${_selectedSupplier?.name ?? 'Supplier'})" : ""}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = KhataState.instance.suppliers;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Stock Inward / Purchase Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Supplier Selector Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFFEA580C)),
                          SizedBox(width: 8),
                          Text('Supplier / Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (_) => const AddPartySheet(initialType: PartyType.supplier),
                          );
                        },
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('+ New Supplier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PartyModel?>(
                        isExpanded: true,
                        value: _selectedSupplier,
                        hint: const Text('Select Supplier (Optional for cash purchase)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        items: [
                          const DropdownMenuItem<PartyModel?>(
                            value: null,
                            child: Text('Cash / Walk-in Supplier (No Ledger)', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          ),
                          ...suppliers.map((s) => DropdownMenuItem<PartyModel?>(
                            value: s,
                            child: Text('${s.name} ${s.phone.isNotEmpty ? "(${s.phone})" : ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )),
                        ],
                        onChanged: (val) => setState(() => _selectedSupplier = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Bill Info (Invoice # & Date)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice / Bill #', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _invoiceNoController,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Inward Date', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _invoiceDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _invoiceDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Products List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Received Products (${_items.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProductSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Product', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Items List
            if (_items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text('No products added yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    Text('Tap "+ Add Product" to add items from supplier invoice', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_2, size: 18, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text(
                              '${item.quantity.toStringAsFixed(0)} ${item.unit} @ Rs. ${item.costPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => setState(() => _items.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 14),

            // 4. Financial Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bill Amount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('PKR ${_totalBill.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Amount Paid Now:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          controller: _paidAmountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixText: 'Rs. ',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining (Added to Ledger):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                      Text('PKR ${_remainingPayable.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Update inventory cost prices to bill rates', style: TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                    value: _updateCostPrice,
                    onChanged: (v) => setState(() => _updateCostPrice = v ?? true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _onConfirmSave,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                label: const Text('Confirm & Save Stock Inward', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
