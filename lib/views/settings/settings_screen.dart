import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../core/utils/app_toast.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/esc_pos_service.dart';
import '../../services/security_service.dart';
import '../../services/google_drive_service.dart';
import '../../state/shop_state.dart';

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
    AuthService.instance.addListener(_refresh);
    CloudSyncService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ShopState.instance.removeListener(_refresh);
    SecurityService.instance.removeListener(_refresh);
    GoogleDriveService.instance.removeListener(_refresh);
    AuthService.instance.removeListener(_refresh);
    CloudSyncService.instance.removeListener(_refresh);
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
                      AppToast.showWarning(context, 'Please enter shop name');
                      return;
                    }
                    ShopState.instance.addShop(
                      name: name,
                      ownerName: ownerCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    AppToast.showSuccess(context, 'Switched to new shop: $name');
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
                  AppToast.showSuccess(context, 'App Lock PIN configured successfully!');
                },
                child: const Text('Save & Enable', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPrinterPickerModal() async {
    bool dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Scanning for printers...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      dialogOpen = false;
    });

    List<Printer> printers = [];
    try {
      printers = await EscPosService.instance.getAvailablePrinters();
    } catch (e) {
      debugPrint('Printer discovery failed: $e');
      if (mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      if (mounted) {
        AppToast.showError(context, 'Failed to scan for printers. Please verify Bluetooth is enabled.');
      }
      return;
    }

    if (mounted && dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      dialogOpen = false;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Bluetooth / ESC-POS Printer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Paired Bluetooth and USB receipt printers detected on your device:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              if (printers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bluetooth_searching, color: Color(0xFF64748B)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No printers detected. Pair your Bluetooth thermal printer in device Android Settings > Bluetooth, then reopen this list.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: printers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = printers[index];
                      final isSelected = ShopState.instance.activeShop.preferredPrinterUrl == p.url;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.print,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(p.url, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2563EB)) : null,
                        onTap: () {
                          ShopState.instance.updateActiveShop(
                            preferredPrinterName: p.name,
                            preferredPrinterUrl: p.url,
                          );
                          Navigator.pop(ctx);
                          AppToast.showSuccess(context, 'Selected printer: ${p.name}');
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleDriveConnect() async {
    final ok = await GoogleDriveService.instance.connectAccount();
    if (mounted) {
      if (ok) {
        AppToast.showSuccess(context, 'Google Drive linked: ${GoogleDriveService.instance.userEmail}!');
      } else {
        AppToast.showWarning(context, 'Could not link Google Drive or sign-in cancelled.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeShop = ShopState.instance.activeShop;
    final allShops = ShopState.instance.shops;
    final sec = SecurityService.instance;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
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
                          AppToast.showWarning(context, 'No biometric hardware or enrolled fingerprints found on this device.');
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
                        Navigator.pushNamed(
                          context,
                          AppRoutes.appLock,
                          arguments: {'isVerificationOnly': false},
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Thermal Printer & Receipt (ESC/POS)',
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

                  // Paired Bluetooth Printer Selector
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
                            const Icon(Icons.bluetooth, color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Paired Bluetooth Printer',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const Spacer(),
                            if (activeShop.preferredPrinterName != null)
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  ShopState.instance.updateActiveShop(clearPrinter: true);
                                },
                                child: const Text('Disconnect', style: TextStyle(fontSize: 11, color: Color(0xFFE11D48))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activeShop.preferredPrinterName ?? 'No printer selected (Will use default/prompt)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: activeShop.preferredPrinterName != null ? FontWeight.bold : FontWeight.normal,
                            color: activeShop.preferredPrinterName != null ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.bluetooth_searching, size: 16),
                                label: const Text('Select Printer', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _showPrinterPickerModal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                                label: const Text('Test Slip', style: TextStyle(fontSize: 12, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final ok = await EscPosService.instance.printTestSlip(shop: activeShop);
                                  if (context.mounted && ok) {
                                    AppToast.showSuccess(context, 'Test receipt slip sent to printer!');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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


            _buildSectionCard(
              title: 'Firebase Cloud Sync & Account',
              icon: Icons.cloud_sync_rounded,
              trailing: AuthService.instance.isSignedIn
                  ? TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Sign Out from Cloud?'),
                            content: const Text(
                              'Signing out will stop cloud sync. Your local database and store records will remain safe on this phone.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await AuthService.instance.signOut();
                          if (context.mounted) {
                            AppToast.showInfo(context, 'Signed out from Firebase Cloud account');
                          }
                        }
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Color(0xFFE11D48), fontSize: 11.5)),
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
                          color: AuthService.instance.isSignedIn
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AuthService.instance.isSignedIn ? Icons.check_circle : Icons.cloud_off,
                              size: 14,
                              color: AuthService.instance.isSignedIn ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AuthService.instance.isSignedIn ? 'Cloud Synced (Firebase)' : 'Offline / Guest Mode',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AuthService.instance.isSignedIn ? const Color(0xFF15803D) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text('Cloud Firestore', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (AuthService.instance.isSignedIn) ...[
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
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF16A34A),
                                child: Text(
                                  (AuthService.instance.userDisplayName?.isNotEmpty == true
                                          ? AuthService.instance.userDisplayName![0]
                                          : 'U')
                                      .toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AuthService.instance.userDisplayName ?? 'Cloud User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                    Text(
                                      AuthService.instance.userEmail ?? '',
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
                              const Text('Last Cloud Sync:', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              Text(
                                CloudSyncService.instance.formattedLastSync,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Sync Changes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Real-time sync to Firestore on new transactions', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: CloudSyncService.instance.autoSyncEnabled,
                      activeTrackColor: const Color(0xFF16A34A),
                      onChanged: (v) => CloudSyncService.instance.setAutoSync(v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: CloudSyncService.instance.isSyncing
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                            label: Text(
                              CloudSyncService.instance.isSyncing ? 'Syncing...' : 'Sync to Cloud',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: CloudSyncService.instance.isSyncing
                                ? null
                                : () async {
                                    final res = await CloudSyncService.instance.uploadToCloud();
                                    if (context.mounted) {
                                      if (res['success'] == true) {
                                        AppToast.showSuccess(
                                          context,
                                          'Data synced to Cloud Firestore (${res['size']})!',
                                        );
                                      } else {
                                        AppToast.showError(
                                          context,
                                          'Sync failed: ${res['error']}',
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
                            label: const Text('Restore Cloud', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: CloudSyncService.instance.isSyncing
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Restore from Cloud?'),
                                        content: const Text(
                                          'Restoring will replace current local database with your latest cloud snapshot.',
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Restore', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      final res = await CloudSyncService.instance.restoreFromCloud();
                                      if (context.mounted) {
                                        if (res['success'] == true) {
                                          AppToast.showSuccess(
                                            context,
                                            'Database restored successfully from Cloud Firestore!',
                                          );
                                        } else {
                                          AppToast.showError(
                                            context,
                                            'Restore note: ${res['error']}',
                                          );
                                        }
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Sign in with your Google Account or Email to securely backup your khata, inventory, and ledger to Cloud Firestore across devices.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 16, color: Colors.white),
                        label: const Text('Sign In or Register (Cloud Backup)', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.auth);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Google Drive Cloud Backup',
              icon: Icons.cloud_done_outlined,
              trailing: GoogleDriveService.instance.isConnected
                  ? TextButton(
                      onPressed: () async {
                        await GoogleDriveService.instance.disconnectAccount();
                        if (context.mounted) {
                          AppToast.showInfo(context, 'Google Drive account disconnected');
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
                                        AppToast.showSuccess(
                                          context,
                                          'Backup uploaded to Google Drive successfully (${res['size']})!',
                                        );
                                      } else {
                                        AppToast.showError(
                                          context,
                                          'Backup failed: ${res['error']}',
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
                                        AppToast.showSuccess(
                                          context,
                                          'Latest backup restored from Google Drive!',
                                        );
                                      } else {
                                        AppToast.showInfo(
                                          context,
                                          'Restore note: ${res['error'] ?? "Data is already fresh"}',
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
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
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
