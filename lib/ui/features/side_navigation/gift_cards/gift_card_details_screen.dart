import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/gift_card.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/gift_cards/gift_cards_controller.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/gift_cards/gift_cards_self/gift_cards_self_controller.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'gift_cards_widgets.dart';

//ignore: must_be_immutable
class GiftCardDetailsScreen extends StatelessWidget {
  GiftCardDetailsScreen({super.key, required this.gCard, this.checkType, this.from});

  final GiftCard gCard;
  final int? checkType;
  final String? from;
  RxString redeemCode = "".obs;

  @override
  Widget build(BuildContext context) {
    String? imagePath = gCard.banner?.banner;
    if (imagePath == null || !imagePath.contains(APIURLConstants.baseUrl)) imagePath = gCard.banner?.image;
    String amountText = "${gCard.amount ?? 0} ${gCard.coinType ?? ""}";

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        children: [
          GiftCardImageAndTag(imagePath: imagePath, amountText: amountText),
          vSpacer20(),
          TextRobotoAutoBold(gCard.banner?.title ?? "", maxLines: 5),
          vSpacer5(),
          TextRobotoAutoNormal(gCard.banner?.subTitle ?? "", maxLines: 10, color: Get.theme.primaryColor),
          vSpacer20(),
          checkType == null ? _cardDetailsView(context) : Align(alignment: Alignment.centerRight, child: _cardCheckView()),
          vSpacer10(),
        ],
      ),
    );
  }

  Column _cardDetailsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TwoTextSpaceFixed("${"Coin Type".tr}: ", gCard.coinType ?? "", subTextAlign: TextAlign.start),
        vSpacer2(),
        TwoTextSpaceFixed("${"Category".tr}: ", gCard.banner?.category?.name ?? "", subTextAlign: TextAlign.start),
        vSpacer2(),
        TwoTextSpaceFixed("${"Lock".tr}: ", gCard.lockText ?? "", subTextAlign: TextAlign.start),
        vSpacer2(),
        TwoTextSpaceFixed("${"Status".tr}: ", gCard.statusText ?? "", subTextAlign: TextAlign.start),
        vSpacer10(),
        Row(
          children: [
            TextRobotoAutoBold("${"Redeem Code".tr}: "),
            hSpacer5(),
            Obx(() => redeemCode.value.isEmpty
                ? SizedBox(
                    height: Dimens.btnHeightMin,
                    child: buttonText("See Code".tr, fontSize: Dimens.fontSizeMidExtra, onPress: () {
                      _getRedeemCode(context);
                    }))
                : textWithCopyView(redeemCode.value))
          ],
        ),
        vSpacer30(),
        Wrap(
          spacing: Dimens.paddingMid,
          runSpacing: Dimens.paddingMid,
          alignment: WrapAlignment.end,
          children: [
            if (gCard.lockStatus == 1)
              buttonText(gCard.lock == 0 ? "Locked".tr : "Unlocked".tr,  onPress: () {
                from == FromKey.home
                    ? Get.find<GiftCardsController>().giftCardUpdate(gCard)
                    : Get.find<GiftCardSelfController>().giftCardUpdate(gCard);
              }, visualDensity: VisualDensity.compact),
            if (gCard.status == 1)
              buttonText("Send Crypto Gift Card".tr, onPress: () {
                Get.back();
                showBottomSheetFullScreen(context, GiftCardSendView(gCard: gCard), title: "Send Crypto Gift Card".tr);
              }, visualDensity: VisualDensity.compact),
          ],
        ),
      ],
    );
  }

  Widget _cardCheckView() {
    if (checkType == GiftCardCheckStatus.check) {
      return vSpacer0();
    } else {
      final btnText = checkType == GiftCardCheckStatus.redeem ? "Redeem".tr : "Add".tr;
      return buttonText(btnText, onPress: () {
        if (checkType == GiftCardCheckStatus.redeem) {
          Get.find<GiftCardsController>().giftCardRedeem(gCard.redeemCode ?? "");
        } else if (checkType == GiftCardCheckStatus.add) {
          Get.find<GiftCardsController>().giftCardAdd(gCard.redeemCode ?? "");
        }
      });
    }
  }

  void _getRedeemCode(BuildContext context) {
    final passEditController = TextEditingController();
    final view = Column(
      children: [
        vSpacer10(),
        TextRobotoAutoBold("Enter your login password".tr, maxLines: 2),
        vSpacer10(),
        textFieldWithSuffixIcon(controller: passEditController, hint: "Write Your Password".tr),
        vSpacer10(),
        Align(
            alignment: Alignment.centerRight,
            child: buttonText("Get Code".tr, visualDensity: VisualDensity.compact, onPress: () {
              final password = passEditController.text;
              if (password.length < DefaultValue.kPasswordLength) {
                showToast("Password_invalid_length".trParams({"count": DefaultValue.kPasswordLength.toString()}), isError: true);
                return;
              }
              hideKeyboard();
              Get.find<GiftCardsController>().getGiftCardCode(gCard.uid ?? "", password, (code) => redeemCode.value = code);
            })),
        vSpacer10(),
      ],
    );
    showModalSheetFullScreen(context, view);
  }
}

class GiftCardSendView extends StatefulWidget {
  const GiftCardSendView({super.key, required this.gCard});

  final GiftCard gCard;

  @override
  State<GiftCardSendView> createState() => _GiftCardSendViewState();
}

class _GiftCardSendViewState extends State<GiftCardSendView> {
  RxInt selectedType = 0.obs;
  final messageController = TextEditingController();
  final sendIdController = TextEditingController();

  @override
  void initState() {
    selectedType.value = -1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        children: [
          vSpacer10(),
          TextRobotoAutoBold("Send Type".tr),
          vSpacer2(),
          Obx(() {
            final type = selectedType.value == 0 ? "Email".tr : "Phone".tr;
            final inputType = selectedType.value == 0 ? TextInputType.emailAddress : TextInputType.phone;
            return Column(
              children: [
                dropDownListIndex(["Email".tr, "Phone".tr], selectedType.value, "Select Type".tr, hMargin: 0, (index) {
                  sendIdController.text = "";
                  selectedType.value = index;
                }),
                vSpacer15(),
                if (selectedType.value != -1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRobotoAutoBold(type),
                      vSpacer5(),
                      textFieldWithSuffixIcon(controller: sendIdController, hint: "${"Enter your".tr} ${type.toLowerCase()}", type: inputType),
                      if (selectedType.value == 1) TextRobotoAutoNormal("add phone number message".tr, maxLines: 2),
                      vSpacer15(),
                      TextRobotoAutoBold("Message".tr),
                      vSpacer2(),
                      textFieldWithSuffixIcon(controller: messageController, hint: "Write your message".tr, height: 80, maxLines: 3),
                      vSpacer15(),
                      Align(
                          alignment: Alignment.centerRight,
                          child: buttonText("Send".tr, radius: Dimens.radiusCorner, onPress: () {
                            final type = selectedType.value == 0 ? GiftCardSendType.email : GiftCardSendType.phone;
                            final id = sendIdController.text.trim();
                            if (type == GiftCardSendType.email && !GetUtils.isEmail(id)) {
                              showToast("Input a valid Email".tr);
                              return;
                            } else if (type == GiftCardSendType.phone) {
                              var number = removeSpecialChar(sendIdController.text.trim());
                              if (number.length < 5) {
                                showToast("Input a valid phone".tr);
                                return;
                              }
                            }
                            hideKeyboard(context: context);
                            Get.find<GiftCardsController>().giftCardSend(widget.gCard.uid ?? "", type, id, messageController.text.trim());
                          }))
                    ],
                  )
              ],
            );
          }),
          vSpacer10(),
        ],
      ),
    );
  }
}
