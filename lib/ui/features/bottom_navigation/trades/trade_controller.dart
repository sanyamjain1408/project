import 'package:get/get.dart';

class TradeController extends GetxController {
  RxInt selectedTab = 1.obs; // default: Spot (index 1)

  List<String> getTradeTabs() {
    return ['Swap', 'Spot', 'Future', 'Earn', 'P2P'];
  }
}