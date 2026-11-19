import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/local_database_service.dart';
import '../../state/shop_state.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final current = ShopState.instance.activeShop;
    if (current.name.isNotEmpty && current.name != 'My Store') {
      _storeNameController.text = current.name;
    }
    if (current.ownerName.isNotEmpty && current.ownerName != 'Store Owner') {
      _ownerNameController.text = current.ownerName;
    }
    if (current.phone.isNotEmpty) {
      _phoneController.text = current.phone;
    }
    if (current.address.isNotEmpty) {
      _cityController.text = current.address;
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final storeName = _storeNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();

    if (storeName.isNotEmpty || ownerName.isNotEmpty || phone.isNotEmpty || city.isNotEmpty) {
      ShopState.instance.updateActiveShop(
        name: storeName.isNotEmpty ? storeName : 'My Store',
        ownerName: ownerName.isNotEmpty ? ownerName : 'Store Owner',
        phone: phone,
        address: city,
      );
    }
    final previousOnboarding = ShopState.instance.hasCompletedOnboarding;
    ShopState.instance.setCompletedOnboarding(true);
    try {
      await LocalDatabaseService.instance.persistToDisk();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      ShopState.instance.setCompletedOnboarding(previousOnboarding);
      if (mounted) {
        AppToast.showError(context, 'Failed to save store profile. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.auth);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B),
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.auth);
              }
            },
          ),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  AppAssets.appLogo,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Business Profile',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFF1A365D),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF16A34A), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Account Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'STEP 2 OF 2',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1. Mobile Verification',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '2. Store Setup',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.storefront,
                                      size: 14, color: Color(0xFF0D9488)),
                                  SizedBox(width: 4),
                                  Text(
                                    'BUSINESS PROFILE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D9488),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Setup Your Store',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Details will appear automatically on your printed receipts, SMS khata reminders, and PDF balance ledgers.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.storefront,
                                color: Color(0xFF1E40AF),
                                size: 28,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF16A34A),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildFieldLabel(
                      label: 'Store Name',
                      isRequired: true,
                      trailingText: 'e.g. Retail, Grocery',
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _storeNameController,
                      prefixIcon: Icons.storefront_outlined,
                      hintText: 'e.g. Al-Madina Super Store',
                    ),

                    const SizedBox(height: 14),

                    _buildFieldLabel(
                      label: 'Owner / Proprietor Name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _ownerNameController,
                      prefixIcon: Icons.person_outline,
                      hintText: 'e.g. Haji Muhammad Ali',
                    ),

                    const SizedBox(height: 14),

                    _buildFieldLabel(
                      label: 'Mobile / WhatsApp Number',
                      isRequired: true,
                      trailingText: 'For WhatsApp Slips & SMS',
                      trailingColor: const Color(0xFF0D9488),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🇵🇰',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '+92',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 20,
                                width: 1,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ],
                          ),
                        ),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Color(0xFF25D366),
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                        hintText: '300 1234567',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF16A34A), width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildFieldLabel(
                      label: 'City & Market Location',
                      isRequired: true,
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _cityController,
                      prefixIcon: Icons.location_on_outlined,
                      hintText: 'e.g. Lahore / Okara',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Builder(
                builder: (context) {
                  final isSignedIn = AuthService.instance.isSignedIn;
                  final isSyncConfirmedActive = isSignedIn &&
                      CloudSyncService.instance.autoSyncEnabled &&
                      CloudSyncService.instance.lastSyncTime != null;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSignedIn
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSignedIn
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSignedIn
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_queue_rounded,
                            color: isSignedIn
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSignedIn
                                    ? (isSyncConfirmedActive
                                        ? 'Cloud Synchronization Active'
                                        : 'Cloud Account Connected')
                                    : 'Offline-First Store Storage',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSignedIn
                                      ? const Color(0xFF14532D)
                                      : const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSignedIn
                                    ? (isSyncConfirmedActive
                                        ? 'Signed in as ${AuthService.instance.userEmail}. Real-time cloud sync is confirmed active.'
                                        : 'Signed in as ${AuthService.instance.userEmail}. Ready to sync store data in Settings.')
                                    : 'Your store records are saved safely on this device. Sign in anytime to enable cloud backup.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSignedIn
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D), // Forest Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started with SmartKhata',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel({
    required String label,
    required bool isRequired,
    String? trailingText,
    Color? trailingColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
        if (trailingText != null)
          Text(
            trailingText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: trailingColor ?? const Color(0xFF64748B),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.normal,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
