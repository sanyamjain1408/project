import 'dart:ui';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/check_deposit/check_deposit_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_list_page.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _green = Color(0xFFCCFF00);
const Color _white = Color(0xFFFFFFFF);
const String _dmSans = 'DMSans';

const double _svgW = 362.0;
const double _svgH = 160.0;
const double _peekAmount = 60.0;

class WalletOverviewPage extends StatefulWidget {
  const WalletOverviewPage({super.key});

  @override
  State<WalletOverviewPage> createState() => _WalletOverviewPageState();
}

class _WalletOverviewPageState extends State<WalletOverviewPage> {
  final _controller = Get.find<WalletController>();
  final Rx<WalletOverview> wOverview = WalletOverview().obs;
  final RxString selectedCoin = "".obs;

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
          color: Colors.black45,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              _buildTopHero(data),
              const SizedBox(height: 16),
              _buildStackedCards(data, settings),
              const SizedBox(height: 20),
              if (data.spotWallet != null) _buildReport(data),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTopHero(WalletOverview data) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.38,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
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
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 160,
              child: Image.asset(
                'assets/images/wallet_green_wave.png',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Container(
                  color: Colors.transparent,
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
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildStackedCards(WalletOverview data, settings) {
    final coin = data.selectedCoin ?? '';

    final rows = <_RowData>[
      _RowData(
        name: "Spot",
        svgIcon: 'assets/images/spot.svg',
        pngIcon: 'assets/images/spot.png',
        amount: data.spotWallet ?? 0,
        amtUsd: data.spotWalletUsd ?? 0,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.spot),
        ),
      ),
      _RowData(
        name: "Future",
        svgIcon: 'assets/images/future.svg',
        pngIcon: 'assets/images/future.png',
        amount: data.futureWallet ?? 0,
        amtUsd: data.futureWalletUsd ?? 0,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.future),
        ),
      ),
      _RowData(
        name: "Earn",
        svgIcon: 'assets/icons/earn.svg',
        pngIcon: 'assets/icons/earn.png',
        amount: 0,
        amtUsd: 0,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.earn),
        ),
      ),
      _RowData(
        name: "P2P",
        svgIcon: 'assets/images/funds.svg',
        pngIcon: 'assets/images/funds.png',
        amount: data.p2PWallet ?? 0,
        amtUsd: data.p2PWalletUsd ?? 0,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.p2p),
        ),
      ),
    ];

    final double totalH = _svgH + (rows.length - 1) * _peekAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _SvgCard(data: rows[0], isLast: false, cardIndex: 0),
            ),
            Positioned(
              top: 1 * _peekAmount,
              left: 0,
              right: 0,
              child: _SvgCard(data: rows[1], isLast: false, cardIndex: 1),
            ),
            Positioned(
              top: 2 * _peekAmount,
              left: 0,
              right: 0,
              child: _SvgCard(data: rows[2], isLast: false, cardIndex: 2),
            ),
            Positioned(
              top: 3 * _peekAmount,
              left: 0,
              right: 0,
              child: _SvgCard(data: rows[3], isLast: true, cardIndex: 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(WalletOverview data) {
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
                  fontFamily: _dmSans,
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
              _HistoryRow(
                history: w,
                isWithdraw: true,
                coinType: data.selectedCoin,
              ),
          if (data.deposit.isValid)
            for (final d in data.deposit!)
              _HistoryRow(
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
}

// ── SVG SHAPED CARD ──────────────────────────────────────────────────────────
class _SvgCard extends StatelessWidget {
  const _SvgCard({
    required this.data,
    required this.isLast,
    required this.cardIndex,
  });

  final _RowData data;
  final bool isLast;
  final int cardIndex;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width - 24;

    return GestureDetector(
      onTap: data.onTap,
      child: SizedBox(
        width: screenW,
        height: _svgH,
        child: Stack(
          children: [
            // ── Card background shape ──
            Positioned.fill(
              child: ClipPath(
                clipper: _CardShapeClipper(cardW: screenW, cardH: _svgH),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: CustomPaint(
                      painter: _CardShapePainter(
                        cardW: screenW,
                        cardH: _svgH,
                        fillColor: Color(0x991A1A1A),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Wave image — only on last card ──
            if (isLast)
              Positioned.fill(
                child: ClipPath(
                  clipper: _CardShapeClipper(cardW: screenW, cardH: _svgH),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: const Offset(0, 80),
                      child: Opacity(
                        opacity: 1,
                        child: Image.asset(
                          'assets/images/wallet_wave_bottom.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: _svgH,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Card content row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      _iconWidget(data.svgIcon, data.pngIcon),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 65,
                        child: Text(
                          data.name,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                            CrossAxisAlignment.baseline, //  important
                            textBaseline: TextBaseline.alphabetic, 
                    
                    children: [
                      // 🔹 LEFT COLUMN (amount + usd)
                      Column(
                        crossAxisAlignment:CrossAxisAlignment.end,
                             
                            
                        children: [
                          Text(
                            _fmtNum(data.amount),
                            style: const TextStyle(
                              color: _white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: _dmSans,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "\$${_fmtNum(data.amtUsd)}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 5),

                      // 🔹 RIGHT COLUMN (coin)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 2,
                        ), //  thoda adjust for baseline feel
                        child: Text(
                          data.coin.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: _dmSans,
                            height: 1,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWidget(String svgPath, String pngPath) {
    return SizedBox(
      width: 36,
      height: 36,
      child: SvgPicture.asset(
        svgPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Image.asset(
          pngPath,
          width: 36,
          height: 36,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.account_balance_wallet_outlined,
            color: _green,
            size: 28,
          ),
        ),
      ),
    );
  }

  String _fmtNum(double v) {
    if (v == 0) return "0.00";
    final s = v.toStringAsFixed(2);
    final p = s.split('.');
    final i = p[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$i.${p[1]}';
  }
}

// ── CARD SHAPE PAINTER ───────────────────────────────────────────────────────
class _CardShapePainter extends CustomPainter {
  const _CardShapePainter({
    required this.cardW,
    required this.cardH,
    required this.fillColor,
  });
  final double cardW, cardH;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = cardW / _svgW;
    final sy = cardH / _svgH;
    final path = _buildPath(sx, sy);

    // ── Fill ──
    canvas.drawPath(path, Paint()..color = fillColor);

    // ── Symmetric gradient border — left+right se center tak white ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cardW, 22 * sy));

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      for (final metric in pathMetrics) {
        const int steps = 1000;
        for (int i = 0; i < steps; i++) {
          final double t = i / steps;

          final double dist = metric.length * t;
          final Tangent? tangent = metric.getTangentForOffset(dist);
          if (tangent == null) continue;

          final double x = tangent.position.dx;

          // X position ke basis pe — left(0) aur right(cardW) pe dim, center(cardW/2) pe bright
          final double distFromCenter = ((x - cardW / 2) / (cardW / 2))
              .abs(); // 0=center, 1=edge
          final double opacity = 0.02 + (1.0 - distFromCenter) * 0.18;
          final double strokeW = 0.3 + (1.0 - distFromCenter) * 0.9;

          final double start = t * metric.length;
          final double end = ((t + 1 / steps) * metric.length).clamp(
            0.0,
            metric.length,
          );

          final segPath = metric.extractPath(start, end);

          canvas.drawPath(
            segPath,
            Paint()
              ..color = Colors.white24.withOpacity(opacity.clamp(0.0, 0.5))
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..strokeCap = StrokeCap.square,
          );
        }
      }
    }

    canvas.restore();
  }

  static Path _buildPath(double sx, double sy) {
    return Path()
      ..moveTo(0, 20 * sy)
      ..cubicTo(0, 8.9543 * sy, 8.95431 * sx, 0, 20 * sx, 0)
      ..lineTo(132.716 * sx, 0)
      ..cubicTo(
        138.02 * sx,
        0,
        143.107 * sx,
        2.10714 * sy,
        146.858 * sx,
        5.85786 * sy,
      )
      ..lineTo(155.142 * sx, 14.1421 * sy)
      ..cubicTo(
        158.893 * sx,
        17.8929 * sy,
        163.98 * sx,
        20 * sy,
        169.284 * sx,
        20 * sy,
      )
      ..lineTo(192.716 * sx, 20 * sy)
      ..cubicTo(
        198.02 * sx,
        20 * sy,
        203.107 * sx,
        17.8929 * sy,
        206.858 * sx,
        14.1421 * sy,
      )
      ..lineTo(215.142 * sx, 5.85786 * sy)
      ..cubicTo(218.893 * sx, 2.10713 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
      ..lineTo(342 * sx, 0)
      ..cubicTo(353.046 * sx, 0, 362 * sx, 8.95431 * sy, 362 * sx, 20 * sy)
      ..lineTo(362 * sx, (_svgH - 20) * sy)
      ..cubicTo(
        362 * sx,
        (_svgH - 9) * sy,
        353.046 * sx,
        _svgH * sy,
        342 * sx,
        _svgH * sy,
      )
      ..lineTo(20 * sx, _svgH * sy)
      ..cubicTo(
        8.9543 * sx,
        _svgH * sy,
        0,
        (_svgH - 9) * sy,
        0,
        (_svgH - 20) * sy,
      )
      ..lineTo(0, 20 * sy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── CARD SHAPE CLIPPER ────────────────────────────────────────────────────────
class _CardShapeClipper extends CustomClipper<Path> {
  const _CardShapeClipper({required this.cardW, required this.cardH});
  final double cardW, cardH;

  @override
  Path getClip(Size size) =>
      _CardShapePainter._buildPath(cardW / _svgW, cardH / _svgH);

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── DATA MODEL ───────────────────────────────────────────────────────────────
class _RowData {
  const _RowData({
    required this.name,
    required this.svgIcon,
    required this.pngIcon,
    required this.amount,
    required this.amtUsd,
    required this.coin,
    required this.onTap,
  });
  final String name, svgIcon, pngIcon, coin;
  final double amount, amtUsd;
  final VoidCallback onTap;
}

// ── HISTORY ROW ──────────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
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
    final color = isWithdraw ? Colors.redAccent : _green;

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
                  color: color,
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

// ── WALLET DETAIL SCREEN ─────────────────────────────────────────────────────
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
    {"label": "Earn", "type": WalletViewType.earn},
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
            fontFamily: _dmSans,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
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
        child: Text(
          "Coming Soon",
          style: TextStyle(color: Colors.white54, fontFamily: _dmSans),
        ),
      );
    }
    if (type == WalletViewType.checkDeposit) {
      return const CheckDepositPage(fromKey: FromKey.wallet);
    }
    if (type == WalletViewType.earn) {
      return const EarnWalletView();
    }
    return WalletListView(fromType: type as int);
  }
}

// ── PAINTERS ─────────────────────────────────────────────────────────────────
class _WaveLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height / 2)
        ..cubicTo(
          size.width * 0.20,
          0,
          size.width * 0.35,
          size.height,
          size.width * 0.50,
          size.height / 2,
        )
        ..cubicTo(
          size.width * 0.65,
          0,
          size.width * 0.80,
          size.height,
          size.width,
          size.height / 2,
        ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.height * 0.7,
      Paint()
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
            ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
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
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF39FF14).withOpacity(0.5),
            const Color(0xFF7FFF00).withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class EarnWalletView extends StatelessWidget {
  const EarnWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Earning",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "0.00 USDT",
                  style: TextStyle(
                    color: _white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "≈ \$0.00",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontFamily: _dmSans,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Staking Products",
            style: TextStyle(
              color: _white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: _dmSans,
            ),
          ),
          const SizedBox(height: 12),
          _EarnProductCard(
            coin: "USDT",
            apy: "12.5%",
            duration: "30 Days",
            minAmount: "100",
            color: const Color(0xFF26A17B),
          ),
          const SizedBox(height: 10),
          _EarnProductCard(
            coin: "BTC",
            apy: "8.2%",
            duration: "60 Days",
            minAmount: "0.001",
            color: const Color(0xFFF7931A),
          ),
          const SizedBox(height: 10),
          _EarnProductCard(
            coin: "ETH",
            apy: "9.8%",
            duration: "90 Days",
            minAmount: "0.01",
            color: const Color(0xFF627EEA),
          ),
        ],
      ),
    );
  }
}

class _EarnProductCard extends StatelessWidget {
  const _EarnProductCard({
    required this.coin,
    required this.apy,
    required this.duration,
    required this.minAmount,
    required this.color,
  });

  final String coin, apy, duration, minAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                coin[0],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: _dmSans,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin,
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: _dmSans,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Min: $minAmount · $duration",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: _dmSans,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                apy,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: _dmSans,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "APY",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontFamily: _dmSans,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Stake",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: _dmSans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
