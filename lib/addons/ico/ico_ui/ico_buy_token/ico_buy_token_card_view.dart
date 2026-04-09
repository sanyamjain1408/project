import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_widgets.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'ico_buy_token_controller.dart';

class IcoBuyTokenCardView extends StatefulWidget {
  const IcoBuyTokenCardView({super.key});

  @override
  State<IcoBuyTokenCardView> createState() => _IcoBuyTokenCardViewState();
}

class _IcoBuyTokenCardViewState extends State<IcoBuyTokenCardView> {
  final _controller = Get.find<IcoBuyCoinController>();
  final amountEditController = TextEditingController();
  RxString stripToken = "".obs;
  CardFieldInputDetails? _cardFieldInputDetails;
  RxInt selectedCurrencyIndex = 0.obs;
  Rx<TokenPriceInfo> tokenPrice = TokenPriceInfo().obs;
  Timer? _timer;
  RxBool isLoading = true.obs;

  @override
  void initState() {
    selectedCurrencyIndex.value = -1;
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
    return Obx(() => isLoading.value ? showLoading() : Obx(() => stripToken.value.isEmpty ? _cardInputView() : _amountInputView()));
  }

  Column _cardInputView() {
    return Column(
      children: [
        vSpacer10(),
        Container(
          height: 100,
          alignment: Alignment.center,
          decoration: boxDecorationRoundCorner(),
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMin),
          child: CardField(
            enablePostalCode: true,
            style: context.textTheme.labelMedium,
            onCardChanged: (cDetails) => _cardFieldInputDetails = cDetails,
            decoration: InputDecoration(
                labelText: 'Card Field'.tr,
                focusColor: context.theme.focusColor,
                labelStyle: context.textTheme.labelMedium?.copyWith(fontSize: Dimens.fontSizeLarge)),
          ),
        ),
        vSpacer10(),
        buttonRoundedMain(text: "Next".tr, onPress: () => _checkInputData(), buttonHeight: Dimens.btnHeightMid),
        vSpacer10(),
      ],
    );
  }

  Widget _amountInputView() {
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
        vSpacer10(),
        TextRobotoAutoBold("Select Currency".tr),
        Obx(() => dropDownListIndex(_controller.getCurrencyList(), selectedCurrencyIndex.value, "Select Currency".tr, (index) {
              selectedCurrencyIndex.value = index;
              _getAndSetCoinRate();
            }, hMargin: 0, bgColor: Colors.transparent)),
        Obx(() => IcoTokenPriceView(token: tokenPrice.value)),
        vSpacer10(),
        buttonRoundedMain(text: "Make Payment".tr, onPress: () => _checkInputData()),
        vSpacer10(),
      ],
    );
  }

  void _onTextChanged(String amount) {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () => _getAndSetCoinRate());
  }

  void _getAndSetCoinRate() {
    if (selectedCurrencyIndex.value == -1) return;
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      tokenPrice.value = TokenPriceInfo();
    } else {
      final currency = _controller.buySettings.value.currencyList![selectedCurrencyIndex.value];
      _controller.getIcoTokenPriceInfo(amount, currency.code ?? "", (info) => tokenPrice.value = info);
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
      final amount = makeDouble(amountEditController.text.trim());
      if (amount <= 0) {
        showToast("Amount_less_then".trParams({"amount": "0"}));
        return;
      }

      if (selectedCurrencyIndex.value == -1) {
        showToast("select your currency".tr);
        return;
      }
      hideKeyboard(context: context);
      final currency = _controller.buySettings.value.currencyList?[selectedCurrencyIndex.value];
      final createToken = IcoCreateBuyToken(amount: amount, currency: currency?.code ?? "", stripeToken: stripToken.value);
      _controller.icoTokenBuy(createToken, () => _clearView());
    }
  }

  void _clearView() {
    selectedCurrencyIndex.value = -1;
    amountEditController.text = "";
    stripToken.value = "";
    tokenPrice.value = TokenPriceInfo();
  }
}
