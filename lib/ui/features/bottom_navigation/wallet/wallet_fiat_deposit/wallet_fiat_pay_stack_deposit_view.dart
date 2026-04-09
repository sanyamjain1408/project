import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/paystack_util.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'wallet_fiat_deposit_controller.dart';

class WalletFiatPayStackDepositView extends StatefulWidget {
  const WalletFiatPayStackDepositView({super.key});

  @override
  State<WalletFiatPayStackDepositView> createState() => _WalletFiatPayStackDepositViewState();
}

class _WalletFiatPayStackDepositViewState extends State<WalletFiatPayStackDepositView> {
  final _controller = Get.find<WalletFiatDepositController>();
  final amountEditController = TextEditingController();
  final emailEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vSpacer10(),
        TwoTextSpaceFixed("Enter amount".tr, "USD", color: context.theme.primaryColor),
        vSpacer5(),
        textFieldWithWidget(controller: amountEditController, hint: "Enter amount".tr, type: const TextInputType.numberWithOptions(decimal: true)),
        vSpacer10(),
        TextRobotoAutoBold("Email address".tr),
        vSpacer5(),
        textFieldWithWidget(controller: emailEditController, hint: "Enter Email".tr.capitalizeFirst),
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
    final email = emailEditController.text.trim();
    if (!GetUtils.isEmail(email)) {
      showToast("Input a valid Email".tr);
      return;
    }
    hideKeyboard();
    _controller.payStackPaymentUrlGet(amount, email, (pData) {
      Get.to(() => PayStackPaymentPage(
          paystackData: pData,
          onFinish: (trxData) {
            final deposit = CreateDeposit(walletId: _controller.wallet.id, amount: amount, transactionId: trxData.trxId, currency: "USD");
            _controller.walletCurrencyDeposit(deposit, () => _clearView());
          }));
    });
  }

  void _clearView() {
    amountEditController.text = "";
    emailEditController.text = "";
  }
}
