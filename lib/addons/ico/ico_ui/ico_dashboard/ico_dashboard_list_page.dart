import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_helper.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_chat/ico_chat_screen.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dashboard.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../helper/app_checker.dart';
import '../../../../ui/ui_helper/app_widgets.dart';
import '../ico_create_phase/ico_create_phase_screen.dart';
import '../ico_create_token/ico_create_token_screen.dart';
import '../ico_token_phase_list/ico_token_phase_list_screen.dart';
import 'ico_dashboard_controller.dart';

class IcoDashboardListPage extends StatelessWidget {
  IcoDashboardListPage({super.key});

  final _controller = Get.find<IcoDashboardController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getIcoListData(false));

    return Obx(() {
      return _controller.icoDataList.isEmpty
          ? handleEmptyViewWithLoading(_controller.isLoading.value)
          : Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimens.paddingMid),
                itemCount: _controller.icoDataList.length,
                itemBuilder: (BuildContext context, int index) {
                  if (_controller.hasMoreData && index == (_controller.icoDataList.length - 1) && !_controller.isLoading.value) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getIcoListData(true));
                  }
                  final item = _controller.icoDataList[index];
                  final selectedType = _controller.selectedType.value;
                  if (selectedType == 0 && item is IcoDynamicForm) {
                    return IcoDynamicFormItemView(dynamicForm: item);
                  } else if (selectedType == 1 && item is IcoToken) {
                    return IcoTokenItemView(token: item);
                  } else if (selectedType == 2 && item is IcoBuyToken) {
                    return IcoBuyTokenItemView(token: item);
                  } else if (selectedType == 3 && item is IcoMyToken) {
                    return IcoMyTokenItemView(token: item);
                  } else if (selectedType == 5 && item is IcoWithdraw) {
                    return IcoWithdrawItemView(withdraw: item);
                  }
                  return Container();
                },
              ),
            );
    });
  }
}

class IcoDynamicFormItemView extends StatelessWidget {
  const IcoDynamicFormItemView({super.key, required this.dynamicForm});

  final IcoDynamicForm dynamicForm;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStatusData(dynamicForm.status ?? 0);
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TwoTextSpaceFixed("ID".tr, (dynamicForm.uniqueId ?? 0).toString()),
          TwoTextSpaceFixed("Status".tr, statusData.first, subColor: statusData.last),
          TwoTextSpaceFixed("Created At".tr, formatDate(dynamicForm.createdAt, format: dateTimeFormatDdMMMYyyyHhMm)),
          TwoTextSpaceFixed("Updated At".tr, formatDate(dynamicForm.updatedAt, format: dateTimeFormatDdMMMYyyyHhMm)),
          if (dynamicForm.status == 1 && dynamicForm.tokenCreateStatus == 1)
            buttonText("Create Token".tr,
                visualDensity: minimumVisualDensity, onPress: () => Get.to(() => IcoCreateTokenScreen(fromId: dynamicForm.id)))
        ],
      ),
    );
  }
}

class IcoTokenItemView extends StatelessWidget {
  const IcoTokenItemView({super.key, required this.token});

  final IcoToken token;

  @override
  Widget build(BuildContext context) {
    final statusData = getApprovedStatusData(token.status);
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TwoTextSpaceFixed("Base Coin".tr, token.baseCoin ?? ""),
          TwoTextSpaceFixed("Token Name".tr, token.tokenName ?? ""),
          TwoTextSpaceFixed("Approved Status".tr, statusData.first, subColor: statusData.last, flex: 4),
          TwoTextSpaceFixed("Wallet Address".tr, token.walletAddress ?? "", flex: 4),
          TwoTextSpaceFixed("Date".tr, formatDate(token.createdAt, format: dateTimeFormatDdMMMYyyyHhMm)),
          Row(
            children: [
              TextRobotoAutoBold("Actions".tr, color: context.theme.primaryColorLight),
              const Spacer(),
              buttonOnlyIcon(
                  iconData: Icons.create_new_folder_rounded,
                  visualDensity: minimumVisualDensity,
                  onPress: () => Get.to(() => IcoCreatePhaseScreen(token: token))),
              buttonOnlyIcon(
                  iconData: Icons.chat_bubble_rounded, visualDensity: minimumVisualDensity, onPress: () => Get.to(() => ICOChatScreen(token: token))),
              buttonOnlyIcon(
                  iconData: Icons.drive_file_rename_outline_rounded,
                  visualDensity: minimumVisualDensity,
                  onPress: () => Get.to(() => IcoCreateTokenScreen(preToken: token, fromId: token.formId))),
              buttonOnlyIcon(
                  iconData: Icons.list_rounded,
                  visualDensity: minimumVisualDensity,
                  onPress: () => Get.to(() => IcoTokenPhaseListScreen(token: token))),
            ],
          )
        ],
      ),
    );
  }
}

class IcoBuyTokenItemView extends StatelessWidget {
  const IcoBuyTokenItemView({super.key, required this.token});

  final IcoBuyToken token;

  @override
  Widget build(BuildContext context) {
    final statusData = getApprovedStatusData(token.status);
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TwoTextSpaceFixed(token.tokenName ?? "", statusData.first, flex: 6, color: context.theme.primaryColor, subColor: statusData.last),
          TwoTextSpaceFixed("Amount".tr, "${coinFormat(token.amount)} ${token.buyCurrency}"),
          TwoTextSpaceFixed("Paid".tr, "${coinFormat(token.payAmount)} ${token.payCurrency}"),
          if (token.trxId.isValid) TwoTextSpaceFixed("Txn ID".tr, token.trxId ?? "N/A".tr),
          TwoTextSpaceFixed("Date".tr, formatDate(token.createdAt, format: dateTimeFormatDdMMMYyyyHhMm)),
          TwoTextSpaceFixed("Pay Method".tr, token.paymentMethod ?? "", flex: 4),
        ],
      ),
    );
  }
}

class IcoMyTokenItemView extends StatelessWidget {
  const IcoMyTokenItemView({super.key, required this.token});

  final IcoMyToken token;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(children: [
            showImageNetwork(
                imagePath: token.imagePath ?? token.coinIcon, width: Dimens.iconSizeLarge, height: Dimens.iconSizeLarge, boxFit: BoxFit.cover),
            hSpacer5(),
            Expanded(child: TextRobotoAutoBold(token.name ?? "")),
          ]),
          vSpacer5(),
          TwoTextSpaceFixed("Balance".tr, "${coinFormat(token.balance)} ${token.coinType ?? ""}"),
          TwoTextSpaceFixed("Date".tr, formatDate(token.createdAt, format: dateTimeFormatDdMMMYyyyHhMm)),
          vSpacer5(),
          Row(
            children: [
              TextRobotoAutoBold("Address".tr, color: context.theme.primaryColorLight),
              const Spacer(),
              SizedBox(width: Get.width / 2, child: TextRobotoAutoNormal(token.address ?? "", maxLines: 2, textAlign: TextAlign.end)),
              buttonOnlyIcon(
                  iconPath: AssetConstants.icCopy,
                  iconColor: Get.theme.focusColor,
                  visualDensity: minimumVisualDensity,
                  onPress: () => copyToClipboard(token.address ?? ""))
            ],
          ),
        ],
      ),
    );
  }
}

class IcoWithdrawItemView extends StatelessWidget {
  const IcoWithdrawItemView({super.key, required this.withdraw});

  final IcoWithdraw withdraw;

  @override
  Widget build(BuildContext context) {
    final status = getApprovedStatusData(withdraw.approvedStatus);
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TwoTextSpaceFixed(getCurrencyTypeText(withdraw.tranType), status.first, flex: 6, color: context.theme.primaryColor, subColor: status.last),
          TwoTextSpaceFixed("Requested".tr, "${coinFormat(withdraw.requestAmount)} ${withdraw.requestCurrency}"),
          TwoTextSpaceFixed("Converted".tr, "${coinFormat(withdraw.convertAmount)} ${withdraw.convertCurrency}"),
          TwoTextSpaceFixed("Date".tr, formatDate(withdraw.createdAt, format: dateTimeFormatDdMMMYyyyHhMm)),
          if (withdraw.paymentDetails.isValid)
            Row(children: [
              TextRobotoAutoBold("Payment Details".tr, color: context.theme.primaryColorLight),
              const Spacer(),
              InkWell(
                  onTap: () => alertForAction(context, title: "Payment Details".tr, subTitle: withdraw.paymentDetails ?? '', maxLinesSub: 50),
                  child: TextRobotoAutoNormal("View".tr, decoration: TextDecoration.underline)),
            ]),
          if (withdraw.paymentSleep.isValid)
            Row(children: [
              TextRobotoAutoBold("Payment Slip".tr, color: context.theme.primaryColorLight),
              const Spacer(),
              showImageNetwork(
                  imagePath: withdraw.paymentSleep,
                  width: Dimens.iconSizeMid,
                  height: Dimens.iconSizeMid,
                  onPressCallback: () => openUrlInBrowser(withdraw.paymentSleep ?? '')),
            ]),
        ],
      ),
    );
  }
}
