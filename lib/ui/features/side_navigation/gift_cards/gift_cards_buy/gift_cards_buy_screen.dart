import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/gift_card.dart';
import '../../../../ui_helper/app_widgets.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/decorations.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../utils/image_util.dart';
import '../../../../../utils/number_util.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_field_util.dart';
import '../../../../../utils/text_util.dart';
import '../gift_cards_widgets.dart';
import 'gift_cards_buy_controller.dart';

class GiftCardBuyScreen extends StatefulWidget {
  const GiftCardBuyScreen({super.key, required this.uid});

  final String uid;

  @override
  GiftCardBuyScreenState createState() => GiftCardBuyScreenState();
}

class GiftCardBuyScreenState extends State<GiftCardBuyScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(GiftCardBuyController());
  late TabController _tabController;
  GiftCardBanner? selectedBanner;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _controller.selectedCoin.value = -1;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getGiftCardBuyData(widget.uid, () => setState(() {}));
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width / 3;
    width = width + (isTextScaleGetterThanOne(context) ? 25 : 0);
    final ribbonWidth = isTextScaleGetterThanOne(context) ? 100 : 80;
    final featureList = _featureItemList();
    selectedBanner = _controller.giftCardBuyData?.selectedBanner;
    return Scaffold(
      appBar: appBarBackWithActions(title: "Buy Theme Cards".tr),
      body: SafeArea(
        child: KeyboardDismissOnTap(
          child: _controller.isLoading
              ? showLoading()
              : CustomScrollView(
                  slivers: [
                    if ((_controller.giftCardBuyData?.header.isValid ?? false) || (_controller.giftCardBuyData?.description.isValid ?? false))
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        expandedHeight: width,
                        collapsedHeight: width,
                        flexibleSpace: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                          child: GiftCardTitleView(
                              title: _controller.giftCardBuyData?.header,
                              subTitle: _controller.giftCardBuyData?.description,
                              image: _controller.giftCardBuyData?.banner),
                        ),
                      ),
                    if (featureList.isNotEmpty)
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        toolbarHeight: 90,
                        flexibleSpace: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
                          child: Row(children: featureList),
                        ),
                      ),
                    SliverAppBar(
                      backgroundColor: Get.theme.scaffoldBackgroundColor,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 50,
                      pinned: true,
                      flexibleSpace: Row(
                        children: [
                          SizedBox(
                              width: Get.width - 100,
                              child: tabBarUnderline(["Buy 1 Card".tr, "Bulk Create".tr], _tabController,
                                  isScrollable: true,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  fontSize: Dimens.fontSizeMid,
                                  onTap: (index) => _controller.selectedTab.value = index)),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: -math.pi,
                                child: showImageAsset(
                                    imagePath: AssetConstants.icRibbon,
                                    width: ribbonWidth.toDouble(),
                                    boxFit: BoxFit.fitWidth,
                                    color: Get.theme.focusColor),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(left: Dimens.paddingMid),
                                  child: TextRobotoAutoNormal("Business".tr, color: Colors.white))
                            ],
                          ),
                        ],
                      ),
                    ),
                    Obx(() {
                      final list = _buyWidgetList(_controller.selectedTab.value, _controller.selectedCoin.value);
                      return SliverPadding(
                          padding: const EdgeInsets.all(Dimens.paddingMid),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) => list[index], childCount: list.length),
                          ));
                    })
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _featureItemList() {
    List<Widget> list = [];
    if (_controller.giftCardBuyData?.featureOne.isValid ?? false) {
      list.add(_featureItemView(_controller.giftCardBuyData?.featureOne, _controller.giftCardBuyData?.featureOneIcon));
    }
    if (_controller.giftCardBuyData?.featureTwo.isValid ?? false) {
      list.add(_featureItemView(_controller.giftCardBuyData?.featureTwo, _controller.giftCardBuyData?.featureTwoIcon));
    }
    if (_controller.giftCardBuyData?.featureThree.isValid ?? false) {
      list.add(_featureItemView(_controller.giftCardBuyData?.featureThree, _controller.giftCardBuyData?.featureThreeIcon));
    }
    return list;
  }

  Expanded _featureItemView(String? title, String? url) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(
              child: Container(
                  decoration: boxDecorationRoundCorner(color: Get.theme.focusColor),
                  padding: const EdgeInsets.all(Dimens.paddingMin),
                  child: showCircleAvatar(url, size: Dimens.iconSizeLarge, ))),
          vSpacer5(),
          TextRobotoAutoBold(title ?? "", fontSize: Dimens.fontSizeMid, maxLines: 1)
        ],
      ),
    );
  }

  Container _walletListView() {
    return Container(
        decoration: boxDecorationRoundCorner(),
        padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
        child: RadioGroup<int>(
          groupValue: _controller.selectedWallet.value,
          onChanged: (int? value) {
            if (value != null) _controller.selectedWallet.value = value;
          },
          child: Column(
            children: <Widget>[
              RadioListTile(
                  value: WalletType.spot,
                  activeColor: context.theme.focusColor,
                  visualDensity: minimumVisualDensity,
                  title: TextRobotoAutoBold("Spot Wallet".tr),
                  subtitle: TextRobotoAutoNormal(
                      "${coinFormat(_controller.walletData.value.exchangeWalletBalance)} ${_controller.getCoinType()}",
                      fontSize: Dimens.fontSizeMid)),
              RadioListTile(
                  value: WalletType.p2p,
                  activeColor: context.theme.focusColor,
                  visualDensity: minimumVisualDensity,
                  title: TextRobotoAutoBold("P2P Wallet".tr),
                  subtitle: TextRobotoAutoNormal(
                      "${coinFormat(_controller.walletData.value.p2PWalletBalance)} ${_controller.getCoinType()}",
                      fontSize: Dimens.fontSizeMid)),
            ],
          ),
        )
    );
  }

  List<Widget> _buyWidgetList(int sTab, int selectedCoin) {
    final banners = _controller.giftCardBuyData?.banners;
    final amountStr = "${_controller.amount.value} ${_controller.getCoinType()}";
    double? balance;
    if(_controller.selectedWallet.value == WalletType.p2p) {
      balance = _controller.walletData.value.p2PWalletBalance;
    } else if(_controller.selectedWallet.value == WalletType.spot) {
      balance = _controller.walletData.value.exchangeWalletBalance;
    }
    // final balance = _controller.selectedWallet.value == WalletType.p2p
    //     ? _controller.walletData.value.p2PWalletBalance
    //     : _controller.walletData.value.exchangeWalletBalance;
    final availableStr = "${coinFormat(balance)} ${_controller.getCoinType()}";
    final quantity = sTab == 0 ? 1 : (_controller.quantity.value == 0 ? 1 : _controller.quantity.value);
    final totalStar = "${_controller.amount.value * quantity} ${_controller.getCoinType()}";
    List<Widget> list = [
      GiftCardImageAndTag(imagePath: selectedBanner?.banner, amountText: amountStr),
      vSpacer15(),
      TextRobotoAutoBold(selectedBanner?.title ?? "", maxLines: 5),
      vSpacer5(),
      TextRobotoAutoNormal(selectedBanner?.subTitle ?? "", maxLines: 10, color: Get.theme.primaryColor),
      dividerHorizontal(height: Dimens.btnHeightMid),
      TextRobotoAutoBold("Buy".tr),
      vSpacer5(),
      dropDownListIndex(_controller.getCoinNameList(), selectedCoin, "Select Coin".tr, hMargin: 0, (index) {
        _controller.selectedCoin.value = index;
        _controller.getGiftCardWalletData();
      }, bgColor: Colors.transparent),
      vSpacer15(),
      _walletListView(),
      vSpacer15(),
      TextRobotoAutoBold("Amount".tr),
      vSpacer5(),
      textFieldWithWidget(
          hint: "Enter Amount".tr,
          type: const TextInputType.numberWithOptions(decimal: true),
          suffixWidget: textFieldTextWidget(_controller.getCoinType(), hMargin: Dimens.paddingMid),
          onTextChange: (text) async => _controller.amount.value = makeDouble(text.trim())),
      vSpacer2(),
      twoTextView("${"Available".tr}: ", availableStr),

      if (sTab == 1)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            vSpacer15(),
            TextRobotoAutoBold("Quantity".tr, fontSize: Dimens.fontSizeMid, textAlign: TextAlign.start),
            vSpacer5(),
            textFieldWithWidget(
                hint: "Enter Quantity".tr,
                type: const TextInputType.numberWithOptions(decimal: true),
                onTextChange: (text) async => _controller.quantity.value = makeInt(text.trim())),
          ],
        ),
      vSpacer15(),
      TextRobotoAutoBold("Note (Optional)".tr),
      vSpacer5(),
      textFieldWithSuffixIcon(hint: "Enter note for this order".tr, maxLines: 3, height: 90),
      vSpacer15(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextRobotoAutoBold("Lock".tr),
                TextRobotoAutoNormal("lock_info_message".tr, maxLines: 3),
              ],
            ),
          ),
          hSpacer5(),
          toggleSwitch(selectedValue: _controller.isLock.value, onChange: (value) => _controller.isLock.value = value, height: Dimens.btnHeightMin)
        ],
      ),
      vSpacer15(),
      twoTextSpaceFixed("Total Amount".tr, totalStar),
      vSpacer15(),
      buttonRoundedMain(text: "Buy".tr, onPress: () => _controller.checkAndBuyGiftCard()),
      dividerHorizontal(height: Dimens.btnHeightMid),
      Row(children: [
        showImageAsset(imagePath: AssetConstants.icGift, height: Dimens.iconSizeMid, color: Get.theme.focusColor),
        TextRobotoAutoBold("Gift Card Store".tr, color: Get.theme.focusColor, fontSize: Dimens.fontSizeLarge)
      ]),
      vSpacer15(),
      banners.isValid
          ? Wrap(
              spacing: Dimens.paddingMid,
              runSpacing: Dimens.paddingMid,
              children: List.generate(banners!.length, (index) {
                final banner = banners[index];
                final isSelected = banner.uid == selectedBanner?.uid;
                return GiftBannerItemView(
                  gBanner: banners[index],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _controller.selectedCoin.value = -1;
                      _controller.selectedWallet.value = 0;
                      _controller.isLoading = true;
                    });
                    _controller.getGiftCardBuyData(banner.uid ?? "", () => setState(() {}));
                  },
                );
              }))
          : showEmptyView(height: Dimens.menuHeight),
      vSpacer15()
    ];

    return list;
  }
}
