import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/wallet.dart';
import '../../../../ui_helper/app_widgets.dart';
import '../../../../../utils/alert_util.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_field_util.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../utils/extensions.dart';
import '../../../../ui_helper/dropdown_widgets.dart';
import 'check_deposit_controller.dart';

class CheckDepositPage extends StatefulWidget {
  const CheckDepositPage({super.key,  this.fromKey});
  final String? fromKey;

  @override
  State<CheckDepositPage> createState() => _CheckDepositPageState();
}

class _CheckDepositPageState extends State<CheckDepositPage> {
  final _controller = Get.put(CheckDepositController());
  final _tranController = TextEditingController();


  @override
  void initState() {
    _controller.initController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getCoinList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if(widget.fromKey == FromKey.wallet){
      return _mainView(context);
    }else {
      return Scaffold(
        appBar: appBarBackWithActions(title: "Check Deposit".tr),
        body: _mainView(context),
      );
    }
  }

  ListView _mainView(BuildContext context){
      return ListView(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        shrinkWrap: true,
        children: [
          textWithBackground("Check_deposit_message".tr, maxLines: 10, bgColor: Theme.of(context).focusColor.withValues(alpha: 0.1)),
          vSpacer20(),
          TextRobotoAutoBold("Deposited Coin".tr),
          vSpacer5(),
          Obx(() {
            return DropdownViewCurrency(
              items: _controller.currencyList,
              selectedItem: _controller.selectedCurrency.value,
              onSelect: (cur) {
                _controller.selectedCurrency.value = cur;
                if(_controller.isEvm) _controller.getWalletNetworks();
              },
            );
          }),
          if(_controller.isEvm)
          Obx(() {
            return _controller.selectedCurrency.value.coinType.isValid
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                vSpacer20(),
                TextRobotoAutoBold("Currency Network".tr),
                vSpacer5(),
                DropDownViewNetwork(
                  items: _controller.networkList.toList(),
                  selectedItem: _controller.selectedNetwork.value,
                  onSelect: (net) {
                    _controller.selectedNetwork.value = net;
                  },
                ),
              ],
            ) : vSpacer0();
          }),
          Obx(() {
            final netId = _controller.selectedNetwork.value.id ?? 0;
            if(!_controller.isEvm || (_controller.isEvm && netId > 0)){
              return  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  vSpacer20(),
                  TextRobotoAutoBold("Transaction ID".tr),
                  vSpacer5(),
                  textFieldWithSuffixIcon(controller: _tranController, hint: "Enter transaction id".tr),
                  vSpacer20(),
                  buttonRoundedMain(text: "Submit".tr, onPress: () => _onCheckDeposit()),
                ],
              );
            } else {
              return vSpacer0();
            }
          }),
          vSpacer10(),
          Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
          vSpacer10(),
        ],
      );

  }


  void _onCheckDeposit() {
    final coinId = _controller.selectedCurrency.value.id ?? 0;
    if (coinId <= 0) {
      showToast("select your coin".tr);
      return;
    }
    int netId = 0;
    if(_controller.isEvm){
      netId = _controller.selectedNetwork.value.id  ?? 0;
      if (netId <= 0) {
        showToast("select network".tr);
        return;
      }
    }else{
      netId = _controller.selectedCurrency.value.network ?? 0;
    }

    final transaction = _tranController.text.trim();
    if (transaction.isEmpty) {
      showToast("enter transaction id".tr);
      return;
    }
    hideKeyboard();
    _controller.checkCoinTransaction(netId, coinId, transaction, (deposit) {
      showModalSheetFullScreen(context, CheckDepositDetailsView(deposit: deposit));
    });
  }
}

class CheckDepositDetailsView extends StatelessWidget {
  const CheckDepositDetailsView({super.key, required this.deposit});

  final CheckDeposit deposit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextRobotoAutoBold("Deposit Info".tr),
        dividerHorizontal(),
        vSpacer10(),
        twoTextSpaceFixed("Network".tr, deposit.network ?? '', subMaxLine: 2),
        vSpacer5(),
        twoTextSpaceFixed("Amount".tr, (deposit.amount ?? 0).toString(), subMaxLine: 2),
        vSpacer10(),
        TextRobotoAutoBold("Address".tr, fontSize: Dimens.fontSizeMid),
        vSpacer2(),
        TextRobotoAutoNormal(deposit.address ?? '', maxLines: 2, color: context.theme.primaryColor),
        vSpacer10(),
        TextRobotoAutoBold("From Address".tr, fontSize: Dimens.fontSizeMid),
        vSpacer2(),
        TextRobotoAutoNormal(deposit.fromAddress ?? '', maxLines: 2, color: context.theme.primaryColor),
        vSpacer10(),
        TextRobotoAutoBold("Transaction ID".tr, fontSize: Dimens.fontSizeMid),
        vSpacer2(),
        TextRobotoAutoNormal(deposit.txId ?? '', maxLines: 2, color: context.theme.primaryColor),
        vSpacer10(),
        dividerHorizontal(),
        TextRobotoAutoBold(deposit.message ?? '', maxLines: 2, fontSize: Dimens.fontSizeMid),
        vSpacer10(),
      ],
    );
  }
}
