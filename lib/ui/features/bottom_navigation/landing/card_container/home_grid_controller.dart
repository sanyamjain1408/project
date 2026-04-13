import 'package:get/get.dart';

class HomeGridController extends GetxController {
  // Ye list store karegi
  var selectedIcons = <Map<String, dynamic>>[].obs;

  // Icons ko add karna
  void addIcon(String image, String title) {
    // === CHANGE: Limit 8 ki jagah 9 kar diya ===
    if (selectedIcons.length >= 9) {
      Get.snackbar("Limit Reached", "You can only edit up to 9 icons. 'More' is fixed.");
      return;
    }
    
    bool exists = selectedIcons.any((item) => item['title'] == title);
    if (!exists) {
      selectedIcons.add({"image": image, "title": title});
    }
  }

  void removeIcon(String title) {
    selectedIcons.removeWhere((item) => item['title'] == title);
  }

  void saveGrid() {
    print("Grid Saved");
    Get.back(); 
  }
}