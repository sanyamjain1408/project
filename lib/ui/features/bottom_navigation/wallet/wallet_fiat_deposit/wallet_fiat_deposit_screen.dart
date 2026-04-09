import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';

import '../../../side_navigation/activity/activity_screen.dart';
import 'wallet_fiat_bank_deposit_view.dart';
import 'wallet_fiat_card_deposit_view.dart';
import 'wallet_fiat_pay_stack_deposit_view.dart';
import 'wallet_fiat_deposit_controller.dart';
import 'wallet_fiat_paypal_deposit_view.dart';

class WalletFiatDepositScreen extends StatefulWidget {
  const WalletFiatDepositScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  WalletFiatDepositScreenState createState() => WalletFiatDepositScreenState();
}

class WalletFiatDepositScreenState extends State<WalletFiatDepositScreen> with TickerProviderStateMixin {
  final _controller = Get.put(WalletFiatDepositController());

  @override
  void initState() {
    _controller.wallet = widget.wallet;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getFiatDepositData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Fiat Deposit".tr,
          actionIcons: [Icons.history],
          onPress: (i) {
            TemporaryData.activityType = HistoryType.deposit;
            Get.to(() => const ActivityScreen());
          }),
      body: SafeArea(child: Obx(() {
        final methodList = _controller.getMethodList(_controller.fiatDepositData.value);
        return _controller.isLoading.value
            ? showLoading()
            : methodList.isEmpty
                ? showEmptyView(message: "Payment methods not available".tr, height: Dimens.mainContendGapTop)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      vSpacer10(),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid), child: TextRobotoAutoBold("Select Method".tr)),
                      dropDownListIndex(methodList, _controller.selectedMethodIndex.value, "Select Method".tr,
                          (value) => _controller.selectedMethodIndex.value = value,
                          bgColor: Colors.transparent),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(Dimens.paddingMid),
                          children: [
                            _openPaymentView(_controller.selectedMethodIndex.value),
                            vSpacer20(),
                          ],
                        ),
                      )
                    ],
                  );
      })),
    );
  }

  Widget _openPaymentView(int selected) {
    final methods = _controller.fiatDepositData.value.paymentMethods?[selected];
    switch (methods?.paymentMethod) {
      case PaymentMethodType.bank:
        return const WalletFiatBankDepositView();
      case PaymentMethodType.card:
        return const WalletFiatCardDepositView();
      case PaymentMethodType.paypal:
        return const WalletFiatPaypalDepositView();
      case PaymentMethodType.payStack:
        return const WalletFiatPayStackDepositView();
      default:
        return Container();
    }
  }
}
