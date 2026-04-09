import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class IcoTokenPhaseListController extends GetxController {
  RxList<IcoPhase> phaseList = <IcoPhase>[].obs;
  RxList<PhaseAdditionalInfo> additionalList = <PhaseAdditionalInfo>[].obs;
  int loadedPage = 0;
  bool hasMoreData = false;
  RxBool isLoading = true.obs;

  Future<void> getIcoListData(bool isLoadMore, int tokenId) async {
    if (!isLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      phaseList.clear();
    }
    isLoading.value = true;
    loadedPage++;

    IcoAPIRepository().getIcoTokenPhaseList(loadedPage, tokenId).then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        final listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        final list = List<IcoPhase>.from(listResponse.data!.map((x) => IcoPhase.fromJson(x)));
        phaseList.addAll(list);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> icoSavePhaseStatus(IcoPhase phase) async {
    showLoadingDialog();
    IcoAPIRepository().icoSavePhaseStatus(phase.id ?? 0).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) {
          final index = phaseList.indexOf(phase);
          phase.status = phase.status == 0 ? 1 : 0;
          phaseList[index] = phase;
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  Future<void> getIcoTokenPhaseAdditionalDetails(IcoPhase phase, Function(List<PhaseAdditionalInfo>) onData) async {
    IcoAPIRepository().getIcoTokenPhaseAdditionalDetails(phase.id ?? 0).then((resp) {
      if (resp.success) {
        final list = List<PhaseAdditionalInfo>.from(resp.data.map((x) => PhaseAdditionalInfo.fromJson(x)));
        onData(list);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> icoCreateUpdateTokenPhaseAdditional(Map<String, dynamic> mapObj,  Function() onSuccess) async {
    showLoadingDialog();
    IcoAPIRepository().icoCreateUpdateTokenPhaseAdditional(mapObj).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
