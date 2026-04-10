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
import 'root_controller.dart';
import 'root_widgets.dart';

const _green = Color(0xFFB5F000);

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

  Drawer _getDrawerNew() {
    return Drawer(
      elevation: 0,
      width: context.width * 0.9,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Obx(() {
          final hasUser = gUserRx.value.id > 0;
          return ListView(
            padding: const EdgeInsets.only(top: Dimens.paddingMainViewTop),
            shrinkWrap: true,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: buttonOnlyIcon(
                  iconData: Icons.arrow_back,
                  iconColor: context.theme.primaryColor,
                  onPress: () => Get.back(),
                ),
              ),
              vSpacer20(),
              DrawerProfileView(user: gUserRx.value),
              vSpacer10(),
              DrawerReferralView(hasUser: hasUser),
              vSpacer20(),
              _drawerMenusView(hasUser),
            ],
          );
        }),
      ),
    );
  }

  Column _drawerMenusView(bool hasUser) {
    final settings = getSettingsLocal();
    return Column(
      children: [
        if (hasUser)
          DrawerMenuItemView(
            navTitle: 'Reports'.tr,
            icon: Icons.history,
            navAction: () => Get.to(() => const ActivityScreen()),
          ),
        if (hasUser)
          DrawerMenuItemView(
            navTitle: 'Fiat'.tr,
            icon: Icons.paid_outlined,
            navAction: () => Get.to(() => const FiatScreen()),
          ),
        if (hasUser)
          DrawerMenuItemView(
            navTitle: 'Settings'.tr,
            icon: Icons.settings_outlined,
            navAction: () => Get.to(() => const SettingsScreen()),
          ),
        if (hasUser && settings?.liveChatStatus == 1)
          DrawerMenuItemView(
            navTitle: 'Support'.tr,
            icon: Icons.support_agent_outlined,
            navAction: () {
              Get.back();
              openCrispChatView();
            },
          ),
        if (settings?.enableStaking == 1)
          DrawerMenuItemView(
            navTitle: 'Staking'.tr,
            icon: Icons.punch_clock_outlined,
            navAction: () => Get.to(() => const StakingScreen()),
          ),
        if (settings?.enableGiftCard == 1)
          DrawerMenuItemView(
            navTitle: 'Gift Cards'.tr,
            icon: Icons.card_giftcard_outlined,
            navAction: () => Get.to(() => const GiftCardsScreen()),
          ),
        if (settings?.navbar?["ico"]?.status == true)
          DrawerMenuItemView(
            navTitle: 'ICO'.tr,
            icon: Icons.local_atm,
            navAction: () => Get.to(() => const ICOScreen()),
          ),
        if (settings?.p2pModule == 1)
          DrawerMenuItemView(
            navTitle: "P2P".tr,
            icon: Icons.people,
            navAction: () {
              TemporaryData.changingPageId = 1;
              Get.back();
              getRootController().changeBottomNavIndex(AppBottomNavKey.trade);
            },
          ),
        if (settings?.blogNewsModule == 1)
          DrawerMenuItemView(
            navTitle: 'Blog'.tr,
            icon: Icons.rss_feed_outlined,
            navAction: () => Get.to(() => const BlogScreen()),
          ),
        if (settings?.blogNewsModule == 1)
          DrawerMenuItemView(
            navTitle: 'News'.tr,
            icon: Icons.newspaper_outlined,
            navAction: () => Get.to(() => const NewsScreen()),
          ),
        DrawerMenuItemView(
          navTitle: 'FAQ'.tr,
          icon: Icons.help_outline,
          navAction: () => Get.to(() => const FAQPage()),
        ),
        if (hasUser)
          DrawerMenuItemView(
            navTitle: 'Log out'.tr,
            icon: Icons.logout_outlined,
            navAction: () => _showLogOutAlert(),
          ),
        _bottomView(settings),
      ],
    );
  }

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