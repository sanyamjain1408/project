import 'dart:io';

import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

import '../ico_token_phase_list/ico_token_phase_list_controller.dart';

class IcoCreatePhaseController extends GetxController {
  RxList<IcoCurrency> currencyList = <IcoCurrency>[].obs;
  RxInt selectedCurrency = 0.obs;
  Rx<Contract> contract = Contract().obs;
  Rx<File> selectedFile = File("").obs;
  RxString contractError = "".obs;

  Future<void> getIcoCoinList(String? currency) async {
    IcoAPIRepository().getIcoCoinList().then((resp) {
      if (resp.success) {
        currencyList.value = List<IcoCurrency>.from(resp.data.map((x) => IcoCurrency.fromJson(x)));
        if (currency.isValid) {
          final index = currencyList.indexWhere((element) => element.coinType == currency);
          if (index != -1) selectedCurrency.value = index;
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> icoCreateUpdateTokenPhase(IcoPhase phase, File file, Map<int, String> sMap) async {
    showLoadingDialog();
    IcoAPIRepository().icoCreateUpdateTokenPhase(phase, file, sMap).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) {
          Get.back();
          Future.delayed(const Duration(microseconds: 500), () {
            if (Get.isRegistered<IcoTokenPhaseListController>()) Get.find<IcoTokenPhaseListController>().getIcoListData(false, phase.icoTokenId ?? 0);
          });
        }
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
