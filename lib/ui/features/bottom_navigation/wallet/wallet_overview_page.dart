import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/check_deposit/check_deposit_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_list_page.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _dmSans = 'DMSans';

class WalletOverviewPage extends StatefulWidget {
  const WalletOverviewPage({super.key});

  @override
  State<WalletOverviewPage> createState() => _WalletOverviewPageState();
}

class _WalletOverviewPageState extends State<WalletOverviewPage> {
  final _controller = Get.find<WalletController>();
  Rx<WalletOverview> wOverview = WalletOverview().obs;
  RxString selectedCoin = "".obs;

  Future<void> _getOverviewData() async {
    _controller.refreshController.callRefresh();
    _controller.getWalletOverviewData(coinType: selectedCoin.value, (overview) {
      wOverview.value = overview;
      selectedCoin.value = wOverview.value.selectedCoin ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      controller: _controller.refreshController,
      refreshOnStart: true,
      onRefresh: _getOverviewData,
      header: ClassicHeader(
        showText: false,
        iconTheme: const IconThemeData().copyWith(color: _green),
      ),
      child: Obx(() {
        final data = wOverview.value;
        final settings = getSettingsLocal();
        return Container(
          color: _primary,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              _buildTopHeroSection(data),
              const SizedBox(height: 12),
              _buildAssetListSection(data, settings),
              const SizedBox(height: 16),
              if (data.spotWallet != null) _buildReportSection(data),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOP HERO SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeroSection(WalletOverview data) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.42,

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),

        // 🔥 Bottom round
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),

        // 🔥 Bottom white border
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
      ),

      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),

        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 🌊 Green wave image
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 160,
              child: Image.asset(
                'assets/images/wallet_green_wave.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => _buildGreenWaveFallback(),
              ),
            ),

            // 🔝 TOP CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => TotalBalanceView(
                            gIsBalanceHide.value,
                            data.total,
                            title: 'Overview'.tr,
                            totalUsd: data.totalUsd,
                            coins: data.coins,
                            selectedCoin: selectedCoin.value,
                            onSelectCoin: (selected) {
                              selectedCoin.value = selected;
                              _getOverviewData();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ⏱ History icon
                      GestureDetector(
                        onTap: () => Get.to(() => const ActivityScreen()),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Colors.white60,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🔥 BOTTOM FIXED BUTTONS (IMPORTANT)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const WalletTopButtonsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ASSET LIST SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAssetListSection(WalletOverview data, settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      // clipBehavior clips children to the rounded corners — no inner ClipRRect needed
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Asset rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                if (data.spotWallet != null) ...[
                  _AssetRow(
                    imagePath: 'assets/icons/spot_wallet.png',
                    name: "Spot",
                    amount: data.spotWallet,
                    amountUsd: data.spotWalletUsd,
                    coinType: data.selectedCoin,
                    isHide: gIsBalanceHide.value,
                    onTap: () => Get.to(
                      () =>
                          WalletDetailScreen(initialType: WalletViewType.spot),
                    ),
                  ),
                  _buildWaveDivider(),
                ],

                if (settings?.enableFutureTrade == 1 &&
                    data.futureWallet != null) ...[
                  _AssetRow(
                    imagePath: 'assets/icons/future_wallet.png',
                    name: "Future",
                    amount: data.futureWallet,
                    amountUsd: data.futureWalletUsd,
                    coinType: data.selectedCoin,
                    isHide: gIsBalanceHide.value,
                    onTap: () => Get.to(
                      () => WalletDetailScreen(
                        initialType: WalletViewType.future,
                      ),
                    ),
                  ),
                  _buildWaveDivider(),
                ],

                _AssetRow(
                  imagePath: 'assets/icons/earn_wallet.png',
                  name: "Earn",
                  amount: 0.0,
                  amountUsd: 0.0,
                  coinType: data.selectedCoin,
                  isHide: gIsBalanceHide.value,
                  onTap: () {},
                ),

                _buildWaveDivider(),

                _AssetRow(
                  imagePath: 'assets/icons/fund_wallet.png',
                  name: "Fund",
                  amount: data.p2PWallet ?? 0.0,
                  amountUsd: data.p2PWalletUsd ?? 0.0,
                  coinType: data.selectedCoin,
                  isHide: gIsBalanceHide.value,
                  onTap: () => Get.to(
                    () => WalletDetailScreen(initialType: WalletViewType.p2p),
                  ),
                ),
              ],
            ),
          ),

          // Bottom wave — plain Column child, no Stack / Positioned needed
          SizedBox(
            width: double.infinity,
            height: 100,
            child: Image.asset(
              'assets/images/wallet_wave_bottom.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (c, e, s) => _buildBottomWaveFallback(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REPORT SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildReportSection(WalletOverview data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Report',
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              buttonTextBordered(
                "View All".tr,
                false,
                onPress: () {
                  TemporaryData.activityType = HistoryType.transaction;
                  Get.to(() => const ActivityScreen());
                },
                radius: Dimens.radiusCorner,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.withdraw.isValid)
            for (final w in data.withdraw!)
              HistoryItemView(
                history: w,
                isWithdraw: true,
                coinType: data.selectedCoin,
              ),
          if (data.deposit.isValid)
            for (final d in data.deposit!)
              HistoryItemView(
                history: d,
                isWithdraw: false,
                coinType: data.selectedCoin,
              ),
          if (!data.deposit.isValid && !data.withdraw.isValid)
            const EmptyView(),
        ],
      ),
    );
  }

  Widget _buildWaveDivider() {
    return CustomPaint(
      size: const Size(double.infinity, 24),
      painter: _WaveDividerPainter(),
    );
  }

  Widget _buildGreenWaveFallback() => CustomPaint(painter: _GreenWavePainter());
  Widget _buildBottomWaveFallback() =>
      CustomPaint(painter: _BottomWavePainter());
}

// ─────────────────────────────────────────────────────────────────────────────
// ASSET ROW
// ─────────────────────────────────────────────────────────────────────────────
class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.imagePath,
    required this.name,
    required this.amount,
    required this.amountUsd,
    required this.coinType,
    required this.isHide,
    required this.onTap,
  });

  final String imagePath;
  final String name;
  final double? amount;
  final double? amountUsd;
  final String? coinType;
  final bool isHide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = getSettingsLocal()?.currency ?? DefaultValue.currency;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _green,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: _white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            isHide
                ? const Text(
                    "******",
                    style: TextStyle(
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${coinFormat(amount)} ${coinType ?? ''}",
                        style: const TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat(amountUsd, name: currency),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY ITEM
// ─────────────────────────────────────────────────────────────────────────────
class HistoryItemView extends StatelessWidget {
  const HistoryItemView({
    super.key,
    required this.history,
    required this.isWithdraw,
    this.coinType,
  });

  final History history;
  final bool isWithdraw;
  final String? coinType;

  @override
  Widget build(BuildContext context) {
    final icon = isWithdraw
        ? Icons.file_upload_outlined
        : Icons.file_download_outlined;
    final title = isWithdraw ? "Withdraw".tr : "Deposit".tr;
    final sign = isWithdraw ? "-" : "+";
    final amtColor = isWithdraw ? Colors.redAccent : _green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatDate(history.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$sign${coinFormat(history.amount)} $coinType",
                style: TextStyle(
                  color: amtColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Completed".tr,
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WALLET DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({super.key, required this.initialType});
  final int initialType;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<WalletController>();
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {"label": "Spot", "type": WalletViewType.spot},
    {"label": "Future", "type": WalletViewType.future},
    {"label": "Earn", "type": null},
    {"label": "P2P", "type": WalletViewType.p2p},
    {"label": "Buy Crypto", "type": null},
    {"label": "Check Deposit", "type": WalletViewType.checkDeposit},
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _tabs.indexWhere((t) => t["type"] == widget.initialType);
    if (_selectedIndex < 0) _selectedIndex = 0;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _selectedIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
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
      backgroundColor: _secondary,
      appBar: AppBar(
        backgroundColor: _secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _white),
          onPressed: () => Get.back(),
        ),
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: _white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: _green, width: 2),
          ),
          dividerColor: Colors.transparent,
          tabs: _tabs.map((t) => Tab(text: t["label"] as String)).toList(),
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    final type = _tabs[_selectedIndex]["type"];
    if (type == null) {
      return const Center(
        child: Text("Coming Soon", style: TextStyle(color: Colors.white54)),
      );
    }
    if (type == WalletViewType.checkDeposit) {
      return const CheckDepositPage(fromKey: FromKey.wallet);
    }
    return WalletListView(fromType: type as int);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────
class _WaveDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..cubicTo(
        size.width * 0.25,
        0,
        size.width * 0.50,
        size.height,
        size.width * 0.75,
        size.height / 2,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.25,
        size.width * 0.95,
        size.height * 0.60,
        size.width,
        size.height / 2,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF111111),
    );

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF7FFF00).withOpacity(0.6),
              const Color(0xFF39FF14).withOpacity(0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.7, size.height * 0.3),
              radius: size.height * 0.7,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.height * 0.7,
      glowPaint,
    );

    final wavePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.6,
        size.height * 0.8,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF39FF14).withOpacity(0.3),
          const Color(0xFF7FFF00).withOpacity(0.1),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.1,
        size.width * 0.6,
        size.height * 0.9,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
