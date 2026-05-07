import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/settings.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../../wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import '../../wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';

import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
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
            // ── Top tabs: Chart | Coin Info | Contract Info ─────────────────
            Obx(
              () => tabBarText(
                ["Chart".tr, "Coin Info".tr, "Contract Info".tr],
                chartIndex.value,
                (index) => chartIndex.value = index,

                selectedColor: Colors.white,
                unSelectedColor: Colors.white.withOpacity(0.5),

                fontSize: 16,

                selectedFontWeight: FontWeight.w700,
                unSelectedFontWeight: FontWeight.w400,

                fontFamily: "DMSans",
              ),
            ),
            // ── Content area ─────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (chartIndex.value != 0) return const SizedBox.expand();
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Price details section
                    Obx(
                      () => _SpotPriceView(
                        order: _controller.dashboardData.value.orderData,
                        prices: _controller.dashboardData.value.lastPriceData,
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
                    // Chart — full width
                    Obx(
                      () => TvChartFullView(
                        coinPair: _controller.selectedCoinPair.value,
                      ),
                    ),
                    // Order Book / Trade History / Asset Overview tabs
                    Column(
                      children: [
                        Obx(
                          () => tabBarText(
                            [
                              "Order Book".tr,
                              "Trade History".tr,
                              "Asset Overview".tr,
                            ],
                            tabIndex.value,
                            (index) => tabIndex.value = index,
                            selectedColor: Colors.white,
                            unSelectedColor: Colors.white.withValues(alpha: 0.5),

                            fontSize: 16,

                            selectedFontWeight: FontWeight.w700,
                            unSelectedFontWeight: FontWeight.w400,

                            fontFamily: "DMSans",
                          ),
                        ),
                        vSpacer10(),
                        Obx(() {
                          switch (tabIndex.value) {
                            case 0:
                              return DetailsOrderBookView(
                                buyExchangeOrder:
                                    _controller.buyExchangeOrder,
                                sellExchangeOrder:
                                    _controller.sellExchangeOrder,
                                total: _controller
                                    .dashboardData
                                    .value
                                    .orderData
                                    ?.total,
                              );
                            case 1:
                              return TradeListView(
                                exchangeTrades: _controller.exchangeTrades,
                                total: _controller
                                    .dashboardData
                                    .value
                                    .orderData
                                    ?.total,
                              );
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
  const _SpotPriceView({required this.order, required this.prices});

  final OrderData? order;
  final List<PriceData>? prices;

  @override
  Widget build(BuildContext context) {
    final lastP = (prices?.isNotEmpty ?? false) ? prices!.first : PriceData();
    final isUp = (lastP.price ?? 0) >= (lastP.lastPrice ?? 0);
    final total = order?.total;
    final change = total?.tradeWallet?.priceChange;
    final (sing, changeColor) = getNumberData(change);
    final priceColor = isUp ? gBuyColor : gSellColor;

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
                Text(
                  currencyFormat(lastP.price, fixed: tradeDecimal),
                  style: TextStyle(
                    color: Color(0xFFD05858),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: "DMSans",
                    height: 32 / 24,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            "≈\$${currencyFormat(lastP.lastPrice, fixed: 2)}  ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),

                      TextSpan(
                        text: "$sing${coinFormat(change, fixed: 2)}%",
                        style: TextStyle(
                          color: Color(0xFFD05858),
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
                  currencyFormat(total?.tradeWallet?.high, fixed: tradeDecimal),
                ),
                _statRow(
                  context,
                  "24h Low".tr,
                  currencyFormat(total?.tradeWallet?.low, fixed: tradeDecimal),
                ),
                _statRow(
                  context,
                  "24h Vol (${total?.tradeWallet?.coinType ?? ''})",
                  coinFormat(total?.tradeWallet?.volume, fixed: 2),
                ),
                _statRow(
                  context,
                  "24h Vol (${total?.baseWallet?.coinType ?? ''})",
                  coinFormat(total?.baseWallet?.volume, fixed: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                color: Colors.white.withOpacity(0.5),
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
    // 👇 same text multiple times
    const marqueeText = "   Trapix.com lists TDO/USDT Trading Pair!   ";

    return Container(
      height: 25,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          const Icon(
            Icons.volume_up_outlined,
            color: Color(0xFF007958),
            size: 20,
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SingleChildScrollView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),

              child: Text(
                marqueeText * 5, //  5 times repeat
                style: const TextStyle(
                  color: Color(0xFF007958),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: "DMSans",
                  height: 16 / 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AssetOverviewView extends StatelessWidget {
  AssetOverviewView({super.key});

  final _controller = Get.find<SpotTradeController>();

  @override
  Widget build(BuildContext context) {
    final color = context.theme.primaryColorLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: context.width,
      decoration: boxDecorationRoundCorner(),
      child: Obx(() {
        final total = _controller.selfBalance.value.total;
        final baseCType = total?.baseWallet?.coinType ?? "";
        final tradeCType = total?.tradeWallet?.coinType ?? "";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextRobotoAutoBold("Trading Account".tr),
            vSpacer5(),
            twoTextSpaceFixed(
              baseCType,
              coinFormat(
                _controller.selfBalance.value.baseWallet,
                fixed: tradeDecimal,
              ),
              color: color,
            ),
            twoTextSpaceFixed(
              tradeCType,
              coinFormat(
                _controller.selfBalance.value.tradeWallet,
                fixed: tradeDecimal,
              ),
              color: color,
            ),
            vSpacer10(),
            TextRobotoAutoBold("Funding Account".tr),
            vSpacer5(),
            twoTextSpaceFixed(
              baseCType,
              coinFormat(total?.baseWallet?.balance, fixed: tradeDecimal),
              color: color,
            ),
            twoTextSpaceFixed(
              tradeCType,
              coinFormat(total?.tradeWallet?.balance, fixed: tradeDecimal),
              color: color,
            ),
            vSpacer15(),
            Row(
              children: [
                Expanded(
                  child: buttonText(
                    "Deposit".tr,
                    visualDensity: VisualDensity.compact,
                    onPress: () {
                      if (total?.tradeWallet != null) {
                        Get.to(
                          () => WalletCryptoDepositScreen(
                            wallet: total!.tradeWallet!.createWallet(),
                          ),
                        );
                      }
                    },
                  ),
                ),
                hSpacer15(),
                Expanded(
                  child: buttonText(
                    "Transfer".tr,
                    visualDensity: VisualDensity.compact,
                    onPress: () {
                      if (total?.tradeWallet != null) {
                        Get.to(
                          () => WalletCryptoWithdrawScreen(
                            wallet: total!.tradeWallet!.createWallet(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
