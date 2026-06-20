import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/coin_pair.dart';
import '../../../../helper/app_helper.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/number_util.dart';
import '../trades/spot_trade/spot_trade_controller.dart';
import '../../root/root_controller.dart';
import '../../../../data/local/constants.dart';
import 'landing_controller.dart';

const _dmSans = 'DMSans';
const _white  = Colors.white;
const _grey   = Color(0x80FFFFFF); // 50% white
const _bg     = Color(0xFF111111);

class LandingMarketView extends StatefulWidget {
  const LandingMarketView({super.key});

  @override
  State<LandingMarketView> createState() => _LandingMarketViewState();
}

class _LandingMarketViewState extends State<LandingMarketView>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<LandingController>();
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TAB BAR ───────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            onTap: (i) => _controller.selectedTab.value = i,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicator: const BoxDecoration(),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelColor: _white,
            unselectedLabelColor: _grey,
            labelStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _dmSans),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, fontFamily: _dmSans),
            tabs: [
              Tab(text: "Core Assets".tr),
              Tab(text: "24H Gainer".tr),
              Tab(text: "New Listing".tr),
            ],
          ),

          // ── COLUMN HEADERS ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(children: [
              // Pair/Volume — takes remaining space (mirrors data row Expanded)
              const Expanded(
                child: Text('Pair/Volume',
                    style: TextStyle(color: _grey, fontSize: 12,
                        fontFamily: _dmSans, fontWeight: FontWeight.w400)),
              ),
              // Last Price — fixed 90px, right-aligned
              const SizedBox(
                width: 90,
                child: Text('Last Price',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: _grey, fontSize: 12,
                        fontFamily: _dmSans, fontWeight: FontWeight.w400)),
              ),
              const SizedBox(width: 18),
              // 24H Change — fixed 83px, centered (mirrors data row SizedBox(width:83))
              const SizedBox(
                width: 83,
                child: Text('24H Change',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _grey, fontSize: 12,
                        fontFamily: _dmSans, fontWeight: FontWeight.w400)),
              ),
            ]),
          ),

          // ── LIST ──────────────────────────────────────────────────
          Obx(() {
            final lData = _controller.landingList.value;
            final tab = _controller.selectedTab.value;
            final list = tab == 0
                ? lData.assetCoinPairs
                : (tab == 1 ? lData.hourlyCoinPairs : lData.latestCoinPairs);
            return list.isValid
                ? ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list!.length,
                    itemBuilder: (_, i) => _MarketRow(coin: list[i]),
                  )
                : showEmptyView(height: Dimens.btnHeightMain);
          }),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.coin});
  final CoinPair coin;

  @override
  Widget build(BuildContext context) {
    final isUp = !isNegativeNum(coin.priceChange);
    final sign = isUp ? '+' : '';
    final color = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final price = coinFormat(coin.lastPrice);
    final change = "$sign${coinFormat(coin.priceChange, fixed: 2)}%";

    return InkWell(
      onTap: () {
        coin.coinPair = coin.getCoinPairKey();
        coin.coinPairName = coin.getCoinPairName();
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.trade);
        if (Get.isRegistered<SpotTradeController>()) {
          final ctrl = Get.find<SpotTradeController>();
          ctrl.selectedCoinPair.value = coin;
          ctrl.getDashBoardData();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── PAIR / VOLUME (left-aligned, takes remaining space) ──
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Coin icon circle
                  ClipOval(
                    child: showImageNetwork(
                      imagePath: coin.icon,
                      width: 30,
                      height: 30,
                      bgColor: const Color(0xFFD9D9D9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Name + volume — constrained so long names don't push right columns
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: coin.childCoinName ?? '',
                            style: const TextStyle(
                              color: _white, fontSize: 16,
                              fontFamily: _dmSans, fontWeight: FontWeight.w400,
                              height: 1.25),
                            children: [
                              TextSpan(
                                text: '/${coin.parentCoinName ?? ''}',
                                style: TextStyle(
                                  color: _white.withValues(alpha: 0.5),
                                  fontSize: 16, fontFamily: _dmSans,
                                  fontWeight: FontWeight.w400, height: 1.25),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          numberFormatCompact(coin.volume, symbol: '\$'),
                          style: const TextStyle(
                            color: _grey, fontSize: 12,
                            fontFamily: _dmSans, fontWeight: FontWeight.w400,
                            height: 1.33),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── LAST PRICE (fixed width, right-aligned) ─────────────
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(price,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _white, fontSize: 16,
                        fontFamily: _dmSans, fontWeight: FontWeight.w700,
                        height: 1.25)),
                  Text('\$$price',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _white.withValues(alpha: 0.5), fontSize: 12,
                        fontFamily: _dmSans, fontWeight: FontWeight.w400,
                        height: 1.33)),
                ],
              ),
            ),

            const SizedBox(width: 18),

            // ── 24H CHANGE BADGE (fixed width, right edge) ────────────
            SizedBox(
              width: 83,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      change,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _white, fontSize: 15,
                        fontFamily: _dmSans, fontWeight: FontWeight.w600,
                        height: 1.33),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
