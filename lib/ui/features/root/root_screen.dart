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
import 'dart:ui';

// COLORS
const _green = Color(0xFFCCFF00);
const _drawerBg = Color(0xFF121212);
const _cardBg = Color(0xFF1E1E1E);
const _sectionClr = Color(0xFFCCFF00);
const _textWhite = Color(0xFFFFFFFF);
const _textGrey = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);
const _dmSans = 'DMSans';

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

  void changeBottomNavTab(int id) {
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

  // ✅ FIXED NAV BAR (NO OVERFLOW)
  Widget _getBottomNavigationBar() {
    navList = AppBottomNavHelper.getBottomNavList();

    return Container(
      height: 76,
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
      ),
      child: Row(
        children: List.generate(navList.length, (index) {
          final isSelected = _controller.bottomNavIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => changeBottomNavTab(navList[index].id),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(navList[index].imagePath),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      navList[index].name ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: _dmSans,
                        color: isSelected ? _green : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

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
        return const FutureTradeScreen();
      case AppBottomNavKey.wallet:
        return const WalletScreen();
      default:
        return Container();
    }
  }

  // ⚡ DRAWER (UNCHANGED)
  Drawer _getDrawerNew() {
    return Drawer(
      elevation: 0,
      width: context.width,
      backgroundColor: _drawerBg,
      child: SafeArea(
        child: Center(
          child: Text(
            "Drawer Working",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}