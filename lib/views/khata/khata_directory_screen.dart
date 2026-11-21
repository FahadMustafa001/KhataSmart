import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/app_toast.dart';
import '../../models/party_model.dart';
import '../../routes/app_routes.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../services/csv_export_service.dart';
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
  String _selectedFilter = 'All Accounts';
  String _sortBy = 'Balance: High to Low';
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
    var filtered = list.where((item) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.phone.contains(q) ||
          item.city.toLowerCase().contains(q) ||
          item.area.toLowerCase().contains(q) ||
          item.address.toLowerCase().contains(q) ||
          item.balance.toString().contains(q);
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Pending (Udhar)') {
        return item.balance > 0 && item.isReceivable;
      }
      if (_selectedFilter == 'Advance / Payable') {
        return item.balance > 0 && !item.isReceivable;
      }
      if (_selectedFilter == 'Settled (Nill)') {
        return item.balance == 0;
      }
      return true;
    }).toList();

    if (_sortBy == 'Balance: High to Low') {
      filtered.sort((a, b) => b.balance.compareTo(a.balance));
    } else if (_sortBy == 'Balance: Low to High') {
      filtered.sort((a, b) => a.balance.compareTo(b.balance));
    } else if (_sortBy == 'Name (A to Z)') {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'Name (Z to A)') {
      filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    return filtered;
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
              const Text('Filter Status',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              ...['All Accounts', 'Pending (Udhar)', 'Advance / Payable', 'Settled (Nill)']
                  .map((filterName) {
                final isSelected = _selectedFilter == filterName;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                    size: 18,
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
              const SizedBox(height: 10),
              const Text('Sort By',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              ...[
                'Balance: High to Low',
                'Balance: Low to High',
                'Name (A to Z)',
                'Name (Z to A)',
              ].map((sortName) {
                final isSelected = _sortBy == sortName;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  title: Text(
                    sortName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  onTap: () {
                    setState(() => _sortBy = sortName);
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const SmartKhataDrawer(currentRoute: AppRoutes.khataDirectory),
      appBar: CustomAppBar(
        title: 'Khata Ledger',
        subtitle: 'SmartKhata Store • Sync OK',
        showLogo: true,
        showMenu: true,
        actions: [
          const NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.table_view_rounded,
                size: 20, color: Color(0xFF16A34A)),
            tooltip: 'Export Khata to Excel / CSV',
            onPressed: () async {
              final file = await CsvExportService.instance.generateKhataPartiesCsv(
                parties: _khataState.parties,
                shop: ShopState.instance.activeShop,
                filterType: _selectedTabIndex == 0 ? PartyType.customer : PartyType.supplier,
              );
              await CsvExportService.instance.shareCsvFile(
                file,
                subject: 'Khata Accounts Export - ${ShopState.instance.activeShop.name}',
              );
            },
          ),
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
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricCardsRow(),

                    const SizedBox(height: 12),

                    _buildSegmentedTabs(),

                    const SizedBox(height: 10),

                    _buildSearchSortRow(),

                    const SizedBox(height: 10),

                    _buildFilterChipsRow(),

                    const SizedBox(height: 10),

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

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

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
              hintText: 'Search by name, phone, city, or balance...',
              hintStyle:
                  const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : const Icon(Icons.mic_none, size: 18, color: Color(0xFF64748B)),
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
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _showFilterBottomSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 16, color: Color(0xFF1E293B)),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy.contains('Balance') ? 'Balance' : 'Name',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 5. Horizontal Filter Chips Row
  Widget _buildFilterChipsRow() {
    final currentParties = _selectedTabIndex == 0 ? _khataState.customers : _khataState.suppliers;
    final totalCount = currentParties.length;
    final pendingCount = currentParties.where((p) => p.balance > 0).length;
    final advanceCount = currentParties.where((p) => p.balance < 0).length;
    final settledCount = currentParties.where((p) => p.balance == 0).length;

    final filters = [
      {'label': 'All Accounts', 'count': '$totalCount'},
      {'label': 'Pending (Udhar)', 'count': '$pendingCount'},
      {'label': 'Advance / Payable', 'count': '$advanceCount'},
      {'label': 'Settled (Nill)', 'count': '$settledCount'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final chip = f['label']!;
          final count = f['count']!;
          final isSelected = _selectedFilter == chip;
          final isPendingAlert = chip == 'Pending (Udhar)' && pendingCount > 0;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = chip),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : (isPendingAlert ? const Color(0xFFFEF2F2) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : (isPendingAlert ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chip,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isPendingAlert ? const Color(0xFFDC2626) : const Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF334155)
                          : (isPendingAlert ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: (isSelected || isPendingAlert)
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 6. Khata Customer / Supplier Card
  Widget _buildKhataCard(KhataCustomerItem item) {
    PartyModel getParty() {
      try {
        return _khataState.parties.firstWhere((p) => p.id == item.id);
      } catch (_) {
        return PartyModel(
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
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final party = getParty();
            Navigator.pushNamed(context, AppRoutes.partyLedgerDetail, arguments: party);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
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

                  // Location Badge
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
                        'Credit Limit: PKR ${item.creditLimit!.toStringAsFixed(0)}',
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

            // Balance, Status Badge & Quick Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${item.balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: item.balance == 0
                        ? const Color(0xFF64748B)
                        : (item.type == PartyType.customer
                            ? (item.isReceivable ? const Color(0xFF15803D) : const Color(0xFFDC2626))
                            : (item.isReceivable ? const Color(0xFFDC2626) : const Color(0xFF15803D))),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.balance == 0
                        ? const Color(0xFFF1F5F9)
                        : (item.type == PartyType.customer
                            ? (item.isReceivable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2))
                            : (item.isReceivable ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7))),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.balance == 0
                        ? 'Chukta (Settled)'
                        : (item.type == PartyType.customer
                            ? (item.isReceivable ? 'Receivable (Lena)' : 'Advance (Dena)')
                            : (item.isReceivable ? 'Payable (Dena)' : 'Advance (Lena)')),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: item.balance == 0
                          ? const Color(0xFF475569)
                          : (item.type == PartyType.customer
                              ? (item.isReceivable ? const Color(0xFF15803D) : const Color(0xFFDC2626))
                              : (item.isReceivable ? const Color(0xFFDC2626) : const Color(0xFF15803D))),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // One-tap Call
                    if (item.phone.isNotEmpty)
                      InkWell(
                        onTap: () => PrintingAndSharingService.instance.makePhoneCall(item.phone),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Icon(Icons.phone, size: 13, color: Color(0xFF2563EB)),
                        ),
                      ),
                    const SizedBox(width: 6),
                    // One-tap WhatsApp Reminder
                    InkWell(
                      onTap: () {
                        try {
                          final party = _khataState.parties.firstWhere((p) => p.id == item.id);
                          PrintingAndSharingService.instance.sendPartyLedgerViaWhatsApp(
                            party: party,
                            shop: ShopState.instance.activeShop,
                          );
                        } catch (_) {
                          AppToast.showInfo(context, 'Sending reminder to ${item.name}...');
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Image.asset(AppAssets.whatsappIcon, width: 13, height: 13),
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}
