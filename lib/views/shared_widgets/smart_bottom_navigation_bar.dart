import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

/// Unified 4-Tab Bottom Navigation Bar for KhataSmart
/// Connected across Home, POS Sale, Inventory, and Khata Book
class SmartBottomNavigationBar extends StatelessWidget {
  final String currentRoute;

  const SmartBottomNavigationBar({
    super.key,
    required this.currentRoute,
  });

  void _onTabTapped(BuildContext context, String targetRoute) {
    if (currentRoute == targetRoute) return;

    if (targetRoute == AppRoutes.dashboard) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    } else {
      if (currentRoute == AppRoutes.dashboard) {
        Navigator.pushNamed(context, targetRoute);
      } else {
        Navigator.pushReplacementNamed(context, targetRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.dashboard_rounded,
                inactiveIcon: Icons.dashboard_outlined,
                label: 'Home',
                route: AppRoutes.dashboard,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.point_of_sale_rounded,
                inactiveIcon: Icons.point_of_sale_outlined,
                label: 'POS Sale',
                route: AppRoutes.posCart,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.inventory_2_rounded,
                inactiveIcon: Icons.inventory_2_outlined,
                label: 'Inventory',
                route: AppRoutes.inventoryList,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.menu_book_rounded,
                inactiveIcon: Icons.menu_book_outlined,
                label: 'Khata',
                route: AppRoutes.khataDirectory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return InkWell(
      onTap: () => _onTabTapped(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0F172A) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? icon : inactiveIcon,
                size: 20,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
