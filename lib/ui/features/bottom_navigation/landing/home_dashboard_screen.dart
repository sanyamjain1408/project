import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_market_view.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_screen.dart';
import 'package:tradexpro_flutter/ui/features/notifications/notifications_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/announcement_view.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/card_container/home_grid_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/card_container/more_card_screen.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/earn_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart'; // ✅ FIXED
import 'package:tradexpro_flutter/data/local/constants.dart';
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
  late AnimationController _rotationController;

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
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    if (_controller.landingData.value.announcementList == null ||
        _controller.landingData.value.announcementList!.isEmpty) {
      _controller.getLandingSettings();
    }
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
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _openEarnScreen() {
    final hasUser = gUserRx.value.id > 0;
    if (hasUser) {
      Get.to(() => const EarnScreen());
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                  onTap: () => Scaffold.of(context).openDrawer(),
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
                                      color: const Color.fromARGB(255, 25, 24, 24),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(width: 10),
                                        Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                                        SizedBox(width: 5),
                                        Text("BTC/USDT", style: TextStyle(color: Colors.white, fontSize: 14)),
                                        Spacer(),
                                        Icon(Icons.search, color: _green, size: 18),
                                        SizedBox(width: 10),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.headphones, color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, _createRoute(const NotificationsPage())),
                                  child: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "Total Assets",
                                style: TextStyle(
                                  color: const Color(0xFFFFFFFF).withOpacity(0.5),
                                  fontWeight: FontWeight.normal,
                                  fontFamily: "DMSans",
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: const Color(0xFFFFFFFF).withOpacity(0.5),
                                size: 15,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "\$10,546.40",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 30,
                                  fontFamily: "DMSans",
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "USDT",
                                  style: TextStyle(
                                    color: const Color(0xFFFFFFFF).withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Text(
                                "Today's PNL",
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w300, fontFamily: "DMSans"),
                              ),
                              SizedBox(width: 10),
                              Text("+14.51 (1.16%)", style: TextStyle(color: _green)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Obx(() {
                            List<Map<String, dynamic>> userItems =
                                _gridController.selectedIcons.isNotEmpty
                                    ? _gridController.selectedIcons.cast<Map<String, dynamic>>()
                                    : [
                                        {"image": "assets/images/deposit.png",  "title": "Deposit"},
                                        {"image": "assets/images/champion.png", "title": "Champion"},
                                        {"image": "assets/images/swap.png",     "title": "Swap"},
                                        {"image": "assets/images/earn.png",     "title": "Earn"},
                                        {"image": "assets/images/buy.png",      "title": "Buy"},
                                        {"image": "assets/images/future.png",   "title": "Future"},
                                        {"image": "assets/images/transfer.png", "title": "Transfer"},
                                        {"image": "assets/images/spot.png",     "title": "Spot"},
                                        {"image": "assets/images/funds.png",    "title": "Funds"},
                                      ];

                            List<Map<String, dynamic>> finalGridItems = [];
                            for (var item in userItems) {
                              finalGridItems.add({
                                "image": item['image'],
                                "title": item['title'],
                                "onTap": () => _navigateTo(context, item['title']),
                              });
                            }
                            finalGridItems.add({
                              "image": "assets/images/more.png",
                              "title": "More",
                              "onTap": () => Navigator.push(context, _createRoute(const MoreCardScreen())),
                            });

                            return GridView.count(
                              crossAxisCount: 5,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              children: List.generate(finalGridItems.length, (index) {
                                final item = finalGridItems[index];
                                return _buildGridItem(
                                  item['image'] as String,
                                  item['title'] as String,
                                  onTap: item['onTap'] as VoidCallback,
                                );
                              }),
                            );
                          }),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    "Add Funds",
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 12, fontFamily: "DMSans"),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 25, 24, 24),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {},
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/images/deposit.png", height: 25, width: 25),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Deposit Crypto",
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: "DMSans"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
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
              if (lData.announcementList != null && lData.announcementList!.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up, color: _green, size: 20),
                      const SizedBox(width: 1),
                      Expanded(child: AnnouncementView(announcementList: lData.announcementList!)),
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
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w300, fontFamily: "DMSans"),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text("30%", style: TextStyle(color: _green, fontSize: 12, fontFamily: "DMSans", fontWeight: FontWeight.w700)),
                            SizedBox(width: 3),
                            Text("Lifetime Rewards!", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w300, fontFamily: "DMSans")),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: -10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white24, width: 0.5),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text("Join Now", style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: "DMSans", fontWeight: FontWeight.w400)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            GestureDetector(
              onTap: _openEarnScreen,
              child: Container(
                width: 382,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bgcolor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 210,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0XFF1A1A1A),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset("assets/images/usdt.png", height: 30),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("USDT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("Simple Earn", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Image.asset("assets/images/img.png", height: 65, fit: BoxFit.cover),
                            const SizedBox(height: 10),
                            const Text("Highest APR", style: TextStyle(color: Colors.grey, fontSize: 15)),
                            const SizedBox(height: 5),
                            const Text("2.8%", style: TextStyle(color: _green, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "DMSans")),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          _buildSmallBox(icon: "assets/images/btc.png", title: "BTC", value: "200%"),
                          const SizedBox(height: 10),
                          _buildSmallBox(icon: "assets/images/ltc.png", title: "LTC", value: "200%"),
                        ],
                      ),
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
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "DMSans"),
              ),
            ),
            const SizedBox(height: 5),

            _buildEarnCards(),

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
              color: const Color(0xFF111111).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              imagePath,
              height: 25,
              width: 25,
              errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w300, fontFamily: "DMSans"),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBox({required String icon, required String title, required String value}) {
    return GestureDetector(
      onTap: _openEarnScreen,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0XFF1A1A1A),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(icon, height: 25),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 14),
            const Text("Simple Earn", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            Text(value, style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem({
    required String percent,
    required String name,
    required String icon,
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: _openEarnScreen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            width: 230,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0XFF1A1A1A),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Earn up to", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
                            child: Text(
                              percent,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text("/ year", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(name, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                Center(child: Image.asset(icon, height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarnCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.transparent,
      child: SizedBox(
        height: 110,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCardItem(percent: "26.78%", name: "Ravencoin", icon: "assets/images/cardo.png", colors: [Colors.blue, Colors.orange]),
            _buildCardItem(percent: "17.28%", name: "Ponke",     icon: "assets/images/cardt.png", colors: [Colors.green, Colors.purple]),
            _buildCardItem(percent: "9.56%",  name: "Tellor",    icon: "assets/images/cardt.png", colors: [Colors.teal, Colors.purple]),
            _buildCardItem(percent: "15.47%", name: "ether.fi",  icon: "assets/images/cardf.png", colors: [Colors.pink, Colors.orange]),
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
        print("Navigate to Deposit");
        break;
      case "Champion":
        print("Navigate to Champion");
        break;
      case "Swap":
        print("Navigate to Swap");
        break;
      case "Buy":
        print("Navigate to Buy");
        break;
      case "Future":
        print("Navigate to Future");
        break;
      case "Transfer":
        print("Navigate to Transfer");
        break;
      case "Spot":
        print("Navigate to Spot");
        break;
      case "Funds":
        print("Navigate to Funds");
        break;
      case "More":
        Navigator.push(context, _createRoute(const MoreCardScreen()));
        break;
      default:
        print("Unknown route: $route");
    }
  }
}