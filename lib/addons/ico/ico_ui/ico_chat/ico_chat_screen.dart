import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/ico_chat.dart';
import '../../model/ico_dashboard.dart';
import '../../../../data/local/constants.dart';
import '../../../../utils/appbar_util.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_field_util.dart';
import '../../../../utils/text_util.dart';
import 'ico_chat_card.dart';
import 'ico_chat_controller.dart';

class ICOChatScreen extends StatefulWidget {
  const ICOChatScreen({super.key, this.token});

  final IcoToken? token;

  @override
  State<ICOChatScreen> createState() => _ICOChatScreenState();
}

class _ICOChatScreenState extends State<ICOChatScreen> {
  final _controller = Get.put(IcoChatController());

  @override
  void initState() {
    _controller.selectedAdmin.value = -1;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getIcoChatDetails(widget.token));
  }

  @override
  void dispose() {
    _controller.manageChatChannel(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Chat".tr),
      body: SafeArea(
          child: Column(
        children: [
          _adminList(),
          vSpacer5(),
          _messageList(),
          Obx(() => _controller.chatFile.value.path.isEmpty
              ? vSpacer0()
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  hSpacer10(),
                  Icon(Icons.attach_file, size: Dimens.iconSizeMinExtra, color: context.theme.primaryColor),
                  hSpacer5(),
                  Expanded(child: TextRobotoAutoNormal(_controller.chatFile.value.absolute.name)),
                  hSpacer5(),
                  buttonOnlyIcon(
                      iconData: Icons.cancel_outlined, visualDensity: minimumVisualDensity, onPress: () => _controller.chatFile.value = File("")),
                  hSpacer10()
                ])),
          Row(
            children: [
              hSpacer10(),
              Expanded(
                  child: textFieldWithWidget(
                      controller: _controller.chatEditController,
                      hint: "Write Message".tr,
                      borderRadius: Dimens.radiusCornerMid,
                      height: Dimens.btnHeightMid,
                      suffixWidget: buttonOnlyIcon(iconData: Icons.image_outlined, onPress: () => _selectImage(context)))),
              hSpacer10(),
              buttonText("Send".tr,
                  textColor: context.theme.scaffoldBackgroundColor, visualDensity: VisualDensity.compact, onPress: () => _sendChatMessage(context)),
              hSpacer10()
            ],
          ),
          vSpacer5()
        ],
      )),
    );
  }

  Widget _adminList() {
    return Obx(() {
      final isSelected = _controller.selectedAdmin.value;
      return SizedBox(
        height: Dimens.btnHeightMid,
        child: ListView.separated(
            itemCount: _controller.adminList.length,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
            separatorBuilder:(context, index) =>  hSpacer10(),
            itemBuilder: (context, index) {
              final user = _controller.adminList[index];
              return AdminUserView(
                  admin: user,
                  isSelected: isSelected == index,
                  onTap: () {
                    _controller.selectedAdmin.value = index;
                    _controller.getIcoChatList(widget.token);
                  });
            }),
      );
    });
  }

  Widget _messageList() {
    return Obx(() {
      return Expanded(
          child: _controller.messageList.isEmpty
              ? handleEmptyViewWithLoading(_controller.isDataLoading.value, message: "Your messages will appear here".tr)
              : ListView.builder(
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  scrollDirection: Axis.vertical,
                  reverse: true,
                  itemCount: _controller.messageList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ChatCard(message: _controller.messageList[index], selfUserId: gUserRx.value.id);
                  },
                ));
    });
  }

  void _selectImage(BuildContext context) {
    showImageChooser(context, (chooseFile, isGallery) async {
      if (chooseFile.path.isNotEmpty) {
        if (isGallery) {
          _controller.chatFile.value = chooseFile;
        } else {
          saveFileOnTempPath(chooseFile, onNewFile: (newFile) => _controller.chatFile.value = newFile);
        }
      } else {
        showToast("Image not found".tr);
      }
    });
  }

  void _sendChatMessage(BuildContext context) {
    var message = _controller.chatEditController.text.trim();
    if (message.isEmpty && _controller.chatFile.value.path.isEmpty) {
      showToast("Message can not be empty".tr);
      return;
    }
    _controller.sendChatMessage(widget.token, message, _controller.chatFile.value, () {
      _controller.chatEditController.text = "";
      _controller.chatFile.value = File("");
    });
  }
}

class AdminUserView extends StatelessWidget {
  const AdminUserView({super.key, required this.admin, required this.isSelected, required this.onTap});

  final Admin admin;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimens.radiusCornerMid),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMin, horizontal: Dimens.paddingMid),
        decoration: isSelected
            ? boxDecorationRoundCorner(radius: Dimens.radiusCornerMid, color: context.theme.focusColor)
            : boxDecorationRoundBorder(radius: Dimens.radiusCornerMid),
        child: Row(
          children: [showCircleAvatar(admin.photo, size: Dimens.iconSizeMin), hSpacer5(), TextRobotoAutoBold(admin.getName())],
        ),
      ),
    );
  }
}
