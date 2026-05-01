import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import '../activity/activity_screen.dart';

class IBProgramScreen extends StatefulWidget {
  const IBProgramScreen({super.key});

  @override
  IBProgramScreenState createState() => IBProgramScreenState();
}

class IBProgramScreenState extends State<IBProgramScreen> {
  // TODO: Add your IB program controller and logic here
  // For now, showing a placeholder UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(
        title: "IB Program".tr,
        actionIcons: [Icons.history],
        onPress: (i) {
          TemporaryData.activityType = HistoryType.refEarningTrade;
          Get.to(() => const ActivityScreen());
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IB Hero Section
              Container(
                decoration: boxDecorationRoundCorner(),
                padding: const EdgeInsets.all(Dimens.paddingMid),
                child: Column(
                  children: [
                    TextRobotoAutoBold("IB (Introducing Broker) Program", 
                      fontSize: Dimens.titleFontSizeLarge,
                      color: Colors.green,
                    ),
                    vSpacer10(),
                    TextRobotoAutoBold("Earn 30-60% Forever",
                      fontSize: Dimens.titleFontSizeMid,
                    ),
                    vSpacer10(),
                    TextRobotoAutoBold(
                      "Introduce traders to Trapix and earn up to 60% of the exchange's 0.3% trading fee",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              vSpacer20(),
              
              // Share Link Section
              _buildShareSection(),
              vSpacer20(),
              
              // Stats Cards
              _buildStatsSection(),
              vSpacer20(),
              
              // Tier Levels
              _buildTiersSection(),
              vSpacer20(),
              
              // Info Message
              Container(
                decoration: boxDecorationRoundCorner(),
                padding: const EdgeInsets.all(Dimens.paddingMid),
                child: Column(
                  children: [
                    TextRobotoAutoBold("How IB Rewards Work", 
                      fontSize: Dimens.fontSizeLarge,
                    ),
                    vSpacer10(),
                    _buildInfoRow("Level 1 (Direct)", "30-60% of 0.3% fee", Colors.green),
                    _buildInfoRow("Level 2 (Indirect)", "10% of 0.3% fee", Colors.blue),
                    vSpacer10(),
                    TextRobotoAutoBold(
                      "Commission increases as you invite more traders!",
                      fontSize: Dimens.fontSizeSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    final referralLink = "https://trapix.com/signup?ib_code=YOUR_CODE";
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold("Your IB Link".tr),
          vSpacer10(),
          Row(
            children: [
              Expanded(child: textWithCopyButton(referralLink)),
              TextRobotoAutoBold("Or".tr),
              hSpacer10(),
              buttonOnlyIcon(
                iconData: Icons.share,
                iconColor: context.theme.focusColor,
                visualDensity: minimumVisualDensity,
                onPress: () => shareText(referralLink)
              )
            ],
          ),
          vSpacer10(),
          TextRobotoAutoBold("Your IB Code: TRX-5Q905R", fontSize: Dimens.fontSizeSmall),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextRobotoAutoBold("Total IBs", color: Get.theme.primaryColorLight),
                TextRobotoAutoBold("0", fontSize: Dimens.titleFontSizeMid),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TextRobotoAutoBold("Total Earned", color: Get.theme.primaryColorLight),
                TextRobotoAutoBold("0 USDT", fontSize: Dimens.titleFontSizeMid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersSection() {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold("IB Tiers", fontSize: Dimens.fontSizeLarge),
          vSpacer10(),
          _buildTierRow("Starter", "30%", "0-9 IBs", Colors.grey),
          _buildTierRow("Pro", "40%", "10-49 IBs", Colors.blue),
          _buildTierRow("Elite", "50%", "50-199 IBs", Colors.orange),
          _buildTierRow("VIP", "60%", "200+ IBs", Colors.green),
        ],
      ),
    );
  }

  Widget _buildTierRow(String tier, String commission, String requirement, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          hSpacer10(),
          Expanded(flex: 2, child: TextRobotoAutoBold(tier)),
          Expanded(flex: 1, child: TextRobotoAutoBold(commission, color: Colors.green)),
          Expanded(flex: 2, child: TextRobotoAutoBold(requirement, fontSize: Dimens.fontSizeSmall)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextRobotoAutoBold(label),
          TextRobotoAutoBold(value, color: color),
        ],
      ),
    );
  }
}