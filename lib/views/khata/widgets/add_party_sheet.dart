import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../models/ledger_entry_model.dart';
import '../../../models/party_model.dart';
import '../../../state/khata_state.dart';
import '../../../state/shop_state.dart';

class AddPartySheet extends StatefulWidget {
  final PartyType initialType;

  const AddPartySheet({
    super.key,
    this.initialType = PartyType.customer,
  });

  static Future<bool?> show(
    BuildContext context, {
    PartyType initialType = PartyType.customer,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPartySheet(initialType: initialType),
    );
  }

  @override
  State<AddPartySheet> createState() => _AddPartySheetState();
}

enum _BalanceType {
  receivable, // Receivable (+)
  payable, // Payable (-)
  zero, // Zero (0)
}

class _AddPartySheetState extends State<AddPartySheet> {
  late PartyType _partyType;
  _BalanceType _balanceType = _BalanceType.receivable;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _cnicController = TextEditingController();
  final _notesController = TextEditingController();

  bool _showAdvancedDetails = false;
  bool _isSavingParty = false;

  final List<String> _popularCities = [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Gujranwala',
    'Peshawar',
    'Sialkot',
  ];

  @override
  void initState() {
    super.initState();
    _partyType = widget.initialType;
    if (_partyType == PartyType.supplier) {
      _balanceType = _BalanceType.payable; // Usually we pay suppliers
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _cnicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_isSavingParty) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isSavingParty = true;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? '0300-0000000'
        : _phoneController.text.trim();
    final city = _cityController.text.trim();
    final area = _areaController.text.trim();
    final address = _addressController.text.trim();
    final cnic = _cnicController.text.trim();
    final notes = _notesController.text.trim();
    final rawCredit = _creditLimitController.text.trim().replaceAll(',', '');
    double? creditLimit;
    if (rawCredit.isNotEmpty) {
      final parsed = double.tryParse(rawCredit);
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        _isSavingParty = false;
        AppToast.showWarning(context, 'Please enter a valid positive credit limit');
        return;
      }
      creditLimit = parsed;
    }

    final rawBalText = _balanceController.text.trim().replaceAll(',', '');
    double rawBalance = 0.0;
    if (rawBalText.isNotEmpty) {
      final parsed = double.tryParse(rawBalText);
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        _isSavingParty = false;
        AppToast.showWarning(context, 'Please enter a valid positive opening balance');
        return;
      }
      rawBalance = parsed;
    }

    double finalBalance = 0.0;
    if (_balanceType == _BalanceType.receivable) {
      finalBalance = rawBalance; // Positive: They owe us
    } else if (_balanceType == _BalanceType.payable) {
      finalBalance = -rawBalance; // Negative: We owe them
    } else {
      finalBalance = 0.0;
    }

    final newPartyId = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final activeShopId = ShopState.instance.activeShopId;

    // Set initial balance to 0.0 so addTransaction applies the opening balance exactly once
    final newParty = PartyModel(
      id: newPartyId,
      name: name,
      phone: phone,
      type: _partyType,
      city: city,
      area: area,
      address: address,
      cnic: cnic,
      creditLimit: creditLimit,
      notes: notes,
      balance: 0.0,
      shopId: activeShopId,
      createdAt: DateTime.now(),
    );

    // Atomic write with rollback on error
    try {
      // 1. Add Party to Khata
      final storedParty = KhataState.instance.addParty(newParty);

      // 2. If initial balance is non-zero, record opening balance entry exactly once
      if (finalBalance != 0.0) {
        KhataState.instance.addTransaction(
          partyId: storedParty.id,
          type: finalBalance > 0 ? LedgerType.gave : LedgerType.got,
          amount: finalBalance.abs(),
          note: 'Opening Balance',
          shopId: storedParty.shopId,
        );
      }
    } catch (e) {
      _isSavingParty = false;
      KhataState.instance.deleteParty(newPartyId);
      AppToast.showError(context, 'Failed to save party: $e');
      return;
    }

    Navigator.pop(context, true);

    AppToast.showSuccess(
      context,
      '${_partyType == PartyType.customer ? "Customer" : "Supplier"} "$name" added to Ledger!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isCustomer = _partyType == PartyType.customer;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle & Header
          _buildHeader(isCustomer),

          // 2. Scrollable Form Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Type Selector (Customer vs Supplier)
                    _buildTypeSelector(),

                    const SizedBox(height: 16),

                    // Section: Name & Contact
                    _buildSectionTitle('Bunyadi Maloomat (Basic Info)', Icons.person_outline),
                    const SizedBox(height: 8),
                    _buildNameField(isCustomer),
                    const SizedBox(height: 10),
                    _buildPhoneField(),

                    const SizedBox(height: 18),

                    // Section: Location (City, Area, Address)
                    _buildSectionTitle('Location & Address', Icons.location_on_outlined),
                    const SizedBox(height: 8),
                    _buildLocationSection(),

                    const SizedBox(height: 18),

                    // Section: Opening Balance
                    _buildSectionTitle('Opening Balance', Icons.account_balance_wallet_outlined),
                    const SizedBox(height: 8),
                    _buildBalanceSection(isCustomer),

                    const SizedBox(height: 14),

                    // Section: Advanced Details (Collapsible)
                    _buildAdvancedToggle(),
                    if (_showAdvancedDetails) ...[
                      const SizedBox(height: 12),
                      _buildAdvancedSection(isCustomer),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Save Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isCustomer) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCustomer
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCustomer ? Icons.person_add_alt_1 : Icons.local_shipping,
              size: 20,
              color: isCustomer
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFEA580C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCustomer ? 'Add New Customer' : 'Add New Supplier',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isCustomer
                      ? 'Create customer profile & credit ledger'
                      : 'Create vendor/dealer supply ledger',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_partyType == PartyType.customer) return;
                setState(() {
                  _partyType = PartyType.customer;
                  _balanceType = _BalanceType.receivable;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _partyType == PartyType.customer
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _partyType == PartyType.customer
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: _partyType == PartyType.customer
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Customer (Grahak)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _partyType == PartyType.customer
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_partyType == PartyType.supplier) return;
                setState(() {
                  _partyType = PartyType.supplier;
                  _balanceType = _BalanceType.payable;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _partyType == PartyType.supplier
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _partyType == PartyType.supplier
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: _partyType == PartyType.supplier
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Supplier (Vendor)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _partyType == PartyType.supplier
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF475569)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(bool isCustomer) {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: isCustomer ? 'Customer Name *' : 'Supplier / Company Name *',
        hintText: isCustomer ? 'e.g. John Doe / Muhammad Usman' : 'e.g. Metro Traders / Al-Karam Fabrics',
        prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        hintText: '0300-1234567',
        prefixIcon: Container(
          width: 55,
          alignment: Alignment.center,
          child: const Text(
            '+92',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ),
        suffixIcon: const Icon(Icons.phone_android, size: 18, color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick City Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _popularCities.map((city) {
              final isSelected = _cityController.text.trim().toLowerCase() == city.toLowerCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _cityController.text = city;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6, bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    city,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // City & Area Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Shehar (City)',
                  hintText: 'e.g. Lahore / Karachi',
                  prefixIcon: const Icon(Icons.location_city, size: 17, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _areaController,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Ilaqa / Market (Area)',
                  hintText: 'e.g. Anarkali / Gulberg',
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 17, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Street Address
        TextFormField(
          controller: _addressController,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Street Address (Shop No / Street / Area)',
            hintText: 'e.g. Shop #14, Ground Floor, Madina Market',
            prefixIcon: const Icon(Icons.home_outlined, size: 17, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(bool isCustomer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance Type Switcher (Receivable vs Payable vs Zero)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _balanceType = _BalanceType.receivable),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _balanceType == _BalanceType.receivable
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _balanceType == _BalanceType.receivable
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE2E8F0),
                      width: _balanceType == _BalanceType.receivable ? 1.5 : 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.arrow_downward, size: 15, color: Color(0xFF15803D)),
                      SizedBox(height: 2),
                      Text(
                        'Receivable',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      Text('(To Collect)', style: TextStyle(fontSize: 8.5, color: Color(0xFF15803D))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _balanceType = _BalanceType.payable),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _balanceType == _BalanceType.payable
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _balanceType == _BalanceType.payable
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFE2E8F0),
                      width: _balanceType == _BalanceType.payable ? 1.5 : 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.arrow_upward, size: 15, color: Color(0xFFB91C1C)),
                      SizedBox(height: 2),
                      Text(
                        'Payable',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      Text('(To Pay)', style: TextStyle(fontSize: 8.5, color: Color(0xFFB91C1C))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _balanceType = _BalanceType.zero;
                    _balanceController.text = '0';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _balanceType == _BalanceType.zero
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _balanceType == _BalanceType.zero
                          ? const Color(0xFF475569)
                          : const Color(0xFFE2E8F0),
                      width: _balanceType == _BalanceType.zero ? 1.5 : 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.remove, size: 15, color: Color(0xFF475569)),
                      SizedBox(height: 2),
                      Text(
                        'No Balance',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text('(Zero PKR)', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_balanceType != _BalanceType.zero) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _balanceType == _BalanceType.receivable
                  ? const Color(0xFF15803D)
                  : const Color(0xFFDC2626),
            ),
            decoration: InputDecoration(
              labelText: _balanceType == _BalanceType.receivable
                  ? 'Receivable Amount (PKR)'
                  : 'Payable Amount (PKR)',
              hintText: '0',
              prefixText: 'PKR  ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _balanceType == _BalanceType.receivable
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showAdvancedDetails = !_showAdvancedDetails),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(
                  _showAdvancedDetails
                      ? 'Mazeed Maloomat Chupayein'
                      : 'Mazeed Maloomat (Credit Limit, CNIC, Notes)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            Icon(
              _showAdvancedDetails ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(bool isCustomer) {
    return Column(
      children: [
        // Credit Limit
        TextFormField(
          controller: _creditLimitController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Credit Limit (PKR)',
            hintText: 'e.g. 50000',
            prefixIcon: const Icon(Icons.speed_outlined, size: 17, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // CNIC Number
        TextFormField(
          controller: _cnicController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'National ID / CNIC (Optional)',
            hintText: '35201-XXXXXXX-X',
            prefixIcon: const Icon(Icons.credit_card, size: 17, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Notes
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Special Notes / Instructions (Optional)',
            hintText: 'e.g. Settles account every Monday, alternate contact: 0321...',
            prefixIcon: const Icon(Icons.note_alt_outlined, size: 17, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
              label: Text(
                _partyType == PartyType.customer
                    ? 'Save Customer'
                    : 'Save Supplier',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
