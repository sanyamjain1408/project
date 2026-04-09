import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/currency.dart';
import '../../../../../data/models/wallet.dart';
import '../../../../../helper/app_helper.dart';
import '../../../../../utils/alert_util.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/decorations.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/number_util.dart';
import '../../../../../utils/qr_scanner.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_field_util.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../utils/extensions.dart';
import '../../../../ui_helper/dropdown_widgets.dart';
import '../../../side_navigation/activity/activity_screen.dart';
import '../../../side_navigation/faq/faq_page.dart';
import '../wallet_widgets.dart';
import 'wallet_crypto_withdraw_controller.dart';

class WalletCryptoWithdrawScreen extends StatefulWidget {
  const WalletCryptoWithdrawScreen({super.key, this.wallet});

  final Wallet? wallet;

  @override
  State<WalletCryptoWithdrawScreen> createState() => _WalletCryptoWithdrawScreenState();
}

class _WalletCryptoWithdrawScreenState extends State<WalletCryptoWithdrawScreen> {
  final _controller = Get.put(WalletCryptoWithdrawController());
  final _addressEditController = TextEditingController();
  final _amountEditController = TextEditingController();
  final _memoEditController = TextEditingController();
  bool isWithdraw2FActive = false;
  Timer? _feeTimer;

  @override
  void initState() {
    _controller.initController();
    isWithdraw2FActive = getSettingsLocal()?.twoFactorWithdraw == "1";
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getWithdrawCoinList(preWallet: widget.wallet);
      _controller.getHistoryListData();
      _controller.getFAQList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: appBarBackWithActions(
        title: "Withdrawal".tr,
        actionIcons: [Icons.history],
        onPress: (i) {
          TemporaryData.activityType = HistoryType.withdraw;
          Get.to(() => const ActivityScreen());
        },
      ),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(Dimens.paddingMid),
          children: [
            TextRobotoAutoBold("Withdraw Coin".tr),
            vSpacer5(),
            Obx(() {
              return DropdownViewCurrency(
                items: _controller.currencyList,
                selectedItem: _controller.selectedCurrency.value,
                onSelect: (cur) {
                  _controller.selectedCurrency.value = cur;
                  _controller.isEvm ? _controller.getWalletNetworks() : _controller.getWalletWithdrawal();
                },
              );
            }),
            Obx(() {
              return Padding(
                padding: const EdgeInsets.only(top: Dimens.paddingMid),
                child: textWithBackground(
                  "${"Balance".tr}: ${_controller.walletBalance}",
                  bgColor: Theme.of(context).secondaryHeaderColor,
                  textColor: Theme.of(context).focusColor,
                ),
              );
            }),
            Obx(() {
              if (_controller.networkList.isEmpty && _controller.selectedNetwork.value.networkType.isValid) {
                return Padding(
                  padding: const EdgeInsets.only(top: Dimens.paddingMid),
                  child: textWithBackground(
                    "${"Network".tr}: ${_controller.selectedNetwork.value.networkName}",
                    bgColor: Theme.of(context).secondaryHeaderColor,
                  ),
                );
              } else if (_controller.networkList.isValid) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    vSpacer20(),
                    TextRobotoAutoBold("Currency Network".tr),
                    vSpacer5(),
                    DropDownViewNetwork(
                      items: _controller.networkList.toList(),
                      selectedItem: _controller.selectedNetwork.value,
                      onSelect: (net) => _controller.selectedNetwork.value = net,
                    ),
                  ],
                );
              } else {
                return vSpacer0();
              }
            }),
            Obx(() {
              final net = _controller.selectedNetwork.value;
              return net.networkType.isValid || (net.id ?? 0) > 0
                  ? Container(
                    padding: const EdgeInsets.all(Dimens.paddingMid),
                    margin: const EdgeInsets.only(top: Dimens.paddingLargeExtra),
                    decoration: boxDecorationRoundCorner(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textFieldWithWidget(
                          controller: _addressEditController,
                          hint: "Address".tr,
                          labelText: "Address".tr,
                          onTextChange: _onTextChanged,
                          suffixWidget: _qrIconView(),
                        ),
                        TextRobotoAutoNormal(
                          "only_enter_valid_address_withdraw".trParams({
                            "coin": _controller.selectedCurrency.value.coinType ?? "",
                          }),
                          color: context.theme.colorScheme.error,
                          maxLines: 2,
                          fontSize: Dimens.fontSizeSmall,
                        ),
                        vSpacer10(),
                        textFieldWithSuffixIcon(
                          controller: _amountEditController,
                          hint: "Amount to withdraw".tr,
                          labelText: "Amount".tr,
                          type: const TextInputType.numberWithOptions(decimal: true),
                          onTextChange: _onTextChanged,
                        ),
                        Obx(() {
                          final preWith = _controller.preWithdrawal.value;
                          final cType = preWith.coinType ?? '';
                          final fees = preWith.fees ?? 0;
                          return cType.isNotEmpty
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextRobotoAutoNormal(
                                    "withdraw_fee_charged_amount_text".trParams({
                                      "amount": coinFormat(fees, fixed: DefaultValue.decimal),
                                      "coin": cType
                                    }),
                                    maxLines: 2,
                                    color: context.theme.primaryColor,
                                    fontSize: Dimens.fontSizeMin,
                                  ),
                                  vSpacer5(),
                                  TextRobotoAutoNormal(
                                    "withdraw_Max_min_fees".trParams({
                                      "min": coinFormat(preWith.min?.toDouble()),
                                      "max": coinFormat(preWith.max?.toDouble()),
                                    }),
                                    maxLines: 2,
                                  ),
                                ],
                              )
                              : vSpacer0();
                        }),
                        vSpacer10(),
                        textFieldWithSuffixIcon(
                          controller: _memoEditController,
                          hint: "Memo if needed".tr,
                          labelText: "Memo (optional)".tr,
                        ),
                        TextRobotoAutoNormal("ensure_memo_correct".tr, maxLines: 2),
                        vSpacer10(),
                        Obx(() {
                          final secret = gUserRx.value.google2FaSecret;
                          return (isWithdraw2FActive && !secret.isValid)
                              ? textWithBackground(
                                "Google 2FA is not enabled".tr,
                                bgColor: Colors.red.withValues(alpha: 0.25),
                                textColor: context.theme.primaryColor,
                              )
                              : vSpacer0();
                        }),
                        vSpacer20(),
                        buttonRoundedMain(text: "Withdraw".tr, onPress: () => _checkInputData()),
                      ],
                    ),
                  )
                  : vSpacer0();
            }),
            vSpacer20(),
            Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
            TextRobotoAutoBold("Recent Withdrawals".tr),
            vSpacer5(),
            Obx(() {
              final list = _controller.historyList;
              return list.isEmpty
                  ? showEmptyView(height: 50)
                  : Column(
                    children: List.generate(list.length, (index) {
                      return WalletRecentTransactionItemView(history: list[index], type: HistoryType.withdraw);
                    }),
                  );
            }),
            Obx(() => FAQRelatedView(_controller.faqList.toList())),
            vSpacer20(),
          ],
        ),
      ),
    );
  }

  InkWell _qrIconView() {
    return InkWell(
      onTap: () => Get.to(() => QRScannerPage(onData: (text) => _addressEditController.text = text)),
      child: Icon(Icons.qr_code_scanner, color: context.theme.primaryColor, size: Dimens.iconSizeMin),
    );
  }

  void _onTextChanged(String text) {
    if (_feeTimer?.isActive ?? false) _feeTimer?.cancel();
    _feeTimer = Timer(const Duration(seconds: 1), () => _getPreWithdrawDate());
  }

  void _getPreWithdrawDate() {
    final address = _addressEditController.text.trim();
    final amount = makeDecimal(_amountEditController.text.trim());
    if (address.isEmpty || amount <= Decimal.zero) {
      _controller.preWithdrawal.value = PreWithdraw();
      return;
    }
    _controller.preWithdrawProcess(address, amount);
  }

  void _checkInputData() {
    final withdraw = WithdrawalCreate();
    if (!_controller.selectedNetwork.value.networkType.isValid && (_controller.selectedNetwork.value.id ?? 0) <= 0) {
      showToast("select network".tr);
      return;
    }
    withdraw.coinId = _controller.selectedCurrency.value.id;
    withdraw.coinType = _controller.selectedCurrency.value.coinType;
    withdraw.networkType = _controller.selectedNetwork.value.networkType;
    withdraw.networkId = _controller.selectedNetwork.value.id;
    final address = _addressEditController.text.trim();
    if (address.isEmpty) {
      showToast("Address can not be empty".tr);
      return;
    }
    withdraw.address = address;
    final amount = makeDecimal(_amountEditController.text.trim());
    if (amount <= Decimal.zero) {
      showToast("amount_must_greater_than_0".tr);
      return;
    }
    final minAmount = _controller.preWithdrawal.value.min ?? Decimal.zero;
    if (amount < minAmount) {
      showToast("Amount_less_then".trParams({"amount": minAmount.toString()}));
      return;
    }
    final maxAmount = _controller.preWithdrawal.value.max ?? Decimal.zero;
    if (amount > maxAmount) {
      showToast("Amount_greater_then".trParams({"amount": maxAmount.toString()}));
      return;
    }
    withdraw.amount = amount;
    final total = amount + makeDecimal(_controller.preWithdrawal.value.fees);
    if(total > _controller.walletBalance.value){
      showToast("Insufficient balance".tr);
      return ;
    }
    if (isWithdraw2FActive && !gUserRx.value.google2FaSecret.isValid) {
      showToast("Please setup your google 2FA".tr);
      return;
    }
    hideKeyboard();
    showModalSheetFullScreen(
      context,
      WithdrawConfirmView(
        withdrawal: withdraw,
        is2FActive: isWithdraw2FActive,
        onWithdrawal: (withdrawal) {
          hideKeyboard();
          Get.back();
          withdrawal.memo = _memoEditController.text.trim();
          _controller.withdrawProcess(withdrawal);
        },
      ),
    );
  }
}

class WithdrawConfirmView extends StatelessWidget {
  const WithdrawConfirmView({
    super.key,
    required this.withdrawal,
    required this.onWithdrawal,
    required this.is2FActive,
  });

  final WithdrawalCreate withdrawal;
  final Function(WithdrawalCreate) onWithdrawal;
  final bool is2FActive;

  @override
  Widget build(BuildContext context) {
    final subTitle =
        "${"You will withdrawal".tr} ${withdrawal.amount} ${withdrawal.coinType} ${"to this address".tr} ${withdrawal.address}";
    final codeEditController = TextEditingController();
    return Column(
      children: [
        vSpacer10(),
        TextRobotoAutoBold("Withdrawal Currency".tr, fontSize: Dimens.fontSizeLarge),
        vSpacer10(),
        TextRobotoAutoBold(subTitle, maxLines: 3),
        vSpacer10(),
        if (is2FActive)
          textFieldWithSuffixIcon(controller: codeEditController, hint: "Input 2FA code".tr, labelText: "2FA code".tr),
        vSpacer15(),
        buttonRoundedMain(
          text: "Withdraw".tr,
          onPress: () {
            final code = codeEditController.text.trim();
            if (is2FActive && code.length < DefaultValue.codeLength) {
              showToast("Code length must be".trParams({"count": DefaultValue.codeLength.toString()}));
              return;
            }
            withdrawal.verifyCode = code;
            onWithdrawal(withdrawal);
          },
        ),
        vSpacer10(),
      ],
    );
  }
}
