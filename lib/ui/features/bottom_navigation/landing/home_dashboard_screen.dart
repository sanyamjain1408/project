import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_market_view.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_screen.dart';
import 'package:tradexpro_flutter/ui/features/notifications/notifications_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/announcement_view.dart';

const _green = Color(0xFFB5F000);

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with SingleTickerProviderStateMixin {
    
  final LandingController _controller = Get.find<LandingController>();

  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    // Data refresh ensure karna
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── LAYER 1: SCROLLABLE CONTENT ──
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // ── MAIN TOP CONTAINER ──
                      Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: const Border(
                            bottom: BorderSide(color: Color.fromARGB(255, 87, 87, 87), width: 1),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // ── CIRCLE BACKGROUND ──
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

                              // ── CONTENT ──
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 50),

                                    // ── TOTAL ASSETS ──
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
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.remove_red_eye_outlined,
                                          color: const Color(0xFFFFFFFF).withOpacity(0.5),
                                          size: 15,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                     Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "\$10,546.40",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 30,
                                            fontFamily: "DMSans",
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 6),
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
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "+14.51 (1.16%)",
                                          style: TextStyle(color: _green),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 30),

                                    // ── GRID ──
                                    GridView.count(
                                      crossAxisCount: 5,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 5,
                                      crossAxisSpacing: 5,
                                      children: [
                                        _buildGridItem("assets/images/deposit.png", "Deposit"),
                                        _buildGridItem("assets/images/champion.png", "Champion"),
                                        _buildGridItem("assets/images/swap.png", "Swap"),
                                        _buildGridItem("assets/images/earn.png", "Earn"),
                                        _buildGridItem("assets/images/buy.png", "Buy"),
                                        _buildGridItem("assets/images/future.png", "Future"),
                                        _buildGridItem("assets/images/transfer.png", "Transfer"),
                                        _buildGridItem("assets/images/spot.png", "Spot"),
                                        _buildGridItem("assets/images/funds.png", "Funds"),
                                        _buildGridItem("assets/images/more.png", "More"),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // ── BUTTONS ──
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _green,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () {},
                                            child: const Text("Add Funds", style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 12, fontFamily: "DMSans")),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color.fromARGB(255, 25, 24, 24),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () {},
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset("assets/images/deposit.png", height: 20, width: 20),
                                                const SizedBox(width: 8),
                                                const Text("Deposit Crypto", style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: "DMSans")),
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

                      // ── ANNOUNCEMENT BAR (FIXED - NO CONST ERROR) ──
                      Obx(() {
                        final lData = _controller.landingData.value;
                        // 'isValid' extension nahi hai, isliye manual check kiya
                        if (lData.announcementList != null && lData.announcementList!.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: Colors.black,
                            child: Row(
                              children: [
                                const Icon(Icons.volume_up, color: _green, size: 20),
                                const SizedBox(width: 8),
                                // Yahan se 'const' hata diya
                                Expanded(
                                  child: AnnouncementView(announcementList: lData.announcementList!),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      }),
                      
                                           // ── GIFT CARD (Width Fixed = 362) ──
                      Container(
                        width: 362, // <--- FIXED WIDTH
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 25, 24, 24),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Image.asset("assets/images/gift.png", height: 40, width: 40),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Build Your Trading Empire", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 4),
                                  Text("Join and earn rewards easily", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black26,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {},
                              child: const Text("Join Now", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),

                      // ── EARN SECTION (Width Fixed = 362, Same as Gift Card) ──
                       // <--- CENTER ADD KIYA TAAKI ALIGNMENT SAHI LAGE
                         Container(
                          width: 382, // <--- SAME WIDTH 362
                          margin: const EdgeInsets.symmetric( vertical: 10, horizontal: 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black, // Background black rakha
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 210, // Height fixed
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 25, 24, 24), // Dark Grey Box
                                    borderRadius: BorderRadius.circular(20),
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
                                      const Text("Highest APR", style: TextStyle(color: Colors.grey, fontSize: 15, )),
                                      const SizedBox(height: 5),
                                      const Text("2.8%", style: TextStyle(color: _green, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "DMSans" )),
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
                      
                         

                      

                      // ── MARKET LIST ──
                      const LandingMarketView(),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("    Earn", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold , fontFamily: "DMSans")),),
                        SizedBox(height: 5),

                      // ── EARN CARDS ──
                      _buildEarnCards(),

                      //MarketEmptyStateWidget()
                      MarketEmptyStateWidget()

                      
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── LAYER 2: FLOATING HEADER (With Background Image) ──
          _buildCustomHeader(context),
        ],
      ),
    );
  }

  // ── CUSTOM HEADER ──
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background Image for Header
            Positioned(
              top: -80,
              right: -100,
              width: 300,
              height: 300,
              child: IgnorePointer(
                child: RotationTransition(
                  turns: _rotationController,
                  child: Opacity(
                    opacity: 0.4,
                    child: Image.asset('assets/images/circle.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            // Foreground Content
            Row(
              children: [
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Image.asset('assets/images/icon.png', height: 30, width: 30, errorBuilder: (c, e, s) => const Icon(Icons.currency_bitcoin, color: Colors.orange, size: 30)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        SizedBox(width: 10),
                        Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                        SizedBox(width: 5),
                        Text("BTC/USDT", style: TextStyle(color: Colors.white, fontSize: 14)),
                        Spacer(),
                        Icon(Icons.search, color: _green, size: 20),
                        SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.headphones, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Get.to(() => const NotificationsPage()),
                  child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──
  Widget _buildGridItem(String imagePath, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: const Color(0xFF111111).withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
          child: Image.asset(imagePath, height: 25, width: 25, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 20, color: Colors.grey)),
        ),
        const SizedBox(height: 0),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSmallBox({required String icon, required String title, required String value}) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 25, 24, 24), borderRadius: BorderRadius.circular(20)),
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
    );
  }

  Widget _buildCardItem({required String percent, required String name, required String icon, required List<Color> colors}) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Color.fromARGB(255, 25, 24, 24), borderRadius: BorderRadius.circular(15)),
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
                      child: Text(percent, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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
    );
  }

  Widget _buildEarnCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 110,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCardItem(percent: "26.78%", name: "Ravencoin", icon: "assets/images/cardo.png", colors: [Colors.blue, Colors.orange]),
            _buildCardItem(percent: "17.28%", name: "Ponke", icon: "assets/images/cardt.png", colors: [Colors.green, Colors.purple]),
            _buildCardItem(percent: "9.56%", name: "Tellor", icon: "assets/images/cardt.png", colors: [Colors.teal, Colors.purple]),
            _buildCardItem(percent: "15.47%", name: "ether.fi", icon: "assets/images/cardf.png", colors: [Colors.pink, Colors.orange]),
          ],
        ),
      ),
    );
  }
}