import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_gift_card.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/p2p_common_utils.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/p2p_constants.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_common_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../../helper/app_helper.dart';
import '../../../../../ui/features/side_navigation/gift_cards/gift_cards_widgets.dart';
import '../../../../../ui/ui_helper/app_widgets.dart';
import 'p2p_gc_home_controller.dart';

class P2pGiftCardBuyPage extends StatefulWidget {
  const P2pGiftCardBuyPage({super.key, required this.gCardAd});

  final P2PGiftCardAd gCardAd;

  @override
  State<P2pGiftCardBuyPage> createState() => _P2pGiftCardBuyPageState();
}

class _P2pGiftCardBuyPageState extends State<P2pGiftCardBuyPage> {
  final _controller = Get.find<P2pGCHomeController>();
  late P2PGiftCardAd p2pGiftCardAd;
  RxInt selectedPayMethod = 0.obs;

  @override
  void initState() {
    selectedPayMethod.value = -1;
    p2pGiftCardAd = widget.gCardAd;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getP2pGiftCardAdDetails(p2pGiftCardAd.uid ?? "", (gCard) => setState(() => p2pGiftCardAd = gCard));
    });
  }

  @override
  Widget build(BuildContext context) {
    final giftCard = p2pGiftCardAd.giftCard;
    final amountStr = "${coinFormat(giftCard?.amount)} ${giftCard?.coinType}";
    String imagePath = giftCard?.banner?.image ?? giftCard?.banner?.banner ?? "";

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        children: [
          P2pUserView(user: p2pGiftCardAd.user),
          vSpacer10(),
          GiftCardImageAndTag(imagePath: imagePath, amountText: amountStr),
          vSpacer20(),
          TextRobotoAutoBold(giftCard?.banner?.title ?? "", maxLines: 5),
          vSpacer10(),
          TextRobotoAutoNormal(giftCard?.banner?.subTitle ?? "", maxLines: 25, color: context.theme.primaryColor),
          dividerHorizontal(height: Dimens.paddingLargeDouble),
          TwoTextSpaceFixed("${"Price".tr}: ", "${coinFormatP2p(p2pGiftCardAd.price)} ${p2pGiftCardAd.currencyType ?? ""}"),
          TwoTextSpaceFixed("${"Available".tr}: ", amountStr),
          if ((p2pGiftCardAd.timeLimit ?? 0) > 0)
            TwoTextSpaceFixed("${"Pay Time Limit".tr}: ", minutesString(p2pGiftCardAd.timeLimit)),
          vSpacer20(),
          TextRobotoAutoBold("Terms and Conditions".tr),
          vSpacer2(),
          TextRobotoAutoNormal(p2pGiftCardAd.termsCondition ?? "", maxLines: 100, color: context.theme.primaryColor),
          if (p2pGiftCardAd.paymentCurrencyType == PaymentCurrencyType.bank)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    vSpacer20(),
                    TextRobotoAutoNormal("Payment Method".tr, fontSize: Dimens.fontSizeMid),
                    vSpacer5(),
                    Obx(() => dropDownListIndex(getPaymentNameList(), selectedPayMethod.value, "Select Payment Method".tr, hMargin: 0, (index) {
                          return selectedPayMethod.value = index;
                        })),
                  ],
                )
              ],
            ),
          vSpacer20(),
          Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                  width: 100,
                  child: buttonText("Buy".tr, textColor: context.theme.scaffoldBackgroundColor, onPress: () {
                    String? payUid;
                    if (p2pGiftCardAd.paymentCurrencyType == PaymentCurrencyType.bank) {
                      if (selectedPayMethod.value == -1) {
                        showToast("Select_Payment_Method_message".tr);
                        return;
                      }
                      payUid = p2pGiftCardAd.paymentMethods?[selectedPayMethod.value].id.toString();
                    }
                    _controller.p2pGiftCardPlaceAd(widget.gCardAd, payUid);
                  }))),
          vSpacer15(),
        ],
      ),
    );
  }

  List<String> getPaymentNameList() {
    List<String> list = <String>[];
    if (p2pGiftCardAd.paymentMethods.isValid) {
      list = p2pGiftCardAd.paymentMethods!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return list;
  }
}
