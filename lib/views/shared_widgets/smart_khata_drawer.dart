import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/app_toast.dart';
import '../../models/party_model.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/google_drive_service.dart';
import '../../services/notification_service.dart';
import '../../services/security_service.dart';
import '../../state/cart_state.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';
import '../../state/shop_state.dart';
import '../khata/widgets/add_party_sheet.dart';

class SmartKhataDrawer extends StatefulWidget {
  final String currentRoute;

  const SmartKhataDrawer({
    super.key,
    this.currentRoute = AppRoutes.dashboard,
  });

  @override
  State<SmartKhataDrawer> createState() => _SmartKhataDrawerState();
}

class _SmartKhataDrawerState extends State<SmartKhataDrawer> {
  final _shopState = ShopState.instance;
  final _khataState = KhataState.instance;
  final _inventoryState = InventoryState.instance;
  final _securityService = SecurityService.instance;
  final _driveService = GoogleDriveService.instance;
  final _notificationService = NotificationService.instance;
  final _authService = AuthService.instance;
  final _cloudSyncService = CloudSyncService.instance;

  @override
  void initState() {
    super.initState();
    _shopState.addListener(_rebuild);
    _khataState.addListener(_rebuild);
    _inventoryState.addListener(_rebuild);
    _securityService.addListener(_rebuild);
    _driveService.addListener(_rebuild);
    _notificationService.addListener(_rebuild);
    _authService.addListener(_rebuild);
    _cloudSyncService.addListener(_rebuild);
  }

  @override
  void dispose() {
    _shopState.removeListener(_rebuild);
    _khataState.removeListener(_rebuild);
    _inventoryState.removeListener(_rebuild);
    _securityService.removeListener(_rebuild);
    _driveService.removeListener(_rebuild);
    _notificationService.removeListener(_rebuild);
    _authService.removeListener(_rebuild);
    _cloudSyncService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _showShopSwitcherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.75;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: Color(0xFF0F172A), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Switch Active Shop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Each shop maintains its own independent stock, credit ledger, and sales records.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _shopState.shops.map((shop) {
                    final isActive = shop.id == _shopState.activeShopId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              shop.name.isNotEmpty ? shop.name[0].toUpperCase() : 'S',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          shop.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          '${shop.ownerName} • ${shop.address.isNotEmpty ? shop.address : "Main Store"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        trailing: isActive
                            ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 22)
                            : const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                        onTap: () {
                          _shopState.switchShop(shop.id);
                          Navigator.pop(ctx);
                          AppToast.showSuccess(context, 'Switched to active shop: "${shop.name}"');
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  label: const Text('+ Add New Shop (Settings)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    foregroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeShop = _shopState.activeShop;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Header: Active Store Profile & Shop Switcher ───────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: App Logo, Name & Close
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        AppAssets.appLogo,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeShop.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeShop.ownerName.isNotEmpty
                                ? activeShop.ownerName
                                : 'Store Manager',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Multi-Shop Switcher Pill
                InkWell(
                  onTap: _showShopSwitcherModal,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 15, color: Color(0xFF60A5FA)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Shop: ${activeShop.name} (${_shopState.shops.length} total)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Stat Cards: Today's Sale & Total Receivable
                Row(
                  children: [
                    // Today's Sale
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TODAY'S SALE",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'PKR ${_khataState.todaySales.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Receivable
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RECEIVABLE (TO GET)',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'PKR ${_khataState.totalReceivable.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFFF87171),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
          ),

          // ── Quick Action Shortcuts Row ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      AddPartySheet.show(context, initialType: PartyType.customer);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1, size: 14, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text(
                            '+ Naya Khata',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.posScanner);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Scan Barcode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Menu Items ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // SECTION 1: CORE APPS & SALES
                _buildSectionHeader("CORE APPS"),
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: AppRoutes.dashboard,
                  isSelected: widget.currentRoute == AppRoutes.dashboard,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'POS Billing & Checkout',
                  route: AppRoutes.posCart,
                  isSelected: widget.currentRoute == AppRoutes.posCart,
                  badgeText: CartState.instance.totalItemCount > 0
                      ? '${CartState.instance.totalItemCount} in Cart'
                      : 'Quick Bill',
                  badgeColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: 'Live Barcode Scanner',
                  route: AppRoutes.posScanner,
                  isSelected: widget.currentRoute == AppRoutes.posScanner,
                  badgeText: 'Camera Gun',
                  badgeColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.menu_book_outlined,
                  title: 'Khata Book (Directory)',
                  route: AppRoutes.khataDirectory,
                  isSelected: widget.currentRoute == AppRoutes.khataDirectory,
                  badgeText: _khataState.customers.where((c) => c.balance > 0).isNotEmpty
                      ? '${_khataState.customers.where((c) => c.balance > 0).length} Pending'
                      : null,
                  badgeColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory & Products',
                  route: AppRoutes.inventoryList,
                  isSelected: widget.currentRoute == AppRoutes.inventoryList,
                  badgeText: _inventoryState.lowStockCount > 0
                      ? '${_inventoryState.lowStockCount} Low'
                      : null,
                  badgeColor: const Color(0xFFFEE2E2),
                  badgeTextColor: const Color(0xFFDC2626),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.input_rounded,
                  title: 'Stock Inward (Purchases)',
                  subtitle: 'Receive stock from vendors',
                  route: AppRoutes.purchaseInward,
                  isSelected: widget.currentRoute == AppRoutes.purchaseInward,
                  badgeText: 'Inward',
                  badgeColor: const Color(0xFFFFF7ED),
                  badgeTextColor: const Color(0xFFEA580C),
                ),

                const SizedBox(height: 10),

                // SECTION 2: REPORTS & ANALYTICS
                _buildSectionHeader('REPORTS & FINANCES'),
                _buildMenuItem(
                  context,
                  icon: Icons.insights_rounded,
                  title: 'Reports & Analytics',
                  subtitle: 'Daily, Weekly, Monthly Profit & Loss',
                  route: AppRoutes.reports,
                  isSelected: widget.currentRoute == AppRoutes.reports,
                  badgeText: 'P&L Graphs',
                  badgeColor: const Color(0xFFEFF6FF),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.print_outlined,
                  title: 'Receipt & Thermal Printer',
                  route: AppRoutes.receiptPreview,
                  isSelected: widget.currentRoute == AppRoutes.receiptPreview,
                  badgeText: '58/80mm',
                ),

                const SizedBox(height: 10),

                // SECTION 3: SYSTEM, MULTI-STORE & SECURITY
                _buildSectionHeader('MANAGEMENT & SECURITY'),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications & Alerts',
                  subtitle: _notificationService.unreadCount > 0
                      ? '${_notificationService.unreadCount} unread store alerts'
                      : 'Stock, credit & system alerts',
                  route: AppRoutes.notifications,
                  isSelected: widget.currentRoute == AppRoutes.notifications,
                  badgeText: _notificationService.unreadCount > 0
                      ? '${_notificationService.unreadCount} New'
                      : null,
                  badgeColor: const Color(0xFFFEE2E2),
                  badgeTextColor: const Color(0xFFDC2626),
                  showArrow: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings & Multi-Store',
                  subtitle: 'Switch shops, printer & cloud accounts',
                  route: AppRoutes.settings,
                  isSelected: widget.currentRoute == AppRoutes.settings,
                  showArrow: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.cloud_sync_rounded,
                  title: 'Firebase Cloud Sync',
                  subtitle: _authService.isSignedIn
                      ? 'Live sync: ${_authService.userEmail ?? "Cloud User"}'
                      : 'Sign in to sync database across devices',
                  route: AppRoutes.settings,
                  badgeText: _authService.isSignedIn ? 'Live Sync' : 'Offline/Guest',
                  badgeColor: _authService.isSignedIn
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  badgeTextColor: _authService.isSignedIn
                      ? const Color(0xFF15803D)
                      : const Color(0xFF64748B),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.add_to_drive_rounded,
                  title: 'Google Drive Backup',
                  subtitle: _driveService.lastBackupTime != null
                      ? 'Backup: ${_driveService.lastBackupTime!.hour}:${_driveService.lastBackupTime!.minute.toString().padLeft(2, '0')}'
                      : 'Personal Google Drive storage',
                  route: AppRoutes.settings,
                  badgeText: _driveService.isConnected ? 'Connected' : '15 GB Free',
                  badgeColor: _driveService.isConnected
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  badgeTextColor: _driveService.isConnected
                      ? const Color(0xFF15803D)
                      : const Color(0xFF2563EB),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.security_rounded,
                  title: 'App Lock & Biometrics',
                  subtitle: _securityService.isLockEnabled
                      ? 'Biometric & PIN Enabled'
                      : 'Protection is currently OFF',
                  route: AppRoutes.settings,
                  badgeText: _securityService.isLockEnabled ? 'Active' : 'Disabled',
                  badgeColor: _securityService.isLockEnabled
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  badgeTextColor: _securityService.isLockEnabled
                      ? const Color(0xFF15803D)
                      : const Color(0xFFDC2626),
                ),

              ],
            ),
          ),

          // ── Bottom Section: Lock & Local Storage Status ────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: const Border(
                top: BorderSide(
                  color: Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Lock Terminal Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          if (_securityService.isLockEnabled) {
                            _securityService.lockApp();
                            nav.pushNamed(AppRoutes.appLock);
                          } else {
                            AppToast.showWarning(
                              context,
                              'App Lock is disabled. You can set a 4-digit PIN in Settings.',
                            );
                            nav.pushNamed(AppRoutes.settings);
                          }
                        },
                        icon: const Icon(Icons.lock_outline, size: 16, color: Colors.white),
                        label: Text(
                          _securityService.isLockEnabled
                              ? 'Lock Terminal'
                              : 'Enable App Lock',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Logout Exit Button
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Color(0xFFE11D48), size: 18),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
                                  SizedBox(width: 8),
                                  Text('Log Out?', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              content: const Text(
                                'Are you sure you want to log out? Local data will remain safely saved on your device.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE11D48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Log Out', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await AuthService.instance.signOut();
                              if (context.mounted) {
                                AppToast.showInfo(context, 'Logged out successfully');
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.auth,
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.showError(
                                  context,
                                  'Logout encountered an error. Please try again.',
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Offline Local Database Auto-Save Status
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 11, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'Local Database: Auto-Saved & Offline Ready',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? route,
    bool isSelected = false,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    bool showArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? const Color(0xFFEEF2FF)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context); // Close drawer
            if (route != null && route != widget.currentRoute) {
              if (route == AppRoutes.dashboard) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.dashboard,
                  (r) => false,
                );
              } else if (widget.currentRoute == AppRoutes.dashboard) {
                Navigator.pushNamed(context, route);
              } else {
                Navigator.pushReplacementNamed(context, route);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
            child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected
                  ? const Color(0xFF3730A3)
                  : const Color(0xFF475569),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1E1B4B)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF3730A3),
                  shape: BoxShape.circle,
                ),
              )
            else if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor ?? const Color(0xFF475569),
                  ),
                ),
              )
            else if (showArrow)
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    ),
  ),
);
}
}
