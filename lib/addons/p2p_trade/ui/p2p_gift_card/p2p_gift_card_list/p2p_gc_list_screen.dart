import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/gift_card.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/gift_cards/gift_cards_widgets.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../../ui/ui_helper/app_widgets.dart';
import '../../../models/p2p_gift_card.dart';
import '../p2p_gc_create_ad/p2p_gc_create_ad_screen.dart';
import 'p2p_gc_list_controller.dart';

class P2PGCListScreen extends StatefulWidget {
  const P2PGCListScreen({super.key});

  @override
  State<P2PGCListScreen> createState() => _P2PGCListScreenState();
}

class _P2PGCListScreenState extends State<P2PGCListScreen> with TickerProviderStateMixin {
  final _controller = Get.put(P2pGCListController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardList(false));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => _controller.giftCardList.isEmpty
        ? handleEmptyViewWithLoading(_controller.isDataLoading.value)
        : Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all( Dimens.paddingMid),
              itemCount: _controller.giftCardList.length,
              itemBuilder: (BuildContext context, int index) {
                if (_controller.hasMoreData && index == (_controller.giftCardList.length - 1)) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardList(true));
                }
                return P2pGiftCardItemView(_controller.giftCardList[index]);
              },
            ),
          ));
  }

// @override
// Widget build(BuildContext context) {
//   return Expanded(
//     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Padding(
//         padding: const EdgeInsets.all(Dimens.paddingMid),
//         child: TextRobotoAutoBold("My Gift Card List".tr, color: context.theme.primaryColorLight),
//       ),
//       Obx(() => _controller.giftCardList.isEmpty
//           ? handleEmptyViewWithLoading(_controller.isDataLoading.value)
//           : Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
//                 itemCount: _controller.giftCardList.length,
//                 itemBuilder: (BuildContext context, int index) {
//                   if (_controller.hasMoreData && index == (_controller.giftCardList.length - 1)) {
//                     WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardList(true));
//                   }
//                   return P2pGiftCardItemView(_controller.giftCardList[index]);
//                 },
//               ),
//             ))
//     ]),
//   );
// }
}

class P2pGiftCardItemView extends StatelessWidget {
  const P2pGiftCardItemView(this.p2pGiftCard, {super.key});

  final P2pGiftCard p2pGiftCard;

  @override
  Widget build(BuildContext context) {
    final giftCard = p2pGiftCard.giftCard ?? GiftCard();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showBottomSheetFullScreen(context, P2pGiftCardDetailsView(gCard: giftCard), title: "Gift Card Details".tr),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
          color: context.theme.secondaryHeaderColor,
          elevation: 0,
          child: Row(
            children: [
              ClipRRect(
                  borderRadius:
                      const BorderRadius.only(bottomLeft: Radius.circular(Dimens.radiusCorner), topLeft: Radius.circular(Dimens.radiusCorner)),
                  child: showImageNetwork(
                      imagePath: giftCard.banner?.image, height: Dimens.iconSizeLogo, width: Dimens.iconSizeLogo, boxFit: BoxFit.cover)),
              hSpacer10(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextRobotoAutoBold(giftCard.banner?.title ?? "", maxLines: 2),
                    Row(
                      children: [
                        Expanded(
                            child: TextRobotoAutoNormal("${coinFormat(giftCard.amount)} ${giftCard.coinType ?? ""}",
                                fontSize: Dimens.fontSizeMid)),
                        buttonText("Create_Ad".tr, visualDensity: minimumVisualDensity, onPress: () async {
                          final result = await Get.to(() => P2PGCCreateAdScreen(p2pGiftCard: p2pGiftCard));
                          if (result != null && result == true) Get.find<P2pGCListController>().getP2pGiftCardList(false);
                        }, fontSize: Dimens.fontSizeSmall, textColor: context.theme.scaffoldBackgroundColor),
                      ],
                    )
                  ],
                ),
              ),
              hSpacer10(),
            ],
          ),
        ),
      ),
    );
  }
}

class P2pGiftCardDetailsView extends StatelessWidget {
  P2pGiftCardDetailsView({super.key, required this.gCard});

  final GiftCard gCard;
  final bgColor = Get.theme.scaffoldBackgroundColor;

  @override
  Widget build(BuildContext context) {
    String? imagePath = gCard.banner?.banner;
    if (imagePath == null || !imagePath.contains(APIURLConstants.baseUrl)) {
      imagePath = gCard.banner?.image;
    }
    String amountText = "${gCard.amount ?? 0} ${gCard.coinType ?? ""}";

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        children: [
          GiftCardImageAndTag(imagePath: imagePath, amountText: amountText),
          vSpacer20(),
          TextRobotoAutoBold(gCard.banner?.title ?? "", maxLines: 5),
          vSpacer10(),
          TextRobotoAutoNormal(gCard.banner?.subTitle ?? "", maxLines: 10, color: context.theme.primaryColor),
          vSpacer20(),
          TwoTextSpaceFixed("${"Coin Type".tr}: ", gCard.coinType ?? ""),
          TwoTextSpaceFixed("${"Category".tr}: ", gCard.banner?.category?.name ?? ""),
          TwoTextSpaceFixed("${"Lock".tr}: ", gCard.lockText ?? ""),
          TwoTextSpaceFixed("${"Wallet Type".tr}: ", gCard.walletType ?? ""),
          TwoTextSpaceFixed("${"Status".tr}: ", gCard.statusText ?? ""),
          vSpacer10(),
        ],
      ),
    );
  }
}
