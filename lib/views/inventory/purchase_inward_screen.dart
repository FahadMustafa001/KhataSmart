import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/notification_model.dart';
import '../../models/party_model.dart';
import '../../models/product_model.dart';
import '../../models/purchase_invoice_model.dart';
import '../../routes/app_routes.dart';
import '../../services/local_database_service.dart';
import '../../services/notification_service.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../khata/widgets/add_party_sheet.dart';

class PurchaseInwardScreen extends StatefulWidget {
  final String? initialSupplierId;
  const PurchaseInwardScreen({super.key, this.initialSupplierId});

  @override
  State<PurchaseInwardScreen> createState() => _PurchaseInwardScreenState();
}

class _PurchaseInwardScreenState extends State<PurchaseInwardScreen> {
  final _khataState = KhataState.instance;
  final _inventoryState = InventoryState.instance;

  String? _selectedSupplierId;
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
    _invoiceNoController.text =
        'PUR-${now.year}${now.month.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    _selectedSupplierId = widget.initialSupplierId;

    _khataState.addListener(_rebuild);
    _inventoryState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _khataState.removeListener(_rebuild);
    _inventoryState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  PartyModel? get _selectedSupplier {
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) return null;
    return _khataState.suppliers
        .where((s) => s.id == _selectedSupplierId)
        .firstOrNull;
  }

  double get _totalBill => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0.0;
  double get _remainingPayable => (_totalBill - _paidAmount).clamp(0.0, double.infinity);

  void _showAddProductSheet() {
    final products = _inventoryState.products;

    if (products.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('No Products Found'),
            ],
          ),
          content: const Text(
            'Your inventory currently has no products registered. Would you like to create your first product to receive in this inward bill?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.pushNamed(context, AppRoutes.addEditProduct);
              },
              child: const Text('Create New Product', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    String selectedProductId = products.first.id;
    final initialP = products.first;
    double cost = initialP.costPrice > 0 ? initialP.costPrice : initialP.salePrice * 0.7;
    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController(
      text: cost % 1 == 0 ? cost.toInt().toString() : cost.toString(),
    );

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
            final activeProducts = _inventoryState.products;
            final currentProduct = activeProducts
                .where((p) => p.id == selectedProductId)
                .firstOrNull ?? activeProducts.first;

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Item to Inward Bill',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Product Item',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.qr_code_scanner, size: 14, color: Color(0xFF2563EB)),
                              label: const Text(
                                'Scan Barcode',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              onPressed: () async {
                                final code = await Navigator.pushNamed(
                                  context,
                                  AppRoutes.posScanner,
                                  arguments: {'mode': 'barcode_capture'},
                                );
                                if (!ctx.mounted) return;
                                if (code != null && code is String) {
                                  final found = activeProducts
                                      .where((p) => p.barcode.trim() == code.trim())
                                      .firstOrNull;
                                  if (found != null) {
                                    setSheetState(() {
                                      selectedProductId = found.id;
                                      cost = found.costPrice > 0 ? found.costPrice : found.salePrice * 0.7;
                                      costController.text = cost % 1 == 0
                                          ? cost.toInt().toString()
                                          : cost.toString();
                                    });
                                    AppToast.showSuccess(ctx, 'Matched: ${found.name}');
                                  } else {
                                    AppToast.showWarning(ctx, 'Barcode "$code" not found in catalog');
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.add, size: 14, color: Color(0xFF16A34A)),
                              label: const Text(
                                '+ New Product',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              onPressed: () async {
                                final res = await Navigator.pushNamed(context, AppRoutes.addEditProduct);
                                if (res is ProductModel && ctx.mounted) {
                                  setSheetState(() {
                                    selectedProductId = res.id;
                                    cost = res.costPrice;
                                    costController.text = cost % 1 == 0
                                        ? cost.toInt().toString()
                                        : cost.toString();
                                  });
                                }
                              },
                            ),
                          ],
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
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedProductId,
                          items: activeProducts.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                '${p.name} (Stock: ${p.stockQty} ${p.unit})',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedProductId = val;
                                final p = activeProducts.firstWhere((item) => item.id == val);
                                cost = p.costPrice > 0 ? p.costPrice : p.salePrice * 0.7;
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
                              const Text(
                                'Quantity Received',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  suffixText: currentProduct.unit,
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
                              const Text(
                                'Unit Cost Price (PKR)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
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

                          if (parsedQty == null || !parsedQty.isFinite || parsedQty <= 0 || parsedQty % 1 != 0) {
                            AppToast.showWarning(context, 'Please enter a valid whole quantity (e.g. 1, 5, 10)');
                            return;
                          }
                          if (parsedCost == null || !parsedCost.isFinite || parsedCost < 0) {
                            AppToast.showWarning(context, 'Please enter a valid positive cost price');
                            return;
                          }

                          setState(() {
                            _items.add(PurchaseItemModel(
                              productId: currentProduct.id,
                              productName: currentProduct.name,
                              quantity: parsedQty,
                              costPrice: parsedCost,
                              unit: currentProduct.unit,
                            ));
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Add Item to List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
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

    if (remainingPayable > 0 && (_selectedSupplierId == null || _selectedSupplierId!.isEmpty)) {
      AppToast.showWarning(context, 'Please select a supplier for purchases with an unpaid credit balance');
      return;
    }

    final supplier = _selectedSupplier;
    final invoice = PurchaseInvoiceModel(
      id: 'purch_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: _invoiceNoController.text.trim().isNotEmpty
          ? _invoiceNoController.text.trim()
          : 'PUR-${DateTime.now().millisecondsSinceEpoch}',
      supplierId: supplier?.id ?? '',
      supplierName: supplier?.name ?? 'Walk-in Vendor',
      date: _invoiceDate,
      items: _items,
      totalAmount: _totalBill,
      paidAmount: parsedPaid,
      creditBalanceAdded: remainingPayable,
      note: _notesController.text.trim(),
      shopId: ShopState.instance.activeShopId,
    );

    _inventoryState.processPurchaseInvoice(invoice, updateCostPrice: _updateCostPrice);
    LocalDatabaseService.instance.persistToDisk();

    // Dispatch live stock notification
    NotificationService.instance.addNotification(
      title: 'Stock Inward Completed: #${invoice.invoiceNo}',
      message: 'Purchased ${_items.length} items from ${invoice.supplierName} (Total: PKR ${invoice.totalAmount.toStringAsFixed(0)}, Paid: PKR ${invoice.paidAmount.toStringAsFixed(0)}, Udhar: PKR ${invoice.creditBalanceAdded.toStringAsFixed(0)}).',
      type: NotificationType.stockAlert,
      route: AppRoutes.inventoryList,
      referenceId: invoice.invoiceNo,
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }

    AppToast.showSuccess(
      context,
      'Stock Inward Complete! Added ${_items.length} items to inventory.${remainingPayable > 0 ? " (Rs. ${remainingPayable.toStringAsFixed(0)} posted to ${supplier?.name ?? 'Supplier'})" : ""}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = _khataState.suppliers;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              }
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Inward & Purchases',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Receive stock & record supplier bills',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
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
                            Text(
                              'Supplier / Vendor',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
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
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _selectedSupplierId,
                          hint: const Text('Select Supplier (Optional for cash purchase)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Cash / Walk-in Vendor (No Ledger)', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ),
                            ...suppliers.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(
                                '${s.name} ${s.phone.isNotEmpty ? "(${s.phone})" : ""}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            )),
                          ],
                          onChanged: (val) => setState(() => _selectedSupplierId = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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

              const SizedBox(height: 12),

              // 3. Products List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Received Products (${_items.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      SizedBox(height: 2),
                      Text('Tap "+ Add Product" to record inward items from vendor bill', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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

              const SizedBox(height: 12),

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
                    // Quick Payment Chips
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(
                                color: _paidAmount >= _totalBill && _totalBill > 0
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFCBD5E1),
                              ),
                              backgroundColor: _paidAmount >= _totalBill && _totalBill > 0
                                  ? const Color(0xFFDCFCE7)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() {
                                _paidAmountController.text = _totalBill.toInt().toString();
                              });
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Paid Full (Cash/Online)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(
                                color: _paidAmount == 0 && _totalBill > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFCBD5E1),
                              ),
                              backgroundColor: _paidAmount == 0 && _totalBill > 0
                                  ? const Color(0xFFFEE2E2)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() {
                                _paidAmountController.text = '0';
                              });
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Full Udhar (Payable)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

              const SizedBox(height: 14),

              // Notes Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Optional Remarks / Vendor Notes',
                    hintText: 'e.g. Delivered by truck, payment terms 15 days',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
      ),
    );
  }
}
