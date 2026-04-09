import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import '../../models/p2p_order.dart';

class ChatCard extends StatelessWidget {
  final ChatMessage message;
  final int selfUserId;

  const ChatCard({super.key, required this.message, required this.selfUserId});

  @override
  Widget build(BuildContext context) {
    return message.senderId == selfUserId ? _outGoingMessageView() : _incomingMessageView();
  }

  Padding _outGoingMessageView() {
    final image = selfUserId == message.senderId ? message.senderImageLink : message.receiverImageLink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
              width: Get.width - 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.filePath.isValid) _imageMessageView(message, false),
                  if (message.filePath.isValid && message.message.isValid) vSpacer2(),
                  if (message.message.isValid)
                    BubbleNormal(
                      text: message.message ?? "",
                      isSender: true,
                      color: Get.theme.colorScheme.secondary.withValues(alpha: 0.20),
                      textStyle: Get.textTheme.labelMedium!,
                    ),
                  vSpacer2(),
                  _textDate(message.createdAt == null ? "" : getVerboseDateTimeRepresentation(message.createdAt!), textAlign: TextAlign.end)
                ],
              )),
          showCircleAvatar(image, size: 40),
        ],
      ),
    );
  }

  Padding _incomingMessageView() {
    final image = selfUserId == message.senderId ? message.receiverImageLink : message.senderImageLink;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          showCircleAvatar(image, size: 40),
          SizedBox(
              width: Get.width - 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.filePath.isValid) _imageMessageView(message, true),
                  if (message.filePath.isValid && message.message.isValid) vSpacer2(),
                  if (message.message.isValid)
                    BubbleNormal(
                      text: message.message ?? "",
                      isSender: false,
                      color: Get.theme.primaryColor.withValues(alpha: 0.10),
                      textStyle: Get.textTheme.labelMedium!,
                    ),
                  vSpacer2(),
                  _textDate(message.createdAt == null ? "" : getVerboseDateTimeRepresentation(message.createdAt!), textAlign: TextAlign.start)
                ],
              )),
        ],
      ),
    );
  }

  Padding _imageMessageView(ChatMessage message, bool isIncoming) {
    return Padding(
      padding: EdgeInsets.only(right: isIncoming ? 0 : Dimens.paddingLarge, left: isIncoming ? Dimens.paddingLarge : 0),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.paddingMid),
          child: Container(
            color: isIncoming ? Get.theme.primaryColor.withValues(alpha: 0.10) : Get.theme.colorScheme.secondary.withValues(alpha: 0.20),
            child: showImageNetwork(
                imagePath: message.filePath ?? "",
                width: Dimens.iconSizeLogo,
                height: Dimens.iconSizeLogo,
                onPressCallback: () => openUrlInBrowser(message.filePath ?? "")),
          )),
    );
  }

  Container _textDate(String text, {TextAlign? textAlign}) {
    var margin = textAlign == TextAlign.start ? const EdgeInsets.only(left: 15) : const EdgeInsets.only(right: 15);
    return Container(
      margin: margin,
      child: Text(
        text,
        textAlign: textAlign,
        style: Get.theme.textTheme.displaySmall!.copyWith(fontSize: 10),
      ),
    );
  }

// _dateSeparatorView() {
//   return Container(
//       alignment: Alignment.center,
//       margin: const EdgeInsets.all(10),
//       height: 20,
//       child: Text(getVerboseDateTimeRepresentation(message as DateTime), style: const TextStyle(color: Colors.grey)));
// }
}
