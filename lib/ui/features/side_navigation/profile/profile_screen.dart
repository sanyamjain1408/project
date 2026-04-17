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

const _bg = Color(0xFF121212);
const _cardBg = Color(0xFF1E1E1E);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);
const _dmSans = 'DMSans';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _textSecondary = Color(0xFFCCFF00);

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

  static const _figmaTabs = ['Profile', 'Security', 'General', 'KYC', 'Banks'];

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
              SizedBox(height: 10),

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
              // ── TOP SECTION ──
              Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 100,
                      height: 100,
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
                    // Tabs
                    Container(
                      color: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 6,
                                ),
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

              // ── BOTTOM SECTION ──
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
        return KycTabView(controller: _controller); // ✅ Direct call
      case 4:
        return const UserBankScreen();
      default:
        return Container();
    }
  }

  Widget _wrapScreen(Widget screen) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        child: screen,
      ),
    );
  }

  ///---------------------------- profile --------------------------------------------
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
        // ── PROFILE UPDATE CARD ──
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

        // ── BANK DETAILS CARD ──
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
            _infoRow("Bank Name", "Axis Bank", "Bank Name", "Patel Vyom"),
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

  ///------------------------------security-------------------------------------
  Widget _securityTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
      children: [
        _securityItem(
          title: "Google Authenticator",
          iconPath: "assets/icons/security_google.png",
          status: "ACTIVE",
          statusBgColor: Color(0x66015629), // dark green bg
          statusTextColor: Color(0xFF00FF4D), // bright green text
        ),

        _securityItem(
          title: "Verify E-Mail",
          iconPath: "assets/icons/security_verify.png",
          status: "Not Verified",
          statusBgColor: Color(0x80920000), // dark red bg
          statusTextColor: Color(0xFFFF0A00), // red text
        ),

        _securityItem(
          title: "Verify E-Mail",
          iconPath: "assets/icons/security_verify_phone.png",
          status: "Not Verified",
          statusBgColor: Color(0x80920000), // dark red bg
          statusTextColor: Color(0xFFFF0A00), // red text
        ),

        _securityItem(
          title: "Change Login Password",
          iconPath: "assets/icons/security_change.png",
          status: "CHANGE",
          statusBgColor: Colors.white.withOpacity(0.5), // grey bg
          statusTextColor: Colors.white, // light grey text
        ),

        _securityItem2(
          title: "Change Login Password",
          iconPath: "assets/icons/security_account.png",
          // light grey text
        ),

        const SizedBox(height: 10),

        // ⚠️ Warning Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: _green, size: 25),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Suspicious activity?\nPlease disable your account to secure your funds.",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // 🚨 Disable Button
        Container(
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

        // Warning + Button same rahega
      ],
    );
  }

  Widget _securityItem({
    required String title,
    required String iconPath,
    String? status,
    Color? statusBgColor, // 👈 new
    Color? statusTextColor, // 👈 new
    bool showStatus = true,
  }) {
    return Container(
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
                color: Color(0xFFFFFFFF),
                fontSize: 16,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),

          if (showStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor, // 👈 bg color alag
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status ?? "",
                style: TextStyle(
                  color: statusTextColor, // 👈 text color alag
                  fontSize: 10,
                  fontFamily: _dmSans,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

          const SizedBox(width: 8),

          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFCCFF00),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _securityItem2({required String title, required String iconPath}) {
    return Container(
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
                color: Color(0xFFFFFFFF),
                fontSize: 16,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),

          const SizedBox(width: 8),

          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFCCFF00),
            size: 16,
          ),
        ],
      ),
    );
  }

  ///------------------------ general-------------------------------
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

        // 👉 Theme Title
        const Text(
          "Theme",
          style: TextStyle(
            color: Color(0xFFCCFF00),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        // 👉 Dark Mode Row (dummy UI)
        _darkModeItem(),

        _generalItem(
          title: "Style Setting",
          iconPath: "assets/icons/style.png",
          customWidget: Row(
            children: [Image.asset("assets/icons/style.png", height: 16)],
          ),
          onTap: () {},
        ),

        _generalItem(
          title: "Color Preference",
          iconPath: "assets/icons/color.png",
          customWidget: Row(
            children: [Image.asset("assets/icons/color.png", height: 18)],
          ),
          onTap: () {},
        ),
      ],
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
      onTap: onTap, // 👈 onTap added
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // 👉 Left Icon
            Image.asset(iconPath, height: 22, width: 22),

            const SizedBox(width: 10),

            // 👉 Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans,
                  height: 1.25,
                ),
              ),
            ),

            // 👉 Right side text (USDT / English)
            if (trailingText != null)
              Row(
                children: [
                  Text(
                    trailingText,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFCCFF00),
                    size: 18,
                  ),
                ],
              ),

            // 👉 Custom widget (dark mode / dots / arrows)
            if (customWidget != null) customWidget,

            // 👉 Arrow
            if (showArrow)
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

  Widget _darkModeItem() {
    int selectedIndex = 0; // 0 = moon, 1 = sun (static for now)

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      child: Row(
        children: [
          // 👉 Left Text
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

          // 👉 Right Toggle Container
          Container(
            padding: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFCCFF00)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                // 🌙 Moon
                GestureDetector(
                  onTap: () {}, // 👈 empty
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0
                          ? Colors.black
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/icons/moon.png",
                      height: 20,
                      color: selectedIndex == 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // ☀️ Sun
                GestureDetector(
                  onTap: () {}, // 👈 empty
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1
                          ? Colors.black
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/icons/son.png",
                      height: 20,
                      color: selectedIndex == 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SINGLE _infoCard — NO DUPLICATE ──────────────────────────────────────

  Widget _infoCard({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary, // card bg — image se match
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
                  color: Color(0xFFCCFF00), // green title
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFCCFF00),
                  size: 20,
                ),
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
            color: Color(0xFF8A8A8A), // grey label
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
                color: Color(0xFFFFFFFF), // white value
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
            color: Color(0x80FFFFFF), // grey label
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
            color: Color(0xFFFFFFFF), // white value
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _activityRow(UserActivity activity) {
    final action =
        "${AppChecker.getActivityActionText(activity.action)}\n${activity.source ?? ""}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                color: _white,
                fontSize: 12,
                fontFamily: _dmSans,
              ),
              maxLines: 2,
            ),
          ),
          Expanded(
            child: Text(
              activity.ipAddress ?? "",
              style: const TextStyle(
                color: _white,
                fontSize: 12,
                fontFamily: _dmSans,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          Expanded(
            child: Text(
              formatDate(
                activity.updatedAt,
                format: dateTimeFormatYyyyMMDdHhMm,
              ),
              style: const TextStyle(
                color: _white,
                fontSize: 12,
                fontFamily: _dmSans,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
            ),
          ),
        ],
      ),
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

// ── WRAPPER ───────────────────────────────────────────────────────────────────
class _ProfileEditPage extends StatelessWidget {
  const _ProfileEditPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: const Text(
          "Profile Update",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'DMSans',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(children: const [ProfileEditScreen()]),
    );
  }
}

// ─── KYC TAB VIEW (used in profile_screen.dart) ──────────────────────────────
class KycTabView extends StatefulWidget {
  // ✅ public — no underscore
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
                onPressed: () {}, // persona flow yahan add karo
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

      // Manual KYC (type == 1)
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
          // ✅ same file — private access OK
          title: title,
          kyc: kyc,
          type: type,
          controller: widget.controller,
          onUploaded: (newDetails) => kycDetailsRx.value = newDetails,
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
                color: Colors.white, // optional (for tint)
              ),
              SizedBox(width: 14),
              Text(
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
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: _secondary,
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 32),
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
