import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_chat.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dashboard.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class IcoChatController extends GetxController implements SocketListener {
  RxList<Admin> adminList = <Admin>[].obs;
  RxList<Conversation> messageList = <Conversation>[].obs;
  final chatEditController = TextEditingController();
  RxBool isDataLoading = true.obs;
  RxInt selectedAdmin = 0.obs;
  Rx<File> chatFile = File("").obs;
  String? chatChannel;

  Future<void> getIcoChatDetails(IcoToken? token) async {
    IcoAPIRepository().getIcoChatDetails(token?.id ?? 0, null).then((resp) {
      if (resp.success && resp.data != null) {
        final data = IcoChatData.fromJson(resp.data);
        adminList.value = data.adminList ?? [];
        if (adminList.isNotEmpty) {
          selectedAdmin.value = 0;
          getIcoChatList(token);
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  void getIcoChatList(IcoToken? token) async {
    if (selectedAdmin.value == -1) return;
    isDataLoading.value = true;
    messageList.clear();
    final adID = adminList[selectedAdmin.value].id;
    manageChatChannel(false);
    IcoAPIRepository().getIcoChatDetails(token?.id ?? 0, adID).then((resp) {
      isDataLoading.value = false;
      if (resp.success) {
        final data = IcoChatData.fromJson(resp.data);
        messageList.value = (data.conversationList ?? []).reversed.toList();
        manageChatChannel(true);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  @override
  void onDataGet(channel, event, data) {
    if (event == SocketConstants.eventConversation && data is ServerResponse) {
      final userId = data.data["receiver_id"] as String? ?? "0";
      if (int.parse(userId) == gUserRx.value.id) addNewMessage(data.data, false);
    }
  }

  void manageChatChannel(bool isSet) {
    if (isSet) {
      if (chatChannel == null && selectedAdmin.value != -1) {
        final adID = adminList[selectedAdmin.value].id;
        chatChannel = "${SocketConstants.channelNewMessage}${gUserRx.value.id}-$adID";
        APIRepository().subscribeEvent(chatChannel!, this);
      }
    } else {
      APIRepository().unSubscribeEvent(chatChannel ?? "", this);
    }
  }

  void sendChatMessage(IcoToken? token, String message, File file, Function() onSent) {
    if (file.path.isNotEmpty) showLoadingDialog();
    final msgFile = file.path.isNotEmpty ? file : null;
    final adID = adminList[selectedAdmin.value].id;
    IcoAPIRepository().icoChatConversationStore(token?.id ?? 0, adID ?? 0, message: message, file: msgFile).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        addNewMessage(resp.data, true);
        onSent();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void addNewMessage(dynamic data, bool isSent) {
    Conversation message = Conversation.fromJson(data);
    // if (message.orderId == orderDetails.value.order?.id) {
    isSent ? message.senderId = gUserRx.value.id : message.receiverId = gUserRx.value.id;
    message.createdAt = DateTime.now();
    messageList.insert(0, message);
    // }
  }
}
