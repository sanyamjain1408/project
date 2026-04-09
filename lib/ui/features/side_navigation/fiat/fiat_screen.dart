import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'fiat_deposit/fiat_deposit_screen.dart';
import 'fiat_withdrawal/fiat_withdrawal_page.dart';

class FiatScreen extends StatefulWidget {
  const FiatScreen({super.key});

  @override
  FiatScreenState createState() => FiatScreenState();
}

class FiatScreenState extends State<FiatScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  RxInt selectedTabIndex = 0.obs;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Row(children: [
                buttonOnlyIcon(onPress: () => Get.back(), iconPath: AssetConstants.icArrowLeft, size: 22, iconColor: Get.theme.primaryColor),
                Expanded(
                  child: tabBarUnderline(["Fiat To Crypto Deposit".tr, "Crypto To Fiat Withdrawal".tr], _tabController,
                      indicatorColor: context.theme.focusColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      fontSize: Dimens.fontSizeMid,
                      isScrollable: true,
                      onTap: (index) => selectedTabIndex.value = index),
                ),
              ]),
              vSpacer20(),
              Obx(() {
                return gUserRx.value.id == 0
                    ? signInNeedView()
                    : selectedTabIndex.value == 0 ? const FiatDepositScreen() : const FiatWithdrawalPage();
              },)

            ],
          ),
        )
    );
  }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: appBarBackWithActions(title: "Fiat".tr),
//     body: Obx(() {
//       return gUserRx.value.id == 0
//           ? signInNeedView()
//           : Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
//                   child: tabBarUnderline(["Crypto Deposit".tr, "Fiat Withdrawal".tr], _tabController,
//                       indicatorColor: context.theme.focusColor,
//                       fontSize: Dimens.fontSizeMid,
//                       isScrollable: false,
//                       onTap: (index) => selectedTabIndex.value = index),
//                 ),
//                 vSpacer20(),
//                 selectedTabIndex.value == 0 ? const FiatDepositScreen() : const FiatWithdrawalPage()
//               ],
//             );
//     }),
//   );
// }
}
