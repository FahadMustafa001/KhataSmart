import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../models/party_model.dart';
import '../../routes/app_routes.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/notification_bell_button.dart';
import '../shared_widgets/smart_khata_drawer.dart';
import '../shared_widgets/smart_bottom_navigation_bar.dart';
import 'widgets/add_party_sheet.dart';

class KhataCustomerItem {
  final String id;
  final String name;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String phone;
  final String city;
  final String area;
  final String address;
  final double? creditLimit;
  final String activity;
  final double balance;
  final bool isReceivable;
  final bool hasActiveDot;
  final String? note;
  final PartyType type;

  const KhataCustomerItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.phone,
    this.city = '',
    this.area = '',
    this.address = '',
    this.creditLimit,
    required this.activity,
    required this.balance,
    this.isReceivable = true,
    this.hasActiveDot = false,
    this.note,
    this.type = PartyType.customer,
  });

  String get displayLocation {
    final components = <String>[];
    if (area.trim().isNotEmpty) components.add(area.trim());
    if (city.trim().isNotEmpty) components.add(city.trim());
    if (components.isEmpty && address.trim().isNotEmpty) {
      components.add(address.trim());
    }
    return components.join(', ');
  }
}

class KhataDirectoryScreen extends StatefulWidget {
  const KhataDirectoryScreen({super.key});

  @override
  State<KhataDirectoryScreen> createState() => _KhataDirectoryScreenState();
}

class _KhataDirectoryScreenState extends State<KhataDirectoryScreen> {
  final _khataState = KhataState.instance;
  int _selectedTabIndex = 0; // 0: Customers, 1: Suppliers
  String _selectedFilter = 'All Pending';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _khataState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _khataState.removeListener(_rebuild);
    _searchController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  KhataCustomerItem _partyToCustomerItem(PartyModel p) {
    return KhataCustomerItem(
      id: p.id,
      name: p.name,
      initials: p.initials,
      avatarBg: p.balance > 0
          ? const Color(0xFFE0F2FE)
          : (p.balance < 0 ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9)),
      avatarTextColor: p.balance > 0
          ? const Color(0xFF0369A1)
          : (p.balance < 0 ? const Color(0xFFBE123C) : const Color(0xFF475569)),
      phone: p.phone,
      city: p.city,
      area: p.area,
      address: p.address,
      creditLimit: p.creditLimit,
      activity: p.displayLocation.isNotEmpty
          ? p.displayLocation
          : 'Active in Khata',
      balance: p.balance.abs(),
      isReceivable: p.balance >= 0,
      hasActiveDot: p.balance != 0,
      note: p.balance < 0 ? 'Advance / Payable' : null,
      type: p.type,
    );
  }

  List<KhataCustomerItem> get _currentList {
    final parties =
        _selectedTabIndex == 0 ? _khataState.customers : _khataState.suppliers;
    final list = parties.map(_partyToCustomerItem).toList();
    return list.where((item) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.phone.contains(q) ||
          item.city.toLowerCase().contains(q) ||
          item.area.toLowerCase().contains(q) ||
          item.address.toLowerCase().contains(q);
      if (!matchesSearch) return false;

      if (_selectedFilter == '> 30 Days Due') {
        return item.balance > 5000;
      }
      if (_selectedFilter == 'Highest Balance') {
        return item.balance > 10000;
      }
      if (_selectedFilter == 'Zero Bal') {
        return item.balance == 0;
      }
      return true;
    }).toList();
  }

  void _showAddNewAccountDialog() {
    AddPartySheet.show(
      context,
      initialType:
          _selectedTabIndex == 0 ? PartyType.customer : PartyType.supplier,
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort Khata Book',
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
              const Divider(),
              ...['All Pending', 'Highest Balance', '> 30 Days Due', 'Zero Bal']
                  .map((filterName) {
                final isSelected = _selectedFilter == filterName;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  title: Text(
                    filterName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedFilter = filterName);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _currentList;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const SmartKhataDrawer(currentRoute: AppRoutes.khataDirectory),
      appBar: CustomAppBar(
        title: 'Khata Ledger',
        subtitle: 'SmartKhata Store • Sync OK',
        showLogo: true,
        showMenu: true,
        actions: [
          const NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                size: 20, color: Color(0xFFDC2626)),
            tooltip: 'Export Complete Khata to PDF',
            onPressed: () {
              PrintingAndSharingService.instance.exportKhataDirectoryPdf(
                parties: _khataState.parties,
                shop: ShopState.instance.activeShop,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20, color: Color(0xFF475569)),
            tooltip: 'Filter & Sort',
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top 2 Metric Cards: Total Receivables vs Total Payables
                    _buildMetricCardsRow(),

                    const SizedBox(height: 12),

                    // Customers vs Suppliers Segmented Tabs
                    _buildSegmentedTabs(),

                    const SizedBox(height: 10),

                    // Search & Sort Row
                    _buildSearchSortRow(),

                    const SizedBox(height: 10),

                    // Horizontal Filter Chips
                    _buildFilterChipsRow(),

                    const SizedBox(height: 10),

                    // Directory Cards List
                    if (list.isEmpty)
                      EmptyStateWidget(
                        imageAsset: AppAssets.emptyState,
                        icon: Icons.people_outline,
                        title: _selectedTabIndex == 0
                            ? 'No Customers Yet'
                            : 'No Suppliers Yet',
                        subtitle: _selectedTabIndex == 0
                            ? 'Tap "+ New Account" to add your first customer ledger.'
                            : 'Tap "+ New Account" to add your first supplier ledger.',
                      )
                    else
                      ...list.map((item) => _buildKhataCard(item)),

                    const SizedBox(height: 80), // Padding for FAB & Bottom Nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button (+ New Account)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.person_add_alt_1, size: 18),
          label: const Text(
            '+ New Account',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          onPressed: _showAddNewAccountDialog,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: const SmartBottomNavigationBar(
        currentRoute: AppRoutes.khataDirectory,
      ),
    ),
    );
  }

  // 2. Top Metric Cards: Total Receivables vs Total Payables
  Widget _buildMetricCardsRow() {
    return Row(
      children: [
        // Total Receivables
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Receivables',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Text(
                          '(To Collect / Lena)',
                          style: TextStyle(
                              fontSize: 8.5, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.call_received,
                          size: 16,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_khataState.customers.length} Customers',
                  style:
                      const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  'PKR ${_khataState.totalReceivable.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Total Payables
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payables',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        Text(
                          '(To Pay / Dena)',
                          style: TextStyle(
                              fontSize: 8.5, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.call_made,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_khataState.suppliers.length} Suppliers',
                  style:
                      const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  'PKR ${_khataState.totalPayable.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Customers vs Suppliers Segmented Tabs
  Widget _buildSegmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Customers Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? const Color(0xFF0F172A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt,
                      size: 15,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_khataState.customers.length}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Suppliers Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? const Color(0xFF0F172A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 15,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Suppliers',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_khataState.suppliers.length}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
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

  // 4. Search & Sort Row
  Widget _buildSearchSortRow() {
    return Row(
      children: [
        // Search Input
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by name or mobile number...',
              hintStyle:
                  const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              suffixIcon:
                  const Icon(Icons.mic_none, size: 18, color: Color(0xFF64748B)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF16A34A), width: 1.5),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 8),

        // Sort Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.sort, size: 16, color: Color(0xFF1E293B)),
              SizedBox(width: 4),
              Text(
                'Sort',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Horizontal Filter Chips Row
  Widget _buildFilterChipsRow() {
    final filters = [
      'All Pending',
      '> 30 Days Due',
      'Highest Balance',
      'Zero Bal'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((chip) {
          final isSelected = _selectedFilter == chip;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = chip),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 6. Khata Customer / Supplier Card
  Widget _buildKhataCard(KhataCustomerItem item) {
    return GestureDetector(
      onTap: () {
        PartyModel party;
        try {
          party = _khataState.parties.firstWhere((p) => p.id == item.id);
        } catch (_) {
          party = PartyModel(
            id: item.id,
            name: item.name,
            phone: item.phone,
            type: item.type,
            city: item.city,
            area: item.area,
            address: item.address,
            creditLimit: item.creditLimit,
            balance: item.isReceivable ? item.balance : -item.balance,
          );
        }
        Navigator.pushNamed(context, AppRoutes.partyLedgerDetail,
            arguments: party);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Initials Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.avatarBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: item.avatarTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name, Phone, Location & Activity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.hasActiveDot) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        item.phone,
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),

                  // Kahan Se Hai (Location Badge)
                  if (item.displayLocation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF2563EB)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.displayLocation,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2563EB),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Credit limit indicator
                  if (item.creditLimit != null && item.creditLimit! > 0) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Udhaar Limit: PKR ${item.creditLimit!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Balance, Status Badge & Remind Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${item.balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: item.balance == 0
                        ? const Color(0xFF64748B)
                        : (item.isReceivable
                            ? const Color(0xFF15803D)
                            : const Color(0xFFDC2626)),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: item.balance == 0
                        ? const Color(0xFFF1F5F9)
                        : (item.isReceivable
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.balance == 0
                        ? 'Chukta (Settled)'
                        : (item.isReceivable ? 'Receivable' : 'Advance (Payable)'),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: item.balance == 0
                          ? const Color(0xFF475569)
                          : (item.isReceivable
                              ? const Color(0xFF15803D)
                              : const Color(0xFFDC2626)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (item.isReceivable && item.balance > 0)
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'WhatsApp Payment Reminder sent to ${item.name}!')),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(AppAssets.whatsappIcon, width: 12, height: 12),
                        const SizedBox(width: 4),
                        const Text(
                          'Remind',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (item.note != null)
                  Text(
                    item.note!,
                    style:
                        const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
