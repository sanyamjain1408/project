import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'common_utils.dart';

class NetworkCheck {
  static Future<bool> isOnline({bool showError = true}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    List checkList = [ConnectivityResult.mobile, ConnectivityResult.wifi, ConnectivityResult.vpn];
    if (Platform.isIOS) checkList.add(ConnectivityResult.other);
    if (checkList.any((item) => connectivityResult.contains(item))) {
      return true;
    } else {
      if (showError) showToast("Please Check Internet Connection and Run the App Again".tr, isError: true, isLong: true);
      return false;
    }
  }
}
