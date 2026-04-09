import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/paypal_util/paypal_payment.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'wallet_fiat_deposit_controller.dart';

class WalletFiatPaypalDepositView extends StatefulWidget {
  const WalletFiatPaypalDepositView({super.key});

  @override
  State<WalletFiatPaypalDepositView> createState() => _WalletFiatPaypalDepositViewState();
}

class _WalletFiatPaypalDepositViewState extends State<WalletFiatPaypalDepositView> {
  final _controller = Get.find<WalletFiatDepositController>();
  TextEditingController amountEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        vSpacer10(),
        TwoTextSpaceFixed("Enter amount".tr, "USD", color: context.theme.primaryColor),
        vSpacer5(),
        textFieldWithWidget(controller: amountEditController, hint: "Enter amount".tr, type: const TextInputType.numberWithOptions(decimal: true)),
        vSpacer20(),
        buttonRoundedMain(text: "Next".tr, onPress: () => _checkInputData())
      ],
    );
  }

  void _checkInputData() {
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      showToast("Amount_less_then".trParams({"amount": "0"}));
      return;
    }
    Get.to(() => PaypalPayment(
        totalAmount: amount,
        onFinish: (token) {
          Future.delayed(const Duration(seconds: 1), () {
            final deposit = CreateDeposit(walletId: _controller.wallet.id, amount: amount, currency: "USD", paypalToken: token);
            _controller.walletCurrencyDeposit(deposit, () => _clearView());
          });
        }));
  }

  void _clearView() {
    amountEditController.text = "";
  }
}
