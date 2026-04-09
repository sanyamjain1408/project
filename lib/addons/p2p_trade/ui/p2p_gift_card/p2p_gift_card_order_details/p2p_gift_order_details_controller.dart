import 'dart:io';

import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../../models/p2p_gift_card.dart';
import '../../../models/p2p_order.dart';
import '../../../p2p_api_repository.dart';
import '../../../p2p_constants.dart';

class P2pGiftOrderDetailsController extends GetxController implements SocketListener {
  Rx<P2PGiftCardOrderDetails> orderDetails = P2PGiftCardOrderDetails().obs;
  bool isDataLoading = true;
  RxList<ChatMessage> messageList = <ChatMessage>[].obs;
  String? chatChannel;
  String? statusChannel;

  void getP2pGiftCardOrderDetails(String uid) {
    isDataLoading = true;
    P2pAPIRepository().getP2pGiftCardOrderDetails(uid).then((resp) {
      isDataLoading = false;
      if (resp.success && resp.data != null) {
        orderDetails.value = P2PGiftCardOrderDetails.fromJson(resp.data);
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
      if (uid == orderDetails.value.order?.uid) getP2pGiftCardOrderDetails(uid);
    }
  }

  void manageChatChannel(bool isSet) {
    if (isSet) {
      if (chatChannel == null && orderDetails.value.order != null) {
        chatChannel = "${SocketConstants.channelNewMessage}${gUserRx.value.id}-${orderDetails.value.order?.uid}";
        APIRepository().subscribeEvent(chatChannel!, this);
      }
      if (statusChannel == null && orderDetails.value.order != null) {
        statusChannel = "${SocketConstants.channelOrderStatus}${gUserRx.value.id}-${orderDetails.value.order?.uid}";
        APIRepository().subscribeEvent(statusChannel!, this);
      }
    } else {
      APIRepository().unSubscribeEvent(chatChannel ?? "", this);
      APIRepository().unSubscribeEvent(statusChannel ?? "", this);
    }
  }

  void p2pGiftCardSendMessage(String message, File file, Function() onSent) {
    if (file.path.isNotEmpty) showLoadingDialog();
    P2pAPIRepository().p2pGiftCardSendMessage(orderDetails.value.order?.id ?? 0, text: message, file: file).then((resp) {
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
    isSent ? message.senderId = gUserRx.value.id : message.receiverId = gUserRx.value.id;
    message.createdAt = DateTime.now();
    messageList.insert(0, message);
  }

  /// *** ORDER Section *** ///

  void p2pGiftCardOrderPayNow(File? file) {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardOrderPayNow(orderDetails.value.order?.id ?? 0, file).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Future.delayed(const Duration(seconds: 3), () => getP2pGiftCardOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pGiftCardOrderPaymentConfirm() {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardOrderPaymentConfirm(orderDetails.value.order?.id ?? 0).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Future.delayed(const Duration(seconds: 3), () => getP2pGiftCardOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pGiftCardOrderCancel(String reason) {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardOrderCancel(orderDetails.value.order?.id ?? 0, reason).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        Future.delayed(const Duration(seconds: 3), () => getP2pGiftCardOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pGiftCardFeedbackUpdate(String review, int type) {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardFeedbackUpdate(orderDetails.value.order?.uid ?? "", review, type == 1 ? 1 : 0).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Future.delayed(const Duration(seconds: 3), () => getP2pGiftCardOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void p2pGiftCardOrderDispute(String reasonTitle, String reasonDescription) {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardOrderDispute(orderDetails.value.order?.id ?? 0, reasonTitle, reasonDescription).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        Future.delayed(const Duration(seconds: 3), () => getP2pGiftCardOrderDetails(orderDetails.value.order?.uid ?? ""));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
