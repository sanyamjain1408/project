import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ico_constants.dart';
import '../model/ico_phase.dart';
import '../model/ico_settings.dart';
import '../../../utils/date_util.dart';
import '../../../utils/decorations.dart';
import '../../../utils/dimens.dart';
import '../../../utils/image_util.dart';
import '../../../utils/number_util.dart';
import '../../../utils/spacers.dart';
import '../../../utils/text_util.dart';
import '../../../data/models/bank_data.dart';
import '../../../ui/ui_helper/app_widgets.dart';
import '../../../utils/common_utils.dart';
import 'ico_phase_details_page.dart';

class IcoPhaseItemView extends StatelessWidget {
  const IcoPhaseItemView({super.key, required this.phase});

  final IcoPhase phase;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => ICOPhaseDetailsPage(phase: phase)),
      child: Container(
          decoration: boxDecorationRoundCorner(),
          padding: const EdgeInsets.all(Dimens.paddingMid),
          margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
          child: Column(
            children: [
              Row(children: [
                showImageNetwork(imagePath: phase.image, width: Dimens.iconSizeLargeExtra, height: Dimens.iconSizeLargeExtra, boxFit: BoxFit.contain),
                hSpacer10(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextRobotoAutoNormal("Available".tr),
                    TextRobotoAutoBold("${coinFormat(phase.availableTokenSupply)} ${phase.coinType ?? ""}"),
                  ],
                ),
                const Spacer(),
                TextRobotoAutoBold((phase.totalParticipated ?? 0).toString(), fontSize: Dimens.fontSizeLarge),
                hSpacer2(),
                Icon(Icons.people, size: Dimens.iconSizeMin, color: context.theme.focusColor)
              ]),
              vSpacer10(),
              TwoTextSpaceFixed("${"Sale Price".tr}: ", "1 ${phase.coinType ?? ""} = ${coinFormat(phase.coinPrice)} ${phase.coinCurrency ?? ""}", tFontSize: Dimens.fontSizeSmall),
              TwoTextSpaceFixed("${"End Time".tr}: ", formatDate(phase.endDate, format: dateTimeFormatDdMMMYyyyHhMm), tFontSize: Dimens.fontSizeSmall),
            ],
          )),
    );
  }
}

class IcoPhaseInfoView extends StatelessWidget {
  const IcoPhaseInfoView({super.key, required this.phase, this.flex, this.fromPage});

  final IcoPhase phase;
  final int? flex;
  final String? fromPage;

  @override
  Widget build(BuildContext context) {
    final cType = phase.coinType ?? "";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Expanded(child: TotalView(value: "${coinFormat(phase.totalTokenSupply)} $cType", title: "Tokens Offered".tr)),
          hSpacer10(),
          Expanded(child: TotalView(value: "${coinFormat(phase.soldPhaseTokens)} $cType", title: "Tokens Sold".tr)),
        ],
      ),
      vSpacer10(),
      Row(
        children: [
          Expanded(child: TotalView(value: "${coinFormat(phase.availableTokenSupply)} $cType", title: "Tokens Available".tr)),
          hSpacer10(),
          Expanded(child: TotalView(value: phase.totalParticipated, title: "Participants".tr)),
        ],
      ),
      vSpacer10(),
      if (fromPage == IcoFromKey.details)
        Column(children: [
          TwoTextFixed("${"Sale Price".tr}: ", "1 ${phase.coinType ?? ""} = ${coinFormat(phase.coinPrice)} ${phase.coinCurrency ?? ""}"),
          TwoTextFixed("${"Base Coin".tr}: ", phase.baseCoin ?? ""),
          TwoTextFixed("${"Token Type".tr}: ", phase.network ?? ""),
        ])
      else if (fromPage == IcoFromKey.buyToken)
        Column(children: [
          TwoTextFixed("${"Sale Price".tr}: ", "1 ${phase.coinType ?? ""} = ${coinFormat(phase.coinPrice)} ${phase.coinCurrency ?? ""}"),
          TwoTextFixed("${"Start Time".tr}: ", formatDate(phase.startDate, format: dateTimeFormatDdMMMMYyyyHhMm)),
          TwoTextFixed("${"End Time".tr}: ", formatDate(phase.endDate, format: dateTimeFormatDdMMMMYyyyHhMm)),
        ])
    ]);
  }
}

class IcoTokenPriceView extends StatelessWidget {
  const IcoTokenPriceView({super.key, required this.token});

  final TokenPriceInfo token;

  @override
  Widget build(BuildContext context) {
    return token.tokenAmount == null
        ? vSpacer0()
        : Container(
            decoration: boxDecorationRoundBorder(),
            padding: const EdgeInsets.all(Dimens.paddingMid),
            margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextRobotoAutoBold("Token Info".tr),
                vSpacer10(),
                TwoTextSpaceFixed("${"Price".tr}: ", coinFormat(token.tokenPrice)),
                TwoTextSpaceFixed("${"Amount".tr}: ", coinFormat(token.tokenAmount)),
                TwoTextSpaceFixed("${"Pay Amount".tr}: ", coinFormat(token.payAmount), flex: 4),
                TwoTextSpaceFixed("${"Total Price".tr}: ", coinFormat(token.tokenTotalPrice), flex: 4),
                TwoTextSpaceFixed("${"Token Currency".tr}: ", token.tokenCurrency ?? "", flex: 4),
                TwoTextSpaceFixed("${"Pay Currency".tr}: ", token.payCurrency ?? "", flex: 4),
              ],
            ),
          );
  }
}

class IcoBankInfoView extends StatelessWidget {
  const IcoBankInfoView({super.key, required this.dBank});

  final DynamicBank dBank;

  @override
  Widget build(BuildContext context) {
    final bankSlugs = dBank.bank?.keys ?? [];
    return Container(
      decoration: boxDecorationRoundBorder(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold("Bank Info".tr),
          vSpacer10(),
          Column(
            children: List.generate(bankSlugs.length, (index) {
              final item = dBank.bank!.values.toList()[index];
              return TwoTextFixedView(item.title ?? '', item.value ?? '',
                  onSubTap: () => copyToClipboard(item.value ?? '', textInMsg: true));
            },),
          ),

        ],
      ),
    );
  }
}

class TotalView extends StatelessWidget {
  const TotalView({super.key, required this.value, required this.title, this.icon});

  final dynamic value;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final valueL = value is num ? coinFormat(value) : value.toString();
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: Dimens.iconSizeMid, color: context.theme.focusColor),
          TextRobotoAutoBold(valueL, fontSize: Dimens.fontSizeLarge, maxLines: 1),
          TextRobotoAutoNormal(title ?? ""),
          vSpacer5(),
        ],
      ),
    );
  }
}
