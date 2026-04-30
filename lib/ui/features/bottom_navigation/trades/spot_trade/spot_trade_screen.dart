import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/side_sheet_component.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import 'spot_buy_sell_view.dart';
import 'spot_trade_controller.dart';
import 'spot_trade_details_screen.dart';
import 'spot_trade_history_views.dart';

class SpotTradeScreen extends StatefulWidget {
  const SpotTradeScreen({super.key});

  @override
  SpotTradeScreenState createState() => SpotTradeScreenState();
}

class SpotTradeScreenState extends State<SpotTradeScreen> {
  final _controller = Get.put(SpotTradeController());
  final isChartShow = false.obs;
  double _buySellViewHeight = 0;

  void _updateBuySellHeight(double height) {
    if (_buySellViewHeight != height) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _buySellViewHeight != height) {
          setState(() => _buySellViewHeight = height);
        }
      });
    }
  }

  @override
  void initState() {
    tradeDecimal = DefaultValue.decimal;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (TemporaryData.selectedCurrencyPair != null) {
        _controller.selectedCoinPair.value = TemporaryData.selectedCurrencyPair!;
        TemporaryData.selectedCurrencyPair = null;

        if (TemporaryData.activityType != null) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_controller.onBuySaleChange != null) {
              _controller.onBuySaleChange!(int.parse(TemporaryData.activityType!));
            }
            TemporaryData.activityType = null;
          });
        }
      }
      _controller.getDashBoardData();
    });
  }

  @override
  void dispose() {
    _controller.unSubscribeChannel(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: No TabBar here — the parent TradesScreen owns the top tab bar.
    // SpotTradeScreen is just the Spot tab body.
    return Expanded(
      child: Column(
        children: [
          // ── Pair header row ───────────────────────────────────────────────
          Obx(() {
            final dd = _controller.dashboardData.value;
            return TradePairTopView(
              coinPair: _controller.selectedCoinPair.value,
              total: dd.orderData?.total,
              onTap: () => _chooseCoinPairModal(),
              onTapIcon: () => isChartShow.value = !isChartShow.value,
              onTapDetails: () => Get.to(() => const SpotTradeDetailsScreen()),
            );
          }),
          vSpacer5(),
          // ── Main scrollable body ─────────────────────────────────────────
          Expanded(
            child: Container(
              
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
                  // Chart shown inline when bar-chart icon is tapped
                  Obx(() => isChartShow.value
                      ? TradeChartView(
                          isShow: true,
                          onTap: () => isChartShow.value = false)
                      : vSpacer0()),
                  vSpacer5(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order book (left) — height pinned to the right column
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: _buySellViewHeight > 0 ? _buySellViewHeight : null,
                          child: Obx(() {
                            return OderBookFixedView(
                              _controller.selectedOrderSort.value,
                              order: _controller.dashboardData.value.orderData,
                              prices: _controller.dashboardData.value.lastPriceData,
                              buyList: _controller.buyExchangeOrder.toList(),
                              sellList: _controller.sellExchangeOrder.toList(),
                              onShortChange: (key) =>
                                  _controller.selectedOrderSort.value = key,
                              selectedHeaderIndex:
                                  _controller.selectedHeaderIndex.value,
                              onHeaderChange: (index) =>
                                  _controller.selectedHeaderIndex.value = index,
                            );
                          }),
                        ),
                      ),
                      hSpacer5(),
                      // Buy/Sell form (right) — reports its height to left column
                      Expanded(
                        flex: 5,
                        child: _HeightReporter(
                          onHeight: _updateBuySellHeight,
                          child: const SpotTradeBuySellView(fromPage: FromKey.buy),
                        ),
                      ),
                    ],
                  ),
                  vSpacer5(),
                  const SpotTradeHistoryView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _chooseCoinPairModal() {
    _controller.getCoinPairList("");
    SideSheet.left(
      context: context,
      barrierColor: context.theme.secondaryHeaderColor.withValues(alpha: 0.5),
      sheetColor: Colors.transparent,
      width: context.width - 50,
      body: Obx(() => TradeCurrencyPairSelectionView(
            title: "Spot Pairs".tr,
            searchEditController: _controller.searchEditController,
            onTextChange: _controller.getCoinPairList,
            coinPairs: _controller.coinPairs.toList(),
            onSelect: (pair) {
              _controller.selectedCoinPair.value = pair;
              _controller.getDashBoardData();
            },
          )),
    );
  }
}

// Reports its render height after every layout pass via [onHeight].
// Avoids IntrinsicHeight (which breaks when a LayoutBuilder is in the tree).
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, required super.child});
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _HeightReporterBox(onHeight);

  @override
  void updateRenderObject(BuildContext context, _HeightReporterBox renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _HeightReporterBox extends RenderProxyBox {
  _HeightReporterBox(this.onHeight);
  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(h));
  }
}