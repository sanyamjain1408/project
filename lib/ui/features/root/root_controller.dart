import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/data/models/socket_response.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/bottom_nav_helper.dart';
import 'package:tradexpro_flutter/helper/data_process_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class RootController extends GetxController implements SocketListener {
  RxInt notificationCount = 0.obs;
  int bottomNavIndex = AppBottomNavHelper.getNavIndex(AppBottomNavKey.home);
  late Function(int) changeBottomNavIndex;

  @override
  void onReady() {
    super.onReady();
    gIsBalanceHide.value = GetStorage().read(PreferenceKey.isBalanceHide) ?? false;
    setMyProfile();
  }

  @override
  void onDataGet(channel, event, data) {
    if (event == SocketConstants.eventNotification) {
      notificationCount.value++;
      if (data is NotificationData) {
        final title = data.title ?? "";
        final msg = data.notifyMessage();
        final isKycReject = title.toLowerCase().contains("kyc") && title.toLowerCase().contains("reject");
        if (isKycReject && Get.context != null) {
          Get.dialog(
            AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(title, style: const TextStyle(color: Color(0xFFFF4D4D), fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
              content: Text(msg, style: const TextStyle(color: Colors.white70, fontFamily: 'DMSans')),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("OK", style: TextStyle(color: Color(0xFFCCFF00), fontFamily: 'DMSans')),
                ),
              ],
            ),
          );
        } else {
          showToast(msg.isNotEmpty ? msg : title, isError: false, gravity: ToastGravity.TOP);
        }
      }
    }
  }

  void setMyProfile() {
    var userMap = GetStorage().read(PreferenceKey.userObject);
    if (userMap != null) {
      try {
        gUserRx.value = User.fromJson(userMap);
      } catch (error) {
        printFunction("setMyProfile error", error);
      }
    }
    Future.delayed(const Duration(seconds: 3), () => getMyProfile());
  }

  void getMyProfile() {
    if (gUserRx.value.id == 0) return;
    APIRepository().getSelfProfile().then((resp) {
      if (resp.success) {
        var userMap = resp.data[APIKeyConstants.user];
        if (userMap != null) {
          GetStorage().write(PreferenceKey.userObject, userMap);
          gUserRx.value = User.fromJson(userMap);
          getNotificationCount();
        }
      }
      if (gUserRx.value.id != 0) {
        String channelNotify = SocketConstants.channelNotification + gUserRx.value.id.toString();
        APIRepository().subscribeEvent(channelNotify, this);
      }
    });
  }

  void getCommonSettings() async {
    APIRepository().getCommonSettings().then((resp) {
      if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
        DataProcessHelper.commonSettingsProcess(resp.data);
      }
    });
  }

  void logOut() {
    showLoadingDialog();
    APIRepository().logoutUser().then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) logOutActions();
    }, onError: (err) {
      hideLoadingDialog();
      err.toString() == ErrorConstants.unauthorized ? logOutActions() : showToast(err.toString());
    });
  }

  void getNotificationCount() {
    APIRepository().getNotifications().then((resp) {
      if (resp.success) {
        notificationCount.value = (resp.data as List? ?? []).length;
      }
    }, onError: (err) {});
  }
}
