import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/app_toast.dart';
import '../../models/ledger_entry_model.dart';
import '../../models/party_model.dart';
import '../../models/purchase_invoice_model.dart';
import '../../routes/app_routes.dart';
import '../../services/printing_and_sharing_service.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../inventory/purchase_inward_screen.dart';
import 'widgets/add_transaction_modal.dart';

class LedgerDetailItem {
  final String id;
  final DateTime rawDate;
  final String date;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;
  final String title;
  final String time;
  final String balanceAfter;
  final double? debit;
  final String? debitLabel;
  final double? credit;
  final String? creditLabel;

  const LedgerDetailItem({
    required this.id,
    required this.rawDate,
    required this.date,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
    required this.title,
    required this.time,
    required this.balanceAfter,
    this.debit,
    this.debitLabel,
    this.credit,
    this.creditLabel,
  });
}

class PartyLedgerDetailScreen extends StatefulWidget {
  final PartyModel? party;

  const PartyLedgerDetailScreen({super.key, this.party});

  @override
  State<PartyLedgerDetailScreen> createState() =>
      _PartyLedgerDetailScreenState();
}

class _PartyLedgerDetailScreenState extends State<PartyLedgerDetailScreen> {
  final _khataState = KhataState.instance;
  final _inventoryState = InventoryState.instance;

  late String _partyId;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDateFilter = 'All Dates';
  String _selectedTypeFilter = 'All';
  final bool _isAutoReminderActive = true;
  int _supplierActiveTab = 0; // 0: Ledger Timeline, 1: Stock Inward Bills

  PartyModel? get _currentParty {
    try {
      return _khataState.parties.firstWhere((p) => p.id == _partyId);
    } catch (_) {
      return widget.party;
    }
  }

  double get _currentBalance => _currentParty?.balance ?? widget.party?.balance ?? 0.0;

  static String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }

  List<LedgerDetailItem> get _partyTransactions {
    final rawEntries = _khataState.getEntriesForParty(_partyId);
    if (rawEntries.isEmpty) return [];

    // Sort ascending to accurately compute historical running balances
    final sortedAsc = List<LedgerEntryModel>.from(rawEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    double totalGave = 0;
    double totalGot = 0;
    for (final e in sortedAsc) {
      if (e.type == LedgerType.gave) {
        totalGave += e.amount;
      } else {
        totalGot += e.amount;
      }
    }

    double running = _currentBalance - (totalGave - totalGot);
    final Map<String, double> runningBalanceMap = {};
    for (final e in sortedAsc) {
      if (e.type == LedgerType.gave) {
        running += e.amount;
      } else {
        running -= e.amount;
      }
      runningBalanceMap[e.id] = running;
    }

    // Sort descending for display (latest on top)
    var entries = List<LedgerEntryModel>.from(rawEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      entries = entries.where((e) {
        return e.note.toLowerCase().contains(q) ||
            e.amount.toString().contains(q) ||
            e.id.toLowerCase().contains(q);
      }).toList();
    }

    // Date filter
    if (_selectedDateFilter == 'This Month') {
      final now = DateTime.now();
      entries = entries.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else if (_selectedDateFilter == 'Last 30 Days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      entries = entries.where((e) => e.date.isAfter(cutoff)).toList();
    }

    // Type filter
    if (_selectedTypeFilter == 'Gave') {
      entries = entries.where((e) => e.type == LedgerType.gave).toList();
    } else if (_selectedTypeFilter == 'Got') {
      entries = entries.where((e) => e.type == LedgerType.got).toList();
    }

    return entries.map((e) {
      final isDebit = e.type == LedgerType.gave;
      final dateStr = '${e.date.day} ${_monthName(e.date.month)} ${e.date.year}';
      final hour = e.date.hour % 12 == 0 ? 12 : e.date.hour % 12;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')} ${e.date.hour >= 12 ? 'PM' : 'AM'}';
      String tagStr;
      if (e.note.startsWith('Bill #')) {
        final spaceIdx = e.note.indexOf(' ', 5);
        tagStr = spaceIdx != -1 ? e.note.substring(5, spaceIdx) : e.note.substring(5);
      } else {
        tagStr = '#TXN-${e.id.length > 4 ? e.id.substring(e.id.length - 4) : e.id}';
      }

      final balAtTime = runningBalanceMap[e.id] ?? _currentBalance;

      return LedgerDetailItem(
        id: e.id,
        rawDate: e.date,
        date: dateStr,
        tag: tagStr,
        tagColor: isDebit ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        tagTextColor: isDebit ? const Color(0xFFDC2626) : const Color(0xFF15803D),
        title: e.note.isNotEmpty ? e.note : (isDebit ? 'Udhaar / Debit' : 'Cash Received / Credit'),
        time: timeStr,
        balanceAfter: 'PKR ${balAtTime.abs().toStringAsFixed(0)} ${balAtTime >= 0 ? "(Dr)" : "(Cr)"}',
        debit: isDebit ? e.amount : null,
        debitLabel: isDebit ? 'You Gave' : null,
        credit: !isDebit ? e.amount : null,
        creditLabel: !isDebit ? 'You Received' : null,
      );
    }).toList();
  }

  double get _totalDebit {
    final entries = _khataState.getEntriesForParty(_partyId);
    return entries.where((e) => e.type == LedgerType.gave).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _totalCredit {
    final entries = _khataState.getEntriesForParty(_partyId);
    return entries.where((e) => e.type == LedgerType.got).fold(0.0, (sum, e) => sum + e.amount);
  }

  String get _latestActivityText {
    final entries = _khataState.getEntriesForParty(_partyId);
    if (entries.isEmpty) return 'No transactions recorded yet';
    final sorted = List<LedgerEntryModel>.from(entries)..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first.date;
    final now = DateTime.now();
    final difference = now.difference(latest);

    final hour = latest.hour % 12 == 0 ? 12 : latest.hour % 12;
    final timeStr = '${hour.toString().padLeft(2, '0')}:${latest.minute.toString().padLeft(2, '0')} ${latest.hour >= 12 ? 'PM' : 'AM'}';

    if (difference.inDays == 0 && now.day == latest.day) {
      return 'Today $timeStr';
    } else if (difference.inDays <= 1) {
      return 'Yesterday $timeStr';
    } else {
      return '${latest.day} ${_monthName(latest.month)} $timeStr';
    }
  }

  @override
  void initState() {
    super.initState();
    _partyId = widget.party?.id ?? '';
    _khataState.addListener(_rebuild);
    _inventoryState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _khataState.removeListener(_rebuild);
    _inventoryState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _openAddModal(LedgerType type) {
    final p = _currentParty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionModal(
        partyId: _partyId,
        partyName: p?.name ?? 'Account',
        initialType: type,
      ),
    );
  }

  void _showEditPartyModal() {
    final party = _currentParty;
    if (party == null) return;

    final nameCtrl = TextEditingController(text: party.name);
    final phoneCtrl = TextEditingController(text: party.phone);
    final cityCtrl = TextEditingController(text: party.city);
    final areaCtrl = TextEditingController(text: party.area);
    final addressCtrl = TextEditingController(text: party.address);
    final creditCtrl = TextEditingController(
      text: party.creditLimit != null && party.creditLimit! > 0
          ? party.creditLimit!.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit ${party.type == PartyType.supplier ? "Supplier" : "Customer"} Details',
                    style: const TextStyle(
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
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone / WhatsApp Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: areaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Area / Market',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Shop / Street Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: creditCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Credit Limit (PKR)',
                  hintText: 'e.g. 50000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    if (newName.isEmpty) {
                      AppToast.showWarning(context, 'Account name cannot be empty');
                      return;
                    }
                    final double? parsedLimit = double.tryParse(creditCtrl.text.trim());
                    final updated = party.copyWith(
                      name: newName,
                      phone: phoneCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      area: areaCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      creditLimit: parsedLimit,
                    );
                    _khataState.updateParty(updated);
                    Navigator.pop(ctx);
                    AppToast.showSuccess(context, 'Account details updated successfully!');
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionOptionsModal(LedgerDetailItem tx) {
    final purchases = _inventoryState.getPurchasesForSupplier(_partyId);
    PurchaseInvoiceModel? matchedInvoice;
    for (final p in purchases) {
      if (tx.title.contains(p.invoiceNo) || tx.tag.contains(p.invoiceNo) || p.id == tx.id) {
        matchedInvoice = p;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.tag,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${tx.date} • ${tx.time}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tx.tagColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tx.debit != null ? 'Gave: PKR ${tx.debit!.toStringAsFixed(0)}' : 'Got: PKR ${tx.credit!.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tx.tagTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Note: ${tx.title}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 16),
              if (matchedInvoice != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF7ED),
                    child: Icon(Icons.receipt_long_outlined, color: Color(0xFFEA580C), size: 20),
                  ),
                  title: Text(
                    'View Purchased Products (${matchedInvoice.items.length} Items)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEA580C)),
                  ),
                  subtitle: Text(
                    'Itemized quantities, rates & bill ${matchedInvoice.invoiceNo}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPurchaseInvoiceDetailSheet(matchedInvoice!);
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.share, color: Color(0xFF16A34A), size: 20),
                ),
                title: const Text('Share Transaction on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Send this entry directly to customer or supplier', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  final p = _currentParty;
                  if (p != null) {
                    PrintingAndSharingService.instance.sendPartyLedgerViaWhatsApp(party: p, shop: ShopState.instance.activeShop);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                ),
                title: const Text('Delete / Revert Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626))),
                subtitle: const Text('Removes this entry and recalculates balance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (alertCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Transaction?'),
                      content: Text('Are you sure you want to delete ${tx.tag} (${tx.title})? Account balance will be restored automatically.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(alertCtx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                          onPressed: () => Navigator.pop(alertCtx, true),
                          child: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    _khataState.deleteEntry(tx.id);
                    AppToast.showSuccess(context, 'Transaction removed and balance recalculated!');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final party = _currentParty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.khataDirectory);
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
                Navigator.pushReplacementNamed(context, AppRoutes.khataDirectory);
              }
            },
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Search ledger by note, amount, bill...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${party?.name ?? "Account"} Ledger',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${party?.type == PartyType.supplier ? "Supplier" : "Customer"} • Smart Khata Book',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, size: 20, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
              tooltip: 'Edit Account',
              onPressed: _showEditPartyModal,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) async {
                final p = _currentParty;
                if (p == null) return;
                final shop = ShopState.instance.activeShop;

                if (val == 'call') {
                  await PrintingAndSharingService.instance.makePhoneCall(p.phone);
                } else if (val == 'whatsapp') {
                  await PrintingAndSharingService.instance.sendPartyLedgerViaWhatsApp(party: p, shop: shop);
                } else if (val == 'print') {
                  final entries = _khataState.getEntriesForParty(p.id);
                  await PrintingAndSharingService.instance.printOrSharePartyLedgerStatement(
                    party: p,
                    entries: entries,
                    shop: shop,
                    isDirectPrint: true,
                  );
                } else if (val == 'edit') {
                  _showEditPartyModal();
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Khata Account?'),
                      content: Text('Are you sure you want to delete ${p.name}? All transaction history for this party will be permanently removed.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    _khataState.deleteParty(p.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 10),
                      Text('Edit Account Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'call',
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 10),
                      Text('Direct Call'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'whatsapp',
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF16A34A)),
                      SizedBox(width: 10),
                      Text('Send WhatsApp Reminder'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print_outlined, size: 18, color: Color(0xFF475569)),
                      SizedBox(width: 10),
                      Text('Print Full Statement PDF'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                      SizedBox(width: 10),
                      Text('Delete Account', style: TextStyle(color: Color(0xFFDC2626))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Customer Profile Card
                    _buildCustomerProfileCard(),

                    const SizedBox(height: 12),

                    // 2. Net Outstanding Balance Card (Properly Formatted & Resolved)
                    _buildNetBalanceCard(),

                    const SizedBox(height: 12),

                    // 3. Quick Action Buttons
                    _buildActionButtonsRow(),

                    const SizedBox(height: 12),

                    // 4. Totals Row
                    _buildTotalsRow(),

                    const SizedBox(height: 12),

                    // Supplier Tab Selector (Khata Ledger vs Purchased Stock Inward Bills)
                    if (party?.type == PartyType.supplier) ...[
                      _buildSupplierTabSelector(_inventoryState.getPurchasesForSupplier(party!.id).length),
                    ],

                    if (party?.type == PartyType.supplier && _supplierActiveTab == 1) ...[
                      _buildSupplierPurchasesView(party!),
                    ] else ...[
                      // 5. Transaction Statement Header & Filters
                      _buildTransactionStatementHeader(),

                      const SizedBox(height: 8),

                      // Filter chips row
                      _buildFilterChipsRow(),

                      const SizedBox(height: 8),

                      // 6. Subheader Table Column Names
                      _buildTableColumnHeader(),

                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // 7. Transaction Feed
                      if (_partyTransactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 42, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text(
                                  'No transactions match current filters.\nUse buttons below to record "You Gave" or "You Received".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        ..._partyTransactions.map((tx) => _buildTransactionRow(tx)),
                        const SizedBox(height: 10),
                      ],
                    ],

                    const SizedBox(height: 8),

                    // 8. Weekly Payment Reminder Banner
                    _buildReminderBanner(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar: Gave Credit & Got Payment
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  // 1. Customer Profile Card
  Widget _buildCustomerProfileCard() {
    final party = _currentParty;
    final isSupplier = party?.type == PartyType.supplier;
    final initials = party?.initials ?? 'KH';
    final locationText = party?.displayLocation.isNotEmpty == true
        ? party!.displayLocation
        : (party?.address ?? '');
    final hasLimit = party?.creditLimit != null && party!.creditLimit! > 0;
    final limitAmount = party?.creditLimit ?? 0.0;
    final usedFraction = hasLimit && limitAmount > 0
        ? (_currentBalance > 0 ? (_currentBalance / limitAmount).clamp(0.0, 1.0) : 0.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initials Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSupplier
                        ? [const Color(0xFFEA580C), const Color(0xFFF97316)]
                        : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Contact Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            party?.name ?? 'Store Account',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSupplier ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSupplier ? const Color(0xFFFFEDD5) : const Color(0xFFDBEAFE),
                            ),
                          ),
                          child: Text(
                            isSupplier ? 'Supplier' : 'Customer',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSupplier ? const Color(0xFFC2410C) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF2563EB)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              locationText,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2563EB)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          party?.phone.isNotEmpty == true ? party!.phone : 'No phone number',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Icon Button
              IconButton(
                icon: const Icon(Icons.mode_edit_outline_outlined, size: 18, color: Color(0xFF2563EB)),
                tooltip: 'Edit Account',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _showEditPartyModal,
              ),
            ],
          ),

          // Credit Limit Progress Bar (if configured)
          if (hasLimit) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CREDIT LIMIT USAGE',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'PKR ${_currentBalance > 0 ? _currentBalance.toStringAsFixed(0) : "0"} / ${limitAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: usedFraction > 0.9 ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: usedFraction,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usedFraction > 0.9
                            ? const Color(0xFFDC2626)
                            : (usedFraction > 0.7 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. Net Outstanding Balance Card
  Widget _buildNetBalanceCard() {
    final party = _currentParty;
    final isSupplier = party?.type == PartyType.supplier;
    final bal = _currentBalance;

    // Determine Financial Meaning
    final bool isSettled = bal == 0;
    final bool isReceivable = !isSupplier ? bal > 0 : bal < 0;

    String titleText;
    String badgeText;
    Color cardBg;
    Color borderColor;
    Color primaryColor;
    IconData statusIcon;

    if (isSettled) {
      titleText = 'ACCOUNT SETTLED';
      badgeText = 'Settled';
      cardBg = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      primaryColor = const Color(0xFF475569);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isReceivable) {
      titleText = !isSupplier ? 'NET RECEIVABLE (TO COLLECT)' : 'ADVANCE PAID';
      badgeText = !isSupplier ? 'Receivable' : 'Advance Paid';
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      primaryColor = const Color(0xFF15803D);
      statusIcon = Icons.arrow_downward_rounded;
    } else {
      titleText = !isSupplier ? 'ADVANCE RECEIVED' : 'NET PAYABLE (TO PAY)';
      badgeText = !isSupplier ? 'Advance Received' : 'Payable';
      cardBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      primaryColor = const Color(0xFFDC2626);
      statusIcon = Icons.arrow_upward_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Icon Badge replacing empty circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(statusIcon, color: primaryColor, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'PKR ${bal.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.history_rounded, size: 12, color: primaryColor.withAlpha(200)),
              const SizedBox(width: 4),
              Text(
                _latestActivityText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: primaryColor.withAlpha(215),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Quick Action Buttons Row: WhatsApp, Direct Call, Statement (+ Stock In for Supplier)
  Widget _buildActionButtonsRow() {
    final party = _currentParty;
    final isSupplier = party?.type == PartyType.supplier;

    return Row(
      children: [
        if (isSupplier) ...[
          // Quick Stock Inward Action for Supplier
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PurchaseInwardScreen(initialSupplierId: party?.id),
                  ),
                );
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFFEA580C)),
                    SizedBox(height: 4),
                    Text(
                      '+ Stock In',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                    ),
                    Text(
                      'Receive Items',
                      style: TextStyle(fontSize: 9, color: Color(0xFFEA580C)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // WhatsApp Action
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (party != null) {
                PrintingAndSharingService.instance.sendPartyLedgerViaWhatsApp(
                  party: party,
                  shop: ShopState.instance.activeShop,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                children: [
                  Image.asset(AppAssets.whatsappIcon, width: 22, height: 22),
                  const SizedBox(height: 4),
                  const Text(
                    'WhatsApp',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                  ),
                  Text(
                    isSupplier ? 'Statement' : 'Send Bill',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Direct Call Action
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final phone = party?.phone ?? '';
              if (phone.isNotEmpty) {
                PrintingAndSharingService.instance.makePhoneCall(phone);
              } else {
                AppToast.showWarning(context, 'No phone number provided for this party');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.phone_in_talk_rounded, size: 20, color: Color(0xFF2563EB)),
                  SizedBox(height: 4),
                  Text(
                    'Direct Call',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                  ),
                  Text(
                    'Dial Phone',
                    style: TextStyle(fontSize: 9, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Statement PDF Action
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (party != null) {
                final entries = _khataState.getEntriesForParty(party.id);
                PrintingAndSharingService.instance.printOrSharePartyLedgerStatement(
                  party: party,
                  entries: entries,
                  shop: ShopState.instance.activeShop,
                  isDirectPrint: false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF475569)),
                  SizedBox(height: 4),
                  Text(
                    'Statement',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Export PDF',
                    style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. Debit & Credit Totals Row
  Widget _buildTotalsRow() {
    return Row(
      children: [
        // Total Given (Debit)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOU GAVE (DEBIT)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, size: 10, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_totalDebit.toStringAsFixed(0)}',
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
        const SizedBox(width: 10),

        // Total Received (Credit)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOU GOT (CREDIT)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, size: 10, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_totalCredit.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 5. Transaction Statement Header & Filters
  Widget _buildTransactionStatementHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'TRANSACTION STATEMENT',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${_partyTransactions.length} Entries',
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChipsRow() {
    return Row(
      children: [
        // Date Filter
        PopupMenuButton<String>(
          initialValue: _selectedDateFilter,
          onSelected: (v) => setState(() => _selectedDateFilter = v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  _selectedDateFilter,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF64748B)),
              ],
            ),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'All Dates', child: Text('All Dates', style: TextStyle(fontSize: 12))),
            const PopupMenuItem(value: 'This Month', child: Text('This Month', style: TextStyle(fontSize: 12))),
            const PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days', style: TextStyle(fontSize: 12))),
          ],
        ),
        const SizedBox(width: 8),

        // Type Filter (All, Gave, Got)
        ...['All', 'Gave', 'Got'].map((type) {
          final isSelected = _selectedTypeFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() => _selectedTypeFilter = type),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type == 'All' ? 'All Types' : (type == 'Gave' ? 'Gave (Dr)' : 'Got (Cr)'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 6. Subheader Table Column Names
  Widget _buildTableColumnHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DATE & DETAILS (TAP FOR OPTIONS)',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          Row(
            children: [
              Text(
                'GAVE (DEBIT)',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
              SizedBox(width: 24),
              Text(
                'GOT (CREDIT)',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Transaction Feed Entries
  Widget _buildTransactionRow(LedgerDetailItem tx) {
    return InkWell(
      onTap: () => _showTransactionOptionsModal(tx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Date, Tag, Description, Time & Running Balance
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tx.date,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: tx.tagColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: tx.tagTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        tx.time,
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Bal: ${tx.balanceAfter}',
                          style: const TextStyle(fontSize: 8.5, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center-Right: Debit Column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (tx.debit != null) ...[
                    Text(
                      'PKR ${tx.debit!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    Text(
                      tx.debitLabel ?? '',
                      style: const TextStyle(fontSize: 9, color: Color(0xFFDC2626)),
                    ),
                  ] else
                    const Text('—', style: TextStyle(color: Color(0xFFCBD5E1))),
                ],
              ),
            ),

            // Right: Credit Column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (tx.credit != null) ...[
                    Text(
                      'PKR ${tx.credit!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    Text(
                      tx.creditLabel ?? '',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF15803D)),
                    ),
                  ] else
                    const Text('—', style: TextStyle(color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. Weekly Payment Reminder Banner
  Widget _buildReminderBanner() {
    final party = _currentParty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automated WhatsApp Reminder',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isAutoReminderActive
                      ? 'Auto-reminder enabled for scheduled balance updates.'
                      : 'Auto-reminder currently paused for this account.',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (party != null) {
                PrintingAndSharingService.instance.sendPartyLedgerViaWhatsApp(
                  party: party,
                  shop: ShopState.instance.activeShop,
                );
              }
            },
            child: const Text('Send Now', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Bottom Fixed Dual Action Buttons
  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gave Credit (Red)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _openAddModal(LedgerType.gave),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'You Gave (Debit)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Give Credit (-)',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFFFECACA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Got Payment (Green)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _openAddModal(LedgerType.got),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'You Got (Credit)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Receive Payment (+)',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFFBBF7D0),
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

  // ── Supplier Inward Inventory & Purchased Products Helpers ──────────────

  Widget _buildSupplierTabSelector(int purchasesCount) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 12),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _supplierActiveTab = 0),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _supplierActiveTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _supplierActiveTab == 0
                      ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 14,
                      color: _supplierActiveTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Khata Ledger',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _supplierActiveTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _supplierActiveTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_partyTransactions.length}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _supplierActiveTab = 1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _supplierActiveTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _supplierActiveTab == 1
                      ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: _supplierActiveTab == 1 ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Purchased Items',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _supplierActiveTab == 1 ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _supplierActiveTab == 1 ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$purchasesCount',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildSupplierPurchasesView(PartyModel party) {
    final purchases = _inventoryState.getPurchasesForSupplier(party.id);

    if (purchases.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFFEA580C)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Stock Inward Bills Yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Record stock received from this supplier to inspect which products, quantities, rates, and cash/credit payments were made.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'Record First Stock Inward',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PurchaseInwardScreen(initialSupplierId: party.id),
                  ),
                );
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      );
    }

    final double totalPurchasedAmount = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
    final double totalPaidAmount = purchases.fold(0.0, (sum, p) => sum + p.paidAmount);
    final double totalCreditAmount = purchases.fold(0.0, (sum, p) => sum + p.creditBalanceAdded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Metrics Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL STOCK VALUE INWARD',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  Text(
                    '${purchases.length} Inward Bills',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'PKR ${totalPurchasedAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cash / Bank Paid', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          'PKR ${totalPaidAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Added to Khata Due', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          'PKR ${totalCreditAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'INWARD BILLS & PRODUCTS LIST',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5),
            ),
            Text(
              'Tap bill for item details',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List of purchases
        ...purchases.map((inv) => _buildPurchaseInvoiceCard(inv)),
      ],
    );
  }

  Widget _buildPurchaseInvoiceCard(PurchaseInvoiceModel inv) {
    final dateStr = '${inv.date.day} ${_monthName(inv.date.month)} ${inv.date.year}';
    final hour = inv.date.hour % 12 == 0 ? 12 : inv.date.hour % 12;
    final timeStr = '${hour.toString().padLeft(2, '0')}:${inv.date.minute.toString().padLeft(2, '0')} ${inv.date.hour >= 12 ? 'PM' : 'AM'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPurchaseInvoiceDetailSheet(inv),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Invoice No, Date & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Text(
                          inv.invoiceNo,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$dateStr • $timeStr',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: inv.creditBalanceAdded > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.creditBalanceAdded > 0 ? 'Due: PKR ${inv.creditBalanceAdded.toStringAsFixed(0)}' : 'Fully Paid',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: inv.creditBalanceAdded > 0 ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Products summary list
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...inv.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• ${item.productName} (x${item.quantity.toInt()} ${item.unit})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '@ PKR ${item.costPrice.toStringAsFixed(0)} = PKR ${item.subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    )),
                    if (inv.items.length > 3) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+ ${inv.items.length - 3} more product items... Tap to view all',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Financial Summary Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'Bill: PKR ${inv.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• Paid: PKR ${inv.paidAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseInvoiceDetailSheet(PurchaseInvoiceModel invoice) {
    final dateStr = '${invoice.date.day} ${_monthName(invoice.date.month)} ${invoice.date.year}';
    final hour = invoice.date.hour % 12 == 0 ? 12 : invoice.date.hour % 12;
    final timeStr = '${hour.toString().padLeft(2, '0')}:${invoice.date.minute.toString().padLeft(2, '0')} ${invoice.date.hour >= 12 ? 'PM' : 'AM'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: Color(0xFFEA580C), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            invoice.invoiceNo,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateStr at $timeStr',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Supplier Info Badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Supplier Name', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text(
                                invoice.supplierName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Text(
                              '${invoice.items.length} Product Types',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Itemized Table Header
                    const Text(
                      'PURCHASED PRODUCTS & QUANTITIES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 5, child: Text('Product Item', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                Expanded(flex: 3, child: Text('Rate (PKR)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                Expanded(flex: 3, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              ],
                            ),
                          ),
                          // Items rows
                          ...invoice.items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final isEven = idx % 2 == 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              color: isEven ? Colors.white : const Color(0xFFFAFAFA),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          'Unit: ${item.unit}',
                                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${item.quantity.toInt()} ${item.unit}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.costPrice.toStringAsFixed(0),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.subtotal.toStringAsFixed(0),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Financial Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Bill Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              Text(
                                'PKR ${invoice.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cash / Bank Paid Now', style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                              Text(
                                'PKR ${invoice.paidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Added to Supplier Khata (Credit)', style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                              Text(
                                'PKR ${invoice.creditBalanceAdded.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                          if (invoice.note.isNotEmpty) ...[
                            const Divider(height: 14, color: Color(0xFFE2E8F0)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Note: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                Expanded(
                                  child: Text(invoice.note, style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155))),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Bottom Actions: Share via WhatsApp & Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Image.asset(AppAssets.whatsappIcon, width: 20, height: 20),
                      label: const Text('Share WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        final party = _currentParty;
                        PrintingAndSharingService.instance.sharePurchaseInvoiceViaWhatsApp(
                          invoice: invoice,
                          shop: ShopState.instance.activeShop,
                          phone: party?.phone,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
}
