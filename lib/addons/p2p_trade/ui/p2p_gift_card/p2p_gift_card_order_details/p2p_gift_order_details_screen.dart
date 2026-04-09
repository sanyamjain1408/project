import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_gift_card.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_common_widgets.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../../ui/ui_helper/app_widgets.dart';
import '../../../p2p_constants.dart';
import '../../p2p_order_details/order_details_widgets.dart';
import 'p2p_gift_order_chat_page.dart';
import 'p2p_gift_order_details_controller.dart';

class P2pGiftOrderDetailsScreen extends StatefulWidget {
  const P2pGiftOrderDetailsScreen({super.key, required this.uid});

  final String uid;

  @override
  P2pGiftOrderDetailsScreenState createState() => P2pGiftOrderDetailsScreenState();
}

class P2pGiftOrderDetailsScreenState extends State<P2pGiftOrderDetailsScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(P2pGiftOrderDetailsController());
  RxInt tabIndex = 0.obs;
  late TabController _tabController;
  late bool isBuy = false;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardOrderDetails(widget.uid));
  }

  @override
  void dispose() {
    _controller.manageChatChannel(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Gift Card Trade".tr, fontSize: Dimens.fontSizeMid),
      body: SafeArea(child: Obx(() {
        isBuy = _controller.orderDetails.value.userBuyer?.id == gUserRx.value.id;
        // final order = _controller.orderDetails.value.order;
        // final user = isBuy ? _controller.orderDetails.value.userSeller : _controller.orderDetails.value.userBuyer;
        // String pTitle = "Gift Card Trade".tr;
        // if (_controller.orderDetails.value.order != null) {
        //   pTitle = "${isBuy ? "Buy".tr : "Sell".tr} ${order?.pGiftCard?.giftCard?.coinType ?? ""} "
        //       "${(isBuy ? "From".tr : "To".tr).toLowerCase()} ${user?.nickName ?? user?.firstName ?? ""}";
        // }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // appBarBackWithActions(title: pTitle, fontSize: Dimens.fontSizeMid),
            tabBarUnderline(["Details".tr, "Conversation".tr], _tabController,
                isScrollable: true,
                onTap: (index) => tabIndex.value = index,
                indicator: tabCustomIndicator(context, padding: Dimens.paddingLargeDouble),
                fontSize: Dimens.fontSizeMid),
            dividerHorizontal(height: 0),
            _controller.isDataLoading ? showLoading() : Obx(() => tabIndex.value == 0 ? _orderDetailsView() : P2pGiftOrderChatPage()),
          ],
        );
      })),
    );
  }

  Expanded _orderDetailsView() {
    final order = _controller.orderDetails.value.order;
    final dispute = _controller.orderDetails.value.dispute;
    final user = isBuy ? _controller.orderDetails.value.userSeller : _controller.orderDetails.value.userBuyer;
    String pTitle = "";
    if (_controller.orderDetails.value.order != null) {
      pTitle = " ${order?.pGiftCard?.giftCard?.coinType ?? ""} "
          "${(isBuy ? "From".tr : "To".tr).toLowerCase()} ${user?.nickName ?? user?.firstName ?? ""}";
    }

    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          vSpacer10(),
          Row(
            children: [
              TextRobotoAutoBold(isBuy ? "Buy".tr : "Sell".tr, color: isBuy ? gBuyColor : gSellColor),
              TextRobotoAutoBold(pTitle),
            ],
          ),
          TwoTextSpaceFixed("${"Order number".tr} : ", order?.orderId ?? "", flex: 4),
          TwoTextSpaceFixed("${"Time Created".tr} : ", formatDate(order?.createdAt, format: dateTimeFormatDdMMMMYyyyHhMm), flex: 4),
          vSpacer20(),
          OrderInfoView(gcOrder: order),
          OrderTimeLimitView(
              gcOrder: order, dueMinute: _controller.orderDetails.value.dueMinute, onEnd: () => _controller.getP2pGiftCardOrderDetails(widget.uid)),
          if (dispute != null)
            DisputedView(p2pGiftCardOrderDetails: _controller.orderDetails.value)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ([
                  P2pTradeStatus.timeExpired,
                  P2pTradeStatus.canceled,
                  P2pTradeStatus.transferDone,
                  P2pTradeStatus.refundedByAdmin,
                  P2pTradeStatus.releasedByAdmin
                ].contains(order?.status))
                  OrderStatusView(gcOrder: order),
                if (order?.status == P2pTradeStatus.escrow)
                  if (isBuy)
                    (order?.paymentCurrencyType == PaymentCurrencyType.bank
                        ? OrderPaymentView(gcOrder: order, payInfo: _controller.orderDetails.value.paymentMethods)
                        : Padding(
                            padding: const EdgeInsets.only(top: Dimens.paddingLargeExtra),
                            child: buttonRoundedMain(text: "Pay and Notify".tr, onPress: () => _controller.p2pGiftCardOrderPayNow(null)),
                          ))
                  else
                    OrderStatusView(gcOrder: order),
                if (order?.status == P2pTradeStatus.paymentDone && isBuy) OrderStatusView(gcOrder: order),
                vSpacer20(),
                order?.status == P2pTradeStatus.transferDone ? GiftOrderReviewView(order: order, isBuy: isBuy) : _buttonsView(),
                vSpacer20(),
              ],
            )
        ],
      ),
    );
  }

  Widget _buttonsView() {
    final order = _controller.orderDetails.value.order;
    return Column(
      children: [
        if (order?.status == P2pTradeStatus.escrow && isBuy)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
            child: buttonRoundedMain(
                text: "Cancel".tr,
                textColor: Get.theme.scaffoldBackgroundColor,
                onPress: () => showModalSheetFullScreen(context, CancelView(onCancel: _controller.p2pGiftCardOrderCancel))),
          ),
        if (order?.status == P2pTradeStatus.paymentDone && !isBuy)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
            child: buttonRoundedMain(
                text: "Release".tr, textColor: Get.theme.scaffoldBackgroundColor, onPress: () => _controller.p2pGiftCardOrderPaymentConfirm()),
          ),
        if (order?.status == P2pTradeStatus.paymentDone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
            child: buttonRoundedMain(
                text: "Dispute".tr,
                textColor: Get.theme.scaffoldBackgroundColor,
                onPress: () => showBottomSheetFullScreen(context, GiftOrderDisputeView(order), title: "Dispute Order".tr)),
          ),
      ],
    );
  }
}

class GiftOrderReviewView extends StatelessWidget {
  GiftOrderReviewView({super.key, this.order, required this.isBuy});

  final P2PGiftCardOrder? order;
  final bool isBuy;
  final reviewEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final typeText = isBuy ? "Seller".tr.toLowerCase() : "Buyer".tr.toLowerCase();
    final feedback = isBuy ? order?.buyerFeedbackType : order?.sellerFeedbackType;
    RxInt feedbackType = 1.obs;

    if (order?.status == P2pTradeStatus.transferDone) {
      return Container(
        decoration: boxDecorationRoundCorner(),
        padding: EdgeInsets.all((order?.feedback == null && feedback != null) ? 0 : Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order?.feedback != null)
              Column(children: [
                twoTextView("${"Feedback Type".tr}: ", order?.feedback?.feedbackType == 1 ? "Positive".tr : "Negative".tr),
                twoTextView("${typeText.toCapitalizeFirst()} ${"Feedback".tr}: ", order?.feedback?.feedback ?? ""),
              ]),
            if (order?.feedback != null && feedback == null) vSpacer15(),
            if (feedback == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRobotoAutoBold("${"Submit review about the".tr} $typeText"),
                  vSpacer5(),
                  textFieldWithSuffixIcon(controller: reviewEditController, hint: "Write your review".tr, maxLines: 3, height: 80),
                  vSpacer10(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextRobotoAutoBold("${"Review Type".tr}: "),
                      vSpacer5(),
                      Obx(() =>
                          SegmentedControlView(["Positive".tr, "Negative".tr], feedbackType.value, onChange: (index) => feedbackType.value = index)),
                    ],
                  ),
                  vSpacer20(),
                  buttonRoundedMain(
                      text: "Submit Review".tr,
                      onPress: () {
                        final reviewText = reviewEditController.text.trim();
                        if (reviewText.isEmpty) {
                          showToast("Write your review".tr);
                          return;
                        }
                        hideKeyboard(context: context);
                        Get.find<P2pGiftOrderDetailsController>().p2pGiftCardFeedbackUpdate(reviewText, feedbackType.value);
                      }),
                  vSpacer10(),
                ],
              ),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}

class GiftOrderDisputeView extends StatelessWidget {
  GiftOrderDisputeView(this.order, {super.key});

  final P2PGiftCardOrder? order;
  final subEditController = TextEditingController();
  final descEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          TextRobotoAutoBold("Dispute Subject".tr),
          vSpacer5(),
          textFieldWithSuffixIcon(controller: subEditController, hint: "Write Subject".tr),
          vSpacer15(),
          TextRobotoAutoBold("Dispute Description".tr),
          vSpacer5(),
          textFieldWithSuffixIcon(controller: descEditController, hint: "Write the Reason to dispute the order".tr, maxLines: 3, height: 90),
          vSpacer20(),
          buttonRoundedMain(
              text: "Confirm".tr,
              onPress: () {
                final title = subEditController.text.trim();
                if (title.isEmpty) {
                  showToast("Write the dispute subject".tr);
                  return;
                }
                final description = descEditController.text.trim();
                if (description.isEmpty) {
                  showToast("Write the dispute description".tr);
                  return;
                }
                hideKeyboard(context: context);
                Get.find<P2pGiftOrderDetailsController>().p2pGiftCardOrderDispute(title, description);
              })
        ],
      ),
    );
  }
}
