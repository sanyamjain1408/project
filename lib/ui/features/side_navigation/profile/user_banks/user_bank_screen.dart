import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../ui_helper/app_widgets.dart';
import '../../../../../utils/alert_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/date_util.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../data/local/constants.dart';
import '../../../../../data/models/bank_data.dart';
import 'bank_input_page.dart';
import 'user_bank_controller.dart';

const _bankGreen  = Color(0xFFCCFF00);
const _bankDmSans = 'DMSans';

class UserBankScreen extends StatefulWidget {
  const UserBankScreen({super.key});

  @override
  State<UserBankScreen> createState() => _UserBankScreenState();
}

class _UserBankScreenState extends State<UserBankScreen> {
  final _controller = Get.put(UserBankController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.getUserBankList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bank List",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: _bankDmSans,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => BankInputPage()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: _bankGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Add Bank",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: _bankDmSans,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          vSpacer10(),
          Obx(() {
            return _controller.userBanks.isEmpty
                ? handleEmptyViewWithLoading(
                    _controller.isDataLoading.value,
                    message: "Your bank list will appear here".tr,
                  )
                : Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                      itemCount: _controller.userBanks.length,
                      separatorBuilder: (context, index) => dividerHorizontal(),
                      itemBuilder: (BuildContext context, int index) {
                        return UserBankItemView(
                          bank: _controller.userBanks[index],
                          onTap: _handleButtonAction,
                        );
                      },
                    ),
                  );
          }),
        ],
      );
  }

  void _handleButtonAction(int action, DynamicBank bank) {
    if (action == ActionType.edit) {
      Get.to(() => BankInputPage(preBank: bank));
    } else if (action == ActionType.delete) {
      _deleteBank(bank.id ?? 0);
    }
  }

  void _deleteBank(int bankId) {
    alertForAction(
      context,
      title: "Delete Bank".tr,
      subTitle: "bank delete message".tr,
      buttonTitle: "Delete".tr,
      buttonColor: Colors.red,
      onOkAction: () {
        Get.back();
        _controller.userBankDelete(bankId);
      },
    );
  }
}

class UserBankItemView extends StatelessWidget {
  const UserBankItemView({super.key, required this.bank, required this.onTap});

  final DynamicBank bank;
  final Function(int, DynamicBank) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Column(
        children: [
          TwoTextFixedView("Bank Name".tr, bank.bankForm?.title ?? ""),
          TwoTextFixedView("Date".tr, formatDate(bank.updatedAt, format: dateFormatMMMMDddYyy)),
          vSpacer5(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: Dimens.btnHeightMin,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.15),
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onTap(ActionType.delete, bank),
                  child: Text("Delete".tr, style: const TextStyle(fontFamily: _bankDmSans)),
                ),
              ),
              hSpacer5(),
              SizedBox(
                height: Dimens.btnHeightMin,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bankGreen.withOpacity(0.15),
                    foregroundColor: _bankGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onTap(ActionType.edit, bank),
                  child: Text("Edit".tr, style: const TextStyle(fontFamily: _bankDmSans)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}