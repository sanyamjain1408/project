import 'dart:io';

import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/ico_ui/ico_dashboard/ico_dashboard_controller.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dashboard.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class IcoCreateTokenController extends GetxController {
  final networkListStatic = [
    Network(id: 4, networkName: "ERC20 Token API".tr, networkType: "ETH"),
    Network(id: 5, networkName: "BEP20 Token API".tr, networkType: "BNB")
  ];
  RxInt selectedNetwork = 0.obs;
  Rx<Contract> contract = Contract().obs;
  Rx<File> selectedFile = File("").obs;
  RxString contractError = "".obs;
  RxList<Network> networkList = <Network>[].obs;
  IcoToken? preToken;

  Future<void> getIcoCreateTokenDetails(int? id, Function(IcoToken) onSuccess) async {
    IcoAPIRepository().getIcoCreateTokenDetails(id).then((resp) {
      if (resp.success) {
        final netList = resp.data[APIKeyConstants.networks];
        if (netList != null) {
          networkList.value = List<Network>.from(netList.map((x) => Network.fromJson(x)));
        }
        final token = resp.data["ico_phase_token"];
        if (token != null) {
          onSuccess(IcoToken.fromJson(token));
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> icoGetContractAddressDetails(String address, {String? chainLink, int? network}) async {
    IcoAPIRepository().icoGetContractAddressDetails(address, chainLink: chainLink, network: network).then((resp) {
      if (resp.success) {
        contract.value = Contract.fromJson(resp.data);
        contractError.value = '';
      } else {
        contractError.value = resp.message;
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> icoCreateUpdateToken(IcoToken token, File file) async {
    showLoadingDialog();
    IcoAPIRepository().icoCreateUpdateToken(token, file).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        if (Get.isRegistered<IcoDashboardController>()) Get.find<IcoDashboardController>().getIcoListData(false);
        Get.back();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
