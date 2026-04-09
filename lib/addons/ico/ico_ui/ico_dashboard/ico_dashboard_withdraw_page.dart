import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_constants.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'ico_dashboard_controller.dart';

class IcoDashboardWithdrawPage extends StatefulWidget {
  const IcoDashboardWithdrawPage({super.key});

  @override
  State<IcoDashboardWithdrawPage> createState() => _IcoDashboardWithdrawPageState();
}

class _IcoDashboardWithdrawPageState extends State<IcoDashboardWithdrawPage> {
  final _controller = Get.find<IcoDashboardController>();
  final amountEditController = TextEditingController();
  final payDetailsEditController = TextEditingController();
  RxInt selectedCurrencyType = 0.obs;
  RxInt selectedCurrency = 0.obs;
  Timer? _timer;
  RxString infoMessage = "".obs;

  @override
  void initState() {
    selectedCurrencyType.value = -1;
    selectedCurrency.value = -1;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getIcoTokenEarns());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final earn = _controller.icoWithdrawData.value.earns;
      final currency = earn?.currency ?? '';
      return _controller.isLoading.value
          ? showLoading()
          : Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Dimens.paddingMid),
                children: [
                  vSpacer10(),
                  Row(
                    children: [
                      Expanded(
                          child:
                              TotalView(title: "Total Earned".tr, value: "${coinFormat(earn?.earn)} $currency", icon: Icons.calendar_month_outlined)),
                      hSpacer10(),
                      Expanded(
                          child: TotalView(title: "Withdrawal Amount".tr, value: "${coinFormat(earn?.withdraw)} $currency", icon: Icons.open_in_new)),
                    ],
                  ),
                  vSpacer10(),
                  TotalView(
                    icon: Icons.event_available_outlined,
                    title: "Available Amount".tr,
                    value: "${coinFormat(earn?.available)} $currency",
                  ),
                  vSpacer20(),
                  TextRobotoAutoBold("Currency Type".tr),
                  Obx(() {
                    final list = _controller.icoWithdrawData.value.currencyTypes?.values.toList() ?? [];
                    return dropDownListIndex(list, selectedCurrencyType.value, "Select Currency Type".tr, (index) {
                      selectedCurrency.value = -1;
                      selectedCurrencyType.value = index;
                    }, hMargin: 0, bgColor: Colors.transparent);
                  }),
                  vSpacer10(),
                  TextRobotoAutoBold("Currency".tr),
                  Obx(() {
                    final list = _getCurrencyList(selectedCurrencyType.value, false);
                    return dropDownListIndex(list, selectedCurrency.value, "Select Currency".tr, (index) {
                      selectedCurrency.value = index;
                      _getWithdrawPrice();
                    }, hMargin: 0, bgColor: Colors.transparent);
                  }),
                  vSpacer10(),
                  TextRobotoAutoBold("Amount".tr, fontSize: Dimens.fontSizeMidExtra),
                  vSpacer5(),
                  textFieldWithSuffixIcon(
                      controller: amountEditController,
                      type: const TextInputType.numberWithOptions(decimal: true),
                      hint: "Enter Amount".tr,
                      contentPadding: const EdgeInsets.all(Dimens.paddingLarge),
                      onTextChange: _onTextChanged),
                  vSpacer2(),
                  Obx(() => infoMessage.value.isNotEmpty ? TextRobotoAutoNormal(infoMessage.value, maxLines: 3) : vSpacer0()),
                  Obx(
                    () {
                      return getSelectedCurrencyType(selectedCurrencyType.value) == IcoCurrencyType.fiat
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                vSpacer10(),
                                TextRobotoAutoBold("Payment Details".tr),
                                vSpacer5(),
                                textFieldWithSuffixIcon(
                                    controller: payDetailsEditController,
                                    hint: "Enter payment details".tr,
                                    maxLines: 3,
                                    height: Dimens.menuHeightSettings)
                              ],
                            )
                          : vSpacer0();
                    },
                  ),
                  vSpacer20(),
                  buttonRoundedMain(text: "Withdraw".tr, onPress: () => _checkAndMakeWithdraw()),
                  vSpacer10()
                ],
              ),
            );
    });
  }

  List<String> _getCurrencyList(int type, bool isKey) {
    if (type != -1) {
      final key = getSelectedCurrencyType(type);
      if (key == IcoCurrencyType.fiat) {
        return _controller.icoWithdrawData.value.currencies?.map((e) => (isKey ? e.code : e.name) ?? "").toList() ?? [];
      } else if (key == IcoCurrencyType.crypto) {
        return _controller.icoWithdrawData.value.coins?.map((e) => e.coinType ?? "").toList() ?? [];
      }
    }
    return [];
  }

  void _onTextChanged(String amount) {
    if (_timer?.isActive ?? false) _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () => _getWithdrawPrice());
  }

  int? getSelectedCurrencyType(int selected) {
    if (selected != -1) {
      final list = _controller.icoWithdrawData.value.currencyTypes?.keys.toList();
      if (list.isValid) {
        return makeInt(list![selectedCurrencyType.value]);
      }
    }
    return null;
  }

  void _getWithdrawPrice() {
    if (selectedCurrencyType.value == -1 || selectedCurrency.value == -1) return;
    final amount = makeDouble(amountEditController.text.trim());
    if (amount == 0) {
      infoMessage.value = "";
      return;
    } else if (amount < 0) {
      infoMessage.value = "amount_must_greater_than_0".tr;
      return;
    } else {
      final type = getSelectedCurrencyType(selectedCurrencyType.value);
      final currency = _getCurrencyList(selectedCurrencyType.value, true)[selectedCurrency.value];
      _controller.icoTokenWithdrawPrice(amount, (type ?? "").toString(), currency, (error) {
        if (error.isValid) {
          infoMessage.value = error!;
        } else {
          infoMessage.value = "";
        }
      });
    }
  }

  void _checkAndMakeWithdraw() {
    if (selectedCurrencyType.value == -1) {
      showToast("Select_currency_type".tr);
      return;
    }
    if (selectedCurrency.value == -1) {
      showToast("select your currency".tr);
      return;
    }
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      showToast("amount_must_greater_than_0".tr);
      return;
    }
    final type = getSelectedCurrencyType(selectedCurrencyType.value);
    String? payDetails = payDetailsEditController.text.trim();
    if (type == IcoCurrencyType.fiat) {
      if (payDetails.isEmpty) {
        showToast("payment details is required".tr);
        return;
      }
    } else {
      payDetails = null;
    }
    final currency = _getCurrencyList(selectedCurrencyType.value, true)[selectedCurrency.value];
    _controller.icoTokenWithdrawRequest(amount, (type ?? "").toString(), currency, payDetails: payDetails, () {
      selectedCurrencyType.value = -1;
      selectedCurrency.value = -1;
      amountEditController.text = "";
      payDetailsEditController.text = "";
      infoMessage.value = "";
    });
  }
}
