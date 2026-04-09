import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/ui/features/charts/charts_screen.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../bottom_navigation/trades/trade_order_book_widgets.dart';
import '../bottom_navigation/trades/trade_widgets.dart';
import 'currency_pair_details_controller.dart';

class CurrencyPairDetailsScreen extends StatefulWidget {
  const CurrencyPairDetailsScreen({super.key, required this.pair, this.fromKey, this.onFavChange});

  final CoinPair pair;
  final String? fromKey;
  final Function(String?)? onFavChange;

  @override
  State<CurrencyPairDetailsScreen> createState() => _CurrencyPairDetailsScreenState();
}

class _CurrencyPairDetailsScreenState extends State<CurrencyPairDetailsScreen> {
  final _controller = Get.put(CurrencyPairDetailsController());
  final isLogin = gUserRx.value.id > 0;
  RxInt chartIndex = 0.obs;
  RxInt tabIndex = 0.obs;

  @override
  void initState() {
    tradeDecimal = DefaultValue.decimal;
    _controller.selectedPair.value = widget.pair;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => widget.fromKey == FromKey.future ? _controller.getCurrencyPairDetailsFuture() : _controller.getCurrencyPairDetailsSpot());
  }

  @override
  void dispose() {
    Get.delete<CurrencyPairDetailsController>();
    super.dispose();
    _controller.unSubscribeChannel(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                buttonOnlyIcon(onPress: () => Navigator.pop(context), iconData: Icons.arrow_back_outlined, size: Dimens.iconSizeMin),
                TextRobotoAutoBold(_controller.selectedPair.value.getCoinPairName(), fontSize: Dimens.fontSizeMid),
                const Spacer(),
                Obx(() {
                  final change = _controller.orderData.value.total?.tradeWallet?.priceChange;
                  final (sing, color) = getNumberData(change);
                  return buttonText("$sing${coinFormat(change, fixed: 4)}%",
                      textColor: color, bgColor: color.withValues(alpha:0.2), visualDensity: minimumVisualDensity);
                }),
                Obx(() => FavoriteHelper.getFavoriteIcon(_controller.selectedPair.value, () {
                      FavoriteHelper.updateFavorite(_controller.selectedPair.value, widget.fromKey ?? '', (pair) {
                        _controller.selectedPair.value = pair;
                        _controller.selectedPair.refresh();
                        if(widget.onFavChange != null)widget.onFavChange!(null);
                      });
                    })),
                hSpacer5()
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                children: [
                  Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
                  Obx(() => CurrencyPairDetailsView(order: _controller.orderData.value, prices: _controller.lastPriceData.toList())),
                  dividerHorizontal(),
                  const ChartsScreen(fromModal: false),
                  vSpacer10(),
                  Obx(() => tabBarText(
                      ["Order Book".tr, "Trades".tr], tabIndex.value, selectedColor: context.theme.focusColor, (index) => tabIndex.value = index)),
                  vSpacer10(),
                  Obx(() {
                    switch (tabIndex.value) {
                      case 0:
                        return DetailsOrderBookView(
                            buyExchangeOrder: _controller.buyExchangeOrder.toList(),
                            sellExchangeOrder: _controller.sellExchangeOrder.toList(),
                            total: _controller.orderData.value.total);
                      case 1:
                        return TradeListView(exchangeTrades: _controller.exchangeTrades.toList(), total: _controller.orderData.value.total);
                      default:
                        return Container();
                    }
                  }),
                ],
              ),
            ),
            TradeBottomButtonsView(
                buyStr: "Buy".tr,
                sellStr: "Sell".tr,
                onTap: (bool isBuy) {
                  Get.back();
                  TemporaryData.selectedCurrencyPair = _controller.selectedPair.value;
                  TemporaryData.activityType = (isBuy ? 0 : 1).toString();
                  if (widget.fromKey == FromKey.future) {
                    getRootController().changeBottomNavIndex(AppBottomNavKey.future);
                  } else {
                    TemporaryData.changingPageId = 0;
                    getRootController().changeBottomNavIndex(AppBottomNavKey.trade);
                  }
                })
          ],
        ),
      ),
    );
  }
}
