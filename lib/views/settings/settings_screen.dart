import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/security_service.dart';
import '../../services/google_drive_service.dart';
import '../../state/shop_state.dart';
import '../security/app_lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    ShopState.instance.addListener(_refresh);
    SecurityService.instance.addListener(_refresh);
    GoogleDriveService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ShopState.instance.removeListener(_refresh);
    SecurityService.instance.removeListener(_refresh);
    GoogleDriveService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // Add New Shop Modal
  void _showAddShopModal() {
    final nameCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

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
                  const Text(
                    'Add New Shop / Branch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Each shop keeps its inventory, customers, and ledger 100% separate.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Shop / Branch Name',
                  hintText: 'Enter shop name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerCtrl,
                decoration: InputDecoration(
                  labelText: 'Owner / Manager Name',
                  hintText: 'Enter manager name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone / WhatsApp',
                  hintText: '03001234567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address / Location',
                  hintText: 'Enter shop address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_business_rounded, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter shop name')),
                      );
                      return;
                    }
                    ShopState.instance.addShop(
                      name: name,
                      ownerName: ownerCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to new shop: $name'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  label: const Text(
                    'Create & Switch to Shop',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Edit Active Shop Modal
  void _showEditShopModal() {
    final active = ShopState.instance.activeShop;
    final nameCtrl = TextEditingController(text: active.name);
    final ownerCtrl = TextEditingController(text: active.ownerName);
    final phoneCtrl = TextEditingController(text: active.phone);
    final addressCtrl = TextEditingController(text: active.address);

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
                  const Text(
                    'Edit Active Shop Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerCtrl,
                decoration: InputDecoration(
                  labelText: 'Owner Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ShopState.instance.updateActiveShop(
                      name: nameCtrl.text,
                      ownerName: ownerCtrl.text,
                      phone: phoneCtrl.text,
                      address: addressCtrl.text,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Details', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _promptVerifyCurrentPin() async {
    final sec = SecurityService.instance;
    if (!sec.isLockEnabled || !sec.hasPinSet) return true;

    final pinCtrl = TextEditingController();
    String? err;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Verify Current PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your current 4-digit PIN to proceed.'),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  counterText: '',
                  errorText: err,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final entered = pinCtrl.text.trim();
                if (sec.verifyPin(entered)) {
                  Navigator.pop(ctx, true);
                } else {
                  setDState(() => err = 'Incorrect PIN. Try again.');
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    return verified ?? false;
  }

  // Setup / Change PIN Modal (Real PIN and Security Answer)
  void _showSetPinDialog() {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final questionCtrl = TextEditingController(text: SecurityService.instance.securityQuestion);
    final answerCtrl = TextEditingController();
    String? err;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Setup App Lock Security PIN'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter 4-Digit PIN',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm 4-Digit PIN',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: questionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Security Question',
                      hintText: 'e.g. What is your favorite city?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerCtrl,
                    decoration: InputDecoration(
                      labelText: 'Recovery Answer',
                      hintText: 'Enter your answer',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                ),
                onPressed: () {
                  final p1 = pinCtrl.text.trim();
                  final p2 = confirmCtrl.text.trim();
                  final ans = answerCtrl.text.trim();
                  final q = questionCtrl.text.trim();

                  if (p1.length != 4) {
                    setDState(() => err = 'PIN must be exactly 4 digits');
                    return;
                  }
                  if (p1 != p2) {
                    setDState(() => err = 'PINs do not match');
                    return;
                  }
                  if (ans.isEmpty) {
                    setDState(() => err = 'Please enter a recovery answer');
                    return;
                  }

                  final success = SecurityService.instance.setLockEnabled(
                    true,
                    pin: p1,
                    question: q.isNotEmpty ? q : null,
                    answer: ans,
                  );
                  if (!success) {
                    setDState(() => err = 'Invalid PIN format. Must be 4 digits.');
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App Lock PIN configured successfully!'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                },
                child: const Text('Save & Enable', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleGoogleDriveConnect() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_to_drive, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Connect Google Drive', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google account email to link your personal 15 GB Google Drive for automated ledger backup:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Google Email',
                hintText: 'e.g. store.owner@gmail.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.pop(ctx);
                final ok = await GoogleDriveService.instance.connectAccount(email: email);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Google Drive linked successfully with $email!'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid Google email address')),
                );
              }
            },
            child: const Text('Link Drive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeShop = ShopState.instance.activeShop;
    final allShops = ShopState.instance.shops;
    final sec = SecurityService.instance;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Settings & Multi-Store',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. MULTI-SHOP MANAGEMENT SECTION
            _buildSectionCard(
              title: 'Multi-Store & Branches',
              icon: Icons.store_rounded,
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Shop', style: TextStyle(fontSize: 12)),
                onPressed: _showAddShopModal,
              ),
              child: Column(
                children: [
                  // Active Shop Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storefront, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    activeShop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${activeShop.ownerName} • ${activeShop.phone.isNotEmpty ? activeShop.phone : "No phone"}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                          onPressed: _showEditShopModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // All registered shops list
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Switch Active Store:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...allShops.map((s) {
                    final isCurrent = s.id == activeShop.id;
                    return InkWell(
                      onTap: () => ShopState.instance.switchShop(s.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFF1F5F9) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.name,
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Text(
                              s.address.isNotEmpty ? s.address : 'Primary',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. SECURITY & APP LOCK SECTION (By default OFF as requested)
            _buildSectionCard(
              title: 'Security & App Lock',
              icon: Icons.security_rounded,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'App Lock Security',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      sec.isLockEnabled
                          ? 'Enabled • Requires 4-Digit PIN to access terminal'
                          : 'Disabled (Default) • No lock required',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: sec.isLockEnabled ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      ),
                    ),
                    value: sec.isLockEnabled,
                    activeTrackColor: const Color(0xFF2563EB),
                    onChanged: (val) async {
                      if (val) {
                        _showSetPinDialog();
                      } else {
                        final ok = await _promptVerifyCurrentPin();
                        if (ok) {
                          sec.setLockEnabled(false, pin: '');
                        } else {
                          setState(() {});
                        }
                      }
                    },
                  ),
                  if (sec.isLockEnabled) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Biometric Unlock (Fingerprint / Face)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Quick unlock without typing PIN',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      value: sec.isBiometricEnabled,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (v) async {
                        final ok = await sec.setBiometricEnabled(v);
                        if (v && !ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No biometric hardware or enrolled fingerprints found on this device.'),
                              backgroundColor: Color(0xFFE11D48),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF2563EB)),
                      title: const Text('Change Security PIN', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        final ok = await _promptVerifyCurrentPin();
                        if (ok) {
                          _showSetPinDialog();
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_clock, size: 20, color: Color(0xFFE11D48)),
                      title: const Text('Lock App Now (Test)', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        sec.lockApp();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppLockScreen(isVerificationOnly: true),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. PRINTER & THERMAL RECEIPT SECTION
            _buildSectionCard(
              title: 'Thermal Printer & Receipt',
              icon: Icons.print_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paper Size:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('58mm (Pocket)'),
                            selected: activeShop.paperSize == '58mm',
                            onSelected: (_) => ShopState.instance.updateActiveShop(paperSize: '58mm'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('80mm (Standard)'),
                            selected: activeShop.paperSize == '80mm',
                            onSelected: (_) => ShopState.instance.updateActiveShop(paperSize: '80mm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Receipt Footer Note:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: ValueKey('receipt_footer_${activeShop.id}'),
                    initialValue: activeShop.receiptFooter,
                    onChanged: (v) => ShopState.instance.updateActiveShop(receiptFooter: v),
                    decoration: InputDecoration(
                      hintText: 'Enter bill footer text',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. REAL GOOGLE DRIVE BACKUP & RESTORE SECTION
            _buildSectionCard(
              title: 'Google Drive Cloud Backup',
              icon: Icons.cloud_done_outlined,
              trailing: GoogleDriveService.instance.isConnected
                  ? TextButton(
                      onPressed: () async {
                        await GoogleDriveService.instance.disconnectAccount();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google Drive account disconnected')),
                          );
                        }
                      },
                      child: const Text('Disconnect', style: TextStyle(color: Color(0xFFE11D48), fontSize: 11.5)),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GoogleDriveService.instance.isConnected
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              GoogleDriveService.instance.isConnected ? Icons.check_circle : Icons.cloud_off,
                              size: 14,
                              color: GoogleDriveService.instance.isConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              GoogleDriveService.instance.isConnected ? 'Drive Connected' : 'Drive Not Linked',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: GoogleDriveService.instance.isConnected ? const Color(0xFF15803D) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text('15 GB Free Cloud', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (GoogleDriveService.instance.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF2563EB),
                                child: Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      GoogleDriveService.instance.userName ?? 'Google User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                    Text(
                                      GoogleDriveService.instance.userEmail ?? '',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Last Cloud Backup:', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 2),
                                  Text(
                                    GoogleDriveService.instance.formattedLastBackup,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                              if (GoogleDriveService.instance.lastBackupSizeBytes > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    GoogleDriveService.instance.formattedBackupSize,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Backup to Drive', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Sync transactions to Drive automatically', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: GoogleDriveService.instance.isAutoBackupEnabled,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (v) => GoogleDriveService.instance.toggleAutoBackup(v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: GoogleDriveService.instance.isSyncing
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                            label: Text(
                              GoogleDriveService.instance.isSyncing ? 'Uploading...' : 'Backup Now',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: GoogleDriveService.instance.isSyncing
                                ? null
                                : () async {
                                    final res = await GoogleDriveService.instance.backupToDrive();
                                    if (context.mounted) {
                                      if (res['success'] == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Backup uploaded to Google Drive successfully (${res['size']})!'),
                                            backgroundColor: const Color(0xFF16A34A),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Backup failed: ${res['error']}'),
                                            backgroundColor: const Color(0xFFE11D48),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cloud_download_outlined, size: 16),
                            label: const Text('Restore Backup', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: GoogleDriveService.instance.isSyncing
                                ? null
                                : () async {
                                    final res = await GoogleDriveService.instance.restoreFromDrive();
                                    if (context.mounted) {
                                      if (res['success'] == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Latest backup restored from Google Drive!'),
                                            backgroundColor: Color(0xFF16A34A),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Restore note: ${res['error'] ?? "Data is already fresh"}')),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Connect your personal Google account to store your entire khata database and invoices in your personal 15 GB Google Drive for free.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 16, color: Colors.white),
                        label: const Text('Connect Google Account (15 GB Free)', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _handleGoogleDriveConnect,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
