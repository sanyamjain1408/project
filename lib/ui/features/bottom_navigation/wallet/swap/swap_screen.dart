import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../side_navigation/activity/activity_screen.dart';
import '../../wallet_selection_page.dart';
import 'swap_controller.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key, this.preWallet, this.prePair});

  final Wallet? preWallet;
  final CoinPair? prePair;

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _controller = Get.put(SwapController());
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getCoinSwapApp(preWallet: widget.preWallet, pair: widget.prePair);
      _controller.fromEditController.text = 1.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(
          title: "Swap Coin".tr,
          actionIcons: [Icons.history],
          onPress: (i) {
            TemporaryData.activityType = HistoryType.swap;
            Get.to(() => const ActivityScreen());
          }),
      body: SafeArea(child: Obx(() {
        final fCoin = _controller.selectedFromCoin.value;
        final tCoin = _controller.selectedToCoin.value;
        return ListView(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          children: [
            vSpacer20(),
            Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
                      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingLargeExtra),
                      child: Column(
                        children: [
                          TwoTextSpaceFixed("Pay".tr, "${"Avail".tr} ${coinFormat(fCoin.balance ?? fCoin.availableBalance)}",
                              subColor: context.theme.primaryColorLight),
                          vSpacer10(),
                          Row(
                            children: [
                              Expanded(child: TextFormFieldSwap(controller: _controller.fromEditController, onTextChange: _onTextChanged)),
                              buttonText("Max".tr,
                                  bgColor: Colors.transparent,
                                  textColor: context.theme.focusColor,
                                  visualDensity: VisualDensity.compact,
                                  onPress: () {
                                    _controller.fromEditController.text = coinFormat(fCoin.balance ?? fCoin.availableBalance);
                                    _controller.getAndSetCoinRate();
                                  }),
                              SwapWalletSelectionView(
                                  wallet: fCoin,
                                  onTap: () => showBottomSheetFullScreen(
                                      context,
                                      WalletSelectionPage(
                                          fromKey: FromKey.swap,
                                          walletList: _controller.walletList,
                                          onSelect: (selected) {
                                            _controller.selectedFromCoin.value = selected;
                                            _controller.getAndSetCoinRate();
                                          }),
                                      title: "Pay".tr)),
                            ],
                          )
                        ],
                      ),
                    ),
                    vSpacer5(),
                    Container(
                      decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
                      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingLargeExtra),
                      child: Column(
                        children: [
                          TwoTextSpaceFixed("Get".tr, "${"Balance".tr}: ${coinFormat(tCoin.balance ?? tCoin.availableBalance)}",
                              subColor: context.theme.primaryColorLight),
                          vSpacer10(),
                          Row(
                            children: [
                              Expanded(child: TextFormFieldSwap(controller: _controller.toEditController, enabled: false)),
                              SwapWalletSelectionView(
                                  wallet: tCoin,
                                  onTap: () => showBottomSheetFullScreen(
                                      context,
                                      WalletSelectionPage(
                                          fromKey: FromKey.swap,
                                          walletList: _controller.walletList,
                                          onSelect: (selected) {
                                            _controller.selectedToCoin.value = selected;
                                            _controller.getAndSetCoinRate();
                                          }),
                                      title: "Get".tr)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _swapCoinSelectView(),
                  child: Container(
                    decoration: boxDecorationRoundCorner(radius: Dimens.radiusCornerLarge),
                    padding: const EdgeInsets.all(Dimens.paddingMin),
                    child: Container(
                      decoration: boxDecorationRoundCorner(radius: Dimens.radiusCornerLarge, color: context.theme.dialogTheme.backgroundColor),
                      padding: const EdgeInsets.all(Dimens.paddingMin),
                      child: Icon(Icons.swap_calls, color: context.theme.primaryColorLight, size: Dimens.iconSizeMin),
                    ),
                  ),
                ),
              ],
            ),
            _coinRateView(),
            vSpacer20(),
            buttonRoundedMain(text: "Convert".tr, onPress: () => _checkInputData())
          ],
        );
      })),
    );
  }

  void _swapCoinSelectView() {
    final fromCoin = _controller.selectedFromCoin.value;
    final toCoin = _controller.selectedToCoin.value;
    _controller.selectedToCoin.value = fromCoin;
    _controller.selectedFromCoin.value = toCoin;
    _controller.getAndSetCoinRate();
  }

  Widget _coinRateView() {
    return Obx(() => Column(children: [
          vSpacer10(),
          TwoTextSpaceFixed("Price".tr,
              "1 ${_controller.selectedFromCoin.value.coinType ?? ""} = ${_controller.rate.value} ${_controller.selectedToCoin.value.coinType ?? ""}"),
          TwoTextSpaceFixed("You will get".tr, "${_controller.convertRate.value} ${_controller.selectedToCoin.value.coinType ?? ""}",
              subColor: context.theme.focusColor),
          vSpacer10(),
        ]));
  }

  void _onTextChanged(String amount) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _controller.getAndSetCoinRate();
    });
  }

  void _checkInputData() {
    var amount = makeDouble(_controller.fromEditController.text.trim());
    if (amount <= 0) {
      showToast("Invalid amount".tr);
      return;
    }
    final from = _controller.selectedFromCoin.value;
    if (amount > (from.balance ?? from.availableBalance ?? 0)) {
      showToast("Insufficient balance".tr);
      return;
    }
    hideKeyboard();
    final to = _controller.selectedToCoin.value;
    final subTitle =
        "${"You will swap".tr} $amount ${from.coinType ?? ""} ${"To".tr.toLowerCase()} ${_controller.convertRate.value} ${to.coinType ?? ""}";
    alertForAction(context,
        title: "Swap".tr, subTitle: subTitle, buttonTitle: "Convert".tr, onOkAction: () => _controller.swapCoinProcess(from.id, to.id, amount));
  }
}

class TextFormFieldSwap extends StatelessWidget {
  const TextFormFieldSwap({super.key, this.controller, this.hint, this.onTextChange, this.enabled});

  final TextEditingController? controller;
  final String? hint;
  final bool? enabled;
  final Function(String)? onTextChange;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: Get.theme.textTheme.labelMedium?.copyWith(fontSize: Dimens.titleFontSizeMid),
      maxLines: 1,
      enabled: enabled,
      cursorColor: context.theme.focusColor,
      onChanged: onTextChange,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        hintText: hint ?? "0.00",
        contentPadding: const EdgeInsets.all(Dimens.paddingMid),
        hintStyle: Get.theme.textTheme.labelMedium?.copyWith(fontSize: Dimens.titleFontSizeMid, color: context.theme.primaryColorLight),
      ),
    );
  }
}

class SwapWalletSelectionView extends StatelessWidget {
  const SwapWalletSelectionView({super.key, required this.wallet, required this.onTap});

  final Wallet? wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: boxDecorationRoundBorder(radius: Dimens.radiusCornerLarge),
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            hSpacer5(),
            TextRobotoAutoBold(wallet?.coinType ?? "Select".tr),
            Icon(Icons.arrow_drop_down, size: Dimens.iconSizeMin, color: context.theme.primaryColorLight)
          ],
        ),
      ),
    );
  }
}
