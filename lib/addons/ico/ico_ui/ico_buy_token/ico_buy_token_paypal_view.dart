import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_widgets.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/paypal_util/paypal_payment.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'ico_buy_token_controller.dart';

class IcoBuyTokenPaypalView extends StatefulWidget {
  const IcoBuyTokenPaypalView({super.key});

  @override
  State<IcoBuyTokenPaypalView> createState() => _IcoBuyTokenPaypalViewState();
}

class _IcoBuyTokenPaypalViewState extends State<IcoBuyTokenPaypalView> {
  final _controller = Get.find<IcoBuyCoinController>();
  final amountEditController = TextEditingController();
  Rx<TokenPriceInfo> tokenPrice = TokenPriceInfo().obs;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    final phase = _controller.phase.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Obx(() => IcoTokenPriceView(token: tokenPrice.value)),
        vSpacer10(),
        buttonRoundedMain(text: "Make Payment".tr, onPress: () => _checkInputData(context)),
        vSpacer10(),
      ],
    );
  }

  void _onTextChanged(String amount) {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () => _getAndSetCoinRate());
  }

  void _getAndSetCoinRate() {
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      tokenPrice.value = TokenPriceInfo();
    } else {
      _controller.getIcoTokenPriceInfo(amount, "USD", (info) => tokenPrice.value = info);
    }
  }

  void _checkInputData(BuildContext con) {
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      showToast("Amount_less_then".trParams({"amount": "0"}));
      return;
    }
    hideKeyboard();
    Get.to(() => PaypalPayment(
        totalAmount: amount,
        onFinish: (token) {
          Future.delayed(const Duration(seconds: 1), () {
            if(con.mounted) hideKeyboard(context: con);
            final createToken = IcoCreateBuyToken(amount: amount, currency: "USD", paypalToken: token);
            _controller.icoTokenBuy(createToken, () => _clearView());
          });
        }));
  }

  void _clearView() {
    amountEditController.text = "";
    tokenPrice.value = TokenPriceInfo();
  }
}
