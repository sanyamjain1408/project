import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dynamic_form.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class IcoLaunchTokenController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<IcoLunchDynamicForm> dynamicFormData = IcoLunchDynamicForm().obs;

  Future<void> getIcoDynamicForm() async {
    isLoading.value = true;
    IcoAPIRepository().getIcoDynamicForm().then((resp) {
      isLoading.value = false;
      if (resp.success) {
        dynamicFormData.value = IcoLunchDynamicForm.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> icoDynamicFormSubmit(Map<String, dynamic> mapObj) async {
    showLoadingDialog();
    IcoAPIRepository().icoDynamicFormSubmit(mapObj).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) Get.back();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
