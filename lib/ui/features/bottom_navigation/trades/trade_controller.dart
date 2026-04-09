import 'package:get/get.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';

class TradeController extends GetxController {
  RxInt selectedTab = 0.obs;

  List<String> getTradeTabs() {
    List<String> list = ['Spot'.tr];
    if (getSettingsLocal()?.p2pModule == 1) list.add('P2P'.tr);
    return list;
  }
}
