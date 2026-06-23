import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/history_sheet.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/price_alerts/price_alerts_screen.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:tradexpro_flutter/data/models/settings.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/ui/features/auth/change_password/change_password_screen.dart';
import 'kyc_screen.dart';
import '../../root/root_screen.dart' show VerificationAvatar;
import 'my_profile_controller.dart';
import 'my_profile_edit_screen.dart';
import 'user_banks/user_bank_controller.dart';
import 'user_banks/bank_input_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _dmSans = 'DMSans';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);

class ProfileScreen extends StatefulWidget {
  final int initialTab;
  const ProfileScreen({super.key, this.initialTab = 0});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final MyProfileController _controller;
  late final TabController _tabController;

  static const _figmaTabs = ['Profile', 'Security', 'General', 'KYC'];

  DynamicBank? _firstBank;
  bool _bankLoaded = false;

  void _loadBankIfNeeded() {
    if (_bankLoaded) return;
    _bankLoaded = true;
    final bankController = Get.put(UserBankController());
    bankController.getUserBankList();
    bankController.userBanks.listen((list) {
      if (list.isNotEmpty && mounted) {
        setState(() => _firstBank = list.first);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Get.delete<MyProfileController>(force: true);
    _controller = Get.put(MyProfileController());
    _controller.selectedType.value = widget.initialTab;
    _tabController = TabController(
      length: _figmaTabs.length,
      initialIndex: widget.initialTab,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.selectedType.value = _tabController.index;
        if (_tabController.index == 1) updateGlobalUser();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = gUserRx.value;
    final selectedIndex = _tabController.index;
    return Scaffold(
      backgroundColor: _primary,
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              color: Colors.transparent,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: _white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "Settings",
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  VerificationAvatar(user: user, size: 60),
                  const SizedBox(height: 10),
                  Text(
                    getName(user.firstName, user.lastName),
                    style: const TextStyle(
                      color: _white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: _dmSans,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _maskEmail(user.email ?? ""),
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                  // ── TABS ──
                  Container(
                    color: Colors.transparent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(
                        _figmaTabs.length,
                        (i) {
                          final isSelected = selectedIndex == i;
                          return GestureDetector(
                            onTap: () {
                              _tabController.animateTo(i);
                              setState(() {});
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(right: 5),
                              child: Text(
                                _figmaTabs[i],
                                style: TextStyle(
                                  color: isSelected
                                      ? _white
                                      : const Color(0x80FFFFFF),
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontFamily: _dmSans,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _buildBody(),
              ),
            ),
          ],
        ),
    );
  }


  Widget _buildBody() {
    switch (_tabController.index) {
      case 0:
        return _profileTab();
      case 1:
        return _securityTab();
      case 2:
        return _generalTab();
      case 3:
        return KycTabView(controller: _controller);
      default:
        return Container();
    }
  }

  // ─────────────────────────── PROFILE TAB ──────────────────────────────────
  Widget _profileTab() {
    final user = gUserRx.value;
    _loadBankIfNeeded();

    final uid = 'TRPX${user.id.toString().padLeft(6, '0')}';
    final bank = _firstBank?.bank;
    final bankName = bank?['bank_name']?.value ?? '';
    final accountHolder = bank?['account_holder']?.value ?? '';
    final accountNumber = bank?['account_number']?.value ?? '';
    final ifscCode = bank?['ifsc_code']?.value ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        _infoCard(
          title: "Profile Update",
          onEdit: () => Get.to(() => const _ProfileEditPage()),
          children: [
            _infoRow(
              "User Name",
              getName(user.firstName, user.lastName),
              "Email",
              user.email ?? "",
            ),
            const SizedBox(height: 16),
            _infoRow(
              "Country",
              user.countryName.isValid
                  ? (user.countryName ?? "")
                  : "No Country",
              "Phone Number",
              user.phone ?? "No Phone",
            ),
            const SizedBox(height: 16),
            _infoSingle("UID Number", uid),
          ],
        ),
        const SizedBox(height: 16),
        _infoCard(
          title: "Bank Details",
          onEdit: () async {
            final bankController = Get.put(UserBankController());
            showLoadingDialog();
            bankController.getUserBankList();
            await Future.delayed(const Duration(seconds: 2));
            hideLoadingDialog();
            if (bankController.userBanks.isNotEmpty) {
              Get.to(
                () => BankInputPage(preBank: bankController.userBanks.first),
              );
            } else {
              Get.to(() => BankInputPage());
            }
          },
          children: [
            _infoRow(
              "Bank Name",
              bankName.isNotEmpty ? bankName : "Not Added",
              "Account Holder",
              accountHolder.isNotEmpty ? accountHolder : "Not Added",
            ),
            const SizedBox(height: 16),
            _infoRow(
              "Bank account number",
              accountNumber.isNotEmpty ? accountNumber : "Not Added",
              "IFSC Code",
              ifscCode.isNotEmpty ? ifscCode : "Not Added",
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─────────────────────────── SECURITY TAB ─────────────────────────────────
  Widget _securityTab() {
    return Obx(() {
      final user = gUserRx.value;
      final bool google2faActive = (user.google2Fa == 1);
      final bool emailVerified = (user.isVerified == 1);
      final bool phoneVerified = (user.phoneVerified == 1);
      return _buildSecurityTabContent(google2faActive, emailVerified, phoneVerified);
    });
  }

  Widget _buildSecurityTabContent(bool google2faActive, bool emailVerified, bool phoneVerified) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
      children: [
        // 1. Google Authenticator
        _securityItem(
          title: "Google Authenticator",
          iconPath: "assets/icons/security_google.png",
          status: google2faActive ? "ACTIVE" : "INACTIVE",
          statusBgColor: google2faActive
              ? const Color(0x66015629)
              : const Color(0x80920000),
          statusTextColor: google2faActive
              ? const Color(0xFF00FF4D)
              : const Color(0xFFFF0A00),
          onTap: () => Get.to(() => const GoogleAuthScreen()),
        ),

        // 2. Verify E-Mail
        _securityItem(
          title: "Verify E-Mail",
          iconPath: "assets/icons/security_verify.png",
          status: emailVerified ? "Verified" : "Not Verified",
          statusBgColor: emailVerified
              ? const Color(0x66015629)
              : const Color(0x80920000),
          statusTextColor: emailVerified
              ? const Color(0xFF00FF4D)
              : const Color(0xFFFF0A00),
          onTap: () => Get.to(() => const VerifyEmailScreen()),
        ),

        // 3. Verify Phone Number
        _securityItem(
          title: "Verify Phone number",
          iconPath: "assets/icons/security_verify_phone.png",
          status: phoneVerified ? "Verified" : "Not Verified",
          statusBgColor: phoneVerified
              ? const Color(0x66015629)
              : const Color(0x80920000),
          statusTextColor: phoneVerified
              ? const Color(0xFF00FF4D)
              : const Color(0xFFFF0A00),
          onTap: () => Get.to(() => const VerifyMobileScreen()),
        ),

        // 4. Change Login Password
        _securityItem(
          title: "Change Login Password",
          iconPath: "assets/icons/security_change.png",
          status: "CHANGE",
          statusBgColor: Colors.white.withOpacity(0.5),
          statusTextColor: Colors.white,
          onTap: () => Get.to(() => const ChangePasswordScreen()),
        ),

        // 5. Account Activity
        _securityItem2(
          title: "Account Activity",
          iconPath: "assets/icons/security_account.png",
          onTap: () => Get.to(() => const AccountActivityScreen()),
        ),

        const SizedBox(height: 10),

        // Warning box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _green, size: 25),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Suspicious activity?\nPlease disable your account to secure your funds.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Disable/Delete button — opens drawer
        GestureDetector(
          onTap: () => _showAccountManagementDrawer(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "Disable Your Account",
                style: TextStyle(
                  color: Color(0xFFD73C3C),
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Account Management Bottom Drawer (Image 6) ────────────────────────────
  void _showAccountManagementDrawer(BuildContext context) {
    final RxInt selected = 0.obs; // 0=delete, 1=disable

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  "Account Management",
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: _white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Delete Account option
            Obx(
              () => _accountOptionTile(
                title: "Delete Account",
                subtitle:
                    "This action will delete your account. if not sure, consider disabling your account",
                isSelected: selected.value == 0,
                onTap: () => selected.value = 0,
              ),
            ),
            const SizedBox(height: 12),
            // Disable Account option
            Obx(
              () => _accountOptionTile(
                title: "Disable Account",
                subtitle: "This is temporary disabling your account",
                isSelected: selected.value == 1,
                onTap: () => selected.value = 1,
              ),
            ),
            const SizedBox(height: 24),
            // Continue button
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _showAccountActionConfirmDialog(selected.value);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountActionConfirmDialog(int actionType) {
    // actionType: 0 = delete, 1 = disable
    final label = actionType == 0 ? "Delete Account" : "Disable Account";
    final reasonCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(label, style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: _white, size: 20)),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Reason", style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 12, fontFamily: _dmSans)),
              const SizedBox(height: 8),
              Container(
                height: 50,
                decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: reasonCtrl,
                  style: const TextStyle(color: _white, fontSize: 14, fontFamily: _dmSans),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter reason",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Password", style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 12, fontFamily: _dmSans)),
              const SizedBox(height: 8),
              Container(
                height: 50,
                decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: _white, fontSize: 14, fontFamily: _dmSans),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter password",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final reason = reasonCtrl.text.trim();
                  final password = passwordCtrl.text.trim();
                  if (reason.isEmpty) { showToast("Please enter a reason"); return; }
                  if (password.isEmpty) { showToast("Please enter your password"); return; }
                  Navigator.pop(ctx);
                  _controller.deleteAccountRequest(reason, password, () {
                    showToast("Request submitted successfully");
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: const Color(0xFFD73C3C), borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(label, style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: _dmSans)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _green : Colors.white38,
                width: isSelected ? 6 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? _white : Colors.white.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: _dmSans,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityItem({
    required String title,
    required String iconPath,
    String? status,
    Color? statusBgColor,
    Color? statusTextColor,
    bool showStatus = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, height: 22, width: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontFamily: _dmSans,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            if (showStatus && status != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 10,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: _green, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _securityItem2({
    required String title,
    required String iconPath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, height: 22, width: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontFamily: _dmSans,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: _green, size: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── GENERAL TAB ──────────────────────────────────
  Widget _generalTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        _generalItem(
          title: "Portfolio base currency",
          iconPath: "assets/icons/portfolio.png",
          trailingText: "USDT",
          onTap: () {},
        ),
        _generalItem(
          title: "Language",
          iconPath: "assets/icons/language.png",
          trailingText: "English",
          onTap: () {},
        ),
        _generalItem(
          title: "History",
          iconPath: "assets/icons/history.png",
          showArrow: true,
          onTap: () => showHistorySheet(),
        ),
        _generalItem(
          title: "Price alerts",
          iconPath: "assets/icons/price.png",
          showArrow: true,
          onTap: () => Get.to(() => const PriceAlertsScreen()),
        ),
        const SizedBox(height: 20),
        const Text(
          "Theme",
          style: TextStyle(
            color: _green,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _darkModeItem(),
        // Style Setting — opens drawer
        _generalItem(
          title: "Style Setting",
          iconPath: "assets/icons/style.png",
          showArrow: true,
          onTap: () => _showStyleSettingDrawer(context),
        ),
        // Color Preference — opens drawer
        _generalItem(
          title: "Color Preference",
          iconPath: "assets/icons/color.png",
          showArrow: true,
          onTap: () => _showColorPreferenceDrawer(context),
        ),
      ],
    );
  }

  // ── Style Setting Drawer (Image 7) ────────────────────────────────────────
  void _showStyleSettingDrawer(BuildContext context) {
    final RxInt selected = 0.obs;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  "Style Setting",
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: _white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(
              () => Row(
                children: [
                  _styleOption(
                    label: "Default",
                    isSelected: selected.value == 0,
                    onTap: () => selected.value = 0,
                    child: _candleChart(
                      colors: [
                        Colors.green,
                        Colors.red,
                        Colors.green,
                        Colors.red,
                        Colors.green,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _styleOption(
                    label: "Color Vision\nDeficiency",
                    isSelected: selected.value == 1,
                    onTap: () => selected.value = 1,
                    child: _candleChart(
                      colors: [
                        const Color(0xFF00CFFF),
                        const Color(0xFFFFD600),
                        const Color(0xFF00CFFF),
                        const Color(0xFFFFD600),
                        const Color(0xFF00CFFF),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _styleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _green : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 70, child: child),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple candle chart illustration
  Widget _candleChart({required List<Color> colors}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(colors.length, (i) {
        final heights = [50.0, 65.0, 45.0, 70.0, 55.0];
        final wicks = [15.0, 20.0, 12.0, 22.0, 18.0];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 2,
              height: wicks[i] / 2,
              color: colors[i].withOpacity(0.6),
            ),
            Container(
              width: 10,
              height: heights[i] * 0.55,
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 2,
              height: wicks[i] / 2,
              color: colors[i].withOpacity(0.6),
            ),
          ],
        );
      }),
    );
  }

  // ── Color Preference Drawer (Image 8) ─────────────────────────────────────
  void _showColorPreferenceDrawer(BuildContext context) {
    final RxInt selected =
        0.obs; // 0 = green up/red down, 1 = green down/red up

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  "Color Preference",
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, color: _white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(
              () => Column(
                children: [
                  // Option 1: Green Up, Red Down
                  _colorPrefOption(
                    isSelected: selected.value == 0,
                    onTap: () => selected.value = 0,
                    leftLabel: "Green Up",
                    leftColor: _green,
                    leftIcon: Icons.arrow_upward,
                    rightLabel: "Red Down",
                    rightColor: Colors.red,
                    rightIcon: Icons.arrow_downward,
                    trailingUp: _green,
                    trailingDown: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  // Option 2: Green Down, Red Up
                  _colorPrefOption(
                    isSelected: selected.value == 1,
                    onTap: () => selected.value = 1,
                    leftLabel: "Green Down",
                    leftColor: _green,
                    leftIcon: Icons.arrow_downward,
                    rightLabel: "Red Up",
                    rightColor: Colors.red,
                    rightIcon: Icons.arrow_upward,
                    trailingUp: Colors.red,
                    trailingDown: _green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _colorPrefOption({
    required bool isSelected,
    required VoidCallback onTap,
    required String leftLabel,
    required Color leftColor,
    required IconData leftIcon,
    required String rightLabel,
    required Color rightColor,
    required IconData rightIcon,
    required Color trailingUp,
    required Color trailingDown,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _green : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // LEFT ICON (colored)
            Icon(leftIcon, color: leftColor, size: 16),
            const SizedBox(width: 4),

            // LEFT TEXT (always white)
            Text(
              leftLabel,
              style: const TextStyle(
                color: _white, //  FIXED
                fontSize: 15,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(width: 16),

            // RIGHT ICON (colored)
            Icon(rightIcon, color: rightColor, size: 16),
            const SizedBox(width: 4),

            // RIGHT TEXT (always white)
            Text(
              rightLabel,
              style: const TextStyle(
                color: _white, //  FIXED
                fontSize: 15,
                fontFamily: _dmSans,
                fontWeight: FontWeight.w400,
              ),
            ),

            const Spacer(),

            // TRAILING ICONS (colored)
            Icon(Icons.arrow_upward, color: trailingUp, size: 16),
            Icon(Icons.arrow_downward, color: trailingDown, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _generalItem({
    required String title,
    required String iconPath,
    String? trailingText,
    bool showArrow = false,
    Widget? customWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, height: 22, width: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans,
                  height: 1.25,
                ),
              ),
            ),
            if (trailingText != null)
              Row(
                children: [
                  Text(
                    trailingText,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: _green,
                    size: 18,
                  ),
                ],
              ),
            if (customWidget != null) customWidget,
            if (showArrow)
              const Icon(Icons.arrow_forward_ios, color: _green, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _darkModeItem() {
    int selectedIndex = 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Dark Mode",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: _green),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _modeBtn("assets/icons/moon.png", selectedIndex == 0),
                const SizedBox(width: 6),
                _modeBtn("assets/icons/son.png", selectedIndex == 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(String asset, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        asset,
        height: 20,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
      ),
    );
  }

  // ─────────────────────────── SHARED WIDGETS ───────────────────────────────
  Widget _infoCard({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined, color: _green, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        Expanded(child: _infoField(l1, v1)),
        const SizedBox(width: 16),
        Expanded(child: _infoField(l2, v2)),
      ],
    );
  }

  Widget _infoSingle(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 11,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: const Icon(
                Icons.copy_outlined,
                color: Color(0xFF8A8A8A),
                size: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0x80FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return "";
    final parts = email.split("@");
    if (parts.length != 2) return email;
    final name = parts[0];
    final masked = name.length > 6
        ? "${name.substring(0, 4)}***${name.substring(name.length - 2)}"
        : name;
    return "$masked@${parts[1]}";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileEditPage extends StatelessWidget {
  const _ProfileEditPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: Column(children: const [ProfileEditScreen()]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE AUTHENTICATOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class GoogleAuthScreen extends StatefulWidget {
  const GoogleAuthScreen({super.key});

  @override
  State<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends State<GoogleAuthScreen> {
  static const _dmSans = 'DMSans';
  static const Color _primary = Color(0xFF111111);
  static const Color _secondary = Color(0xFF1A1A1A);
  static const _green = Color(0xFFCCFF00);
  static const _white = Color(0xFFFFFFFF);

  String secretKey = "";
  String qrData = "";
  bool _isLoading = true;
  bool _isSubmitting = false;
  final codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSecret());
  }

  void _loadSecret() {
    showLoadingDialog();
    APIRepository().getUserSetting().then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final uSettings = UserSettings.fromJson(resp.data);
        if (mounted) {
          setState(() {
            secretKey = uSettings.google2faSecret ?? gUserRx.value.google2FaSecret ?? "";
            qrData = uSettings.qrcode ?? secretKey;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _verify() {
    final code = codeCtrl.text.trim();
    if (code.length != 6) {
      showToast("Please enter 6-digit code");
      return;
    }
    setState(() => _isSubmitting = true);
    final isCurrentlyActive = gUserRx.value.google2Fa == 1;
    APIRepository().setupGoogleSecret(code, secretKey, !isCurrentlyActive).then((resp) {
      setState(() => _isSubmitting = false);
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        updateGlobalUser();
        Get.back();
      }
    }, onError: (err) {
      setState(() => _isSubmitting = false);
      showToast(err.toString(), isError: true);
    });
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = gUserRx.value;
    final isActive = user.google2Fa == 1;

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back, color: _white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Google Authenticator",
                    style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          isActive
                              ? "Google Authenticator is currently ACTIVE.\nEnter your 6-digit code to disable it."
                              : "Open Google Authenticator, Scan the QR code\nor enter the key, then come\nback here to continue",
                          style: const TextStyle(color: _white, fontSize: 16, fontFamily: _dmSans, height: 1.6, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 32),
                        if (!isActive && secretKey.isNotEmpty) ...[
                          Center(
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: QrImageView(
                                  data: qrData.isNotEmpty ? qrData : secretKey,
                                  version: QrVersions.auto,
                                  size: 160.0,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SelectableText(
                              secretKey,
                              style: const TextStyle(color: _white, fontSize: 14, fontFamily: _dmSans, fontWeight: FontWeight.w400),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: secretKey));
                                showToast("Copied to clipboard");
                              },
                              child: Container(
                                width: 180,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
                                child: const Center(
                                  child: Text("Copy", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                        const Text(
                          "Enter the 6 digit verification code from your authenticator app.",
                          style: TextStyle(color: _white, fontSize: 12, fontFamily: _dmSans, height: 1.5, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: codeCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(color: _white, fontSize: 16, fontFamily: _dmSans),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                    hintText: "Google 2FA Code",
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontFamily: _dmSans),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GestureDetector(
                                  onTap: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    codeCtrl.text = data?.text ?? '';
                                  },
                                  child: const Text("Paste", style: TextStyle(color: Color(0xFF00B052), fontSize: 13, fontFamily: _dmSans, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white)),
                        child: const Center(child: Text("Close", style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSubmitting ? null : _verify,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(isActive ? "Disable" : "Verify", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFY EMAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _dmSans = 'DMSans';
  static const Color _primary = Color(0xFF111111);
  static const Color _secondary = Color(0xFF1A1A1A);
  static const _green = Color(0xFFCCFF00);
  static const _white = Color(0xFFFFFFFF);

  bool _verifying = false;
  final otpCtrl = TextEditingController();

  String get _userEmail => gUserRx.value.email ?? "";

  void _verify() {
    final code = otpCtrl.text.trim();
    if (code.isEmpty) { showToast("Please enter verification code"); return; }
    setState(() => _verifying = true);
    APIRepository().verifyEmail(_userEmail, code).then((resp) {
      setState(() => _verifying = false);
      if (resp.success) {
        showToast(resp.message);
        updateGlobalUser();
        Get.back();
      } else {
        showToast(resp.message, isError: true);
      }
    }, onError: (err) {
      setState(() => _verifying = false);
      showToast(err.toString(), isError: true);
    });
  }

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back, color: _white, size: 22)),
                  const SizedBox(width: 16),
                  const Text("Verify E-mail", style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text("Your Email", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _dmSans)),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_userEmail, style: const TextStyle(color: _white, fontSize: 15, fontFamily: _dmSans)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Verification Code", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _dmSans)),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: _white, fontSize: 15, fontFamily: _dmSans),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter verification code",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("Verify Email", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFY MOBILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VerifyMobileScreen extends StatefulWidget {
  const VerifyMobileScreen({super.key});

  @override
  State<VerifyMobileScreen> createState() => _VerifyMobileScreenState();
}

class _VerifyMobileScreenState extends State<VerifyMobileScreen> {
  static const _dmSans = 'DMSans';
  static const Color _primary = Color(0xFF111111);
  static const Color _secondary = Color(0xFF1A1A1A);
  static const _green = Color(0xFFCCFF00);
  static const _white = Color(0xFFFFFFFF);

  bool _sending = false;
  bool _otpSent = false;
  bool _verifying = false;
  final otpCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: gUserRx.value.phone ?? "");
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return "";
    final v = phone.replaceAll(RegExp(r'\s+'), '');
    if (v.length <= 6) return v;
    return "${v.substring(0, 3)}*****${v.substring(v.length - 3)}";
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty || phone.length < 6) {
      showToast("Please enter a valid mobile number");
      return;
    }
    setState(() => _sending = true);

    // If phone changed, update profile first (same as website UpdateUserInfoByToken)
    final currentPhone = (gUserRx.value.phone ?? "").replaceAll(RegExp(r'\D'), '');
    if (phone != currentPhone) {
      final userWithPhone = gUserRx.value;
      userWithPhone.phone = phone;
      final updateResp = await APIRepository().updateProfile(userWithPhone, File(''));
      if (!updateResp.success) {
        setState(() => _sending = false);
        showToast(updateResp.message, isError: true);
        return;
      }
      updateGlobalUser();
    }

    APIRepository().sendPhoneSMS().then((resp) {
      setState(() => _sending = false);
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        setState(() { _otpSent = true; _resendSeconds = 60; });
        _startResendTimer();
      }
    }, onError: (err) {
      setState(() => _sending = false);
      showToast(err.toString(), isError: true);
    });
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 60));
      return _resendSeconds > 0;
    });
  }

  void _verify() {
    final code = otpCtrl.text.trim();
    if (code.isEmpty) { showToast("Please enter OTP"); return; }
    setState(() => _verifying = true);
    APIRepository().verifyPhone(code).then((resp) {
      setState(() => _verifying = false);
      showToast(resp.message, isError: !resp.success);
      if (resp.success) { updateGlobalUser(); Get.back(); }
    }, onError: (err) {
      setState(() => _verifying = false);
      showToast(err.toString(), isError: true);
    });
  }

  @override
  void dispose() {
    otpCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back, color: _white, size: 22)),
                  const SizedBox(width: 16),
                  const Text("Verify Mobile", style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text("Mobile Verification", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _dmSans, fontWeight: FontWeight.w400)),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: _white, fontSize: 15, fontFamily: _dmSans),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Mobile phone number",
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: (_sending || _resendSeconds > 0) ? null : _sendOtp,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                _sending ? "Sending..." : (_resendSeconds > 0 ? "Resend (${_resendSeconds}s)" : "Send OTP"),
                                style: TextStyle(
                                  color: (_resendSeconds > 0 && !_sending) ? Colors.white38 : const Color(0xFF00B052),
                                  fontSize: 12,
                                  fontFamily: _dmSans,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 8),
                      Text("Sent to ${_maskPhone(_phoneCtrl.text)}", style: const TextStyle(color: _green, fontSize: 12, fontFamily: _dmSans)),
                      const SizedBox(height: 20),
                      Text("Verify Code", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _dmSans)),
                      const SizedBox(height: 8),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                        child: TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(color: _white, fontSize: 15, fontFamily: _dmSans),
                          decoration: InputDecoration(
                            counterText: "",
                            border: InputBorder.none,
                            hintText: "Enter OTP",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: (_sending || _verifying) ? null : (_otpSent ? _verify : _sendOtp),
                  child: Text(
                    _verifying ? "Verifying..." : (_sending ? "Sending..." : (_otpSent ? "Confirm" : "Send OTP")),
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT ACTIVITY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AccountActivityScreen extends StatefulWidget {
  const AccountActivityScreen({super.key});

  @override
  State<AccountActivityScreen> createState() => _AccountActivityScreenState();
}

class _AccountActivityScreenState extends State<AccountActivityScreen> {
  static const _dmSans = 'DMSans';
  static const Color _primary = Color(0xFF111111);
  static const Color _secondary = Color(0xFF1A1A1A);
  static const _white = Color(0xFFFFFFFF);

  List<UserActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    APIRepository().getSelfProfile().then((resp) {
      if (mounted) {
        if (resp.success) {
          final listMap = resp.data[APIKeyConstants.activityLog] as List? ?? [];
          final list = List<UserActivity>.from(listMap.map((x) => UserActivity.fromJson(x)));
          setState(() { _activities = list; _isLoading = false; });
        } else {
          setState(() => _isLoading = false);
        }
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back, color: _white, size: 22)),
                  const SizedBox(width: 16),
                  const Text("Account Activity", style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)))
                  : _activities.isEmpty
                      ? const Center(child: Text("No activity found", style: TextStyle(color: Colors.white54, fontSize: 15)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _activities.length,
                          itemBuilder: (ctx, i) {
                            final item = _activities[i];
                            final device = item.source ?? 'Unknown';
                            final time = item.createdAt != null
                                ? "${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year} | ${item.location ?? ''}"
                                : (item.location ?? "");
                            final ip = "IP : ${item.ipAddress ?? 'N/A'}";
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset('assets/icons/phone.png', height: 54, width: 54, fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, st) => const Icon(Icons.phone_android, color: Colors.white54, size: 40)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(device, style: const TextStyle(color: _white, fontSize: 14, fontFamily: _dmSans, fontWeight: FontWeight.w400, height: 1.4)),
                                        const SizedBox(height: 5),
                                        if (time.isNotEmpty)
                                          Text(time, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _dmSans)),
                                        Text(ip, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _dmSans)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KYC TAB VIEW
// ─────────────────────────────────────────────────────────────────────────────
class KycTabView extends StatefulWidget {
  final MyProfileController controller;
  const KycTabView({super.key, required this.controller});
  @override
  State<KycTabView> createState() => _KycTabViewState();
}

class _KycTabViewState extends State<KycTabView> {
  Rx<KycDetails> kycDetailsRx = KycDetails().obs;
  Rx<KycSettings> kycSettingsRx = KycSettings(enabledKycType: 0).obs;
  RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.getKYCSettingsDetails((settings) {
        isLoading.value = false;
        kycSettingsRx.value = settings;
        final kycDetails = settings.enabledKycUserDetails;
        if (kycDetails != null && kycDetails is KycDetails) {
          kycDetailsRx.value = kycDetails;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.transparent),
        );
      }
      final settings = kycSettingsRx.value;
      if (settings.enabledKycType == 0) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_disabled, color: Colors.white54, size: 60),
              SizedBox(height: 12),
              Text(
                "KYC Disabled",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        );
      }
      if (settings.enabledKycType == 2) {
        if (settings.enabledKycUserDetails?.persona?.isVerified == 1) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_reg, color: Color(0xFFCCFF00), size: 60),
                SizedBox(height: 12),
                Text(
                  "KYC Verified Successfully",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                color: Color(0xFFCCFF00),
                size: 60,
              ),
              const SizedBox(height: 12),
              const Text(
                "Verify your identity",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'DMSans',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "Start",
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      final details = kycDetailsRx.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          if (details.nid != null)
            _kycListItem(
              iconPath: "assets/icons/id_card.png",
              title: "Upload your ID Card",
              kyc: details.nid,
              onTap: () => _handleKycTap(context, "ID Card", details.nid, IdVerificationType.nid),
            ),
          if (details.passport != null)
            _kycListItem(
              iconPath: "assets/icons/passport.png",
              title: "Upload your Passport",
              kyc: details.passport,
              onTap: () => _handleKycTap(context, "Passport", details.passport, IdVerificationType.passport),
            ),
        ],
      );
    });
  }

  void _handleKycTap(BuildContext context, String title, KycObject? kyc, IdVerificationType type) {
    final status = (kyc?.status ?? '').toLowerCase();
    if (status == 'approved') return; // disabled
    // Rejected: clear images so user re-uploads fresh
    final kycToPass = status == 'rejected'
        ? KycObject(frontImage: null, backImage: null, selfieImage: null, status: kyc?.status)
        : kyc;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycUploadPage(
          title: title,
          kyc: kycToPass,
          type: type,
          controller: widget.controller,
          onUploaded: (d) => kycDetailsRx.value = d,
        ),
      ),
    );
  }

  Widget _kycListItem({
    required String iconPath,
    required String title,
    required KycObject? kyc,
    required VoidCallback onTap,
  }) {
    final rawStatus = (kyc?.status ?? '').toLowerCase();
    final isApproved = rawStatus == 'approved';
    final isPending = rawStatus == 'pending' || (kyc?.frontImage != null && rawStatus != 'approved' && rawStatus != 'rejected');
    final isRejected = rawStatus == 'rejected';

    Color statusColor = const Color(0xFFFFAA00);
    String statusLabel = 'Pending';
    if (isApproved) { statusColor = const Color(0xFFCCFF00); statusLabel = 'Approved'; }
    else if (isRejected) { statusColor = const Color(0xFFFF4D4D); statusLabel = 'Rejected'; }

    final showStatus = isApproved || isPending || isRejected;

    return GestureDetector(
      onTap: isApproved ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, height: 22, width: 22,
              color: isApproved ? Colors.white38 : null),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DMSans',
                      color: isApproved ? Colors.white38 : Colors.white,
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSans',
                        color: statusColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isApproved)
              const Icon(Icons.arrow_forward_ios, color: Color(0xFFCCFF00), size: 16)
            else
              const Icon(Icons.check_circle, color: Color(0xFFCCFF00), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _selfieItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                "assets/icons/selfie.png",
                height: 22,
                width: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 14),
              const Text(
                "Upload your Selfie",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: _secondary,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitBtn() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            "Submit",
            style: TextStyle(
              color: Color(0xF1111111),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ),
    );
  }
}
