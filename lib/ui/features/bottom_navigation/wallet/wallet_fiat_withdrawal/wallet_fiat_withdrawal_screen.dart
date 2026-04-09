import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../side_navigation/activity/activity_screen.dart';
import 'wallet_fiat_withdraw_views.dart';
import 'wallet_fiat_withdrawal_controller.dart';

class WalletFiatWithdrawalScreen extends StatefulWidget {
  const WalletFiatWithdrawalScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  WalletFiatWithdrawalScreenState createState() => WalletFiatWithdrawalScreenState();
}

class WalletFiatWithdrawalScreenState extends State<WalletFiatWithdrawalScreen> {
  final _controller = Get.put(WalletFiatWithdrawalController());

  @override
  void initState() {
    _controller.wallet = widget.wallet;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (gUserRx.value.id > 0) _controller.getFiatWithdrawal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(
          title: "Fiat Withdraw".tr,
          actionIcons: [Icons.history],
          onPress: (i) {
            TemporaryData.activityType = HistoryType.withdraw;
            Get.to(() => const ActivityScreen());
          }),
      body: SafeArea(child: Obx(() {
        final methodList = _controller.getMethodList(_controller.fiatWithdrawalData.value);
        PaymentMethod? method;
        if (methodList.isValid) method = _controller.fiatWithdrawalData.value.paymentMethodList?[_controller.selectedMethodIndex.value];
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
                            WalletFiatWithdrawViews(paymentType: method?.paymentMethod),
                            vSpacer20(),
                          ],
                        ),
                      )
                    ],
                  );
      },)),
    );
  }
}
