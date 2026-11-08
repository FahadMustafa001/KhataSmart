import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final bool showMenu;
  final bool showLogo;
  final Widget? leading;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.showBack = true,
    this.showMenu = false,
    this.showLogo = false,
    this.leading,
    this.onBack,
    this.backgroundColor = Colors.white,
    this.elevation = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;

    if (leadingWidget == null) {
      if (showMenu) {
        leadingWidget = Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        );
      } else if (showBack) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          tooltip: 'Back',
          onPressed: onBack ??
              () {
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
        );
      }
    }

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      leading: leadingWidget,
      titleSpacing: (leadingWidget != null) ? 0 : 16,
      title: titleWidget ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLogo) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    AppAssets.appLogo,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
