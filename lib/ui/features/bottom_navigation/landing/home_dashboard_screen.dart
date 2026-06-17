import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/live_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_market_view.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/discover_feed.dart';
import 'package:tradexpro_flutter/ui/features/notifications/notifications_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/announcement_view.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/card_container/home_grid_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/card_container/more_card_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_overview_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_widgets.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transfer_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/spin_win/spin_win_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/referrals/referral_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/profile/profile_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/earn_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/airdrop/airdrop_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/swap/swap_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/champion_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/root/root_controller.dart';
import 'package:tradexpro_flutter/helper/bottom_nav_helper.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/earn_controller.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/earn_recommended_section.dart';
import 'dart:ui';

const _green = Color(0xFFB5F000);
const _bgcolor = Color.fromARGB(255, 17, 17, 17);

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with SingleTickerProviderStateMixin {
  final LandingController _controller = Get.find<LandingController>();
  final HomeGridController _gridController = Get.put(HomeGridController());
  final EarnController _earnController = Get.isRegistered<EarnController>()
      ? Get.find<EarnController>()
      : Get.put(EarnController());
  late AnimationController _rotationController;
  late final WalletController _walletController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    if (_controller.landingData.value.announcementList == null ||
        _controller.landingData.value.announcementList!.isEmpty) {
      _controller.getLandingSettings();
    }

    _walletController = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : Get.put(WalletController());
    _walletController.fetchGrandTotal();
    if (_earnController.products.isEmpty) _earnController.fetchProducts();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _openEarnScreen() {
    final hasUser = gUserRx.value.id > 0;
    if (hasUser) {
      if (!Get.isRegistered<WalletController>()) {
        Get.put(WalletController());
      }
      Get.to(() => const WalletDetailScreen(initialType: WalletViewType.earn));
    } else {
      Get.to(() => const SignInPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgcolor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(0),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide.none,
                    left: BorderSide.none,
                    right: BorderSide.none,
                    bottom: BorderSide(color: Colors.white38, width: 0.5),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -55,
                      left: 143,
                      width: 496,
                      height: 496,
                      child: IgnorePointer(
                        ignoring: true,
                        child: RotationTransition(
                          turns: _rotationController,
                          child: Image.asset(
                            'assets/images/circle.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top,
                              bottom: 10,
                              left: 10,
                              right: 10,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      Scaffold.of(context).openDrawer(),
                                  child: Image.asset(
                                    'assets/images/icon.png',
                                    height: 30,
                                    width: 30,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.currency_bitcoin,
                                      color: Colors.orange,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        25,
                                        24,
                                        24,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.local_fire_department,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          "BTC/USDT",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(
                                          Icons.search,
                                          color: _green,
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LiveChatScreen()),
                                  ),
                                  child: const Icon(
                                    Icons.headphones,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    _createRoute(const NotificationsPage()),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Text(
                                "Total Asset",
                                style: TextStyle(
                                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "DMSans",
                                  fontSize: 16,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  GetStorage().write(
                                    PreferenceKey.isBalanceHide,
                                    !gIsBalanceHide.value,
                                  );
                                  gIsBalanceHide.value = !gIsBalanceHide.value;
                                },
                                child: Obx(
                                  () => Icon(
                                    gIsBalanceHide.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.remove_red_eye_outlined,
                                    color: const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.5),
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Obx(() {
                            final hide = gIsBalanceHide.value;
                            final balance =
                                _walletController.totalBalance.value;
                            if (hide) {
                              return const Text(
                                "******",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 20,
                                  fontFamily: "DMSans",
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Amount + USDT inline
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "\$ ${currencyFormat(balance.total)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 30,
                                        fontFamily: "DMSans",
                                        height: 1.33,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "USDT",
                                      style: TextStyle(
                                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                                        fontSize: 15,
                                        height: 1.33,
                                        fontFamily: "DMSans",
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // ≈ same price repeated below (Figma)
                                Text(
                                  "≈ \$${currencyFormat(balance.total)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                    height: 1.33,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Today's PNL
                                if (balance.todayPnl != null)
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: "Today's PNL ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: "DMSans",
                                            height: 1.33,
                                          ),
                                        ),
                                        TextSpan(
                                          text: formatPnl(balance.todayPnl, balance.todayPnlPercent),
                                          style: TextStyle(
                                            color: (balance.todayPnl ?? 0) >= 0
                                                ? const Color(0xFF4ED78E)
                                                : Colors.redAccent,
                                            fontSize: 12,
                                            fontFamily: "DMSans",
                                            fontWeight: FontWeight.w400,
                                            height: 1.33,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }),
                          const SizedBox(height: 0),
                          Obx(() {
                            List<Map<String, dynamic>> userItems =
                                _gridController.selectedIcons.isNotEmpty
                                ? _gridController.selectedIcons
                                      .cast<Map<String, dynamic>>()
                                : [
                                    {
                                      "image": "assets/images/deposit.png",
                                      "title": "Deposit",
                                    },
                                    {
                                      "image": "assets/images/champion.png",
                                      "title": "Champion",
                                    },
                                    {
                                      "image": "assets/images/swap.png",
                                      "title": "Swap",
                                    },
                                    {
                                      "image": "assets/images/earn.png",
                                      "title": "Earn",
                                    },
                                    {
                                      "image": "assets/images/buy.png",
                                      "title": "Buy",
                                    },
                                    {
                                      "image": "assets/images/future.png",
                                      "title": "Future",
                                    },
                                    {
                                      "image": "assets/images/transfer.png",
                                      "title": "Transfer",
                                    },
                                    {
                                      "image": "assets/images/spot.png",
                                      "title": "Spot",
                                    },
                                    {
                                      "image": "assets/images/funds.png",
                                      "title": "Funds",
                                    },
                                  ];

                            List<Map<String, dynamic>> finalGridItems = [];
                            for (var item in userItems) {
                              finalGridItems.add({
                                "image": item['image'],
                                "title": item['title'],
                                "onTap": () =>
                                    _navigateTo(context, item['title']),
                              });
                            }
                            finalGridItems.add({
                              "image": "assets/images/more.png",
                              "title": "More",
                              "onTap": () => Navigator.push(
                                context,
                                _createRoute(const MoreCardScreen()),
                              ),
                            });

                            return GridView.count(
                              crossAxisCount: 5,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              childAspectRatio: 0.85,
                              children: List.generate(finalGridItems.length, (
                                index,
                              ) {
                                final item = finalGridItems[index];
                                return _buildGridItem(
                                  item['image'] as String,
                                  item['title'] as String,
                                  onTap: item['onTap'] as VoidCallback,
                                );
                              }),
                            );
                          }),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => showAddFundsSheet(context),
                                  child: const Text(
                                    "Add Funds",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      fontFamily: "DMSans",
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      25,
                                      24,
                                      24,
                                    ),
                                    overlayColor: Colors.transparent,
                                    splashFactory: NoSplash.splashFactory,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => Get.to(() => WalletCryptoDepositScreen()),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "assets/images/deposit.png",
                                        height: 25,
                                        width: 25,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Deposit Crypto",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontFamily: "DMSans",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Obx(() {
              final lData = _controller.landingData.value;
              if (lData.announcementList != null &&
                  lData.announcementList!.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up, color: _green, size: 20),
                      const SizedBox(width: 1),
                      Expanded(
                        child: AnnouncementView(
                          announcementList: lData.announcementList!,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox();
              }
            }),

            const SizedBox(height: 10),

            Container(
              width: 362,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage("assets/images/frame.png"),
                  fit: BoxFit.cover,
                ),
                color: const Color(0XFF1A1A1A),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Image.asset("assets/images/gift.png", height: 30, width: 30),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Build Your Trading Empire & Claim",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            fontFamily: "DMSans",
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              "30%",
                              style: TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontFamily: "DMSans",
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Text(
                              "Lifetime Rewards!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bgcolor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: -10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.white24,
                            width: 0.5,
                          ),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Join Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),
            GestureDetector(
              child: Container(
                width: 382,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF111111)),
                child: Row(
                  children: [
                    AutoSliderCard(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() {
                        final Map<String, EarnProduct> best = {};
                        for (final p in _earnController.products) {
                          if (!best.containsKey(p.coin) ||
                              p.apr > best[p.coin]!.apr)
                            best[p.coin] = p;
                        }
                        final top2 =
                            (best.values.toList()
                                  ..sort((a, b) => b.apr.compareTo(a.apr)))
                                .take(2)
                                .toList();
                        return Column(
                          children: [
                            _buildSmallBox(
                              iconUrl: top2.isNotEmpty
                                  ? top2[0].coinIcon
                                  : null,
                              title: top2.isNotEmpty ? top2[0].coin : '---',
                              value: top2.isNotEmpty
                                  ? '${top2[0].apr.toStringAsFixed(2)}%'
                                  : '--',
                            ),
                            const SizedBox(height: 10),
                            _buildSmallBox(
                              iconUrl: top2.length > 1
                                  ? top2[1].coinIcon
                                  : null,
                              title: top2.length > 1 ? top2[1].coin : '---',
                              value: top2.length > 1
                                  ? '${top2[1].apr.toStringAsFixed(2)}%'
                                  : '--',
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const LandingMarketView(),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "    Earn",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "DMSans",
                ),
              ),
            ),
            const SizedBox(height: 5),

            const EarnRecommendedSection(),

            DiscoverTabsWidget(),

            Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String imagePath, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF111111).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              imagePath,
              height: 25,
              width: 25,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.broken_image, size: 20, color: Colors.grey),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w300,
              fontFamily: "DMSans",
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBox({
    String? icon,
    String? iconUrl,
    required String title,
    required String value,
  }) {
    Widget coinImg;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      coinImg = ClipOval(
        child: Image.network(
          iconUrl,
          height: 25,
          width: 25,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.monetization_on, color: _green, size: 22),
        ),
      );
    } else if (icon != null && icon.isNotEmpty) {
      coinImg = Image.asset(
        icon,
        height: 25,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.monetization_on, color: _green, size: 22),
      );
    } else {
      coinImg = const Icon(Icons.monetization_on, color: _green, size: 22);
    }
    return GestureDetector(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0XFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                coinImg,
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    fontFamily: "DMSans",
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Easy Earn | Flexible",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 16 / 12,
              ),
            ),
            const SizedBox(height: 5),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF00B2E3),
                  Color(0xFFFFA600),
                  Color(0xFFF03A89),
                ],
                stops: [0.0, 0.53, 1.0],
              ).createShader(bounds),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: "DMSans",
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    switch (route) {
      case "Earn":
        _openEarnScreen();
        break;
      case "Deposit":
        Get.to(() => WalletCryptoDepositScreen());
        break;
      case "Champion":
        Get.to(() => const ChampionScreen());
        break;
      case "Swap":
        Get.to(() => const SwapScreen());
        break;
      case "Buy":
        break;
      case "Future":
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.future);
        break;
      case "Transfer":
        Get.to(() => const TransferScreen());
        break;
      case "Spot":
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.trade);
        break;
      case "Spin":
        Get.to(() => const SpinWinScreen());
        break;
      case "Referals":
        Get.to(() => const ReferralScreen());
        break;
      case "KYC":
        Get.to(() => const ProfileScreen(initialTab: 3));
        break;
      case "Easy Earn":
        Get.to(() => const EarnScreen(initialTab: 1));
        break;
      case "Airdrop":
        Get.to(() => const AirdropScreen());
        break;
      case "Funds":
        break;
      case "More":
        Navigator.push(context, _createRoute(const MoreCardScreen()));
        break;
      default:
        break;
    }
  }
}

class AutoSliderCard extends StatefulWidget {
  const AutoSliderCard({super.key});

  @override
  State<AutoSliderCard> createState() => _AutoSliderCardState();
}

class _AutoSliderCardState extends State<AutoSliderCard> {
  final PageController _pageController = PageController();

  final List<String> images = [
    "assets/images/poster1.png",
    "assets/images/poster2.png",
    "assets/images/poster3.png",
    "assets/images/poster4.png",
  ];

  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), autoScroll);
  }

  void autoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      currentPage++;

      if (currentPage >= images.length) {
        currentPage = 0;
      }

      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0XFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Image.asset(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
      ),
    );
  }
}
