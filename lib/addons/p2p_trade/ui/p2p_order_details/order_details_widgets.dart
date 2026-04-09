import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_gift_card.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_order.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_common_widgets.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../ui/ui_helper/app_widgets.dart';
import '../../p2p_constants.dart';
import '../p2p_gift_card/p2p_gift_card_order_details/p2p_gift_order_details_controller.dart';
import 'p2p_order_details_controller.dart';

class OrderInfoView extends StatelessWidget {
  const OrderInfoView({super.key, this.order, this.gcOrder});

  final P2POrder? order;
  final P2PGiftCardOrder? gcOrder;

  @override
  Widget build(BuildContext context) {
    String amount = order != null
        ? "${coinFormat(order?.amount)} ${order?.coinType ?? ""}"
        : "${coinFormat(gcOrder?.amount)} ${gcOrder?.pGiftCard?.giftCard?.coinType ?? ""}";

    String price =
        order != null ? "${coinFormat(order?.price)} ${order?.currency ?? ""}" : "${coinFormat(gcOrder?.price)} ${gcOrder?.currencyType ?? ""}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vSpacer10(),
        TextRobotoAutoBold("Confirm order info".tr),
        vSpacer10(),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRobotoAutoNormal("Amount".tr),
                  TextRobotoAutoBold(amount),
                ],
              ),
            ),
            hSpacer10(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRobotoAutoNormal("Price".tr),
                  TextRobotoAutoBold(price),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}

class OrderTimeLimitView extends StatelessWidget {
  const OrderTimeLimitView({super.key, this.order, this.gcOrder, this.dueMinute, this.onEnd});

  final P2POrder? order;
  final P2PGiftCardOrder? gcOrder;
  final int? dueMinute;
  final Function()? onEnd;

  @override
  Widget build(BuildContext context) {
    dynamic currentOrder = gcOrder ?? order;
    if (currentOrder?.status == P2pTradeStatus.escrow && (currentOrder.paymentTime ?? 0) > 0 && (dueMinute ?? 0) > 0) {
      final endTime = DateTime.now().add(Duration(seconds: dueMinute!));
      return Row(
        children: [
          TextRobotoAutoBold("${"Time Left".tr} : "),
          CountDownView(endTime: endTime, onEnd: onEnd),
        ],
      );
    } else {
      return vSpacer0();
    }
  }
}

class OrderStatusView extends StatelessWidget {
  const OrderStatusView({super.key, this.order, this.gcOrder});

  final P2POrder? order;
  final P2PGiftCardOrder? gcOrder;

  @override
  Widget build(BuildContext context) {
    String title = "";
    Color color = Colors.deepOrange;
    final status = order != null ? order?.status : gcOrder?.status;
    if (status == P2pTradeStatus.timeExpired) {
      title = "Trade time expired".tr;
    } else if (status == P2pTradeStatus.canceled) {
      title = "Trade canceled".tr;
    } else if (status == P2pTradeStatus.paymentDone) {
      title = "Waiting for releasing order".tr;
      color = Colors.amber;
    } else if (status == P2pTradeStatus.escrow) {
      title = "Waiting for payment".tr;
      color = Colors.amber;
    } else if (status == P2pTradeStatus.transferDone) {
      title = "Trade completed".tr;
      color = Colors.green;
    } else if (status == P2pTradeStatus.releasedByAdmin) {
      title = "Order Released By Admin".tr;
      color = Colors.green;
    } else if (status == P2pTradeStatus.refundedByAdmin) {
      title = "Order Refunded By Admin".tr;
    }
    return Column(
      children: [
        vSpacer20(),
        Container(
          width: Get.width,
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge, vertical: Dimens.paddingLargeExtra),
          decoration: boxDecorationRoundBorder(color: Colors.transparent, borderColor: color),
          child: TextRobotoAutoBold(title, color: color),
        ),
      ],
    );
  }
}

//ignore: must_be_immutable
class OrderPaymentView extends StatelessWidget {
  OrderPaymentView({super.key, this.gcOrder, this.order, this.payInfo});

  final P2POrder? order;
  final P2PGiftCardOrder? gcOrder;
  final DynamicBank? payInfo;
  Rx<File> documentImage = File("").obs;

  @override
  Widget build(BuildContext context) {
    final bankSlugs = payInfo?.bank?.keys ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dividerHorizontal(),
        textWithBackground("Transfer the fund to the seller account provided below".tr, bgColor: context.theme.focusColor.withValues(alpha: 0.5)),
        vSpacer10(),
        Container(
          decoration: boxDecorationRoundBorder(),
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(
            children: [
              TwoTextFixedView("Method Name".tr, payInfo?.bankForm?.title ?? '', onSubTap: () => copyToClipboard(payInfo?.bankForm?.title ?? '', textInMsg: true)),
              ...List.generate(bankSlugs.length, (index) {
                final item = payInfo?.bank!.values.toList()[index];
                return TwoTextFixedView(item?.title ?? '', item?.value ?? 'N_A'.tr, onSubTap: () => copyToClipboard(item?.value ?? '', textInMsg: true));
              },),
            ],
          ),
        ),
        vSpacer2(),
        Align(alignment: Alignment.centerRight, child: TextRobotoAutoNormal("Tap on the value for copy".tr, textAlign: TextAlign.end)),
        vSpacer20(),
        TextRobotoAutoNormal("Select document".tr, color: context.theme.primaryColor),
        vSpacer5(),
        _showUploadImage(context),
        vSpacer20(),
        buttonRoundedMain(
            text: "Pay and notify seller".tr,
            onPress: () {
              if (documentImage.value.path.isEmpty) {
                showToast("select image of your payment");
                return;
              }
              if (order != null) {
                Get.find<P2pOrderDetailsController>().p2pPaymentOrder(documentImage.value);
              } else if (gcOrder != null) {
                Get.find<P2pGiftOrderDetailsController>().p2pGiftCardOrderPayNow(documentImage.value);
              }
            }),
        vSpacer10(),
        dividerHorizontal(height: 0),
      ],
    );
  }

  Widget _showUploadImage(BuildContext context) {
    return Obx(() => InkWell(
      child: Container(
        height: context.width / 3,
        width: context.width,
        decoration: boxDecorationRoundBorder(color: context.theme.secondaryHeaderColor),
        child: (documentImage.value.path.isNotEmpty)
            ? showImageLocal(documentImage.value)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buttonOnlyIcon(iconPath: AssetConstants.icUpload, size: Dimens.iconSizeMid),
            vSpacer10(),
            TextRobotoAutoNormal("Tap to upload photo".tr),
          ],
        ),
      ),
      onTap: () {
        showImageChooser(context, (chooseFile, isGallery) {
          isGallery ? documentImage.value = chooseFile : saveFileOnTempPath(chooseFile, onNewFile: (newFile) => documentImage.value = newFile);
        });
      },
    ));
  }
}

// class OrderPaymentView extends StatelessWidget {
//   OrderPaymentView({super.key, this.gcOrder, this.order, this.payInfo});
//
//   final P2POrder? order;
//   final P2PGiftCardOrder? gcOrder;
//   final P2pPaymentInfo? payInfo;
//   Rx<File> documentImage = File("").obs;
//
//   @override
//   Widget build(BuildContext context) {
//     final type = payInfo?.adminPaymentMethod?.paymentType ?? 0;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         dividerHorizontal(),
//         textWithBackground("Transfer the fund to the seller account provided below".tr, bgColor: context.theme.focusColor.withValues(alpha: 0.5)),
//         vSpacer10(),
//         _textWithCopyView(payInfo?.adminPaymentMethod?.name ?? "", preText: "Method Name".tr, hideCopy: true),
//         _textWithCopyView(payInfo?.username ?? "", preText: "Account Name".tr),
//         if (type == P2pPaymentType.mobile)
//           _textWithCopyView(payInfo?.mobileAccountNumber ?? "", preText: "Mobile Number".tr)
//         else if (type == P2pPaymentType.card)
//           Column(children: [
//             _textWithCopyView(payInfo?.cardNumber ?? "", preText: "Card Number".tr),
//             _textWithCopyView(payInfo?.cardType == CardPaymentType.debit ? "Debit".tr : "Credit".tr, preText: "Card Type".tr, hideCopy: true)
//           ])
//         else if (type == P2pPaymentType.bank)
//           Column(children: [
//             _textWithCopyView(payInfo?.bankName ?? "", preText: "Bank Name".tr),
//             _textWithCopyView(payInfo?.bankAccountNumber ?? "", preText: "Bank Account Number".tr),
//             _textWithCopyView(payInfo?.accountOpeningBranch ?? "", preText: "Account Opening Branch".tr),
//             _textWithCopyView(payInfo?.transactionReference ?? "", preText: "Transaction Reference".tr),
//           ]),
//         vSpacer20(),
//         TextRobotoAutoNormal("Select document".tr, color: context.theme.primaryColor),
//         vSpacer5(),
//         _showUploadImage(context),
//         vSpacer20(),
//         buttonRoundedMain(
//             text: "Pay and notify seller".tr,
//             onPress: () {
//               if (documentImage.value.path.isEmpty) {
//                 showToast("select image of your payment", context: context);
//                 return;
//               }
//               if (order != null) {
//                 Get.find<P2pOrderDetailsController>().p2pPaymentOrder(documentImage.value);
//               } else if (gcOrder != null) {
//                 Get.find<P2pGiftOrderDetailsController>().p2pGiftCardOrderPayNow(documentImage.value);
//               }
//             }),
//         vSpacer10(),
//         dividerHorizontal(height: 0),
//       ],
//     );
//   }
//
//   _textWithCopyView(String text, {String? preText, bool hideCopy = false}) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         TextRobotoAutoNormal("$preText : "),
//         TextRobotoAutoBold(text, maxLines: 2),
//         if (!hideCopy)
//           buttonOnlyIcon(
//               iconPath: AssetConstants.icCopy,
//               visualDensity: minimumVisualDensity,
//               iconColor: Get.theme.colorScheme.secondary,
//               onPress: () => copyToClipboard(text))
//       ],
//     );
//   }
//
//   _showUploadImage(BuildContext context) {
//     return Obx(() => InkWell(
//           child: Container(
//             height: context.width / 3,
//             width: context.width,
//             decoration: boxDecorationRoundBorder(color: context.theme.secondaryHeaderColor),
//             child: (documentImage.value.path.isNotEmpty)
//                 ? showImageLocal(documentImage.value)
//                 : Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       buttonOnlyIcon(iconPath: AssetConstants.icUpload, size: Dimens.iconSizeMid),
//                       vSpacer10(),
//                       TextRobotoAutoNormal("Tap to upload photo".tr),
//                     ],
//                   ),
//           ),
//           onTap: () {
//             showImageChooser(context, (chooseFile, isGallery) {
//               isGallery ? documentImage.value = chooseFile : saveFileOnTempPath(chooseFile, onNewFile: (newFile) => documentImage.value = newFile);
//             });
//           },
//         ));
//   }
// }

class OrderReviewView extends StatelessWidget {
  OrderReviewView({super.key, this.order, required this.isBuy});

  final P2POrder? order;
  final bool isBuy;
  final reviewEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final typeText = isBuy ? "Seller".tr.toLowerCase() : "Buyer".tr.toLowerCase();
    final feedback = isBuy ? order?.buyerFeedback : order?.sellerFeedback;
    final feedbackOpposite = isBuy ? order?.sellerFeedback : order?.buyerFeedback;
    RxInt feedbackType = 1.obs;

    if (order?.status == P2pTradeStatus.transferDone) {
      return Container(
        decoration: boxDecorationRoundCorner(),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feedbackOpposite != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRobotoAutoBold("${typeText.toCapitalizeFirst()} ${"Feedback".tr}: "),
                  hSpacer5(),
                  Expanded(child: TextRobotoAutoNormal(feedbackOpposite, maxLines: 20, textAlign: TextAlign.start, color: Get.theme.primaryColor)),
                ],
              ),
            if (feedbackOpposite != null && feedback == null) vSpacer10(),
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
                        Get.find<P2pOrderDetailsController>().p2pFeedbackOrder(reviewText, feedbackType.value);
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

class OrderDisputeView extends StatelessWidget {
  OrderDisputeView(this.order, {super.key});

  final P2POrder? order;
  final subEditController = TextEditingController();
  final descEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Rx<File> documentImage = File("").obs;
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
          vSpacer15(),
          TextRobotoAutoBold("Select document".tr),
          vSpacer5(),
          Obx(() => DocumentUploadView(documentImage: documentImage.value, selectedImage: (selected) => documentImage.value = selected)),
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
                // if (documentImage.value.path.isEmpty) {
                //   showToast("Select a image for dispute".tr, context: context);
                //   return;
                // }
                hideKeyboard(context: context);
                Get.find<P2pOrderDetailsController>().p2pOrderDispute(title, description, documentImage.value);
              })
        ],
      ),
    );
  }
}

class DisputedView extends StatelessWidget {
  const DisputedView({super.key, this.p2pGiftCardOrderDetails, this.p2pOrderDetails});

  final P2PGiftCardOrderDetails? p2pGiftCardOrderDetails;
  final P2POrderDetails? p2pOrderDetails;

  @override
  Widget build(BuildContext context) {
    dynamic order = p2pOrderDetails != null ? p2pOrderDetails?.order : p2pGiftCardOrderDetails?.order;
    dynamic dispute = p2pOrderDetails != null ? p2pOrderDetails?.dispute : p2pGiftCardOrderDetails?.dispute;
    String title = "";

    if (dispute?.status == 1) {
      if (order?.status == P2pTradeStatus.releasedByAdmin) {
        title = "Order Released By Admin".tr;
      } else if (order?.status == P2pTradeStatus.refundedByAdmin) {
        title = "Order Refunded By Admin".tr;
      } else {
        title = "Disputed".tr;
      }
    } else {
      final disputer = (p2pOrderDetails != null ? p2pOrderDetails?.whoDispute : p2pGiftCardOrderDetails?.whoDispute) ?? "";
      title = disputer == "seller" ? "Seller created dispute against order".tr : "Buyer created dispute against order".tr;
    }
    return dispute == null
        ? vSpacer0()
        : Column(
            children: [
              vSpacer20(),
              Container(
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge, vertical: Dimens.paddingLargeExtra),
                decoration: boxDecorationRoundBorder(color: Colors.transparent, borderColor: Colors.deepOrangeAccent),
                child: TextRobotoAutoBold(title, color: Colors.deepOrangeAccent),
              ),
            ],
          );
  }
}

class PaymentProofView extends StatelessWidget {
  const PaymentProofView({super.key, this.paySleep});

  final String? paySleep;

  @override
  Widget build(BuildContext context) {
    return paySleep.isValid
        ? Container(
            decoration: boxDecorationRoundBorder(),
            padding: const EdgeInsets.all(Dimens.paddingMid),
            margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextRobotoAutoBold("${"Deposit Proof".tr}: "),
                showImageNetwork(
                    imagePath: paySleep,
                    width: Dimens.iconSizeLarge,
                    height: Dimens.iconSizeLarge,
                    boxFit: BoxFit.cover,
                    onPressCallback: () => openUrlInBrowser(paySleep ?? ""))
              ],
            ),
          )
        : vSpacer0();
  }
}
