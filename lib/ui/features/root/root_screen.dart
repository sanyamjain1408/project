import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/settings.dart';
import 'package:tradexpro_flutter/helper/bottom_nav_helper.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
// ── FIX: Correct import path for HomeDashboardScreen ──
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/home_dashboard_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_screen.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../bottom_navigation/market/market_screen.dart';
import '../bottom_navigation/trades/future_trade/future_trade_screen.dart';
import '../bottom_navigation/trades/trade_screen.dart';
import '../side_navigation/activity/activity_screen.dart';
import '../side_navigation/fiat/fiat_screen.dart';
import '../bottom_navigation/wallet/wallet_screen.dart';
import '../side_navigation/news/news_screen.dart';
import '../side_navigation/staking/staking_screen.dart';
import '../side_navigation/blog/blog_screen.dart';
import '../side_navigation/faq/faq_page.dart';
import '../side_navigation/gift_cards/gift_cards_screen.dart';
import '../side_navigation/settings/settings_screen.dart';
import '../side_navigation/profile/profile_screen.dart';
import '../side_navigation/referrals/referrals_screen.dart';
import '../auth/sign_in/sign_in_screen.dart';
import 'root_controller.dart';
import 'root_widgets.dart';

const _green = Color(0xFFB5F000);
const _drawerBg = Color(0xFF111111);
const _cardBg = Color(0xFF1C1C1C);

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  final RootController _controller = Get.put(RootController());
  final autoSizeGroup = AutoSizeGroup();
  List<AppBottomNav> navList = AppBottomNavHelper.getBottomNavList();

  @override
  void initState() {
    currentContext = context;
    super.initState();
    _controller.changeBottomNavIndex = changeBottomNavTab;
  }

  @override
  void dispose() {
    hideKeyboard();
    super.dispose();
    currentContext = null;
    Get.delete<RootController>();
  }

  void changeBottomNavTab(int id) async {
    setState(() => _controller.bottomNavIndex = AppBottomNavHelper.getNavIndex(id));
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        extendBody: true,
        drawer: _getDrawerNew(),
        bottomNavigationBar: _getBottomNavigationBar(),
        body: SafeArea(
          child: Obx(() => _getBody()),
        ),
      ),
    );
  }

  // ── BOTTOM NAV BAR — IDENTICAL TO ORIGINAL ──────────────────────────────
  Widget _getBottomNavigationBar() {
    navList = AppBottomNavHelper.getBottomNavList();

    return Container(
      margin: const EdgeInsets.only(left: 0, right: 0, bottom: 0, top: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            elevation: 0,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFFB5F000),
            unselectedItemColor: Theme.of(context).primaryColorLight,
            selectedLabelStyle: Theme.of(context).textTheme.displaySmall,
            unselectedLabelStyle: Theme.of(context).textTheme.displaySmall,
            type: BottomNavigationBarType.fixed,
            currentIndex: _controller.bottomNavIndex,
            onTap: (index) => changeBottomNavTab(navList[index].id),
            items: List.generate(navList.length, (index) {
              return BottomNavigationBarItem(
                icon: SizedBox(
                  width: 18,
                  height: 18,
                  child: Image.asset(navList[index].imagePath, fit: BoxFit.contain),
                ),
                activeIcon: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    navList[index].imagePath,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
                label: navList[index].name,
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── BODY — IDENTICAL TO ORIGINAL ────────────────────────────────────────
  Widget _getBody() {
    final id = navList[_controller.bottomNavIndex].id;
    final bool isLoggedIn = gUserRx.value.id > 0;

    switch (id) {
      case AppBottomNavKey.home:
        return isLoggedIn
            ? const HomeDashboardScreen()
            : const LandingScreen();
      case AppBottomNavKey.market:
        return const MarketScreen();
      case AppBottomNavKey.trade:
        return const TradesScreen();
      case AppBottomNavKey.future:
        return const FutureTradeScreen();
      case AppBottomNavKey.wallet:
        return const WalletScreen();
      default:
        return Container();
    }
  }

  // ── NEW FIGMA DRAWER — ONLY THIS IS REDESIGNED ───────────────────────────
  Drawer _getDrawerNew() {
    return Drawer(
      elevation: 0,
      width: context.width * 0.9,
      backgroundColor: _drawerBg,
      child: SafeArea(
        child: Obx(() {
          final hasUser = gUserRx.value.id > 0;
          final user = gUserRx.value;
          final settings = getSettingsLocal();

          return ListView(
            padding: EdgeInsets.zero,
            children: [

              // ── TOP BAR: back + notification + settings ───────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      onPressed: () => Get.back(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                      onPressed: () => Get.to(() => const SettingsScreen()),
                    ),
                  ],
                ),
              ),

              // ── USER PROFILE ──────────────────────────────────────────
              InkWell(
                onTap: () => hasUser
                    ? Get.to(() => const ProfileScreen())
                    : Get.offAll(() => const SignInPage()),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _green, width: 2.5),
                            ),
                            child: hasUser
                                ? showCircleAvatar(user.photo, size: 46)
                                : showCircleAvatar(null, size: 46),
                          ),
                          Positioned(
                            bottom: -4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Verified",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hasUser
                                        ? getName(user.firstName, user.lastName)
                                        : "Sign In".tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                              ],
                            ),
                            if (hasUser)
                              Text(
                                _maskEmail(user.email ?? ""),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            if (hasUser)
                              Row(
                                children: [
                                  Text(
                                    "UID: ${user.id}",
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy_outlined, color: Colors.grey, size: 11),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── SPIN + REFER BANNERS ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _bannerCard(
                        label1: "Spin to Earn",
                        label2: "Rewards",
                        label2Color: _green,
                        bgColor: const Color(0xFF1A2A10),
                        iconWidget: const Icon(Icons.monetization_on_outlined, color: _green, size: 28),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _bannerCard(
                        label1: "Refer and Earn",
                        label2: "Rewards",
                        label2Color: Colors.orange,
                        bgColor: const Color(0xFF2A1A0A),
                        iconWidget: const Icon(Icons.people_alt_outlined, color: Colors.orange, size: 28),
                        onTap: () => hasUser
                            ? Get.to(() => const ReferralsScreen())
                            : Get.offAll(() => const SignInPage()),
                      ),
                    ),
                  ],
                ),
              ),

              // ── QUICK ICON ROW ────────────────────────────────────────
              _quickActionsRow(),

              const SizedBox(height: 4),
              const Divider(color: Colors.white12, thickness: 0.5, height: 1),

              // ── GET HELP ──────────────────────────────────────────────
              _sectionHeader("Get help"),
              _menuItem(icon: Icons.headset_mic_outlined, label: "Help & Support".tr, onTap: () { Get.back(); openCrispChatView(); }),
              _menuItem(icon: Icons.receipt_long_outlined, label: "Fee structure".tr, onTap: () {}),
              _menuItem(icon: Icons.feedback_outlined, label: "App feedback".tr, onTap: () {}),
              _menuItem(icon: Icons.help_outline, label: "FAQ".tr, onTap: () => Get.to(() => const FAQPage())),

              // ── FEATURES ──────────────────────────────────────────────
              _sectionHeader("Features"),
              _menuItem(icon: Icons.verified_outlined, label: "Official Verification".tr, onTap: () {}),
              _menuItem(icon: Icons.paragliding_outlined, label: "Airdrop Campaign".tr, onTap: () {}),
              _menuItem(icon: Icons.list_alt_outlined, label: "Listing".tr, onTap: () {}),

              // ── REWARDS ───────────────────────────────────────────────
              _sectionHeader("Rewards"),
              _menuItem(
                icon: Icons.card_giftcard_outlined,
                label: "Refer & Earn".tr,
                onTap: () => hasUser
                    ? Get.to(() => const ReferralsScreen())
                    : Get.offAll(() => const SignInPage()),
              ),
              _menuItem(icon: Icons.rotate_right_outlined, label: "Spin & Win".tr, onTap: () {}),

              // ── ABOUT US ──────────────────────────────────────────────
              _sectionHeader("About us"),
              _menuItem(icon: Icons.privacy_tip_outlined, label: "Trapix Transparency Center".tr, onTap: () {}),
              _menuItem(icon: Icons.info_outline, label: "About Trapix".tr, onTap: () {}),
              _menuItem(icon: Icons.code_outlined, label: "API Setting".tr, onTap: () {}),
              _menuItem(icon: Icons.telegram, label: "Join Telegram channel".tr, onTap: () => openUrlInBrowser("https://t.me/trapix")),
              _menuItem(icon: Icons.alternate_email, label: "Follow us on X".tr, onTap: () => openUrlInBrowser("https://x.com/trapix")),

              const Divider(color: Colors.white12, thickness: 0.5, height: 24),

              // ── ORIGINAL MENU ITEMS — ALL KEPT EXACTLY AS ORIGINAL ────
              if (hasUser)
                _menuItem(icon: Icons.history, label: "Reports".tr, onTap: () => Get.to(() => const ActivityScreen())),
              if (hasUser)
                _menuItem(icon: Icons.paid_outlined, label: "Fiat".tr, onTap: () => Get.to(() => const FiatScreen())),
              if (hasUser)
                _menuItem(icon: Icons.settings_outlined, label: "Settings".tr, onTap: () => Get.to(() => const SettingsScreen())),
              if (hasUser && settings?.liveChatStatus == 1)
                _menuItem(icon: Icons.support_agent_outlined, label: "Support".tr, onTap: () { Get.back(); openCrispChatView(); }),
              if (settings?.enableStaking == 1)
                _menuItem(icon: Icons.punch_clock_outlined, label: "Staking".tr, onTap: () => Get.to(() => const StakingScreen())),
              if (settings?.enableGiftCard == 1)
                _menuItem(icon: Icons.card_giftcard_outlined, label: "Gift Cards".tr, onTap: () => Get.to(() => const GiftCardsScreen())),
              if (settings?.navbar?["ico"]?.status == true)
                _menuItem(icon: Icons.local_atm, label: "ICO".tr, onTap: () => Get.to(() => const ICOScreen())),
              if (settings?.p2pModule == 1)
                _menuItem(
                  icon: Icons.people,
                  label: "P2P".tr,
                  onTap: () {
                    TemporaryData.changingPageId = 1;
                    Get.back();
                    getRootController().changeBottomNavIndex(AppBottomNavKey.trade);
                  },
                ),
              if (settings?.blogNewsModule == 1)
                _menuItem(icon: Icons.rss_feed_outlined, label: "Blog".tr, onTap: () => Get.to(() => const BlogScreen())),
              if (settings?.blogNewsModule == 1)
                _menuItem(icon: Icons.newspaper_outlined, label: "News".tr, onTap: () => Get.to(() => const NewsScreen())),

              // ── SOCIAL + COPYRIGHT — IDENTICAL TO ORIGINAL ────────────
              _bottomView(settings),

              // ── LOGOUT BUTTON ──────────────────────────────────────────
              if (hasUser)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showLogOutAlert,
                    child: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

  // ── HELPER WIDGETS ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 2),
      child: Text(
        title,
        style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _menuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _bannerCard({
    required String label1,
    required String label2,
    required Color label2Color,
    required Color bgColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 0.5),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label1, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(label2, style: TextStyle(color: label2Color, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsRow() {
    final items = [
      {"icon": Icons.emoji_events_outlined, "label": "Champion"},
      {"icon": Icons.history_outlined, "label": "History"},
      {"icon": Icons.shield_outlined, "label": "Security"},
      {"icon": Icons.verified_user_outlined, "label": "KYC"},
      {"icon": Icons.notifications_active_outlined, "label": "Price Alert"},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item["icon"] as IconData, color: Colors.white70, size: 20),
                ),
                const SizedBox(height: 4),
                Text(item["label"] as String, style: const TextStyle(color: Colors.grey, fontSize: 9)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return "";
    final parts = email.split("@");
    if (parts.length != 2) return email;
    final name = parts[0];
    final masked = name.length > 2
        ? "${name.substring(0, 2)}${"*" * (name.length - 2)}"
        : name;
    return "$masked@${parts[1]}";
  }

  // ── LOGOUT ALERT — IDENTICAL TO ORIGINAL ────────────────────────────────
  void _showLogOutAlert() {
    alertForAction(
      context,
      title: "Log out".tr,
      subTitle: "Are you want to logout from app".tr,
      buttonTitle: "YES".tr,
      onOkAction: () {
        Get.back();
        _controller.logOut();
      },
    );
  }

  // ── BOTTOM VIEW — IDENTICAL TO ORIGINAL ─────────────────────────────────
  Container _bottomView(CommonSettings? cSettings) {
    final socialView = _socialMediaView();
    return Container(
      margin: const EdgeInsets.all(Dimens.paddingLarge),
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.paddingLarge,
        horizontal: Dimens.paddingMid,
      ),
      decoration: boxDecorationRoundCorner(),
      child: Column(
        children: [
          if (socialView != null) socialView,
          if (socialView != null) vSpacer10(),
          if (cSettings?.copyrightText.isValid ?? false)
            textSpanWithAction(
              cSettings?.copyrightText ?? "",
              " ${cSettings?.appTitle ?? ""}",
              onTap: () => openUrlInBrowser(URLConstants.website),
              maxLines: 2,
            ),
        ],
      ),
    );
  }

  Wrap? _socialMediaView() {
    final objMap = GetStorage().read(PreferenceKey.mediaList);
    if (objMap != null) {
      try {
        final mList = List<SocialMedia>.from(
          objMap.map((element) => SocialMedia.fromJson(element)),
        );
        if (mList.isValid) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: Dimens.paddingMid,
            runSpacing: Dimens.paddingMid,
            children: List.generate(mList.length, (index) {
              final item = mList[index];
              final isValid = item.mediaIcon.isValid && item.mediaLink.isValid;
              return isValid
                  ? showImageNetwork(
                      imagePath: item.mediaIcon,
                      height: Dimens.iconSizeMid,
                      width: Dimens.iconSizeMid,
                      bgColor: Colors.transparent,
                      onPressCallback: () => openUrlInBrowser(item.mediaLink ?? ""),
                    )
                  : vSpacer0();
            }),
          );
        }
      } catch (_) {
        printFunction("_socialMediaView error", "");
      }
    }
    return null;
  }
}