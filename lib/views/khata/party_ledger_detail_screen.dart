import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../models/ledger_entry_model.dart';
import '../../models/party_model.dart';
import '../../state/khata_state.dart';
import 'widgets/add_transaction_modal.dart';

class LedgerDetailItem {
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

  late String _partyName;
  late String _partyPhone;
  late String _partyAddress;
  late String _partyId;
  late double _balance;

  PartyModel? get _currentParty {
    try {
      return _khataState.parties.firstWhere((p) => p.id == _partyId);
    } catch (_) {
      return widget.party;
    }
  }

  double get _currentBalance => _currentParty?.balance ?? _balance;

  static String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }

  List<LedgerDetailItem> get _partyTransactions {
    final entries = _khataState.getEntriesForParty(_partyId);
    if (entries.isEmpty) {
      return [];
    }
    return entries.map((e) {
      final isDebit = e.type == LedgerType.gave;
      final dateStr = '${e.date.day} ${_monthName(e.date.month)} ${e.date.year}';
      final hour = e.date.hour % 12 == 0 ? 12 : e.date.hour % 12;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')} ${e.date.hour >= 12 ? 'PM' : 'AM'}';
      final tagStr = e.note.startsWith('Bill #')
          ? e.note.replaceAll('Bill ', '')
          : '#TXN-${e.id.length > 4 ? e.id.substring(e.id.length - 4) : e.id}';

      return LedgerDetailItem(
        date: dateStr,
        tag: tagStr,
        tagColor: isDebit ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
        tagTextColor: isDebit ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
        title: e.note,
        time: timeStr,
        balanceAfter: 'PKR ${_currentBalance.toStringAsFixed(0)}',
        debit: isDebit ? e.amount : null,
        debitLabel: isDebit ? 'Udhaar' : null,
        credit: !isDebit ? e.amount : null,
        creditLabel: !isDebit ? 'Cash Wasool' : null,
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

  @override
  void initState() {
    super.initState();
    final p = widget.party;
    _partyName = p?.name ?? 'Account';
    _partyPhone = p?.phone ?? '';
    _partyAddress = p?.address.isNotEmpty == true ? p!.address : '';
    _partyId = p?.id ?? '';
    _balance = p?.balance ?? 0.0;

    _khataState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _khataState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _openAddModal(LedgerType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionModal(
        partyId: _partyId,
        partyName: _partyName,
        initialType: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Ledger',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1),
            Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF22C55E), size: 6),
                SizedBox(width: 4),
                Text(
                  'ID: CUST-0492 • Khata Book',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search, size: 18, color: Colors.white),
              onPressed: () {},
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Customer Profile Card
                  _buildCustomerProfileCard(),

                  const SizedBox(height: 10),

                  // 2. Net Outstanding Balance Card
                  _buildNetBalanceCard(),

                  const SizedBox(height: 10),

                  // 3. Quick Action Buttons Row: WhatsApp, Direct Call, Statement
                  _buildActionButtonsRow(),

                  const SizedBox(height: 10),

                  // 4. Debit & Credit Totals Row
                  _buildTotalsRow(),

                  const SizedBox(height: 14),

                  // 5. Transaction Statement Header
                  _buildTransactionStatementHeader(),

                  const SizedBox(height: 8),

                  // 6. Subheader Table Column Names
                  _buildTableColumnHeader(),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // 7. Transaction Feed Entries
                  if (_partyTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
                      child: Center(
                        child: Text(
                          'No transactions recorded yet for this account.\nUse the buttons below to record "Maine Diye" or "Maine Liye".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    ..._partyTransactions.map((tx) => _buildTransactionRow(tx)),
                    const SizedBox(height: 10),
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
    );
  }

  // 1. Customer Profile Card
  Widget _buildCustomerProfileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Initials Avatar
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'TM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _partyName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _partyAddress,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 11, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      _partyPhone,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Icon
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // 2. Net Outstanding Balance Card
  Widget _buildNetBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Row(
                children: [
                  const Text(
                    'NET OUTSTANDING BALANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Receivable',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'PKR ${_currentBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF064E3B),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.access_time, size: 11, color: Color(0xFF15803D)),
              SizedBox(width: 4),
              Text(
                'Last activity: Yesterday 06:45 PM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Quick Action Buttons Row: WhatsApp, Direct Call, Statement
  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // WhatsApp
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp Ledger PDF slip...')),
              );
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
                  const Text(
                    'Send Bill',
                    style: TextStyle(fontSize: 9, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Direct Call
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $_partyPhone...')),
              );
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
                  Icon(Icons.phone_outlined, size: 20, color: Color(0xFF2563EB)),
                  SizedBox(height: 4),
                  Text(
                    'Direct Call',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                  ),
                  Text(
                    'Dial Number',
                    style: TextStyle(fontSize: 9, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Statement
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting PDF Ledger Statement...')),
              );
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
                  Icon(Icons.description_outlined, size: 20, color: Color(0xFF475569)),
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
                      'TOTAL GIVEN (DEBIT)',
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Total Received
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
                      'TOTAL RECEIVED',
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
                    fontSize: 14.5,
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

  // 5. Transaction Statement Header
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
        Row(
          children: [
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
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.filter_list, size: 11, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text(
                    'All Dates',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            'DATE & DETAILS',
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Date, Tag, Description, Time & Balance
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tx.tagColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.tag,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: tx.tagTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tx.title,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.time}   Bal: ${tx.balanceAfter}',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
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
    );
  }

  // 8. Weekly Payment Reminder Banner
  Widget _buildReminderBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFF166534),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, size: 16, color: Color(0xFF86EFAC)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Payment Reminder',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Auto-send friendly Urdu/English WhatsApp reminder every Friday.',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
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
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
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
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_circle, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        '+ Gave Credit',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '(You Gave / Udhaar)',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFFECACA),
                    ),
                  ),
                ],
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
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        '+ Got Payment',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '(You Received / Wasool)',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFBBF7D0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
