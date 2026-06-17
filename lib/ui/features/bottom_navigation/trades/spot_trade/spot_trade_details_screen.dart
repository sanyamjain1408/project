import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/settings.dart';
import 'package:tradexpro_flutter/data/models/spot_data.dart';
import 'package:tradexpro_flutter/data/remote/spot_socket.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import '../../wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';

import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import '../trapix_chart_widget.dart';
import 'spot_trade_controller.dart';

class SpotTradeDetailsScreen extends StatefulWidget {
  const SpotTradeDetailsScreen({super.key});

  @override
  State<SpotTradeDetailsScreen> createState() => _SpotTradeDetailsScreenState();
}

class _SpotTradeDetailsScreenState extends State<SpotTradeDetailsScreen> {
  final _controller = Get.find<SpotTradeController>();
  final isLogin = gUserRx.value.id > 0;
  RxInt chartIndex = 0.obs;
  RxInt tabIndex = 0.obs;

  final _tradesWs = SpotWebSocket();

  @override
  void initState() {
    super.initState();
    final sym = (_controller.selectedCoinPair.value.coinPair ?? 'BTC_USDT')
        .replaceAll('_', '')
        .replaceAll('/', '');
    _tradesWs.connect(sym, (msg) {
      if (msg['trades'] is List) {
        final list = (msg['trades'] as List)
            .map((t) => SpotTrade.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList();
        _controller.applyLastTrades(list);
      }
    });
  }

  @override
  void dispose() {
    _tradesWs.dispose();
    super.dispose();
  }

  List<Announcement> get _announcements {
    try {
      return Get.find<LandingController>().landingData.value.announcementList ??
          [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                buttonOnlyIcon(
                  onPress: () => Navigator.pop(context),
                  iconData: Icons.arrow_back_outlined,
                  size: Dimens.iconSizeMin,
                ),
                Text(
                  _controller.selectedCoinPair.value.getCoinPairName(),
                  style: TextStyle(
                    fontFamily: "DMSans",
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 28 / 20,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => FavoriteHelper.getFavoriteIcon(
                    _controller.selectedCoinPair.value,
                    () {
                      FavoriteHelper.updateFavorite(
                        _controller.selectedCoinPair.value,
                        '',
                        (pair) {
                          _controller.selectedCoinPair.value = pair;
                          _controller.selectedCoinPair.refresh();
                        },
                      );
                    },
                  ),
                ),
                buttonOnlyIcon(
                  onPress: () {},
                  iconData: Icons.ios_share_sharp,
                  size: 20,
                ),
                hSpacer5(),
              ],
            ),
            // ── Top tabs: Chart | Coin Info ──────────────────────────────────
            Obx(
              () => tabBarText(
                ["Chart".tr, "Coin Info".tr],
                chartIndex.value,
                (index) => chartIndex.value = index,
                selectedColor: Colors.white,
                unSelectedColor: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                selectedFontWeight: FontWeight.w700,
                unSelectedFontWeight: FontWeight.w400,
                fontFamily: "DMSans",
              ),
            ),
            // ── Content area ─────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (chartIndex.value == 1) {
                  final meta = _controller.spotPairsMeta.firstWhereOrNull(
                    (p) => p.symbol == (_controller.selectedCoinPair.value.coinPair ?? '').replaceAll('_', ''),
                  );
                  return _CoinInfoView(
                    pair: _controller.selectedCoinPair.value,
                    spotPair: meta,
                    ticker: _controller.spotTicker.value,
                    prices: _controller.dashboardData.value.lastPriceData,
                  );
                }
                if (chartIndex.value != 0) return const SizedBox.expand();
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Price details section
                    Obx(
                      () => _SpotPriceView(
                        order: _controller.dashboardData.value.orderData,
                        prices: _controller.dashboardData.value.lastPriceData,
                        isUp: _controller.tickerGoingUp.value,
                        ticker: _controller.spotTicker.value,
                        pair: _controller.selectedCoinPair.value,
                      ),
                    ),
                    // Horizontal scrolling announcement ticker
                    if (_announcements.isNotEmpty)
                      _MarqueeTicker(
                        texts: _announcements
                            .map((a) => a.title ?? '')
                            .where((t) => t.isNotEmpty)
                            .toList(),
                      ),
                    // Chart — TradingView chart via WebView
                    Obx(() {
                      final pair = _controller.selectedCoinPair.value;
                      final child = pair.childCoinName?.toUpperCase() ?? '';
                      final parent = pair.parentCoinName?.toUpperCase() ?? '';
                      // API symbol format: parentCoin + childCoin (e.g. BTCUSDT)
                      // coinPair field is "USDT_BTC" format (child_parent), so swap parts
                      String sym;
                      if (parent.isNotEmpty && child.isNotEmpty) {
                        sym = '$parent$child';
                      } else {
                        final cp = pair.coinPair ?? '';
                        final parts = cp.split('_');
                        sym = parts.length == 2
                            ? '${parts[1]}${parts[0]}'.toUpperCase()
                            : cp.replaceAll('_', '').toUpperCase();
                      }
                      return TrapixChartWidget(
                        symbol: sym.isNotEmpty ? sym : 'BNBUSDT',
                        height: MediaQuery.of(context).size.width * 1.05,
                      );
                    }),
                    // Order Book / Last Trade / Asset Overview tabs
                    Column(
                      children: [
                        Obx(
                          () => tabBarText(
                            [
                              "Order Book".tr,
                              "Last Trade".tr,
                              "Asset Overview".tr,
                            ],
                            tabIndex.value,
                            (index) => tabIndex.value = index,
                            selectedColor: Colors.white,
                            unSelectedColor: Colors.white.withValues(
                              alpha: 0.5,
                            ),

                            fontSize: 16,

                            selectedFontWeight: FontWeight.w700,
                            unSelectedFontWeight: FontWeight.w400,

                            fontFamily: "DMSans",
                          ),
                        ),
                        vSpacer10(),
                        dividerHorizontal(height: Dimens.paddingMid),
                        vSpacer10(),
                        Obx(() {
                          switch (tabIndex.value) {
                            case 0:
                              return DetailsOrderBookView(
                                buyExchangeOrder: _controller.buyExchangeOrder,
                                sellExchangeOrder: _controller.sellExchangeOrder,
                                total: _controller.dashboardData.value.orderData?.total,
                                tradeCoinOverride: _controller.selectedCoinPair.value.parentCoinName,
                                baseCoinOverride: _controller.selectedCoinPair.value.childCoinName,
                              );
                            case 1:
                              return Obx(() => TradeListView(
                                exchangeTrades: _controller.exchangeTrades,
                                total: _controller.dashboardData.value.orderData?.total,
                                tradeCoinOverride: _controller.selectedCoinPair.value.parentCoinName,
                                baseCoinOverride: _controller.selectedCoinPair.value.childCoinName,
                              ));
                            case 2:
                              return AssetOverviewView();
                            default:
                              return Container();
                          }
                        }),
                      ],
                    ),
                  ],
                );
              }),
            ),
            // ── Full-width Buy / Sell buttons ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                Dimens.paddingMid,
                Dimens.paddingMin,
                Dimens.paddingMid,
                Dimens.paddingMin,
              ),
              decoration: boxDecorationTopRound(
                color: Theme.of(context).secondaryHeaderColor,
              ),
              child: Row(
                children: [
                  // BUY BUTTON
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _controller.onBuySaleChange?.call(0);
                      },
                      child: Container(
                        height: 40,

                        alignment: Alignment.center,

                        decoration: BoxDecoration(
                          color: gBuyColor,
                          borderRadius: BorderRadius.circular(5),

                          // optional border
                          border: Border.all(color: gBuyColor, width: 1),
                        ),

                        child: Text(
                          "Buy".tr,
                          style: const TextStyle(
                            color: Colors.white,

                            //  custom everything
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: "DMSans",
                            height: 24 / 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  hSpacer10(),

                  // SELL BUTTON
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _controller.onBuySaleChange?.call(1);
                      },
                      child: Container(
                        height: 40,

                        alignment: Alignment.center,

                        decoration: BoxDecoration(
                          color: gSellColor,
                          borderRadius: BorderRadius.circular(5),

                          border: Border.all(color: gSellColor, width: 1),
                        ),

                        child: Text(
                          "Sell".tr,
                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: "DMSans",
                            height: 24 / 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price section widget ────────────────────────────────────────────────────
class _SpotPriceView extends StatelessWidget {
  const _SpotPriceView({
    required this.order,
    required this.prices,
    required this.isUp,
    required this.ticker,
    required this.pair,
  });

  final OrderData? order;
  final List<PriceData>? prices;
  final bool isUp;
  final SpotTicker ticker;
  final CoinPair pair;

  @override
  Widget build(BuildContext context) {
    final lastP = (prices?.isNotEmpty ?? false) ? prices!.first : PriceData();
    final change = ticker.priceChange24h;
    final (sing, changeColor) = getNumberData(change);
    final isChangeUp = change >= 0; // drives price color + arrow direction

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: price + change + mark price
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price + direction arrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: "DMSans",
                          height: 32 / 24,
                        ),
                        child: Text(
                          currencyFormat(lastP.price, fixed: tradeDecimal),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    Icon(
                      isChangeUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: changeColor,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            "≈\$${currencyFormat(lastP.lastPrice, fixed: 2)}  ",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),

                      TextSpan(
                        text: "$sing${coinFormat(change, fixed: 2)}%",
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${"Mark Price".tr} ${currencyFormat(lastP.lastPrice, fixed: 2)}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 12 / 10,
                  ),
                ),
              ],
            ),
          ),
          hSpacer10(),
          // Right: 24h stats
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _statRow(
                  context,
                  "24h High".tr,
                  currencyFormat(ticker.high24h, fixed: tradeDecimal),
                ),
                _statRow(
                  context,
                  "24h Low".tr,
                  currencyFormat(ticker.low24h, fixed: tradeDecimal),
                ),
                _statRow(
                  context,
                  "24h Vol (${pair.parentCoinName ?? ''})",
                  coinFormat(ticker.price > 0 ? ticker.volume24h / ticker.price : 0, fixed: 2),
                ),
                _statRow(
                  context,
                  "24h Vol (${pair.childCoinName ?? ''})",
                  _fmtVolM(ticker.volume24h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtVolM(double vol) {
    final inM = vol / 1e6;
    return '${inM.toStringAsFixed(2)}M';
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 16 / 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: "DMSans",
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal scrolling announcement ticker ────────────────────────────────
class _MarqueeTicker extends StatefulWidget {
  const _MarqueeTicker({required this.texts});

  final List<String> texts;

  @override
  State<_MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<_MarqueeTicker> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  Future<void> _startScroll() async {
    await Future.delayed(const Duration(seconds: 1));

    while (mounted && _sc.hasClients) {
      final max = _sc.position.maxScrollExtent;

      if (max <= 0) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      await _sc.animateTo(
        max,
        duration: Duration(milliseconds: (max * 60).toInt()),
        curve: Curves.linear,
      );

      if (!mounted) break;

      _sc.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcements = () {
      try {
        return Get.find<LandingController>().landingData.value.announcementList ?? [];
      } catch (_) { return []; }
    }();
    final marqueeText = announcements.isNotEmpty
        ? announcements.map((a) => '   ${a.title ?? ''}   ').join('')
        : '   Trapix Exchange   ';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.volume_up_outlined, color: Color(0xFF007958), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                marqueeText * 5,
                style: const TextStyle(
                  color: Color(0xFF007958),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: "DMSans",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coin Info tab ───────────────────────────────────────────────────────────
class _CoinInfoView extends StatelessWidget {
  const _CoinInfoView({
    required this.pair,
    required this.spotPair,
    required this.ticker,
    required this.prices,
  });

  final CoinPair pair;
  final SpotPair? spotPair;
  final SpotTicker ticker;
  final List<PriceData>? prices;

  @override
  Widget build(BuildContext context) {
    final lastPrice = (prices?.isNotEmpty ?? false) ? prices!.first.price : 0.0;
    final change = ticker.priceChange24h;
    final isUp = change >= 0;
    final changeColor = isUp ? const Color(0xFF4ED78E) : const Color(0xFFD05858);
    final changeSign = isUp ? '+' : '';

    final rows = <_InfoRow>[
      _InfoRow('Symbol', spotPair?.symbol ?? pair.getCoinPairName()),
      _InfoRow('Base Currency', pair.parentCoinName ?? ''),
      _InfoRow('Quote Currency', pair.childCoinName ?? ''),
      _InfoRow('Current Price', '${coinFormat(lastPrice, fixed: tradeDecimal)} ${pair.childCoinName ?? ''}'),
      _InfoRow('24H Change', '$changeSign${coinFormat(change, fixed: 2)}%', valueColor: changeColor),
      _InfoRow('24H High', coinFormat(ticker.high24h, fixed: tradeDecimal)),
      _InfoRow('24H Low', coinFormat(ticker.low24h, fixed: tradeDecimal)),
      _InfoRow('Maker Fee', '${spotPair?.makerFee ?? 0}%'),
      _InfoRow('Taker Fee', '${spotPair?.takerFee ?? 0}%'),
      _InfoRow('Min Order', '${spotPair?.minOrderAmount ?? 0} ${pair.parentCoinName ?? ''}'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pair.parentCoinName ?? ''} / ${pair.childCoinName ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 20),
          ...rows.map((r) => _buildRow(r)),
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRow r) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              r.label,
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 13,
                fontFamily: 'DMSans',
              ),
            ),
          ),
          Text(
            r.value,
            style: TextStyle(
              color: r.valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
}

class AssetOverviewView extends StatelessWidget {
  AssetOverviewView({super.key});

  final _controller = Get.find<SpotTradeController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: context.width,
      child: Obx(() {
        final total      = _controller.selfBalance.value.total;
        final baseCType  = total?.baseWallet?.coinType  ?? "";
        final tradeCType = total?.tradeWallet?.coinType ?? "";

        // Trading Account: live available balances from spot balances API
        final availBase  = _controller.spotAvailableBase.value;
        final availTrade = _controller.spotAvailableTrade.value;

        // Funding Account: total wallet balances from order_data
        final fundBase  = total?.baseWallet?.balance  ?? 0.0;
        final fundTrade = total?.tradeWallet?.balance ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Trading Account".tr),
            vSpacer5(),
            _balanceLine(baseCType,  coinFormat(availBase,  fixed: tradeDecimal)),
            _balanceLine(tradeCType, coinFormat(availTrade, fixed: tradeDecimal)),
            vSpacer10(),
            _sectionTitle("Funding Account".tr),
            vSpacer5(),
            _balanceLine(baseCType,  coinFormat(fundBase,  fixed: tradeDecimal)),
            _balanceLine(tradeCType, coinFormat(fundTrade, fixed: tradeDecimal)),
            vSpacer15(),
            Row(
              children: [
                Expanded(
                  child: _greenBtn("Deposit".tr, onTap: () {
                    if (total?.tradeWallet != null) {
                      Get.to(() => WalletCryptoDepositScreen(
                        wallet: total!.tradeWallet!.createWallet(),
                      ));
                    }
                  }),
                ),
                hSpacer15(),
                Expanded(
                  child: _darkBtn("Transfer".tr, onTap: () {}),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        fontFamily: "DMSans",
      ),
    );
  }

  Widget _balanceLine(String coin, String amount) {
    if (coin.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(coin, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, fontFamily: "DMSans")),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: "DMSans")),
        ],
      ),
    );
  }

  Widget _greenBtn(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5),
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2ECC71),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: "DMSans")),
      ),
    );
  }

  Widget _darkBtn(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: "DMSans")),
      ),
    );
  }
}
