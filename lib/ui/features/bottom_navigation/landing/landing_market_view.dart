import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/coin_pair.dart';
import '../../../../helper/app_helper.dart';
import '../../../../utils/appbar_util.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/number_util.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';
import '../../currency_pair_details/currency_pair_details_screen.dart';
import 'landing_controller.dart';



const _bg =  Color.fromARGB(255, 17, 17, 17);
const _card      = Color(0xFF111318);
const _green     = Color(0xFFB5F000);
const _border    = Color(0xFF1E2128);
const _textDim   = Color(0xFF6B7280);
const _textMid   = Color(0xFFB0B8C1);

class LandingMarketView extends StatefulWidget {
  const LandingMarketView({super.key});

  @override
  State<LandingMarketView> createState() => _LandingMarketViewState();
}

class _LandingMarketViewState extends State<LandingMarketView> with SingleTickerProviderStateMixin {
  final _controller = Get.find<LandingController>();
  late final TabController _tabController;
  RxBool isExpand = false.obs;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tabBarUnderline(
            ["Core Assets".tr, "24H Gainer".tr, "New Listing".tr],
            _tabController,
            onTap: (index) => _controller.selectedTab.value = index,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              border: Border(bottom: BorderSide(color: _green,width: 4))
            ),
            fontSize: Dimens.fontSizeMid,
            isScrollable: true,

            labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          ),
          dividerHorizontal(height: 0),
          vSpacer10(),
          Row(
            children: [
              hSpacer10(),
              Expanded(flex: 3, child: TextRobotoAutoNormal("Pair".tr)),
              hSpacer5(),
              Expanded(flex: 3, child: TextRobotoAutoNormal("Price".tr, textAlign: TextAlign.center)),
              hSpacer5(),
              Expanded(flex: 2, child: TextRobotoAutoNormal("24h Change".tr, textAlign: TextAlign.end)),
              hSpacer10(),
            ],
          ),
          vSpacer5(),
          Obx(() {
            final lData = _controller.landingList.value;
            final list = _controller.selectedTab.value == 0
                ? lData.assetCoinPairs
                : (_controller.selectedTab.value == 1 ? lData.hourlyCoinPairs : lData.latestCoinPairs);
            return list.isValid
                ? ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) => MarketTrendItemView(coin: list![index]),
                    separatorBuilder: (context, index) => Container(height: 16, color: Colors.transparent),
                    itemCount: list?.length ?? 0,
                    physics: const NeverScrollableScrollPhysics(),
                  )
                : showEmptyView(height: Dimens.btnHeightMain);
          }),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  int getListLength(int listLength) {
    final length = isExpand.value ? 10 : 5;

    return listLength > length ? length : listLength;
  }
}

class MarketTrendItemView extends StatelessWidget {
  const MarketTrendItemView({super.key, required this.coin});

  final CoinPair coin;

  @override
  Widget build(BuildContext context) {
    final (sign, color) = getNumberData(coin.priceChange);
    String formattedPrice = coinFormat(coin.lastPrice);

    return InkWell(
      
      onTap: () {
        coin.coinPair = coin.getCoinPairKey();
        coin.coinPairName = coin.getCoinPairName();
        Get.to(() => CurrencyPairDetailsScreen(pair: coin));
      },
      child: Row(
        children: [
          hSpacer10(),
          
          // --- 1. ICON + COLUMN SECTION ---
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Icon: Waisa ka waisa (Network Image)
                showImageNetwork(
                  imagePath: coin.icon,
                  width: Dimens.iconSizeMin,
                  height: Dimens.iconSizeMin,
                  bgColor: Colors.transparent,
                ),
                hSpacer5(),
                
                // Column: Upar Name, Niche Price ($23k)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Upar: Coin Name (BTC/USDT)
                      AutoSizeText.rich(
                        TextSpan(
                          text: coin.childCoinName ?? '',
                          style: Get.theme.textTheme.labelMedium!.copyWith(fontSize: Dimens.fontSizeMidExtra),
                          children: <TextSpan>[
                            TextSpan(
                              text: "/${coin.parentCoinName ?? ''}",
                              style: Get.theme.textTheme.displaySmall!.copyWith(fontSize: Dimens.fontSizeSmall),
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                      // Niche: Price (e.g., $23k)
                      Text(
                            "\$23.15k", // Yahan Price add hoga
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11, // Chhota font size
                            ),
                            maxLines: 1,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          hSpacer5(),
          
          // --- 2. PRICE SECTION ---
          Expanded(
            flex: 3,
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Upar: Coin Name (BTC/USDT)
                     TextRobotoAutoBold(formattedPrice, maxLines: 1, textAlign: TextAlign.end),
                      // Niche: Price (e.g., $23k)
                      Text(
                            "\$${formattedPrice} ", // Yahan Price add hoga
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11, // Chhota font size
                            ),
                            maxLines: 1,
                          ),
                    ],
                  ),
            
            
            
          ),
          
          hSpacer20(),
          
          // --- 3. BUTTON SECTION ---
          // Expanded(
          //   flex: 2,
          //   child: buttonText(
          //     "$sign${coinFormat(coin.priceChange, fixed: 2)}%",
          //     radius: Dimens.radiusCorner,
          //     bgColor: color,
          //     textColor: Colors.white,
          //     visualDensity: VisualDensity.compact,
          //   ),
          // ),

          Expanded(
              flex: 2,
              child: SizedBox(
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(Dimens.radiusCorner),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$sign${coinFormat(coin.priceChange, fixed: 2)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          hSpacer15(),
        ],
      ),
      
    );
  }
}