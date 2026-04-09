import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/trade_widgets.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import '../../../models/p2p_ads.dart';
import '../../../p2p_constants.dart';
import 'p2p_create_ads_controller.dart';
import 'p2p_create_ads_page_one.dart';
import 'p2p_create_ads_page_three.dart';
import 'p2p_create_ads_page_two.dart';

class P2pCreateAdsPage extends StatefulWidget {
  const P2pCreateAdsPage({super.key, this.editableAds, this.isBuy});

  final P2PAds? editableAds;
  final bool? isBuy;

  @override
  State<P2pCreateAdsPage> createState() => _P2pCreateAdsPageState();
}

class _P2pCreateAdsPageState extends State<P2pCreateAdsPage> {
  final _controller = Get.put(P2pCreateAdsController());

  @override
  void initState() {
    _controller.isEdit = widget.editableAds?.uid?.isValid ?? false;
    super.initState();
    _controller.selectedCoin.value = -1;
    _controller.selectedCurrency.value = -1;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_controller.adsSettings == null) {
        _controller.getAdsCreateSetting(() {
          setState(() => _setPreviousData());
        });
      } else {
        _setPreviousData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.adsPrice.value = P2PAdsPrice();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
          appBar: appBarBackWithActions(title: _controller.isEdit ? "Edit Advertisement".tr : "Create Advertisement".tr),
          body: SafeArea(
            child: Column(
              children: [
                // if (!_controller.isEdit)
                Obx(() {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                    child: BuySellToggleButton(
                        options: ['I want to Buy'.tr, 'I want to Sell'.tr],
                        selected: _controller.selectedAdType.value,
                        onSelect: (index) => _controller.isEdit ? null : _controller.selectedAdType.value = index),
                  );
                }),
                vSpacer10(),
                _controller.isDataLoading
                    ? showLoading()
                    : Expanded(
                        child: PageView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _controller.pageController,
                          onPageChanged: (int page) => setState(() => _controller.currentPageCreate = page),
                          children: const [CreateAdsPageOne(), CreateAdsPageTwo(), CreateAdsPageThree()],
                        ),
                      )
              ],
            ),
          )),
    );
  }

  void _setPreviousData() {
    if (widget.editableAds != null) {
      _controller.currentAds = widget.editableAds;
      _controller.selectedAdType.value = widget.isBuy == true ? 0 : 1;
      final coinType = _controller.adsSettings?.assets?.indexWhere((element) => element.coinType == _controller.currentAds?.coinType) ?? 0;
      _controller.selectedCoin.value = coinType;
      final currency = _controller.adsSettings?.currency?.indexWhere((element) => element.currencyCode == _controller.currentAds?.currency) ?? 0;
      _controller.selectedCurrency.value = currency;

      final priceType = _controller.currentAds?.priceType ?? P2pPriceType.fixed;
      _controller.selectedPriceType.value = priceType;
      if (priceType == P2pPriceType.floating) {
        _controller.priceEditController.text = (_controller.currentAds?.priceRate ?? 0).toString();
        _controller.isUpdatePrice = false;
      }
      _controller.getAdsPrice(_controller.currentAds?.coinType ?? "", _controller.currentAds?.currency ?? "");

      _controller.priceEditController.text = (_controller.currentAds?.price ?? 0).toString();
      _controller.amountEditController.text = (_controller.currentAds?.amount ?? 0).toString();
      _controller.minEditController.text = (_controller.currentAds?.minimumTradeSize ?? 0).toString();
      _controller.maxEditController.text = (_controller.currentAds?.maximumTradeSize ?? 0).toString();

      final payIdList = _controller.currentAds?.paymentMethod?.split(",") ?? [];
      for (final uid in payIdList) {
        // final payment = (_controller.adsSettings?.paymentMethods ?? []).firstWhereOrNull((element) => element.uid == uid)?.adminPaymentMethod?.name;
        final payment = (_controller.adsSettings?.paymentMethods ?? []).firstWhereOrNull((element) => element.id.toString() == uid)?.bankForm?.title;
        if (payment.isValid) _controller.selectedPayMethods.add(payment!);
      }

      final payTime = _controller.currentAds?.paymentTimes;
      if (payTime != null) {
        final index = _controller.adsSettings?.paymentTime?.indexWhere((element) => element.time == payTime);
        if (index != null && index != -1) _controller.selectedTime.value = index + 1;
      }

      _controller.termsEditController.text = _controller.currentAds?.terms ?? "";
      _controller.replyEditController.text = _controller.currentAds?.autoReply ?? "";
      if ((_controller.currentAds?.registerDays ?? 0) > 0) {
        _controller.regiEditController.text = _controller.currentAds!.registerDays.toString();
      }
      if ((_controller.currentAds?.coinHolding ?? 0) > 0) {
        _controller.holdingEditController.text = _controller.currentAds!.coinHolding.toString();
      }

      final countryList = _controller.currentAds?.country?.split(",") ?? [];
      for (final code in countryList) {
        final country = _controller.adsSettings?.country?.firstWhere((element) => element.key == code).value;
        if (country.isValid) _controller.selectedCountryList.add(country!);
      }
    }
  }
}
