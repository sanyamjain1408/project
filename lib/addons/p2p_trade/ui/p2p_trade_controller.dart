import 'package:get/get.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';

class P2pTradeController extends GetxController {
  RxInt selectedTabIndex = 0.obs;

  Map<int, String> getP2pTabMap() {
    var map = {0: "Home".tr, 1: "Orders".tr, 2: "User Center".tr, 3: "P2P Wallet".tr, 4: "My Ads".tr};
    final isGCEnable = getSettingsLocal()?.enableGiftCard == 1;
    if (isGCEnable) map[5] = "Gift Card".tr;
    return map;
  }
}