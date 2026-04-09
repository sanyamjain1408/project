import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/alert_util.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/decorations.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../data/local/constants.dart';
import '../../../../../data/models/bank_data.dart';
import '../../p2p_common_widgets.dart';
import 'p2p_bank_input_page.dart';
import 'p2p_bank_controller.dart';

class P2PBanksScreen extends StatefulWidget {
  const P2PBanksScreen({super.key});

  @override
  State<P2PBanksScreen> createState() => _P2PBanksScreenState();
}

class _P2PBanksScreenState extends State<P2PBanksScreen> {
  final _controller = Get.put(P2PBankController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pBankList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextRobotoAutoBold("P2P Payment Methods".tr),
              buttonText(
                "Add".tr,
                visualDensity: VisualDensity.compact,
                onPress: () => Get.to(() => P2pBankInputPage()),
              ),
            ],
          ),
          vSpacer10(),
          Obx(() {
            return _controller.p2pBankList.isEmpty
                ? handleEmptyViewWithLoading(
                  _controller.isDataLoading.value,
                  message: "Your bank list will appear here".tr,
                )
                : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _controller.p2pBankList.length,
                  separatorBuilder: (context, index) => dividerHorizontal(),
                  itemBuilder: (BuildContext context, int index) {
                    return P2PBankItemView(dBank: _controller.p2pBankList[index], onTap: _handleButtonAction);
                  },
                );
          }),
        ],
      ),
    );
  }

  void _handleButtonAction(int action, DynamicBank bank) {
    if (action == ActionType.edit) {
      Get.to(() => P2pBankInputPage(preBank: bank));
    } else if (action == ActionType.delete) {
      _deleteBank(bank.id ?? 0);
    }
  }

  void _deleteBank(int bankId) {
    alertForAction(
      context,
      title: "Delete Payment Method".tr,
      subTitle: "Do you want to delete this payment info".tr,
      buttonTitle: "Delete".tr,
      buttonColor: Theme.of(context).colorScheme.error,
      onOkAction: () {
        Get.back();
        _controller.userBankDelete(bankId);
      },
    );
  }
}

class P2PBankItemView extends StatelessWidget {
  const P2PBankItemView({super.key, required this.dBank, required this.onTap});

  final DynamicBank dBank;
  final Function(int, DynamicBank) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Row(
        children: [
          Expanded(child: TextRobotoAutoBold(dBank.bankForm?.title ?? " ", maxLines: 2)),
          P2pIconWithTap(
              icon: Icons.drive_file_rename_outline,
              onTap: () => onTap(ActionType.edit, dBank)),
          P2pIconWithTap(icon: Icons.delete_outline, iconColor: context.theme.colorScheme.error, onTap: () => onTap(ActionType.delete, dBank))
        ],
      ),
    );
  }
}
