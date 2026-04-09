import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/wallet.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/decorations.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/image_util.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../utils/extensions.dart';
import '../../../../ui_helper/dropdown_widgets.dart';
import '../../../side_navigation/activity/activity_screen.dart';
import '../../../side_navigation/faq/faq_page.dart';
import '../check_deposit/check_deposit_page.dart';
import '../wallet_widgets.dart';
import 'wallet_crypto_deposit_controller.dart';

class WalletCryptoDepositScreen extends StatefulWidget {
  const WalletCryptoDepositScreen({super.key, this.wallet});

  final Wallet? wallet;

  @override
  State<WalletCryptoDepositScreen> createState() => _WalletCryptoDepositScreenState();
}

class _WalletCryptoDepositScreenState extends State<WalletCryptoDepositScreen> {
  final _controller = Get.put(WalletCryptoDepositController());

  @override
  void initState() {
    _controller.initController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getDepositCoinList(preCode: widget.wallet?.coinType);
      _controller.getHistoryListData();
      _controller.getFAQList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eColor = context.theme.colorScheme.error;
    return Scaffold(
      appBar: appBarBackWithActions(
        title: "Deposit".tr,
        actionIcons: [Icons.history],
        onPress: (i) {
          TemporaryData.activityType = HistoryType.deposit;
          Get.to(() => const ActivityScreen());
        },
      ),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(Dimens.paddingMid),
          children: [
            TextRobotoAutoBold("Deposit Coin".tr),
            vSpacer5(),
            Obx(() {
              return DropdownViewCurrency(
                items: _controller.currencyList,
                selectedItem: _controller.selectedCurrency.value,
                onSelect: (cur) {
                  _controller.selectedCurrency.value = cur;
                  _controller.isEvm ? _controller.getWalletNetworks() : _controller.getWalletDeposit();
                },
              );
            }),
            Obx(() {
              if (_controller.networkList.isEmpty && _controller.selectedNetwork.value.networkType.isValid) {
                return Padding(
                  padding: const EdgeInsets.only(top: Dimens.paddingLargeExtra),
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
                      onSelect: (net) {
                        _controller.selectedNetwork.value = net;
                        _controller.isEvm ? _controller.getWalletDepositAddress() : _controller.getWalletNetworkAddress();
                      },
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
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            showImageAsset(icon: Icons.warning_outlined, iconSize: Dimens.iconSizeMin, color: eColor),
                            hSpacer5(),
                            TextRobotoAutoBold("Warning".tr, color: eColor, fontSize: Dimens.fontSizeLarge),
                          ],
                        ),
                        vSpacer5(),
                        TextRobotoAutoNormal(
                          "Sending_any_other_asset_message".trParams({
                            "coinName": _controller.selectedCurrency.value.coinType ?? "",
                          }),
                          maxLines: 5,
                          color: eColor,
                        ),
                        vSpacer10(),
                        Obx(() {
                          return CryptoDepositAddressView(
                            depositAddress: _controller.depositAddress.value,
                            isLoading: _controller.isLoading.value,
                          );
                        }),
                      ],
                    ),
                  )
                  : vSpacer0();
            }),
            vSpacer20(),
            Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
            CheckDepositButtonView(),
            TextRobotoAutoBold("Recent Deposits".tr),
            vSpacer5(),
            Obx(() {
              final list = _controller.historyList;
              return list.isEmpty
                  ? showEmptyView(height: 50)
                  : Column(
                    children: List.generate(list.length, (index) {
                      return WalletRecentTransactionItemView(history: list[index], type: HistoryType.deposit);
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
}

class CheckDepositButtonView extends StatelessWidget {
  const CheckDepositButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingLarge),
      decoration: boxDecorationRoundCorner(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextRobotoAutoBold("Having trouble with your deposit".tr),
                vSpacer5(),
                TextRobotoAutoNormal("You can manually check the status of your transaction".tr, maxLines: 2),
              ],
            ),
          ),
          hSpacer5(),
          buttonTextBordered("Check".tr, true, onPress: () => Get.to(() => CheckDepositPage())),
        ],
      ),
    );
  }
}

class CryptoDepositAddressView extends StatelessWidget {
  const CryptoDepositAddressView({super.key, required this.depositAddress, required this.isLoading});

  final WalletAddress depositAddress;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final address = depositAddress.address ?? "";
    final tokenAddress = depositAddress.tokenAddress ?? "";
    return address.isValid
        ? Container(
          width: context.width,
          padding: const EdgeInsets.all(Dimens.paddingMid),
          decoration: boxDecorationRoundBorder(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextRobotoAutoBold("Deposit Address".tr),
              vSpacer10(),
              Align(alignment: Alignment.center, child: qrView(address)),
              vSpacer20(),
              textWithCopyButton(address),
              if (depositAddress.rentedTill != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextRobotoAutoNormal(
                    "${"Exp AT".tr} ${formatDate(depositAddress.rentedTill, format: dateTimeFormatDdMMMMYyyyHhMm)}",
                    textAlign: TextAlign.end,
                  ),
                ),
              if (tokenAddress.isNotEmpty) vSpacer20(),
              if (tokenAddress.isNotEmpty)
                Theme(
                  data: context.theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: TextRobotoAutoBold("Contract Address".tr, maxLines: 10),
                    backgroundColor: Theme.of(context).secondaryHeaderColor,
                    collapsedIconColor: context.theme.primaryColor,
                    iconColor: context.theme.primaryColor,
                    children: <Widget>[textWithCopyButton(tokenAddress)],
                  ),
                ),
              vSpacer10(),
            ],
          ),
        )
        : !isLoading
        ? Padding(padding: const EdgeInsets.all(Dimens.paddingMid), child: TextRobotoAutoBold("No Address Found".tr))
        : vSpacer0();
  }
}

// class _WalletCryptoDepositScreenState extends State<WalletCryptoDepositScreen> {
//   final _controller = Get.put(WalletCryptoDepositController());
//
//   @override
//   void initState() {
//     _controller.initController();
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//       _controller.getDepositCoinList(preCode: widget.wallet?.coinType);
//       _controller.getHistoryListData();
//       _controller.getFAQList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final eColor = context.theme.colorScheme.error;
//     return Scaffold(
//       appBar: appBarBackWithActions(
//         title: "Deposit".tr,
//         actionIcons: [Icons.history],
//         onPress: (i) {
//           TemporaryData.activityType = HistoryType.deposit;
//           Get.to(() => const ActivityScreen());
//         },
//       ),
//       body: SafeArea(
//         child: ListView(
//           shrinkWrap: true,
//           padding: const EdgeInsets.all(Dimens.paddingMid),
//           children: [
//             TextRobotoAutoBold("Deposit Coin".tr),
//             vSpacer5(),
//             Obx(() {
//               return DropdownViewCurrency(
//                 items: _controller.currencyList,
//                 selectedItem: _controller.selectedCurrency.value,
//                 onSelect: (cur) {
//                   _controller.selectedCurrency.value = cur;
//                   _controller.isEvm ? _controller.getWalletNetworks() : _controller.getWalletDeposit();
//                 },
//               );
//             }),
//             Obx(() {
//               return _controller.selectedCurrency.value.coinType.isValid
//                   ? Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       vSpacer20(),
//                       TextRobotoAutoBold("Currency Network".tr),
//                       vSpacer5(),
//                       DropDownViewNetwork(
//                         items: _controller.networkList.toList(),
//                         selectedItem: _controller.selectedNetwork.value,
//                         onSelect: (net) {
//                           _controller.selectedNetwork.value = net;
//                           _controller.getWalletDepositAddress();
//                         },
//                       ),
//                     ],
//                   )
//                   : vSpacer0();
//             }),
//             Obx(() {
//               return _controller.selectedNetwork.value.networkType.isValid
//                   ? Container(
//                     padding: const EdgeInsets.all(Dimens.paddingMid),
//                     margin: const EdgeInsets.only(top: Dimens.paddingLargeExtra),
//                     decoration: boxDecorationRoundCorner(),
//                     child: Column(
//                       children: [
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             showImageAsset(icon: Icons.warning_outlined, iconSize: Dimens.iconSizeMin, color: eColor),
//                             hSpacer5(),
//                             TextRobotoAutoBold("Warning".tr, color: eColor, fontSize: Dimens.fontSizeLarge),
//                           ],
//                         ),
//                         vSpacer5(),
//                         TextRobotoAutoNormal(
//                           "Sending_any_other_asset_message".trParams({
//                             "coinName": _controller.selectedCurrency.value.coinType ?? "",
//                           }),
//                           maxLines: 5,
//                           color: eColor,
//                         ),
//                         vSpacer10(),
//                         Obx(() {
//                           final address = _controller.depositAddress.value.address ?? "";
//                           final tokenAddress = _controller.depositAddress.value.tokenAddress ?? "";
//                           return address.isValid
//                               ? Container(
//                                 width: context.width,
//                                 padding: const EdgeInsets.all(Dimens.paddingMid),
//                                 decoration: boxDecorationRoundBorder(),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     TextRobotoAutoBold("Deposit Address".tr),
//                                     vSpacer10(),
//                                     Align(alignment: Alignment.center, child: qrView(address)),
//                                     vSpacer20(),
//                                     textWithCopyButton(address),
//                                     if(tokenAddress.isNotEmpty) vSpacer20(),
//                                     if(tokenAddress.isNotEmpty) Theme(
//                                       data: context.theme.copyWith(dividerColor: Colors.transparent),
//                                       child: ExpansionTile(
//                                         title: TextRobotoAutoBold("Contract Address".tr, maxLines: 10),
//                                         backgroundColor: Theme.of(context).secondaryHeaderColor,
//                                         collapsedIconColor: context.theme.primaryColor,
//                                         iconColor: context.theme.primaryColor,
//                                         children: <Widget>[textWithCopyButton(tokenAddress)],
//                                       ),
//                                     ),
//                                     vSpacer10(),
//                                   ],
//                                 ),
//                               )
//                               : !_controller.isLoading.value
//                               ? Padding(
//                                 padding: const EdgeInsets.all(Dimens.paddingMid),
//                                 child: TextRobotoAutoBold("No Address Found".tr),
//                               )
//                               : vSpacer0();
//                         }),
//                       ],
//                     ),
//                   )
//                   : vSpacer0();
//             }),
//             vSpacer20(),
//             Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
//             CheckDepositButtonView(),
//             TextRobotoAutoBold("Recent Deposits".tr),
//             vSpacer5(),
//             Obx(() {
//               final list = _controller.historyList;
//               return list.isEmpty
//                   ? showEmptyView(height: 50)
//                   : Column(
//                     children: List.generate(list.length, (index) {
//                       return WalletRecentTransactionItemView(history: list[index], type: HistoryType.deposit);
//                     }),
//                   );
//             }),
//             Obx(() => FAQRelatedView(_controller.faqList.toList())),
//             vSpacer20(),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class CheckDepositButtonView extends StatelessWidget {
//   const CheckDepositButtonView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(Dimens.paddingMid),
//       margin: const EdgeInsets.symmetric(vertical: Dimens.paddingLarge),
//       decoration: boxDecorationRoundCorner(),
//       child: Row(children: [
//         Expanded(child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//           TextRobotoAutoBold("Having trouble with your deposit".tr),
//           vSpacer5(),
//           TextRobotoAutoNormal("You can manually check the status of your transaction".tr, maxLines: 2),
//         ],)),
//         buttonTextBordered("Check".tr, true, onPress: ()=> Get.to(() =>  CheckDepositPage()))
//       ],),
//     );
//   }
// }
//
