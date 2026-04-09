import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dashboard.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class IcoDashboardController extends GetxController {
  RxInt selectedType = 0.obs;
  RxList<dynamic> icoDataList = <dynamic>[].obs;
  Rx<IcoWithdrawData> icoWithdrawData = IcoWithdrawData().obs;
  int loadedPage = 0;
  bool hasMoreData = false;
  RxBool isLoading = true.obs;

  Future<void> getIcoListData(bool isLoadMore) async {
    if (!isLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      icoDataList.clear();
    }
    isLoading.value = true;
    loadedPage++;

    try {
      ServerResponse? resp;
      if (selectedType.value == 0) {
        resp = await IcoAPIRepository().getIcoSubmittedDynamicFormList(loadedPage);
      } else if (selectedType.value == 1) {
        resp = await IcoAPIRepository().getIcoTokenListUser(loadedPage);
      } else if (selectedType.value == 2) {
        resp = await IcoAPIRepository().getIcoTokenBuyHistory(loadedPage);
      } else if (selectedType.value == 3) {
        resp = await IcoAPIRepository().getIcoMyTokenBalance(loadedPage);
      }else if (selectedType.value == 5) {
        resp = await IcoAPIRepository().getIcoTokenWithdrawList(loadedPage);
      }
      isLoading.value = false;
      if ((resp?.success ?? false) && resp!.data != null) {
        final listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        List<dynamic> list = [];
        if (selectedType.value == 0) {
          list = List<IcoDynamicForm>.from(listResponse.data!.map((x) => IcoDynamicForm.fromJson(x)));
        } else if (selectedType.value == 1) {
          list = List<IcoToken>.from(listResponse.data!.map((x) => IcoToken.fromJson(x)));
        } else if (selectedType.value == 2) {
          list = List<IcoBuyToken>.from(listResponse.data!.map((x) => IcoBuyToken.fromJson(x)));
        } else if (selectedType.value == 3) {
          list = List<IcoMyToken>.from(listResponse.data!.map((x) => IcoMyToken.fromJson(x)));
        }else if (selectedType.value == 5) {
          list = List<IcoWithdraw>.from(listResponse.data!.map((x) => IcoWithdraw.fromJson(x)));
        }
        icoDataList.addAll(list);
      } else {
        showToast(resp?.message ?? "");
      }
    } catch (err) {
      isLoading.value = false;
      showToast(err.toString());
    }
  }

  Future<void> getIcoTokenEarns() async {
    isLoading.value = true;
    IcoAPIRepository().getIcoTokenEarns().then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        icoWithdrawData.value = IcoWithdrawData.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> icoTokenWithdrawPrice(double amount, String currencyType, String currencyTo, Function(String? error) onData) async {
    IcoAPIRepository().icoTokenWithdrawPrice(amount, currencyType, currencyTo).then((resp) {
      if (resp.success) {
        onData("");
      } else {
        onData(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> icoTokenWithdrawRequest(double amount, String currencyType, String currencyTo, Function() onSuccess, {String? payDetails}) async {
    showLoadingDialog();
    IcoAPIRepository().icoTokenWithdrawRequest(amount, currencyType, currencyTo, payDetails: payDetails).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        onSuccess();
        getIcoTokenEarns();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }


}
