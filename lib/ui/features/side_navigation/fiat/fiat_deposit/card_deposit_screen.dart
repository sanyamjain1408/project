import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'fiat_deposit_controller.dart';

class CardDepositScreen extends StatefulWidget {
  const CardDepositScreen({super.key});

  @override
  State<CardDepositScreen> createState() => _CardDepositScreenState();
}

class _CardDepositScreenState extends State<CardDepositScreen> {
  final _controller = Get.find<FiatDepositController>();
  CardFieldInputDetails? _cardFieldInputDetails;
  RxString stripToken = "".obs;
  TextEditingController amountEditController = TextEditingController();
  TextEditingController coinEditController = TextEditingController();
  Timer? _timer;
  Rx<Wallet> selectedWallet = Wallet(id: 0).obs;
  RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    initStripe();
  }

  Future<void> initStripe() async {
    try {
      final stKey = dotenv.env[EnvKeyValue.kStripKey];
      if (stKey.isValid) {
        Stripe.publishableKey = stKey!;
        await Stripe.instance.applySettings();
      } else {
        showToast("Stripe key not found");
      }
      isLoading.value = false;
    } catch (e) {
      showToast(e.toString(), isLong: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => isLoading.value
        ? showLoading()
        : Column(
            children: [
              vSpacer10(),
              Obx(() => stripToken.value.isEmpty ? _cardInputView() : _amountInputView()),
              vSpacer20(),
              buttonRoundedMain(text: "Deposit".tr, onPress: () => _checkInputData())
            ],
          ));
  }

  Widget _cardInputView() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMin),
      child: CardField(
        enablePostalCode: true,
        style: context.textTheme.displaySmall?.copyWith(color: Get.theme.primaryColor),
        onCardChanged: (cDetails) => _cardFieldInputDetails = cDetails,
        decoration: InputDecoration(labelText: 'Card Field'.tr),
      ),
    );
  }

  Widget _amountInputView() {
    return Column(
      children: [
        twoTextSpace("Enter amount".tr, "Currency(USD)".tr),
        vSpacer5(),
        textFieldWithWidget(
            controller: amountEditController,
            hint: "Enter amount".tr,
            onTextChange: _onTextChanged,
            type: const TextInputType.numberWithOptions(decimal: true)),
        vSpacer20(),
        twoTextSpace("Converted amount".tr, "Select Wallet".tr),
        vSpacer5(),
        textFieldWithWidget(
            controller: coinEditController,
            hint: "0",
            readOnly: true,
            suffixWidget: Obx(() => walletsSuffixView(_controller.fiatDepositData.value.walletList ?? [], selectedWallet.value, onChange: (selected) {
                  selectedWallet.value = selected;
                  _getAndSetCoinRate();
                }))),
      ],
    );
  }

  void _onTextChanged(String amount) {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      _getAndSetCoinRate();
    });
  }

  void _getAndSetCoinRate() {
    if (selectedWallet.value.id == 0) return;
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      coinEditController.text = "0";
    } else {
      _controller.getCurrencyDepositRate(
          selectedWallet.value.id, amount, currency: "USD", (rate) => coinEditController.text = coinFormat(rate, fixed: 10));
    }
  }

  Future<void> _checkInputData() async {
    if (stripToken.value.isEmpty) {
      try {
        if (!Stripe.publishableKey.isValid || Stripe.publishableKey == EnvKeyValue.kStripKey) {
          showToast("Invalid Strip key".tr);
          return;
        }
      } catch (error) {
        showToast(error is StripeConfigException ? error.message : error.toString());
      }

      if (_cardFieldInputDetails != null &&
          _cardFieldInputDetails!.complete &&
          _cardFieldInputDetails!.validNumber == CardValidationState.Valid &&
          _cardFieldInputDetails!.validExpiryDate == CardValidationState.Valid &&
          _cardFieldInputDetails!.validCVC == CardValidationState.Valid) {
        try {
          final paymentMethod = await Stripe.instance.createToken(const CreateTokenParams.card(params: CardTokenParams(type: TokenType.Card)));
          stripToken.value = paymentMethod.id;
        } catch (error) {
          showToast(error is StripeException ? (error.error.localizedMessage ?? "") : error.toString());
        }
      } else {
        showToast("Please input valid card details".tr);
      }
    } else {
      if (selectedWallet.value.id == 0) {
        showToast("select your wallet".tr);
        return;
      }
      final amount = makeDouble(amountEditController.text.trim());
      if (amount <= 0) {
        showToast("Amount_less_then".trParams({"amount": "0"}));
        return;
      }
      final deposit = CreateDeposit(walletId: selectedWallet.value.id, amount: amount, stripeToken: stripToken.value, currency: "USD");
      _controller.currencyDepositProcess(deposit, () => _clearView());
    }
  }

  void _clearView() {
    selectedWallet.value = Wallet(id: 0);
    amountEditController.text = "";
    coinEditController.text = "";
    stripToken.value = "";
  }
}
