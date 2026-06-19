import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeGridController extends GetxController {
  final _box = GetStorage();
  static const _storageKey = 'home_grid_icons';

  static const List<Map<String, dynamic>> defaultIcons = [
    {"image": "assets/images/deposit.png", "title": "Deposit"},
    {"image": "assets/images/champion.png", "title": "Champion"},
    {"image": "assets/images/swap.png", "title": "Swap"},
    {"image": "assets/images/earn.png", "title": "Earn"},
    {"image": "assets/images/buy.png", "title": "Buy"},
    {"image": "assets/images/future.png", "title": "Future"},
    {"image": "assets/images/transfer.png", "title": "Transfer"},
    {"image": "assets/images/spot.png", "title": "Spot"},
    {"image": "assets/images/funds.png", "title": "Funds"},
  ];

  var selectedIcons = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    final saved = _box.read<List>(_storageKey);
    if (saved != null && saved.isNotEmpty) {
      selectedIcons.value = saved.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      // First time — initialize with defaults
      selectedIcons.value = List<Map<String, dynamic>>.from(defaultIcons);
      _save();
    }
  }

  void _save() {
    _box.write(_storageKey, selectedIcons.toList());
  }

  void addIcon(String image, String title) {
    if (selectedIcons.length >= 9) {
      Get.snackbar("Limit Reached", "You can only add up to 9 icons.");
      return;
    }
    if (!selectedIcons.any((item) => item['title'] == title)) {
      selectedIcons.add({"image": image, "title": title});
      _save();
    }
  }

  void removeIcon(String title) {
    selectedIcons.removeWhere((item) => item['title'] == title);
    _save();
  }

  void saveGrid() {
    _save();
    Get.back();
  }
}
