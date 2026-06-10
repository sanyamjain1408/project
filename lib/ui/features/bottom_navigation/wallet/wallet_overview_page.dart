import 'dart:convert';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/check_deposit/check_deposit_page.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_list_page.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/earn_screen.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/future_trade/future_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/future_trade/future_widgets.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/swap/swap_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transfer_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/future_pnl_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transaction_history_screen.dart';

const Color _primary = Color(0xFF111111);
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
  final RxList<History> depositList = <History>[].obs;
  final RxList<History> withdrawList = <History>[].obs;
  Future<void> _getOverviewData() async {
    _controller.refreshController.callRefresh();

    final grandFuture = _controller.fetchGrandTotal();
    final overviewFuture = _controller.getWalletOverviewData(coinType: selectedCoin.value);

    await grandFuture;
    final overview = await overviewFuture;

    if (overview != null) {
      wOverview.value = overview;
      selectedCoin.value = overview.selectedCoin ?? "";
    }

    // Fetch deposit + withdraw using direct HTTP (same as TransactionHistoryScreen)
    _fetchRecentTx();
  }

  Map<String, String> _authHeaders() {
    final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
    final type = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
    final secret = dotenv.env[EnvKeyValue.kApiSecret] ?? '';
    return {
      'Accept': 'application/json',
      'userapisecret': secret,
      if (token.isNotEmpty) 'Authorization': '$type $token',
    };
  }

  Future<void> _fetchRecentTx() async {
    try {
      const base = 'https://api.trapix.com/api/wallet-history-app';
      final headers = _authHeaders();
      final depFuture = http.get(Uri.parse('$base?type=deposit&page=1&per_page=8'), headers: headers);
      final wdFuture = http.get(Uri.parse('$base?type=withdraw&page=1&per_page=8'), headers: headers);
      final results = await Future.wait([depFuture, wdFuture]);

      List<History> deps = [];
      List<History> wds = [];

      if (results[0].statusCode == 200) {
        final body = jsonDecode(results[0].body);
        debugPrint('DEP BODY: ${results[0].body.substring(0, results[0].body.length.clamp(0, 300))}');
        final raw = body['data']?['histories']?['data'] ?? body['data']?['data'] ?? body['data'];
        if (raw is List) deps = raw.map((e) => History.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (results[1].statusCode == 200) {
        final body = jsonDecode(results[1].body);
        debugPrint('WD BODY: ${results[1].body.substring(0, results[1].body.length.clamp(0, 300))}');
        final raw = body['data']?['histories']?['data'] ?? body['data']?['data'] ?? body['data'];
        if (raw is List) wds = raw.map((e) => History.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      depositList.value = deps;
      withdrawList.value = wds;
    } catch (e) { debugPrint('fetchRecentTx error: $e'); }
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
          color: const Color(0xFF111111),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              _buildTopHero(data),
              const SizedBox(height: 20),
              Obx(() => _buildStackedCards(data, settings)),
              const SizedBox(height: 20),
              Obx(() {
                final deps = depositList.toList();
                final wds = withdrawList.toList();
                final coin = wOverview.value.selectedCoin ?? "";
                return _buildReportWithLists(
                  depositList: deps,
                  withdrawList: wds,
                  selectedCoin: coin,
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReportWithLists({
    required List<History> depositList,
    required List<History> withdrawList,
    required String selectedCoin,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Report",
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
            ),
          ),
          const SizedBox(height: 15),

          // ── TAX + GENERATE REPORT CARDS ──
          Container(
            decoration: BoxDecoration(
              color: Color(0x4D1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _reportCardRow(
                  iconBg: Colors.transparent,
                  icon: Image.asset(
                    'assets/icons/tax.png',
                    width: 20,
                    height: 20,
                  ),
                  title: "Tax Report with",
                  subtitle: "Calculate tax in 2 minutes",
                  badge: null,
                  onTap: () {},
                ),
                Divider(color: Colors.white.withOpacity(0.07), height: 1),
                _reportCardRow(
                  iconBg: Colors.transparent,
                  icon: Image.asset(
                    'assets/icons/generate.png',
                    width: 20,
                    height: 20,
                  ),
                  title: "Generate report",
                  subtitle: "Trade report, TDS certificates & summary",
                  badge: "CLAIM TDS",
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── RECENT TRANSACTIONS HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: _dmSans,
                  height: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () => Get.to(() => const TransactionHistoryScreen()),
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: _white.withOpacity(0.5),
                    fontSize: 15,
                    fontFamily: _dmSans,
                    height: 1.33,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── MERGED + SORTED RECENT TRANSACTIONS (same as web) ──
          Builder(builder: (_) {
            final deps = depositList.map((d) => _TxItem(isDeposit: true, amount: d.amount ?? 0, date: d.createdAt, status: d.status ?? 0)).toList();
            final wds = withdrawList.map((w) => _TxItem(isDeposit: false, amount: w.amount ?? 0, date: w.createdAt, status: w.status ?? 0)).toList();

            final merged = [...deps, ...wds]..sort((a, b) {
              final da = a.date ?? DateTime(0);
              final db = b.date ?? DateTime(0);
              return db.compareTo(da);
            });
            final recent = merged.take(8).toList();
            if (recent.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: _dmSans))),
              );
            }
            return Column(
              children: recent.map((tx) => _transactionRow(
                isDeposit: tx.isDeposit,
                amount: tx.amount,
                date: formatDate(tx.date, format: dateTimeFormatDdMMMYyyyHhMm),
                status: tx.status,
                coinType: selectedCoin,
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ── REPORT CARD ROW ───────────────────────────────────────────────────────
  Widget _reportCardRow({
    required Color iconBg,
    required Widget icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: icon), //  yaha change
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: _dmSans,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF00B7FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Color(0xFF00B7FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              fontFamily: _dmSans,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.1),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── TRANSACTION ROW ───────────────────────────────────────────────────────
  // ── TRANSACTION ROW ───────────────────────────────────────────────────────
  Widget _transactionRow({
    required bool isDeposit,
    required double amount,
    required String date,
    required int status,
    required String coinType,
  }) {
    String statusText;
    Color statusColor;
    switch (status) {
      case 1:
        statusText = "Success";
        statusColor = Color(0xFF4ED78E);
        break;
      default:
        statusText = "Failed";
        statusColor = Color(0xFFD73C3C);
        break;
    }

    final iconBg = isDeposit
        ? const Color(0xFF015629).withOpacity(0.4)
        : const Color(0xFF920000).withOpacity(0.5);
    final iconColor = isDeposit ? Color(0xFF4ED78E) : Color(0xFFD73C3C);
    final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
    final sign = isDeposit ? "+" : "-";
    final label = isDeposit ? "Deposit" : "Withdraw";

    // Format: e.g. "$300.00" like image
    final formattedAmount = "\$${amount.toStringAsFixed(2)}";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // ── LEFT ICON ──
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 20),

              // ── LABEL + DATE ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: _dmSans,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),

              // ── AMOUNT + STATUS ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedAmount, // "$300.00" format — image jaisa
                    style: const TextStyle(
                      color: _white, // amount always white like image
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor, // green=Success, red=Failed
                      fontSize: 12,
                      fontFamily: _dmSans,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── TOP HERO ──────────────────────────────────────────────────────────────
  Widget _buildTopHero(WalletOverview data) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        color: Color(0x4D1A1A1A),
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
                const SizedBox(height: 55),
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => TotalBalanceView(
                            gIsBalanceHide.value,
                            _controller.totalBalance.value.total,
                            title: 'Overview'.tr,
                            totalUsd: _controller.totalBalance.value.total,
                            todayPnl: _controller.totalBalance.value.todayPnl,
                            todayPnlPercent: _controller.totalBalance.value.todayPnlPercent,
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

  // ── STACKED CARDS ─────────────────────────────────────────────────────────
  Widget _buildStackedCards(WalletOverview data, settings) {
    final coin = data.selectedCoin ?? '';

    final rows = <_RowData>[
      _RowData(
        name: "Spot",
        svgIcon: 'assets/images/spot.svg',
        pngIcon: 'assets/images/spot.png',
        amount: _controller.spotWalletTotal.value,
        amtUsd: _controller.spotWalletTotal.value,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.spot),
        ),
      ),
      _RowData(
        name: "Future",
        svgIcon: 'assets/images/future.svg',
        pngIcon: 'assets/images/future.png',
        amount: _controller.futureWalletBalance.value,
        amtUsd: _controller.futureWalletBalance.value,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.future),
        ),
      ),
      _RowData(
        name: "Earn",
        svgIcon: 'assets/icons/earn.svg',
        pngIcon: 'assets/icons/earn.png',
        amount: _controller.earnWalletTotal.value,
        amtUsd: _controller.earnWalletTotal.value,
        coin: coin,
        onTap: () => Get.to(
          () => const WalletDetailScreen(initialType: WalletViewType.earn),
        ),
      ),
      // _RowData(
      //   name: "P2P",
      //   svgIcon: 'assets/images/funds.svg',
      //   pngIcon: 'assets/images/funds.png',
      //   amount: data.p2PWallet ?? 0,
      //   amtUsd: data.p2PWalletUsd ?? 0,
      //   coin: coin,
      //   onTap: () => Get.to(
      //     () => const WalletDetailScreen(initialType: WalletViewType.p2p),
      //   ),
      // ),
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
              child: _SvgCard(data: rows[2], isLast: true, cardIndex: 2),
            ),
            // Positioned(
            //   top: 3 * _peekAmount,
            //   left: 0,
            //   right: 0,
            //   child: _SvgCard(data: rows[3], isLast: true, cardIndex: 3),
            // ),
          ],
        ),
      ),
    );
  }

  // ── OLD REPORT (fallback jab data nahi hota) ──────────────────────────────
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
                        fillColor: const Color(0x4D1A1A1A),
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
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
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
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
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
      width: 25,
      height: 25,
      child: Image.asset(
        pngPath,
        width: 25,
        height: 25,
        fit: BoxFit.contain,
        errorBuilder: (_, __, _) => const Icon(
          Icons.account_balance_wallet_outlined,
          color: _green,
          size: 28,
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

// ── CARD SHAPE PAINTER ────────────────────────────────────────────────────────
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

    canvas.drawPath(path, Paint()..color = fillColor);

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
          final double distFromCenter = ((x - cardW / 2) / (cardW / 2)).abs();
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
              ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0))
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

// ── DATA MODEL ────────────────────────────────────────────────────────────────
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

// ── HISTORY ROW (fallback) ────────────────────────────────────────────────────
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

// ── WALLET DETAIL SCREEN ──────────────────────────────────────────────────────
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
    // {"label": "P2P", "type": WalletViewType.p2p},
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
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        scrolledUnderElevation: 0,

        leadingWidth: 30, // default 56 hota hai

        titleSpacing: 0, // gap remove

        leading: IconButton(
          padding: EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.arrow_back, color: _white),
          onPressed: () => Navigator.of(context).pop(),
        ),

        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.only(right: 16),
          labelColor: _white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),

          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
            height: 24 / 16,
          ),

          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
            height: 24 / 16,
          ),

          indicator: const BoxDecoration(),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),

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
      return const EarnScreen();
    }
    if (type == WalletViewType.future) {
      return const _FutureWalletBody();
    }
    return WalletListView(fromType: type as int);
  }
}

// ── Future Wallet Body ────────────────────────────────────────────────────────
class _FutureWalletBody extends StatelessWidget {
  const _FutureWalletBody();

  @override
  Widget build(BuildContext context) {
    NewFutureController fc;
    try {
      fc = Get.find<NewFutureController>();
    } catch (_) {
      fc = Get.put(NewFutureController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => fc.refreshAll());

    return Obx(() {
      final isHide = gIsBalanceHide.value;
      final balance = fc.balance.value;
      final available = fc.availableBalance.value;
      final margin = fc.marginUsed.value;
      final walletBal = fc.walletBalance.value;
      final unrealizedPnl = fc.unrealizedPnl.value;
      final todayPnl = fc.futurePnlToday.value;
      final todayPnlPct = fc.futurePnlPct.value;

      final screenW = MediaQuery.of(Get.context!).size.width;
      const cardH = 220.0;
      const svgW = 362.0;
      const svgH = 204.0;
      final pnlText = '${todayPnl >= 0 ? '+' : ''}${todayPnl.toStringAsFixed(2)} USD (${todayPnlPct >= 0 ? '+' : ''}${todayPnlPct.toStringAsFixed(2)}%)';

      return SingleChildScrollView(
        child: Column(
          children: [
            // ── TOP HERO CARD — same as Spot ─────────────────────────────────
            Container(
              color: Colors.transparent,
              child: SizedBox(
                width: screenW,
                height: cardH,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Background blur + paint
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _FutureHeroClipper(cardW: screenW, cardH: cardH, svgW: svgW, svgH: svgH),
                        child: CustomPaint(
                          painter: _FutureHeroBgPainter(cardW: screenW, cardH: cardH, svgW: svgW, svgH: svgH),
                        ),
                      ),
                    ),
                    // Green wave image
                    Positioned(
                      right: 25,
                      top: 30,
                      width: screenW * 0.40,
                      height: cardH * 1.3,
                      child: Transform.rotate(
                        angle: 1.250,
                        alignment: Alignment.center,
                        child: Image.asset('assets/images/wallet_green_wave.png', fit: BoxFit.cover, alignment: Alignment.bottomRight),
                      ),
                    ),
                    // Border
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FutureHeroBorderPainter(cardW: screenW, cardH: cardH, svgW: svgW, svgH: svgH),
                      ),
                    ),
                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Row(
                                  children: [
                                    Text('Margin Balance', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dmSans)),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        GetStorage().write(PreferenceKey.isBalanceHide, !isHide);
                                        gIsBalanceHide.value = !isHide;
                                      },
                                      child: Icon(
                                        isHide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => Get.to(() => FutureHistoryFullScreen(
                                        ctrl: fc,
                                        pair: fc.currentPair.value,
                                        pp: fc.currentPair.value?.pricePrecision ?? 2,
                                      )),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                                        ),
                                        child: const RotatingIcon(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Balance
                                isHide
                                    ? const Text('******', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: _dmSans))
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '\$${currencyFormat(balance)}',
                                              style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700, fontFamily: _dmSans, height: 1.2),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text('USDT', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.w400, fontFamily: _dmSans)),
                                        ],
                                      ),
                                if (!isHide) const SizedBox(height: 4),
                                if (!isHide)
                                  GestureDetector(
                                    onTap: () => Get.to(() => const FuturePnlScreen()),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RichText(
                                          text: TextSpan(children: [
                                            TextSpan(text: "Today's PnL  ", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: _dmSans)),
                                            TextSpan(
                                              text: pnlText,
                                              style: TextStyle(
                                                color: todayPnl >= 0 ? const Color(0xFF4ED78E) : Colors.redAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: _dmSans,
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!isHide) const SizedBox(height: 8),
                                if (!isHide)
                                  Row(children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Wallet Balance (USDT)', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: _dmSans)),
                                      const SizedBox(height: 2),
                                      Text(walletBal.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: _dmSans)),
                                    ])),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Unrealized PNL (USDT)', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: _dmSans)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${unrealizedPnl >= 0 ? '+' : ''}${unrealizedPnl.toStringAsFixed(2)}',
                                        style: TextStyle(color: unrealizedPnl >= 0 ? const Color(0xFF4ED78E) : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: _dmSans),
                                      ),
                                    ])),
                                  ]),
                              ],
                            ),
                            // 3 Buttons: Trade | Swap | Transfer
                            _FutureHeroButtons(fc: fc),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── TABS: Position | Crypto Assets | Fiat ─────────────────────────
            _FutureWalletTabs(fc: fc),
          ],
        ),
      );
    });
  }
}

// ── Future Hero Buttons (Trade | Swap | Transfer) ────────────────────────────
class _FutureHeroButtons extends StatelessWidget {
  final NewFutureController fc;
  const _FutureHeroButtons({required this.fc});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final btnW = (constraints.maxWidth - 16) / 3;
      return Row(
        children: [
          _FutureBtn(label: 'Trade', iconWidget: const Icon(Icons.candlestick_chart_rounded, size: 16, color: Colors.black), isMain: true, width: btnW, onTap: () {}),
          const SizedBox(width: 8),
          _FutureBtn(label: 'Swap', iconWidget: Image.asset('assets/images/swap.png', width: 16, height: 16), isMain: false, width: btnW, onTap: () => Get.to(() => const SwapScreen())),
          const SizedBox(width: 8),
          _FutureBtn(label: 'Transfer', iconWidget: Image.asset('assets/images/transfer.png', width: 16, height: 16), isMain: false, width: btnW, onTap: () => Get.to(() => const TransferScreen())),
        ],
      );
    });
  }
}

class _FutureBtn extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final bool isMain;
  final double width;
  final VoidCallback onTap;
  const _FutureBtn({required this.label, required this.iconWidget, required this.isMain, required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isMain ? _green : const Color(0xFF2A2A2A),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isMain ? Colors.black : Colors.white, fontFamily: _dmSans), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

// ── Future Hero Painters & Clipper (same path as Spot) ───────────────────────
Path _buildFutureHeroPath(double cardW, double cardH, double svgW, double svgH) {
  final sx = cardW / svgW;
  final sy = cardH / svgH;
  return Path()
    ..moveTo(0, 20 * sy)
    ..cubicTo(0, 8.9543 * sy, 8.95431 * sx, 0, 20 * sx, 0)
    ..lineTo(132.716 * sx, 0)
    ..cubicTo(138.02 * sx, 0, 143.107 * sx, 2.10714 * sy, 146.858 * sx, 5.85786 * sy)
    ..lineTo(155.142 * sx, 14.1421 * sy)
    ..cubicTo(158.893 * sx, 17.8929 * sy, 163.98 * sx, 20 * sy, 169.284 * sx, 20 * sy)
    ..lineTo(192.716 * sx, 20 * sy)
    ..cubicTo(198.02 * sx, 20 * sy, 203.107 * sx, 17.8929 * sy, 206.858 * sx, 14.1421 * sy)
    ..lineTo(215.142 * sx, 5.85786 * sy)
    ..cubicTo(218.893 * sx, 2.10713 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
    ..lineTo(342 * sx, 0)
    ..cubicTo(353.046 * sx, 0, 362 * sx, 8.95431 * sy, 362 * sx, 20 * sy)
    ..lineTo(362 * sx, 184 * sy)
    ..cubicTo(362 * sx, 195.046 * sy, 353.046 * sx, 204 * sy, 342 * sx, 204 * sy)
    ..lineTo(20 * sx, 204 * sy)
    ..cubicTo(8.9543 * sx, 204 * sy, 0, 195.046 * sy, 0, 184 * sy)
    ..lineTo(0, 20 * sy)
    ..close();
}

class _FutureHeroBgPainter extends CustomPainter {
  final double cardW, cardH, svgW, svgH;
  const _FutureHeroBgPainter({required this.cardW, required this.cardH, required this.svgW, required this.svgH});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_buildFutureHeroPath(cardW, cardH, svgW, svgH), Paint()..color = const Color(0xFF111111).withOpacity(0.5));
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FutureHeroBorderPainter extends CustomPainter {
  final double cardW, cardH, svgW, svgH;
  const _FutureHeroBorderPainter({required this.cardW, required this.cardH, required this.svgW, required this.svgH});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _buildFutureHeroPath(cardW, cardH, svgW, svgH),
      Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FutureHeroClipper extends CustomClipper<Path> {
  final double cardW, cardH, svgW, svgH;
  const _FutureHeroClipper({required this.cardW, required this.cardH, required this.svgW, required this.svgH});
  @override
  Path getClip(Size size) => _buildFutureHeroPath(cardW, cardH, svgW, svgH);
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _FutureWalletTabs extends StatefulWidget {
  final NewFutureController fc;
  const _FutureWalletTabs({required this.fc});

  @override
  State<_FutureWalletTabs> createState() => _FutureWalletTabsState();
}

class _FutureWalletTabsState extends State<_FutureWalletTabs> {
  String _tab = 'Position';

@override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab row
          Row(
            children: ['Position', 'Crypto Assets', 'Fiat'].map((t) {
              final active = _tab == t;
              return GestureDetector(
                onTap: () => setState(() => _tab = t),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? Colors.white : Colors.white38,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Tab content
          if (_tab == 'Position')
            FuturePositionsSection(
              pair: widget.fc.currentPair.value,
              pp: widget.fc.currentPair.value?.pricePrecision ?? 2,
              bottomTab: 'Position',
              ctrl: widget.fc,
              onTabChanged: (_) {},
              onTpSlTap: (_) {},
              onLeverageTap: () {},
              hideHeader: true,
            )
          else if (_tab == 'Crypto Assets')
            _FutureCryptoAssetsTab(fc: widget.fc)
          else
            const _FutureFiatTab(),
        ],
      ),
    );
  }
}


// ── Future Crypto Assets Tab ──────────────────────────────────────────────────
class _FutureCryptoAssetsTab extends StatelessWidget {
  final NewFutureController fc;
  const _FutureCryptoAssetsTab({required this.fc});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isHide = gIsBalanceHide.value;
      final total = fc.balance.value;
      final available = fc.availableBalance.value;
      final margin = fc.marginUsed.value;

      // Header row
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Asset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.5), fontFamily: _dmSans))),
                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.5), fontFamily: _dmSans))),
                Expanded(flex: 2, child: Text('In Margin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.5), fontFamily: _dmSans))),
                Expanded(flex: 2, child: Text('Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.5), fontFamily: _dmSans))),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          const SizedBox(height: 12),
          // USDT row
          Row(
            children: [
              // Asset name + icon
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://api.trapix.com/uploaded_file/uploads/coin/657c66c3067d81702651587.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFF26A17B), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Text('U', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('USDT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: _dmSans)),
                        Text('TetherUS', style: TextStyle(fontSize: 10,fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.5), fontFamily: _dmSans)),
                      ],
                    ),
                  ],
                ),
              ),
              // Total
              Expanded(
                flex: 2,
                child: Text(
                  isHide ? '****' : total.toStringAsFixed(4),
                  style: const TextStyle(fontSize: 12,height: 16/12, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: _dmSans),
                ),
              ),
              // In Margin
              Expanded(
                flex: 2,
                child: Text(
                  isHide ? '****' : margin.toStringAsFixed(4),
                  style: const TextStyle(fontSize: 12,height: 16/12, fontWeight: FontWeight.w700, color: Color(0xFFCCFF00), fontFamily: _dmSans),
                ),
              ),
              // Available
              Expanded(
                flex: 2,
                child: Text(
                  isHide ? '****' : available.toStringAsFixed(4),
                  style: const TextStyle(fontSize: 12,height: 16/12, fontWeight: FontWeight.w700, color: Color(0xFF4ED78E), fontFamily: _dmSans),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

// ── Future Fiat Tab ───────────────────────────────────────────────────────────
class _FutureFiatTab extends StatelessWidget {
  const _FutureFiatTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('Coming Soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFCCFF00), fontFamily: _dmSans)),
          const SizedBox(height: 6),
          Text('Fiat support will be available shortly.', style: TextStyle(fontSize: 13, color: Colors.white38, fontFamily: _dmSans)),
        ],
      ),
    );
  }
}

// ── PAINTERS ──────────────────────────────────────────────────────────────────
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

// ── EARN WALLET VIEW ──────────────────────────────────────────────────────────

// ── EARN PRODUCT CARD ─────────────────────────────────────────────────────────
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

class _TxItem {
  final bool isDeposit;
  final double amount;
  final DateTime? date;
  final int status;
  _TxItem({required this.isDeposit, required this.amount, required this.date, required this.status});
}
