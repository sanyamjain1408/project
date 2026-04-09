import 'dart:io';

import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_order.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/p2p_constants.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../p2p_api_repository.dart';

class P2pOrderDetailsController extends GetxController implements SocketListener {
  Rx<P2POrderDetails> orderDetails = P2POrderDetails().obs;
  bool isDataLoading = true;
  RxList<ChatMessage> messageList = <ChatMessage>[].obs;
  String? chatChannel;
  String? statusChannel;

  void getOrderDetails(String uid) {
    isDataLoading = true;
    P2pAPIRepository().p2pOrderDetails(uid).then((resp) {
      isDataLoading = false;
      if (resp.success && resp.data != null) {
        orderDetails.value = P2POrderDetails.fromJson(resp.data);
        messageList.value = (orderDetails.value.chatMessages ?? []).reversed.toList();
        manageChatChannel(true);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isDataLoading = false;
      showToast(err.toString());
    });
  }

  /// *** CHAT Section *** ///
  @override
  void onDataGet(channel, event, data) {
    if (event == SocketConstants.eventConversation && data is ServerResponse) {
      final userId = data.data[APIKeyConstants.userId] as int? ?? 0;
      if (userId != gUserRx.value.id) addNewMessage(data.data, false);
    } else if (event == SocketConstants.eventOrderStatus && data is Map) {
      String uid = data[P2pAPIKeyConstants.order][P2pAPIKeyConstants.uid] ?? "";
      if (uid == orderDetails.value.order?.uid) getOrderDetails(uid);
    }
  }

  void manageChatChannel(bool isSet) {
    if (isSet) {
      if (chatChannel == null && orderDetails.value.order != null) {
        chatChannel = "${SocketConstants.channelNewMessage}${gUserRx.value.id}-${orderDetails.value.order?.uid}";
        APIRepository().subscribeEvent(chatChannel!, this);
      }
      if (statusChannel == null && orderDetails.value.order != null) {
        statusChannel = "${SocketConstants.channelOrderStatus}${gUserRx.value.id}${orderDetails.value.order?.uid}";
        APIRepository().subscribeEvent(statusChannel!, this);
      }
    } else {
      APIRepository().unSubscribeEvent(chatChannel ?? "", this);
      APIRepository().unSubscribeEvent(statusChannel ?? "", this);
    }
  }

  void sendChatMessage(String message, File file, Function() onSent) {
    if (file.path.isNotEmpty) showLoadingDialog();
    P2pAPIRepository().p2pSendMessage(orderDetails.value.order?.uid ?? "", text: message, file: file).then((resp) {
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
    ChatMessage message = ChatMessage.fromJson(data);
    if (message.orderId == orderDetails.value.order?.id) {
      isSent ? message.senderId = gUserRx.value.id : message.receiverId = gUserRx.value.id;
      message.createdAt = DateTime.now();
      messageList.insert(0, message);
    }
  }

  /// *** ORDER Section *** ///

  void p2pPaymentOrder(File image) {
    showLoadingDialog();
    P2pAPIRepository().p2pOrderPayment(orderDetails.value.order?.uid ?? "", image).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Future.delayed(const Duration(seconds: 3), () => getOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pReleaseOrder() {
    showLoadingDialog();
    P2pAPIRepository().p2pOrderRelease(orderDetails.value.order?.uid ?? "").then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        Future.delayed(const Duration(seconds: 3), () => getOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pFeedbackOrder(String review, int type) {
    showLoadingDialog();
    P2pAPIRepository().p2pOrderFeedback(orderDetails.value.order?.uid ?? "", review, type == 1 ? 1 : 0).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Future.delayed(const Duration(seconds: 3), () => getOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pOrderCancel(String reason) {
    showLoadingDialog();
    P2pAPIRepository().p2pOrderCancel(orderDetails.value.order?.uid ?? "", reason).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        Future.delayed(const Duration(seconds: 3), () => getOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pOrderDispute(String reasonTitle, String reasonDescription, File reasonImage) {
    showLoadingDialog();
    P2pAPIRepository().p2pOrderDispute(orderDetails.value.order?.uid ?? "", reasonTitle, reasonDescription, reasonImage).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) {
          Get.back();
          Future.delayed(const Duration(seconds: 3), () => getOrderDetails(orderDetails.value.order?.uid ?? ""));
        }
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
