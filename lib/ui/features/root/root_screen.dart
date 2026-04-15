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
import '../bottom_navigation/wallet/wallet_screen.dart';
import '../side_navigation/activity/activity_screen.dart';
import '../side_navigation/blog/blog_screen.dart';
import '../side_navigation/faq/faq_page.dart';
import '../side_navigation/fiat/fiat_screen.dart';
import '../side_navigation/gift_cards/gift_cards_screen.dart';
import '../side_navigation/news/news_screen.dart';
import '../side_navigation/profile/profile_screen.dart';
import '../side_navigation/referrals/referrals_screen.dart';
import '../side_navigation/settings/settings_screen.dart';
import '../side_navigation/staking/staking_screen.dart';
import '../auth/sign_in/sign_in_screen.dart';
import 'root_controller.dart';
import 'root_widgets.dart';

// ── EXACT FIGMA COLORS ───────────────────────────────────────────────────────
const _green       = Color(0xFFCCFF00);   // EXACT Figma secondary #CCFF00
const _drawerBg    = Color(0xFF121212);   // near-black background
const _cardBg      = Color(0xFF1E1E1E);   // card / icon box background
const _sectionClr  = Color(0xFFCCFF00);   // section header color
const _textWhite   = Color(0xFFFFFFFF);
const _textGrey    = Color(0xFF8A8A8A);
const _divider     = Color(0xFF2A2A2A);
const _dmSans      = 'DMSans';           // DM Sans font family

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
        drawerScrimColor: Colors.transparent,
        drawer: _getDrawerNew(),
        bottomNavigationBar: _getBottomNavigationBar(),
        body: SafeArea(
          child: Obx(() => _getBody()),
        ),
      ),
    );
  }

  // ── BOTTOM NAV — UNCHANGED ───────────────────────────────────────────────
  Widget _getBottomNavigationBar() {
    navList = AppBottomNavHelper.getBottomNavList();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            elevation: 0,
            iconSize: 24,
            backgroundColor: Colors.transparent,
            selectedItemColor: _green,
            unselectedItemColor: Theme.of(context).primaryColorLight,
            selectedLabelStyle: Theme.of(context).textTheme.displaySmall,
            unselectedLabelStyle: Theme.of(context).textTheme.displaySmall,
            type: BottomNavigationBarType.fixed,
            currentIndex: _controller.bottomNavIndex,
            onTap: (index) => changeBottomNavTab(navList[index].id),
            items: List.generate(navList.length, (index) {
              return BottomNavigationBarItem(
                icon: SizedBox(width: 18, height: 18,
                    child: Image.asset(navList[index].imagePath, fit: BoxFit.contain)),
                activeIcon: SizedBox(width: 24, height: 24,
                    child: Image.asset(navList[index].imagePath, fit: BoxFit.contain, gaplessPlayback: true)),
                label: navList[index].name,
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── BODY — UNCHANGED ────────────────────────────────────────────────────
  Widget _getBody() {
    final id = navList[_controller.bottomNavIndex].id;
    final bool isLoggedIn = gUserRx.value.id > 0;
    switch (id) {
      case AppBottomNavKey.home:   return isLoggedIn ? const HomeDashboardScreen() : const LandingScreen();
      case AppBottomNavKey.market: return const MarketScreen();
      case AppBottomNavKey.trade:  return const TradesScreen();
      case AppBottomNavKey.future: return const FutureTradeScreen();
      case AppBottomNavKey.wallet: return const WalletScreen();
      default: return Container();
    }
  }

  // ── FIGMA DRAWER ─────────────────────────────────────────────────────────
  Drawer _getDrawerNew() {
    return Drawer(
      elevation: 0,
      width: context.width,
      backgroundColor: _drawerBg,
      child: SafeArea(
        child: Obx(() {
          final hasUser = gUserRx.value.id > 0;
          final user    = gUserRx.value;
          final settings = getSettingsLocal();

          return ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [

              // ── TOP BAR: ← bell settings ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 10, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new, color: _textWhite, size: 18),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.notifications_none_outlined, color: _textWhite, size: 22),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Get.to(() => const SettingsScreen()),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.settings_outlined, color: _textWhite, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── PROFILE ROW ──────────────────────────────────────────
              GestureDetector(
                onTap: () => hasUser
                    ? Get.to(() => const ProfileScreen())
                    : Get.offAll(() => const SignInPage()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar circle with green border
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _green, width: 2),
                            ),
                            child: ClipOval(
                              child: showCircleAvatar(
                                hasUser ? user.photo : null,
                                size: 52,
                              ),
                            ),
                          ),
                          // Verified badge
                          Positioned(
                            bottom: -2,
                            left: 2,
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
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Name / email / uid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasUser ? getName(user.firstName, user.lastName) : "Sign In".tr,
                              style: const TextStyle(
                                color: _textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: _dmSans,
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (hasUser) ...[
                              const SizedBox(height: 2),
                              Text(
                                _maskEmail(user.email ?? ""),
                                style: const TextStyle(color: _textGrey, fontSize: 12, fontFamily: _dmSans),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    "UID: ${user.id}",
                                    style: const TextStyle(color: _textGrey, fontSize: 11, fontFamily: _dmSans),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.copy_outlined, color: _textGrey, size: 12),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: _textGrey, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── SPIN + REFER BANNERS ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // Spin to Earn
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2512),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2E3D1A), width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 13, height: 1.4, fontFamily: _dmSans),
                                    children: [
                                      TextSpan(text: "Spin ", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w700)),
                                      TextSpan(text: "to ", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w400)),
                                      TextSpan(text: "Earn\n", style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
                                      TextSpan(text: "Rewards", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w400, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: _green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.monetization_on, color: _green, size: 22),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Refer and Earn
                    Expanded(
                      child: GestureDetector(
                        onTap: () => hasUser
                            ? Get.to(() => const ReferralsScreen())
                            : Get.offAll(() => const SignInPage()),
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF252535), width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 13, height: 1.4, fontFamily: _dmSans),
                                    children: [
                                      TextSpan(text: "Refer ", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w700)),
                                      TextSpan(text: "and ", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w400)),
                                      TextSpan(text: "Earn\n", style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
                                      TextSpan(text: "Rewards", style: TextStyle(color: _textWhite, fontWeight: FontWeight.w400, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.purpleAccent.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_alt_outlined, color: Colors.purpleAccent, size: 22),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── QUICK ICON ROW ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickIcon(Icons.emoji_events_outlined,  "Champion"),
                    _quickIcon(Icons.history_outlined,       "History"),
                    _quickIcon(Icons.shield_outlined,        "Security"),
                    _quickIcon(Icons.badge_outlined,         "KYC"),
                    _quickIcon(Icons.notifications_outlined, "Price Alert"),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: _divider, thickness: 1, height: 1),

              // ── GET HELP ──────────────────────────────────────────────
              _sectionHeader("Get help"),
              _menuRow(Icons.headset_mic_outlined,     "Help & Support",   () { Get.back(); openCrispChatView(); }),
              _menuRow(Icons.receipt_long_outlined,    "Fee structure",    () {}),
              _menuRow(Icons.sentiment_satisfied_alt,  "App feedback",     () {}),
              _menuRow(Icons.help_outline,             "FAQ",              () => Get.to(() => const FAQPage())),

              // ── FEATURES ─────────────────────────────────────────────
              _sectionHeader("Features"),
              _menuRow(Icons.verified_outlined,        "Official Verification", () {}),
              _menuRow(Icons.paragliding_outlined,     "Airdrop Campaign",      () {}),
              _menuRow(Icons.list_alt_outlined,        "Listing",               () {}),

              // ── REWARDS ──────────────────────────────────────────────
              _sectionHeader("Rewards"),
              _menuRow(Icons.card_giftcard_outlined, "Refer & Earn", () => hasUser
                  ? Get.to(() => const ReferralsScreen())
                  : Get.offAll(() => const SignInPage())),
              _menuRow(Icons.rotate_right_outlined, "Spin & Win", () {}),

              // ── ABOUT US ─────────────────────────────────────────────
              _sectionHeader("About us"),
              _menuRow(Icons.privacy_tip_outlined,   "Trapix Transparency Center", () {}),
              _menuRow(Icons.info_outline,           "About Trapix",               () {}),
              _menuRow(Icons.code_outlined,          "API Setting",                () {}),
              _menuRow(Icons.telegram,               "Join Telegram channel",      () => openUrlInBrowser("https://t.me/trapix")),
              _menuRow(Icons.alternate_email,        "Follow us on X",             () => openUrlInBrowser("https://x.com/trapix")),

              const SizedBox(height: 6),
              Divider(color: _divider, thickness: 1, height: 1),

              // ── ORIGINAL MENUS — KEPT EXACTLY ────────────────────────
              if (hasUser) _menuRow(Icons.history,              "Reports",    () => Get.to(() => const ActivityScreen())),
              if (hasUser) _menuRow(Icons.paid_outlined,        "Fiat",       () => Get.to(() => const FiatScreen())),
              if (hasUser) _menuRow(Icons.settings_outlined,    "Settings",   () => Get.to(() => const SettingsScreen())),
              if (hasUser && settings?.liveChatStatus == 1)
                _menuRow(Icons.support_agent_outlined, "Support", () { Get.back(); openCrispChatView(); }),
              if (settings?.enableStaking == 1)
                _menuRow(Icons.punch_clock_outlined,   "Staking",    () => Get.to(() => const StakingScreen())),
              if (settings?.enableGiftCard == 1)
                _menuRow(Icons.card_giftcard_outlined, "Gift Cards", () => Get.to(() => const GiftCardsScreen())),
              if (settings?.navbar?["ico"]?.status == true)
                _menuRow(Icons.local_atm,              "ICO",        () => Get.to(() => const ICOScreen())),
              if (settings?.p2pModule == 1)
                _menuRow(Icons.people, "P2P", () {
                  TemporaryData.changingPageId = 1;
                  Get.back();
                  getRootController().changeBottomNavIndex(AppBottomNavKey.trade);
                }),
              if (settings?.blogNewsModule == 1)
                _menuRow(Icons.rss_feed_outlined,   "Blog", () => Get.to(() => const BlogScreen())),
              if (settings?.blogNewsModule == 1)
                _menuRow(Icons.newspaper_outlined,  "News", () => Get.to(() => const NewsScreen())),

              // ── LOGOUT ───────────────────────────────────────────────
              if (hasUser)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _divider, width: 1),
                        backgroundColor: _cardBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showLogOutAlert,
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ── SECTION HEADER — green label like Figma ──────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: _sectionClr,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: _dmSans,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── MENU ROW — icon + label + arrow ─────────────────────────────────────
  Widget _menuRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: _green.withOpacity(0.06),
      highlightColor: _green.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: _textWhite, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _textGrey, size: 18),
          ],
        ),
      ),
    );
  }

  // ── QUICK ICON BUTTON ────────────────────────────────────────────────────
  Widget _quickIcon(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _textWhite, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              fontFamily: _dmSans,
            ),
          ),
        ],
      ),
    );
  }

  // ── EMAIL MASK ───────────────────────────────────────────────────────────
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

  // ── LOGOUT ALERT — UNCHANGED ─────────────────────────────────────────────
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

  // ── BOTTOM SOCIAL — UNCHANGED ────────────────────────────────────────────
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