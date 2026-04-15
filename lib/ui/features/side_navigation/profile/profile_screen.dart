import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
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

const _bg      = Color(0xFF121212);
const _cardBg  = Color(0xFF1E1E1E);
const _green   = Color(0xFFCCFF00);
const _white   = Color(0xFFFFFFFF);
const _grey    = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);
const _dmSans  = 'DMSans';

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

  // ── FIGMA TAB NAMES — exactly matching Figma design ──
  static const _figmaTabs = ['Profile', 'Security', 'General', 'KYC', 'Banks'];

  @override
  void initState() {
    super.initState();
    // Use controller menu count to avoid mismatch crash
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_new, color: _white, size: 18),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: _dmSans,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final user = gUserRx.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── AVATAR ──────────────────────────────────────────────
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _green, width: 2.5),
                  ),
                  child: ClipOval(child: showCircleAvatar(user.photo, size: 72)),
                ),
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Verified",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── NAME ────────────────────────────────────────────────
            Text(
              getName(user.firstName, user.lastName),
              style: const TextStyle(
                color: _white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(height: 4),

            // ── EMAIL — masked like Figma ────────────────────────────
            Text(
              _maskEmail(user.email ?? ""),
              style: const TextStyle(
                color: _grey,
                fontSize: 13,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(height: 20),

            // ── TABS — Figma names ───────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _divider, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: _white,
                unselectedLabelColor: _grey,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: _green, width: 3.0),
                  insets: EdgeInsets.symmetric(horizontal: 0),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: _dmSans,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                ),
                onTap: (index) => _controller.selectedType.value = index,
                // Show Figma names but keep same count as controller
                tabs: List.generate(
                  _controller.getProfileMenus().length,
                  (i) => Tab(
                    text: i < _figmaTabs.length
                        ? _figmaTabs[i]
                        : _controller.getProfileMenus()[i],
                  ),
                ),
              ),
            ),

            // ── BODY ─────────────────────────────────────────────────
            Expanded(
              child: _buildBody(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBody() {
    switch (_controller.selectedType.value) {
      case 0:  return _profileTab();
      case 1:  return _wrapScreen(const ProfileEditScreen());
      case 2:  return _wrapScreen(const SecurityScreen());
      case 3:  return _wrapScreen(const KYCScreen());
      case 4:  return const UserBankScreen();
      default: return Container();
    }
  }

  // Wrap screens that use Expanded internally
  Widget _wrapScreen(Widget screen) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        child: screen,
      ),
    );
  }

  Widget _profileTab() {
    final user = gUserRx.value;
    if (userActivities.isEmpty) {
      _controller.getUserActivities(
          (list) => setState(() => userActivities = list));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [

        // ── PROFILE UPDATE CARD ──────────────────────────────────────
        _infoCard(
          title: "Profile Update",
          onEdit: () => Get.to(() => const _ProfileEditPage()),
          children: [
            _infoRow(
              "User Name", getName(user.firstName, user.lastName),
              "Email",     user.email ?? "",
            ),
            const SizedBox(height: 16),
            _infoRow(
              "Country",
              user.countryName.isValid ? (user.countryName ?? "") : "No Country",
              "Phone Number",
              user.phone ?? "No Phone",
            ),
            const SizedBox(height: 16),
            _infoSingle("UID Number", user.id.toString()),
          ],
        ),

        const SizedBox(height: 16),

        // ── BANK DETAILS CARD ────────────────────────────────────────
        _infoCard(
          title: "Bank Details",
          onEdit: () async {
            final bankController = Get.put(UserBankController());
            showLoadingDialog();
            bankController.getUserBankList();
            await Future.delayed(const Duration(seconds: 2));
            hideLoadingDialog();
            if (bankController.userBanks.isNotEmpty) {
              Get.to(() => BankInputPage(preBank: bankController.userBanks.first));
            } else {
              Get.to(() => BankInputPage());
            }
          },
          children: [
            // FIXED: "Bank Name" on both sides like Figma
            _infoRow("Bank Name", "Axis Bank", "Bank Name", "Patel Vyom"),
            const SizedBox(height: 16),
            _infoRow("Bank account number", "10000100012121", "IFSC Code", "BARBOHUHDAS"),
          ],
        ),

        const SizedBox(height: 24),

        // ── PROFILE ACTIVITY ─────────────────────────────────────────
        if (userActivities.isNotEmpty) ...[
          const Text(
            "Profile Activity",
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: Text("Action",     style: TextStyle(color: _grey, fontSize: 12, fontFamily: _dmSans))),
            Expanded(child: Text("IP Address", style: TextStyle(color: _grey, fontSize: 12, fontFamily: _dmSans), textAlign: TextAlign.center)),
            Expanded(child: Text("Time",       style: TextStyle(color: _grey, fontSize: 12, fontFamily: _dmSans), textAlign: TextAlign.end)),
          ]),
          const SizedBox(height: 8),
          ...userActivities.map((a) => _activityRow(a)),
        ],
      ],
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _infoCard({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: const TextStyle(
              color: _green, fontSize: 15,
              fontWeight: FontWeight.w700, fontFamily: _dmSans,
            )),
            const Spacer(),
            GestureDetector(
              onTap: onEdit,
              child: const Icon(Icons.edit_outlined, color: _green, size: 18),
            ),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String l1, String v1, String l2, String v2) {
    return Row(children: [
      Expanded(child: _infoField(l1, v1)),
      const SizedBox(width: 16),
      Expanded(child: _infoField(l2, v2)),
    ]);
  }

  Widget _infoSingle(String label, String value) {
    return Row(children: [
      _infoField(label, value),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => Clipboard.setData(ClipboardData(text: value)),
        child: const Icon(Icons.copy_outlined, color: _grey, size: 14),
      ),
    ]);
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: _grey, fontSize: 11, fontFamily: _dmSans,
        )),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          color: _white, fontSize: 14,
          fontWeight: FontWeight.w500, fontFamily: _dmSans,
        )),
      ],
    );
  }

  Widget _activityRow(UserActivity activity) {
    final action =
        "${AppChecker.getActivityActionText(activity.action)}\n${activity.source ?? ""}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(action,
            style: const TextStyle(color: _white, fontSize: 12, fontFamily: _dmSans),
            maxLines: 2)),
        Expanded(child: Text(activity.ipAddress ?? "",
            style: const TextStyle(color: _white, fontSize: 12, fontFamily: _dmSans),
            textAlign: TextAlign.center, maxLines: 2)),
        Expanded(child: Text(
            formatDate(activity.updatedAt, format: dateTimeFormatYyyyMMDdHhMm),
            style: const TextStyle(color: _white, fontSize: 12, fontFamily: _dmSans),
            textAlign: TextAlign.end, maxLines: 2)),
      ]),
    );
  }

  // ── vyym****tel@gmail.com format ─────────────────────────────────────────
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

// ── WRAPPER: opens ProfileEditScreen as a proper full Scaffold page ───────────
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
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
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
      body: Column(
        children: const [
          ProfileEditScreen(),
        ],
      ),
    );
  }
}

// end of file