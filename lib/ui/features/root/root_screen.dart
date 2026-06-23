import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
// import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/history_sheet.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:tradexpro_flutter/data/models/settings.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/helper/bottom_nav_helper.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/home_dashboard_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/live_chat_screen.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../bottom_navigation/market/market_screen.dart';
import '../bottom_navigation/trades/future_trade/new_future_screen.dart';
import '../bottom_navigation/trades/trade_screen.dart';
import '../bottom_navigation/wallet/wallet_screen.dart';
import '../side_navigation/activity/activity_screen.dart';
// import '../side_navigation/blog/blog_screen.dart';
import '../side_navigation/faq/faq_page.dart';
// import '../side_navigation/fiat/fiat_screen.dart';
// import '../side_navigation/gift_cards/gift_cards_screen.dart';
// import '../side_navigation/news/news_screen.dart';
import '../side_navigation/profile/profile_screen.dart';
import '../side_navigation/referrals/referral_screen.dart';
import '../side_navigation/ib_program/ib_screen.dart';
// import '../side_navigation/settings/settings_screen.dart';
// import '../side_navigation/staking/staking_screen.dart';
import '../side_navigation/airdrop/airdrop_screen.dart';
import '../side_navigation/about/about_trapix_screen.dart';
import '../side_navigation/community/community_screen.dart';
import '../side_navigation/giveaway/giveaway_screen.dart';
import '../side_navigation/spin_win/spin_win_screen.dart';
import '../side_navigation/listing/listing_screen.dart';
import '../side_navigation/official_verification/official_verification_screen.dart';
import '../auth/sign_in/sign_in_screen.dart';
import '../auth/sign_up/sign_up_screen.dart';
import '../bottom_navigation/champion/champion_screen.dart';
import '../side_navigation/price_alerts/price_alerts_screen.dart';
import 'root_controller.dart';
import '../bottom_navigation/landing/banner_popup.dart';
import 'dart:ui';

// ── EXACT FIGMA COLORS ───────────────────────────────────────────────────────
const _green = Color(0xFFCCFF00); // EXACT Figma secondary #CCFF00
const _drawerBg = Color(0xFF121212); // near-black background
const _cardBg = Color(0xFF1E1E1E); // card / icon box background
const _sectionClr = Color(0xFFCCFF00); // section header color
const _textWhite = Color(0xFFFFFFFF);
const _textGrey = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);
const _dmSans = 'DMSans';
const _bgcolor = Color.fromARGB(255, 17, 17, 17); // DM Sans font family

class AppColors {
  static const Color primary = Color(0xFF111111); // --Primary
  static const Color secondary = Color(0xFF1A1A1A); // --Secondary
  static const Color textSecondary = Color(0xFFCCFF00); // textSecondary
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  final RootController _controller = Get.put(RootController());
  // Static flag — set to true once popup is shown this app session, never resets on rebuild
  static bool _popupShownThisSession = false;
  bool _showPopup = false;
  int _popupKey = 0;
  final autoSizeGroup = AutoSizeGroup();
  List<AppBottomNav> navList = AppBottomNavHelper.getBottomNavList();

  @override
  void initState() {
    currentContext = context;
    super.initState();
    _controller.changeBottomNavIndex = changeBottomNavTab;
    // Pre-fetch banners immediately so popup is fast when it mounts
    BannerPopup.prefetch();
    // Show popup only once per app session — static flag prevents re-showing on rebuild
    if (!_popupShownThisSession) {
      _popupShownThisSession = true;
      _showPopup = true;
    }
  }

  @override
  void dispose() {
    hideKeyboard();
    super.dispose();
    currentContext = null;
    Get.delete<RootController>();
  }

  void changeBottomNavTab(int id) async {
    setState(
      () => _controller.bottomNavIndex = AppBottomNavHelper.getNavIndex(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            extendBody: true,
            extendBodyBehindAppBar: true,
            drawerScrimColor: Colors.transparent,
            drawer: _getDrawerNew(),
            bottomNavigationBar: _getBottomNavigationBar(),
            body: SafeArea(top: false, child: Obx(() => _getBody())),
          ),
          if (_showPopup)
            Positioned.fill(
              child: BannerPopup(
                key: ValueKey(_popupKey),
                onClose: () => setState(() => _showPopup = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getBottomNavigationBar() {
    navList = AppBottomNavHelper.getBottomNavList();

    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        margin: EdgeInsets.zero,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navList.length, (index) {
            final isSelected = _controller.bottomNavIndex == index;

            return GestureDetector(
              onTap: () => changeBottomNavTab(navList[index].id),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Image.asset(navList[index].imagePath),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      navList[index].name ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: "DMSans",
                        height: 1.33,
                        color: isSelected
                            ? const Color(0xFFCCFF00)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── BODY — UNCHANGED ────────────────────────────────────────────────────
  Widget _getBody() {
    final id = navList[_controller.bottomNavIndex].id;
    final bool isLoggedIn = gUserRx.value.id > 0;
    switch (id) {
      case AppBottomNavKey.home:
        return isLoggedIn ? const HomeDashboardScreen() : const LandingScreen();
      case AppBottomNavKey.market:
        return const MarketScreen();
      case AppBottomNavKey.trade:
        return const TradesScreen();
      case AppBottomNavKey.future:
        return const NewFutureScreen();
      case AppBottomNavKey.wallet:
        return const WalletScreen();
      default:
        return Container();
    }
  }

  // ── FIGMA DRAWER ─────────────────────────────────────────────────────────
  Drawer _getDrawerNew() {
    return Drawer(
      elevation: 0,
      width: context.width,
      backgroundColor: AppColors.primary,

      ///background: var(--Primary, rgba(17, 17, 17, 1));
      child: SafeArea(
        child: Obx(() {
          final hasUser = gUserRx.value.id > 0;
          final user = gUserRx.value;
          final settings = getSettingsLocal();

          return ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              // ── TOP BAR: ← bell settings ────────────────────────────
              Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: _textWhite,
                            size: 25,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/icons/light.png', // apna path
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                      if (hasUser) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Get.to(() => const ProfileScreen(initialTab: 2)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              'assets/icons/setting.png',
                              height: 20,
                              width: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── PROFILE ROW (logged in) / WELCOME (logged out) ───────
              if (hasUser)
                GestureDetector(
                  onTap: () => Get.to(() => const ProfileScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    color: Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        VerificationAvatar(user: user, size: 50),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                getName(user.firstName, user.lastName),
                                maxLines: 1,
                                minFontSize: 12,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _textWhite, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: _dmSans, letterSpacing: 0),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _maskEmail(user.email ?? ""),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _textWhite, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dmSans),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text("UID: ${user.id}", style: const TextStyle(color: _textWhite, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dmSans)),
                                  const SizedBox(width: 5),
                                  Image.asset('assets/icons/uid.png', height: 14, width: 13),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: _green, size: 30),
                      ],
                    ),
                  ),
                )
              else
                // ── WELCOME SECTION (logout) ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const ShapeDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: OvalBorder(side: BorderSide(width: 1, color: Colors.white)),
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Image.asset(
                                'assets/images/icon.png',
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, st) => const Icon(Icons.currency_exchange, size: 26),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Welcome to Trapix',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 30, fontFamily: _dmSans, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () { Get.back(); Get.offAll(() => const SignInPage()); },
                              child: Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _green, width: 1),
                                ),
                                child: const Text('Sign In', textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: _dmSans, fontWeight: FontWeight.w400, height: 1.50)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () { Get.back(); Get.offAll(() => const SignUpScreen()); },
                              child: Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
                                child: const Text('Sign Up', textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF111111), fontSize: 16, fontFamily: _dmSans, fontWeight: FontWeight.w400, height: 1.50)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20,),

              // ── SPIN + REFER BANNERS ──────────────────────────────────
              Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Spin to Earn
                      Expanded(
                        child: GestureDetector(
                          onTap: () => hasUser ? Get.to(() => const SpinWinScreen()) : Get.offAll(() => const SignInPage()),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 4,
                                sigmaY: 4,
                              ), // blur 4px
                              child: Container(
                                height: 80,
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  8,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1A1A1A),
                                      Color(0xFF6B6B6B),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: _dmSans,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: "Spin ",
                                              style: TextStyle(
                                                color: _green,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "to ",
                                              style: TextStyle(
                                                color: _textWhite,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "Earn\n",
                                              style: TextStyle(
                                                color: _green,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "Rewards",
                                              style: TextStyle(
                                                color: _textWhite,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    RotatingSpinner(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Refer and Earn
                      AnimatedReferralCard(hasUser: hasUser)
                    ],
                  ),
                ),
              ),
               const SizedBox(height: 20),

              // ── QUICK ICON ROW (only when logged in) ──────────────────
              if (hasUser)
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickIcon('assets/icons/profilechampion.png', "Champion",
                        () => Get.to(() => const ChampionScreen())),
                    _quickIcon('assets/icons/profilehistory.png', "History",
                        () => showHistorySheet()),
                    _quickIcon('assets/icons/profilesecurity.png', "Security",
                        () => Get.to(() => const ProfileScreen(initialTab: 1))),
                    _quickIcon('assets/icons/profilekyc.png', "KYC",
                        () => Get.to(() => const ProfileScreen(initialTab: 3))),
                    _quickIcon('assets/icons/profileprice.png', "Price Alert",
                        () => Get.to(() => const PriceAlertsScreen())),
                  ],
                ),
              ),

              ///-------------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // ── GET HELP ──────────────────────────────────────────────
                    _sectionHeader("Get help"),
                    _menuRow("assets/icons/help.png", "Help & Support", () {
                      Get.back();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveChatScreen()));
                    }),
                    _menuRow("assets/icons/fee.png", "Fee structure", () {}),
                    _menuRow("assets/icons/app.png", "App feedback", () {}),
                    _menuRow(
                      "assets/icons/faq.png",
                      "FAQ",
                      () => Get.to(() => const FAQPage()),
                    ),

                    // ── FEATURES ─────────────────────────────────────────────
                    _sectionHeader("Features"),
                    _menuRow(
                      "assets/icons/official.png",
                      "Official Verification",
                      () => hasUser ? Get.to(() => const OfficialVerificationScreen()) : Get.offAll(() => const SignInPage()),
                    ),
                    _menuRow(
                      "assets/icons/airdrop.png",
                      "Airdrop Campaign",
                      () => hasUser ? Get.to(() => const AirdropScreen()) : Get.offAll(() => const SignInPage()),
                    ),
                    _menuRow(
                      "assets/icons/listing.png",
                      "Listing",
                      () => hasUser ? Get.to(() => const ListingScreen()) : Get.offAll(() => const SignInPage()),
                    ),

                    // ── REWARDS ──────────────────────────────────────────────
                    _sectionHeader("Rewards"),
                    _menuRow(
                      "assets/images/giveaway.png",
                      "Giveaways",
                      () => hasUser ? Get.to(() => const GiveawayScreen()) : Get.offAll(() => const SignInPage()),
                    ),
                    _menuRow(
                      "assets/icons/refer_earn.png",
                      "Referral",
                      () => hasUser ? Get.to(() => const ReferralScreen()) : Get.offAll(() => const SignInPage()),
                    ),
                    _menuRow(
                      "assets/icons/spin.png",
                      "Spin & Win",
                      () => hasUser ? Get.to(() => const SpinWinScreen()) : Get.offAll(() => const SignInPage()),
                    ),
                     _menuRow(
                      "assets/icons/ib.png",
                      "IB Program",
                      () => hasUser
                          ? Get.to(() => const IBScreen())
                          : Get.offAll(() => const SignInPage()),
                    ),

                    // ── ABOUT US ─────────────────────────────────────────────
                    _sectionHeader("About us"),
                    _menuRow(
                      "assets/icons/trapix.png",
                      "Trapix Transparency Center",
                      () {},
                    ),
                    _menuRow("assets/icons/about.png", "About Trapix", () => Get.to(() => const AboutTrapixScreen())),
                    _menuRow("assets/icons/api.png", "API Setting", () {}),
                    _menuRow("assets/images/community.png", "Community", () => Get.to(() => const CommunityScreen())),

                    // ── ORIGINAL MENUS — KEPT EXACTLY ────────────────────────
                    // if (hasUser)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "Reports",
                    //     () { Navigator.of(context).pop(); Future.delayed(const Duration(milliseconds: 300), () => showHistorySheet()); },
                    //   ),
                    // if (hasUser)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "Fiat",
                    //     () => Get.to(() => const FiatScreen()),
                    //   ),
                    // if (hasUser)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "Settings",
                    //     () => Get.to(() => const SettingsScreen()),
                    //   ),
                    if (hasUser && settings?.liveChatStatus == 1)
                      _menuRow("assets/icons/help.png", "Support", () {
                        Get.back();
                        openCrispChatView();
                      }),
                    // if (settings?.enableStaking == 1)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "Staking",
                    //     () => Get.to(() => const StakingScreen()),
                    //   ),
                    // if (settings?.enableGiftCard == 1)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "Gift Cards",
                    //     () => Get.to(() => const GiftCardsScreen()),
                    //   ),
                    // if (settings?.navbar?["ico"]?.status == true)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "ICO",
                    //     () => Get.to(() => const ICOScreen()),
                    //   ),
                    // if (settings?.p2pModule == 1)
                    //   _menuRow("assets/icons/help.png", "P2P", () {
                    //     TemporaryData.changingPageId = 1;
                    //     Get.back();
                    //     getRootController().changeBottomNavIndex(
                    //       AppBottomNavKey.trade,
                    //     );
                    //   }),
                    // if (settings?.blogNewsModule == 1)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "Blog",
                    //     () => Get.to(() => const BlogScreen()),
                    //   ),
                    // if (settings?.blogNewsModule == 1)
                    //   _menuRow(
                    //     "assets/icons/help.png",
                    //     "News",
                    //     () => Get.to(() => const NewsScreen()),
                    //   ),

                    // ── LOGOUT ───────────────────────────────────────────────
                    if (hasUser)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0, // flat look
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _showLogOutAlert,
                            child: const Text(
                              "Logout",
                              style: TextStyle(
                                color: _textWhite,
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
            ],
          );
        }),
      ),
    );
  }

  // ── SECTION HEADER — green label like Figma ──────────────────────────────
  Widget _sectionHeader(String title) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: _dmSans,
          height: 1.25,
        ),
      ),
    );
  }


  Widget _menuRow(String iconPath, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: _green.withOpacity(0.06),
      highlightColor: _green.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            Image.asset(
              iconPath, // 👈 asset icon
              width: 20, // 👈 size control
              height: 20,
              // optional tint
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _green, size: 25),
          ],
        ),
      ),
    );
  }

  // ── QUICK ICON BUTTON ────────────────────────────────────────────────────
  Widget _quickIcon(String iconPath, String label, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Column(
        children: [
          Container(width: 50, height: 50, child: Image.asset(iconPath)),
          Text(
            label,
            style: const TextStyle(
              color: _textWhite,
              fontSize: 12,
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
    final masked = name.length > 6
        ? "${name.substring(0, 4)}***${name.substring(name.length - 2)}"
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
                      onPressCallback: () =>
                          openUrlInBrowser(item.mediaLink ?? ""),
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

class RotatingSpinner extends StatefulWidget {
  const RotatingSpinner({super.key});

  @override
  State<RotatingSpinner> createState() => _RotatingSpinnerState();
}

class _RotatingSpinnerState extends State<RotatingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // continuous rotate
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 50,
        height: 50,
        child: Image.asset('assets/icons/spinner.png', fit: BoxFit.contain),
      ),
    );
  }
}


class AnimatedReferralCard extends StatefulWidget {
  final bool hasUser;

  const AnimatedReferralCard({
    super.key,
    required this.hasUser,
  });

  @override
  State<AnimatedReferralCard> createState() =>
      _AnimatedReferralCardState();
}

class _AnimatedReferralCardState
    extends State<AnimatedReferralCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.hasUser
            ? Get.to(() => const ReferralScreen())
            : Get.offAll(() => const SignInPage()),

        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final color1 = Color.lerp(
              const Color(0xFF1A1A1A),
              const Color(0xFF6B6B6B),
              _controller.value,
            )!;

            final color2 = Color.lerp(
              const Color(0xFF6B6B6B),
              const Color(0xFF1A1A1A),
              _controller.value,
            )!;

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),

              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 4,
                  sigmaY: 4,
                ),

                child: Container(
                  height: 80,
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    10,
                    8,
                    10,
                  ),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),

                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color1,
                        color2,
                      ],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: _dmSans,
                            ),
                            children: [
                              TextSpan(
                                text: "Refer ",
                                style: TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: "and ",
                                style: TextStyle(
                                  color: _textWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: "Earn\n",
                                style: TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: "Rewards",
                                style: TextStyle(
                                  color: _textWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 50,
                        width: 26,
                        child: Image.asset(
                          'assets/icons/refer.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Verification Progress Avatar ─────────────────────────────────────────────
class VerificationAvatar extends StatefulWidget {
  final dynamic user;
  final double size;
  const VerificationAvatar({super.key, required this.user, this.size = 50});

  @override
  State<VerificationAvatar> createState() => _VerificationAvatarState();
}

class _VerificationAvatarState extends State<VerificationAvatar> {
  bool _kycApproved = false;

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  void _loadKycStatus() {
    APIRepository().getUserKYCSettingsDetails().then((resp) {
      if (!mounted || !resp.success) return;
      try {
        final settings = KycSettings.fromJson(resp.data);
        final kd = settings.enabledKycUserDetails;
        bool approved = false;
        if (kd is KycDetails) {
          approved = [kd.nid, kd.passport, kd.driving, kd.voter].any((k) {
            final s = k?.status?.toLowerCase() ?? '';
            return s == 'approved' || s == '1';
          });
        } else if (kd is EnabledKycUserDetails) {
          approved = (kd.persona?.isVerified ?? 0) == 1;
        }
        setState(() => _kycApproved = approved);
      } catch (_) {}
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final phoneDone = (widget.user.phoneVerified ?? 0) == 1;
    final emailDone = (widget.user.isVerified ?? 0) == 1;
    final kycDone = _kycApproved;

    final steps = [phoneDone, emailDone, kycDone];
    final doneCount = steps.where((v) => v).length;
    final allDone = doneCount == steps.length;
    final percent = (doneCount / steps.length * 100).round();
    const pi = 3.14159265;
    const fullSweep = 2 * pi;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size + 14,
          height: widget.size + 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              SizedBox(
                width: widget.size + 14,
                height: widget.size + 14,
                child: const CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 3,
                  color: Color(0xFF2A2A2A),
                ),
              ),
              // Filled arc — continuous from top, clockwise, proportional to done steps
              SizedBox(
                width: widget.size + 14,
                height: widget.size + 14,
                child: CustomPaint(
                  painter: _ArcPainter(
                    startAngle: -pi / 2,
                    sweepAngle: fullSweep * doneCount / steps.length,
                    color: allDone ? const Color(0xFF22C55E) : const Color(0xFFCCFF00),
                    strokeWidth: 3,
                  ),
                ),
              ),
              // Avatar
              ClipOval(
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: showCircleAvatar(widget.user.photo, size: widget.size),
                ),
              ),
              // % badge at bottom
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Color(0xFFCCFF00),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: allDone
                ? const Color(0xFF015629).withValues(alpha: 0.4)
                : const Color(0xFF5A1A1A).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            allDone ? 'Verified' : 'Not Verified',
            style: TextStyle(
              color: allDone ? const Color(0xFF00FF4D) : const Color(0xFFFF4D4D),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final double strokeWidth;
  const _ArcPainter({required this.startAngle, required this.sweepAngle, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.startAngle != startAngle || old.sweepAngle != sweepAngle || old.color != color;
}