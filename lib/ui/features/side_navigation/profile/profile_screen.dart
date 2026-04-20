import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import '../../../../helper/app_checker.dart';
import 'kyc_screen.dart';
import 'my_profile_controller.dart';
import 'my_profile_edit_screen.dart';
import 'security_screen.dart';
import 'user_banks/user_bank_screen.dart';
import 'user_banks/user_bank_controller.dart';
import 'user_banks/bank_input_page.dart';
import 'package:tradexpro_flutter/ui/features/auth/change_password/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart'; // GetX import assume kiya hai
import 'package:qr_flutter/qr_flutter.dart'; // QR Package import kiya

const _bg = Color(0xFF121212);
const _cardBg = Color(0xFF1E1E1E);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);
const _dmSans = 'DMSans';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _controller = Get.put(MyProfileController());
  late final TabController _tabController;
  List<UserActivity> userActivities = <UserActivity>[];

  static const _figmaTabs = ['Profile', 'Security', 'General', 'KYC'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _controller.getProfileMenus().length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.selectedType.value = _tabController.index;
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
    return SafeArea(
      top: true,
      child: Scaffold(
        backgroundColor: _primary,
        body: Obx(() {
          final user = gUserRx.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
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
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipOval(child: showCircleAvatar(user.photo)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF015629).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Verified",
                        style: TextStyle(
                          color: Color(0xFF00FF4D),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ),
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
                          _controller.getProfileMenus().length,
                          (i) {
                            final isSelected =
                                _controller.selectedType.value == i;
                            final title = i < _figmaTabs.length
                                ? _figmaTabs[i]
                                : _controller.getProfileMenus()[i];
                            return GestureDetector(
                              onTap: () {
                                _controller.selectedType.value = i;
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
                                  title,
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
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.selectedType.value) {
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
    if (userActivities.isEmpty) {
      _controller.getUserActivities(
        (list) => setState(() => userActivities = list),
      );
    }
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
            _infoSingle("UID Number", user.id.toString()),
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
            _infoRow("Bank Name", "Axis Bank", "Account Holder", "Patel Vyom"),
            const SizedBox(height: 16),
            _infoRow(
              "Bank account number",
              "10000100012121",
              "IFSC Code",
              "BARBOHUHDAS",
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─────────────────────────── SECURITY TAB ─────────────────────────────────
  Widget _securityTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
      children: [
        // 1. Google Authenticator
        _securityItem(
          title: "Google Authenticator",
          iconPath: "assets/icons/security_google.png",
          status: "ACTIVE",
          statusBgColor: const Color(0x66015629),
          statusTextColor: const Color(0xFF00FF4D),
          onTap: () => Get.to(() => const GoogleAuthScreen()),
        ),

        // 2. Verify E-Mail
        _securityItem(
          title: "Verify E-Mail",
          iconPath: "assets/icons/security_verify.png",
          status: "Not Verified",
          statusBgColor: const Color(0x80920000),
          statusTextColor: const Color(0xFFFF0A00),
          onTap: () => Get.to(() => const VerifyEmailScreen()),
        ),

        // 3. Verify Phone Number
        _securityItem(
          title: "Verify Phone number",
          iconPath: "assets/icons/security_verify_phone.png",
          status: "Not Verified",
          statusBgColor: const Color(0x80920000),
          statusTextColor: const Color(0xFFFF0A00),
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
                // TODO: handle delete/disable API call based on selected.value
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
          onTap: () {},
        ),
        _generalItem(
          title: "Price alerts",
          iconPath: "assets/icons/price.png",
          showArrow: true,
          onTap: () {},
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
    final masked = name.length > 4
        ? "${name.substring(0, 4)}${"*" * (name.length - 4)}tel"
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
// GOOGLE AUTHENTICATOR SCREEN  (Image 1)
// ─────────────────────────────────────────────────────────────────────────────

// Class ko StatefulWidget banaya
class GoogleAuthScreen extends StatefulWidget {
  const GoogleAuthScreen({super.key});

  @override
  State<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

// State class banayi
class _GoogleAuthScreenState extends State<GoogleAuthScreen> {
  // Colors aur Fonts (Apne project ke hisab se adjust kar sakte hain)

  static const _bg = Color(0xFF121212);
  static const _cardBg = Color(0xFF1E1E1E);
  static const _green = Color(0xFFCCFF00);
  static const _white = Color(0xFFFFFFFF);
  static const _grey = Color(0xFF8A8A8A);
  static const _divider = Color(0xFF2A2A2A);
  static const _dmSans = 'DMSans';

  static const Color _primary = Color(0xFF111111);
  static const Color _secondary = Color(0xFF1A1A1A);

  // Ab 'const' hata diya, bas 'final' rakha hai. Error solve ho jayega.
  final String secretKey = "wetyruykngbvsfbl25434wergfbdn";

  final codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // AppBar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: _white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Google Authenticator",
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Open Google Authenticator, Scan the QR code\nor enter the key, then come\nback here to continue",
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontFamily: _dmSans,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- QR CODE CONTAINER START ---
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: QrImageView(
                          data: secretKey,
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // --- QR CODE CONTAINER END ---
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      secretKey,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 16,
                        fontFamily: _dmSans,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Copy button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: secretKey),
                        ); // 'const' hata diya
                        // Agar aapke paas custom showToast function hai to use use karein, nahi to SnackBar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Copied to clipboard"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            "Copy",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Enter the 6 digit verification code from your authenticator app.",
                    style: TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontFamily: _dmSans,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Code input
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 16,
                              fontFamily: _dmSans,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Google 2FA Code",
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () async {
                              final data = await Clipboard.getData(
                                'text/plain',
                              );
                              codeCtrl.text = data?.text ?? '';
                            },
                            child: const Text(
                              "Paste",
                              style: TextStyle(
                                color: Color(0xFF00B052),
                                fontSize: 13,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w600,
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
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white),
                        ),
                        child: const Center(
                          child: Text(
                            "Close",
                            style: TextStyle(
                              color: _white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: verify 2FA
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            "Verify",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: _dmSans,
                            ),
                          ),
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
// VERIFY EMAIL SCREEN  (Image 2)
// ─────────────────────────────────────────────────────────────────────────────
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController(text: "Ab123@df");

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
                    child: const Icon(
                      Icons.arrow_back,
                      color: _white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Verify E-mail",
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "Email Verification",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: _dmSans,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailCtrl,
                              style: const TextStyle(
                                color: _white,
                                fontSize: 16,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Text(
                              "Sent OTP",
                              style: TextStyle(
                                color: Color(0xFF00B052),
                                fontSize: 13,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sent to Ab123@df",
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontFamily: _dmSans,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // TODO: confirm email OTP
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFY MOBILE SCREEN  (Image 3)
// ─────────────────────────────────────────────────────────────────────────────
class VerifyMobileScreen extends StatelessWidget {
  const VerifyMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mobileCtrl = TextEditingController(text: "1234567890");

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
                    child: const Icon(
                      Icons.arrow_back,
                      color: _white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Verify Mobile",
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "Mobile Verification",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: _dmSans,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: mobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color: _white,
                                fontSize: 15,
                                fontFamily: _dmSans,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Text(
                              "Sent OTP",
                              style: TextStyle(
                                color: Color(0xFF00B052),
                                fontSize: 12,
                                fontFamily: _dmSans,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sent to 99******12",
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontFamily: _dmSans,
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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // TODO: confirm mobile OTP
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT ACTIVITY SCREEN  (Image 5)
// ─────────────────────────────────────────────────────────────────────────────
class AccountActivityScreen extends StatelessWidget {
  const AccountActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data — replace with real API
    final items = List.generate(
      3,
      (_) => {
        "device": "Mobile Safari – Apple iphone\niOS 26.2",
        "time": "11 Days Ago | Surat – GJ – In",
        "ip": "IP : 152.59.40.245",
      },
    );

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
                    child: const Icon(
                      Icons.arrow_back,
                      color: _white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Account Activity",
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 127,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // 👈 ye add karo
                      children: [
                        Image.asset(
                          'assets/icons/phone.png',
                          height: 54,
                          width: 54,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment
                                .center, // 👈 optional but better
                            children: [
                              Text(
                                item["device"]!,
                                style: const TextStyle(
                                  color: _white,
                                  fontSize: 16,
                                  fontFamily: _dmSans,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item["time"]!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: _dmSans,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                item["ip"]!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: _dmSans,
                                  fontWeight: FontWeight.w400,
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
              onTap: () => _goUpload(
                context,
                "ID Card",
                details.nid,
                IdVerificationType.nid,
              ),
            ),
          if (details.passport != null)
            _kycListItem(
              iconPath: "assets/icons/passport.png",
              title: "Upload your Passport",
              onTap: () => _goUpload(
                context,
                "Passport",
                details.passport,
                IdVerificationType.passport,
              ),
            ),
          _selfieItem(),
          const SizedBox(height: 30),
          _submitBtn(),
        ],
      );
    });
  }

  void _goUpload(
    BuildContext context,
    String title,
    KycObject? kyc,
    IdVerificationType type,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycUploadPage(
          title: title,
          kyc: kyc,
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, height: 22, width: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFCCFF00),
              size: 16,
            ),
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
