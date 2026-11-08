import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../routes/app_routes.dart';
import '../../state/inventory_state.dart';
import '../../state/khata_state.dart';

class SmartKhataDrawer extends StatelessWidget {
  final String currentRoute;

  const SmartKhataDrawer({
    super.key,
    this.currentRoute = AppRoutes.dashboard,
  });

  @override
  Widget build(BuildContext context) {
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
          // Dark Navy Header with Real App Logo & Store Status
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 18),
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
                // Top Row: App Logo, Name, Terminal & Close Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            AppAssets.appLogo,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF0F172A), width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SmartKhata Store',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'POS Operator ',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFF94A3B8), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stat Cards: Today's Sale & Udhaar
                Row(
                  children: [
                    // Today's Sale
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
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
                              'PKR ${KhataState.instance.todaySales.toStringAsFixed(0)}',
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
                    // Udhaar
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UDHAAR',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'PKR ${KhataState.instance.totalReceivable.toStringAsFixed(0)}',
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

          // 2. Navigation Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                // SECTION 1: CORE
                _buildSectionHeader('CORE APPS', 'بنیادی فیچرز'),
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: AppRoutes.dashboard,
                  isSelected: currentRoute == AppRoutes.dashboard,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'POS Billing',
                  route: AppRoutes.posCart,
                  isSelected: currentRoute == AppRoutes.posCart,
                  badgeText: 'Quick Bill',
                  badgeColor: const Color(0xFFDBEAFE),
                  badgeTextColor: const Color(0xFF1D4ED8),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.menu_book_outlined,
                  title: 'Khata Book (کھاتہ)',
                  route: AppRoutes.khataDirectory,
                  isSelected: currentRoute == AppRoutes.khataDirectory,
                  badgeText: KhataState.instance.customers
                          .where((c) => c.balance > 0)
                          .isNotEmpty
                      ? '${KhataState.instance.customers.where((c) => c.balance > 0).length} Pending'
                      : null,
                  badgeColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory & Stock',
                  route: AppRoutes.inventoryList,
                  isSelected: currentRoute == AppRoutes.inventoryList,
                  badgeText: InventoryState.instance.lowStockCount > 0
                      ? '${InventoryState.instance.lowStockCount} Low'
                      : null,
                  badgeColor: const Color(0xFFFEE2E2),
                  badgeTextColor: const Color(0xFFDC2626),
                ),

                const SizedBox(height: 12),

                // SECTION 2: MANAGEMENT & CONFIGURATION
                _buildSectionHeader('STORE SETTINGS', 'سیٹنگز اور پروفائل'),
                _buildMenuItem(
                  context,
                  icon: Icons.storefront_outlined,
                  title: 'Shop Profile & Setup',
                  route: AppRoutes.shopSetup,
                  isSelected: currentRoute == AppRoutes.shopSetup,
                  showArrow: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.print_outlined,
                  title: 'Receipt & Thermal Printer',
                  route: AppRoutes.receiptPreview,
                  isSelected: currentRoute == AppRoutes.receiptPreview,
                  showArrow: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: 'Barcode Scanner Gun',
                  route: AppRoutes.posScanner,
                  isSelected: currentRoute == AppRoutes.posScanner,
                  showArrow: true,
                ),
              ],
            ),
          ),

          // 3. Bottom Lock & Logout Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Lock Terminal Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Terminal Locked for Safety')),
                          );
                        },
                        icon: const Icon(Icons.lock_outline,
                            size: 16, color: Colors.white),
                        label: const Text(
                          'Lock Terminal',
                          style: TextStyle(
                            fontSize: 12.5,
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
                    const SizedBox(width: 10),
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
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.auth,
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SmartKhata v4.2.0 • Offline Ready',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.bolt, size: 12, color: Color(0xFF16A34A)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String english, String urdu) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            english,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            urdu,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (route != null && route != currentRoute) {
          if (route == AppRoutes.dashboard) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (r) => false,
            );
          } else if (currentRoute == AppRoutes.dashboard) {
            Navigator.pushNamed(context, route);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
    );
  }
}
