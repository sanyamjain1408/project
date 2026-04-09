import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';

class WalletOverviewPage extends StatefulWidget {
  const WalletOverviewPage({super.key});

  @override
  State<WalletOverviewPage> createState() => _WalletOverviewPageState();
}

class _WalletOverviewPageState extends State<WalletOverviewPage> {
  final _controller = Get.find<WalletController>();
  Rx<WalletOverview> wOverview = WalletOverview().obs;
  RxString selectedCoin = "".obs;

  Future<void> _getOverviewData() async {
    _controller.refreshController.callRefresh();
    _controller.getWalletOverviewData(coinType: selectedCoin.value, (overview) {
      wOverview.value = overview;
      selectedCoin.value = wOverview.value.selectedCoin ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      controller: _controller.refreshController,
      refreshOnStart: true,
      onRefresh: _getOverviewData,
      header: ClassicHeader(showText: false, iconTheme: const IconThemeData().copyWith(color: context.theme.focusColor)),
      child: Obx(() {
        final data = wOverview.value;
        final settings = getSettingsLocal();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
          shrinkWrap: true,
          children: [
            Obx(() => TotalBalanceView(
                  gIsBalanceHide.value,
                  data.total,
                  title: 'Estimated Balance'.tr,
                  totalUsd: data.totalUsd,
                  onHistoryTap: () => Get.to(() => const ActivityScreen()),
                  coins: data.coins,
                  selectedCoin: selectedCoin.value,
                  onSelectCoin: (selected) {
                    selectedCoin.value = selected;
                    _getOverviewData();
                  },
                )),
            vSpacer10(),
            const WalletTopButtonsView(),
            dividerHorizontal(height: Dimens.paddingLargeDouble),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextRobotoAutoNormal('Asset'.tr, fontSize: Dimens.fontSizeMid),
                TextRobotoAutoNormal('Available Balance'.tr, fontSize: Dimens.fontSizeMid)
              ],
            ),
            vSpacer5(),
            if (data.spotWallet != null)
              AssetItemView(
                  icon: Icons.dashboard_outlined,
                  name: "Spot".tr,
                  amount: data.spotWallet,
                  amountCurrency: data.spotWalletUsd,
                  coinType: data.selectedCoin,
                  isBalanceHide: gIsBalanceHide.value,
                  onTap: () => _controller.changeWalletTab(WalletViewType.spot)),
            if (settings?.enableFutureTrade == 1 && data.futureWallet != null)
              AssetItemView(
                  icon: Icons.update_outlined,
                  name: "Future".tr,
                  amount: data.futureWallet,
                  amountCurrency: data.futureWalletUsd,
                  coinType: data.selectedCoin,
                  isBalanceHide: gIsBalanceHide.value,
                  onTap: () => _controller.changeWalletTab(WalletViewType.future)),
            if (settings?.p2pModule == 1 && data.p2PWallet != null)
              AssetItemView(
                  icon: Icons.people_outline,
                  name: "P2P".tr,
                  amount: data.p2PWallet,
                  amountCurrency: data.p2PWalletUsd,
                  coinType: data.selectedCoin,
                  isBalanceHide: gIsBalanceHide.value,
                  onTap: () => _controller.changeWalletTab(WalletViewType.p2p)),
            dividerHorizontal(height: Dimens.paddingLargeDouble),
            if (data.spotWallet != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextRobotoAutoBold('Recent Transactions'.tr),
                      buttonTextBordered("View All".tr, false, onPress: () {
                        TemporaryData.activityType = HistoryType.transaction;
                        Get.to(() => const ActivityScreen());
                      }, radius: Dimens.radiusCorner, visualDensity: VisualDensity.compact),
                    ],
                  ),
                  vSpacer5(),
                  if (data.withdraw.isValid)
                    for (final withdraw in data.withdraw!) HistoryItemView(history: withdraw, isWithdraw: true, coinType: data.selectedCoin),
                  if (data.deposit.isValid)
                    for (final deposit in data.withdraw!) HistoryItemView(history: deposit, isWithdraw: false, coinType: data.selectedCoin),
                  if (!data.deposit.isValid && !data.withdraw.isValid) const EmptyView(),
                ],
              ),
          ],
        );
      }),
    );
  }
}

class AssetItemView extends StatelessWidget {
  const AssetItemView(
      {super.key, required this.icon, required this.name, this.amount, this.amountCurrency, this.coinType, required this.onTap, this.isBalanceHide});

  final IconData icon;
  final String name;
  final double? amount;
  final double? amountCurrency;
  final String? coinType;
  final Function() onTap;
  final bool? isBalanceHide;

  @override
  Widget build(BuildContext context) {
    String currencyName = getSettingsLocal()?.currency ?? DefaultValue.currency;
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  showImageAsset(icon: icon, width: Dimens.iconSizeMid, height: Dimens.iconSizeMid, color: context.theme.primaryColorLight),
                  hSpacer5(),
                  Expanded(child: TextRobotoAutoBold(name, fontSize: Dimens.fontSizeLarge, color: context.theme.primaryColorLight)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: isBalanceHide == true
                  ? const TextRobotoAutoBold("******", fontSize: Dimens.fontSizeMid)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextRobotoAutoBold("${coinFormat(amount)} $coinType", fontSize: Dimens.fontSizeMid),
                        TextRobotoAutoNormal(currencyFormat(amountCurrency, name: currencyName)),
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class HistoryItemView extends StatelessWidget {
  const HistoryItemView({super.key, required this.history, required this.isWithdraw, this.coinType});

  final History history;
  final bool isWithdraw;
  final String? coinType;

  @override
  Widget build(BuildContext context) {
    final icon = isWithdraw ? Icons.file_upload_outlined : Icons.file_download_outlined;
    final title = isWithdraw ? "Withdraw".tr : "Deposit".tr;
    final sign = isWithdraw ? "-" : "+";
    return Container(
      decoration: boxDecorationRoundBorder(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
      child: InkWell(
        // onTap: () => showModalSheetFullScreen(context, _walletDetailsView(wallet)),
        child: Row(
          children: [
            showImageAsset(icon: icon, width: Dimens.iconSizeMid, height: Dimens.iconSizeMid),
            hSpacer5(),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRobotoAutoBold(title, fontSize: Dimens.fontSizeMid),
                  vSpacer5(),
                  TextRobotoAutoNormal(formatDate(history.createdAt)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextRobotoAutoBold("$sign${coinFormat(history.amount)} $coinType", fontSize: Dimens.fontSizeMid),
                  vSpacer5(),
                  TextRobotoAutoNormal("Completed".tr, color: Colors.green),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
