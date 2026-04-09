import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/exchange_order.dart';
import '../../../../../data/models/history.dart';
import '../../../../../data/models/referral.dart';
import '../../../../../helper/app_checker.dart';
import '../../../../../ui/ui_helper/app_widgets.dart';
import '../../../../../ui/ui_helper/bank_widgets.dart';
import '../../../../../utils/alert_util.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/date_util.dart';
import '../../../../../utils/decorations.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../utils/image_util.dart';
import '../../../../../utils/number_util.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_util.dart';

class WalletFiatHistory extends StatelessWidget {
  const WalletFiatHistory({super.key, required this.history, required this.historyData, required this.type});

  final WalletCurrencyHistory history;
  final List historyData;
  final String type;

  @override
  Widget build(BuildContext context) {
   final sData = AppChecker.getWalletFiatHistoryStatusData(history.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: Dimens.btnHeightSmall, child: buttonText(historyData.first, bgColor: historyData.last,
                  fontSize: Dimens.fontSizeMidExtra, textColor: Colors.white)),
              TextRobotoAutoBold(history.coinType ?? ""),
            ],
          ),
          vSpacer5(),
          twoTextSpace('Amount'.tr, coinFormat(history.amount)),
          if (type == HistoryType.withdraw) vSpacer5(),
          if (type == HistoryType.withdraw) twoTextSpace('Fees'.tr, coinFormat(history.fees)),
          if (type == HistoryType.deposit) vSpacer5(),
          if (type == HistoryType.deposit) twoTextSpace('Payment Method'.tr, history.paymentType ?? ""),
          vSpacer5(),
          if (type == HistoryType.deposit) twoTextSpace('Payment Title'.tr, history.paymentTitle ?? ""),
          if (type == HistoryType.withdraw) twoTextSpace("Bank".tr, history.bank?.bankForm?.title ?? ""),
          vSpacer5(),
          twoTextSpace('Created At'.tr, formatDate(history.createdAt, format: dateTimeFormatYyyyMMDdHhMm)),
          vSpacer5(),
          twoTextSpace('Status'.tr,sData.first, subColor: sData.last),
          if (history.bankReceipt.isValid) vSpacer5(),
          if (history.bankReceipt.isValid)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextRobotoAutoBold("Receipt".tr, color: context.theme.primaryColorLight),
              showImageNetwork(
                  imagePath: history.bankReceipt,
                  width: Dimens.iconSizeMid,
                  height: Dimens.iconSizeMid,
                  boxFit: BoxFit.cover,
                  onPressCallback: () => openUrlInBrowser(history.bankReceipt ?? ""))
            ]),
        ],
      ),
    );
  }
}

class TradeItemView extends StatelessWidget {
  const TradeItemView(this.tradeHistory, this.historyData, this.type, {super.key});

  final Trade tradeHistory;
  final List historyData;
  final String type;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStatusData(tradeHistory.status ?? 0);
    final pcl = context.theme.primaryColorLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttonText(historyData.first, bgColor: historyData.last, visualDensity: minimumVisualDensity, fontSize: Dimens.fontSizeSmall, textColor: Colors.white),
          if (type == HistoryType.transaction) twoTextSpaceFixed('Txn ID'.tr, tradeHistory.transactionId ?? "", color: pcl),
          twoTextSpaceFixed("${'Base Coin'.tr}/${'Trade Coin'.tr}", "${tradeHistory.baseCoin ?? ""}/${tradeHistory.tradeCoin ?? ""}",
              color: pcl, flex: 7),
          twoTextSpaceFixed('Amount'.tr, coinFormat(tradeHistory.amount), color: pcl),
          if (type != HistoryType.transaction) twoTextSpaceFixed('Processed'.tr, coinFormat(tradeHistory.processed), color: pcl),
          twoTextSpaceFixed('Price'.tr, coinFormat(tradeHistory.price), color: pcl),
          if (type == HistoryType.transaction) twoTextSpaceFixed('Fees'.tr, coinFormat(tradeHistory.fees), color: pcl),
          twoTextSpaceFixed('Date'.tr,
              type == HistoryType.transaction ? (tradeHistory.time ?? "") : formatDate(tradeHistory.createdAt, format: dateTimeFormatDdMMMYyyyHhMm),
              color: pcl),
          if (type != HistoryType.transaction) twoTextSpaceFixed('Status'.tr, statusData.first, subColor: statusData.last, color: pcl),
        ],
      ),
    );
  }
}

class StopLimitItemView extends StatelessWidget {
  const StopLimitItemView(this.tradeHistory, this.historyData, {super.key});

  final Trade tradeHistory;
  final List historyData;

  @override
  Widget build(BuildContext context) {
    final pcl = context.theme.primaryColorLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttonText(historyData.first, bgColor: historyData.last, visualDensity: minimumVisualDensity, fontSize: Dimens.fontSizeSmall, textColor: Colors.white),
          twoTextSpaceFixed("${'Base Coin'.tr}/${'Trade Coin'.tr}", "${tradeHistory.baseCoin ?? ""}/${tradeHistory.tradeCoin ?? ""}",
              color: pcl, flex: 7),
          twoTextSpaceFixed('Amount'.tr, coinFormat(tradeHistory.amount), color: pcl),
          twoTextSpaceFixed('Price'.tr, coinFormat(tradeHistory.price), color: pcl),
          twoTextSpaceFixed('Order Type'.tr, tradeHistory.type ?? "", color: pcl),
          twoTextSpaceFixed('Date'.tr, formatDate(tradeHistory.createdAt, format: dateTimeFormatDdMMMYyyyHhMm), color: pcl),
        ],
      ),
    );
  }
}

class FiatHistoryItemView extends StatelessWidget {
  const FiatHistoryItemView(this.history, this.historyData, {super.key});

  final FiatHistory history;
  final List historyData;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStatusData(history.status ?? 0);
    final plc = context.theme.primaryColorLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            buttonText(historyData.first, bgColor: historyData.last, visualDensity: minimumVisualDensity, fontSize: Dimens.fontSizeSmall, textColor: Colors.white),
            (history.bank != null || history.paymentInfo.isValid)
                ? buttonOnlyIcon(
                    iconData: Icons.remove_red_eye_rounded,
                    size: Dimens.iconSizeMin,
                    iconColor: context.theme.primaryColor,
                    visualDensity: minimumVisualDensity,
                    onPress: () => _showPaymentView(context))
                : hSpacer10()
          ]),
          twoTextSpaceFixed('Currency Amount'.tr, "${coinFormat(history.currencyAmount)} ${history.currency ?? ""}", color: plc, flex: 4),
          twoTextSpaceFixed('Coin Amount'.tr, "${coinFormat(history.coinAmount)} ${history.coinType ?? ""}", color: plc, flex: 4),
          twoTextSpaceFixed('Rate'.tr, "${coinFormat(history.rate)} ${history.coinType ?? ""}", color: plc),
          if (history.transactionId.isValid) twoTextSpaceFixed('Txn ID'.tr, history.transactionId ?? "", color: plc),
          twoTextSpaceFixed('Date'.tr, formatDate(history.createdAt, format: dateTimeFormatYyyyMMDdHhMm), color: plc),
          twoTextSpaceFixed('Status'.tr, statusData.first, subColor: statusData.last, color: plc),
        ],
      ),
    );
  }

  void _showPaymentView(BuildContext context) {
    final view = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vSpacer10(),
        TextRobotoAutoBold("Payment Details".tr, fontSize: Dimens.fontSizeLarge),
        vSpacer20(),
        if (history.bank != null)
          DynamicBankDetailsView(dBank: history.bank!)
        else if (history.paymentInfo.isValid)
          Container(
              decoration: boxDecorationRoundBorder(),
              width: Get.width,
              padding: const EdgeInsets.all(Dimens.paddingMid),
              child: TextRobotoAutoBold(history.paymentInfo ?? "")),
        vSpacer20(),
      ],
    );
    showModalSheetFullScreen(context, view);
  }
}

class ReferralItemView extends StatelessWidget {
  const ReferralItemView(this.history, this.historyData, this.type, {super.key});

  final ReferralHistory history;
  final List historyData;
  final String type;

  @override
  Widget build(BuildContext context) {
    final pcl = context.theme.primaryColorLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttonText(historyData.first, bgColor: historyData.last, visualDensity: minimumVisualDensity, fontSize: Dimens.fontSizeSmall, textColor: Colors.white),
          twoTextSpaceFixed('User Email'.tr, history.referralUserEmail ?? "", color: pcl),
          twoTextSpaceFixed('Txn ID'.tr, history.transactionId ?? "", color: pcl),
          twoTextSpaceFixed('Amount'.tr, "${coinFormat(history.amount)} ${history.coinType}", color: pcl),
          twoTextSpaceFixed('Date'.tr, formatDate(history.createdAt, format: dateTimeFormatDdMMMYyyyHhMm), color: pcl),
        ],
      ),
    );
  }
}

class HistoryItemView extends StatelessWidget {
  const HistoryItemView(this.history, this.historyData, this.type, {super.key});

  final History history;
  final List historyData;
  final String type;

  @override
  Widget build(BuildContext context) {
    List statusData =  AppChecker.getStatusData(history.status ?? 0);
    if(type == HistoryType.deposit || type == HistoryType.withdraw){
      statusData = AppChecker.getWalletCryptoHistoryStatusData(history.status);
    }
    final pcl = context.theme.primaryColorLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buttonText(historyData.first, bgColor: historyData.last, visualDensity: minimumVisualDensity, fontSize: Dimens.fontSizeSmall, textColor: Colors.white),
              TextRobotoAutoBold(history.coinType ?? "")
            ],
          ),
          twoTextSpaceFixed('Amount'.tr, coinFormat(history.amount), color: pcl),
          twoTextSpaceFixed('Fees'.tr, coinFormat(history.fees), color: pcl),
          twoTextSpaceFixed('Address'.tr, history.address ?? "", color: pcl),
          if (type == HistoryType.deposit) twoTextSpaceFixed('Txn ID'.tr, history.transactionId ?? "", color: pcl),
          if (type == HistoryType.withdraw) twoTextSpaceFixed('Txn Hash'.tr, history.transactionHash ?? "", color: pcl),
          twoTextSpaceFixed('Created At'.tr, formatDate(history.createdAt, format: dateTimeFormatDdMMMYyyyHhMm), color: pcl),
          twoTextSpaceFixed('Status'.tr, statusData.first, subColor: statusData.last, color: pcl),
        ],
      ),
    );
  }
}

class SwapHistoryItemView extends StatelessWidget {
  const SwapHistoryItemView(this.swapHistory, this.historyData, {super.key});

  final SwapHistory swapHistory;
  final List historyData;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStatusData(swapHistory.status ?? 0);
    final pcl = context.theme.primaryColorLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttonText(historyData.first, bgColor: historyData.last, visualDensity: minimumVisualDensity, fontSize: Dimens.fontSizeSmall, textColor: Colors.white),
          twoTextSpaceFixed('From'.tr, swapHistory.fromWallet ?? "", color: pcl),
          twoTextSpaceFixed('To'.tr, swapHistory.toWallet ?? "", color: pcl),
          twoTextSpaceFixed('Req Amount'.tr, coinFormat(swapHistory.requestedAmount), color: pcl),
          twoTextSpaceFixed('Conv Amount'.tr, coinFormat(swapHistory.convertedAmount), color: pcl),
          twoTextSpaceFixed('Rate'.tr, coinFormat(swapHistory.rate), color: pcl),
          twoTextSpaceFixed('Created At'.tr, formatDate(swapHistory.createdAt, format: dateTimeFormatDdMMMYyyyHhMm), color: pcl),
          twoTextSpaceFixed('Status'.tr, statusData.first, subColor: statusData.last, color: pcl),
        ],
      ),
    );
  }
}
