import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_widgets.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'ico_buy_token_controller.dart';

class IcoBuyTokenWalletView extends StatefulWidget {
  const IcoBuyTokenWalletView({super.key});

  @override
  State<IcoBuyTokenWalletView> createState() => _IcoBuyTokenWalletViewState();
}

class _IcoBuyTokenWalletViewState extends State<IcoBuyTokenWalletView> {
  final _controller = Get.find<IcoBuyCoinController>();
  final amountEditController = TextEditingController();
  RxInt selectedWalletIndex = 0.obs;
  Rx<TokenPriceInfo> tokenPrice = TokenPriceInfo().obs;
  Timer? _timer;

  @override
  void initState() {
    selectedWalletIndex.value = -1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _controller.phase.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextRobotoAutoBold("Quantity of token".tr),
      vSpacer5(),
      textFieldWithSuffixIcon(
          controller: amountEditController,
          type: const TextInputType.numberWithOptions(decimal: true),
          hint: "Enter Quantity".tr,
          contentPadding: const EdgeInsets.all(Dimens.paddingLarge),
          onTextChange: _onTextChanged),
      TextRobotoAutoNormal(
          "${"Min amount".tr} ${coinFormat(phase.minimumPurchasePrice)} ${"Max amount".tr} ${coinFormat(phase.maximumPurchasePrice)}",
          maxLines: 2),
      vSpacer10(),
      TextRobotoAutoBold("Select Currency".tr),
      Obx(() => dropDownListIndex(_controller.getWalletList(), selectedWalletIndex.value, "Select Currency".tr, (index) {
            selectedWalletIndex.value = index;
            _getAndSetCoinRate();
          }, hMargin: 0, bgColor: Colors.transparent)),
      Obx(() => IcoTokenPriceView(token: tokenPrice.value)),
      vSpacer10(),
      buttonRoundedMain(text: "Make Payment".tr, onPress: () => _checkInputData()),
      vSpacer10(),
    ]);
  }

  void _onTextChanged(String amount) {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () => _getAndSetCoinRate());
  }

  void _getAndSetCoinRate() {
    if (selectedWalletIndex.value == -1) return;
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      tokenPrice.value = TokenPriceInfo();
    } else {
      final wallet = _controller.buySettings.value.wallet![selectedWalletIndex.value];
      _controller.getIcoTokenPriceInfo(amount, wallet.coinType ?? "", (info) => tokenPrice.value = info, payerWallet: wallet.id);
    }
  }

  void _checkInputData() {
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      showToast("Amount_less_then".trParams({"amount": "0"}));
      return;
    }
    if (selectedWalletIndex.value == -1) {
      showToast("select your currency".tr);
      return;
    }
    hideKeyboard(context: context);
    final wallet = _controller.buySettings.value.wallet?[selectedWalletIndex.value];
    final createToken = IcoCreateBuyToken(amount: amount, currency: wallet?.coinType ?? "", payerWallet: wallet?.id);
    _controller.icoTokenBuy(createToken, () => _clearView());
  }

  void _clearView() {
    selectedWalletIndex.value = -1;
    amountEditController.text = "";
    tokenPrice.value = TokenPriceInfo();
  }
}
