import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/ico_constants.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class IcoController extends GetxController {
  RxList<IcoPhase> featuredList = <IcoPhase>[].obs;
  RxList<IcoPhase> ongoingList = <IcoPhase>[].obs;
  RxList<IcoPhase> futureList = <IcoPhase>[].obs;
  bool isDataLoading = true;
  IcoLaunchpad launchpad = IcoLaunchpad();

  Future<void> getIcoLaunchpadSettings(Function() onSuccess) async {
    IcoAPIRepository().getIcoLaunchpadSettings().then((resp) {
      isDataLoading = false;
      if (resp.success && resp.data != null) {
        launchpad = IcoLaunchpad.fromJson(resp.data);
        onSuccess();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isDataLoading = false;
      showToast(err.toString());
    });
  }

  void getIcoPhaseActiveList(int type, {Function(List<IcoPhase>)? onList}) async {
    IcoAPIRepository().getIcoPhaseActiveList(type, limit: DefaultValue.listLimitShort).then((resp) {
      if (resp.success) {
        final list = List<IcoPhase>.from(resp.data!.map((x) => IcoPhase.fromJson(x)));
        if (onList != null) {
          onList(list);
        } else {
          if (type == IcoPhaseSortType.featured) {
            featuredList.value = list;
          } else if (type == IcoPhaseSortType.recent) {
            ongoingList.value = list;
          } else if (type == IcoPhaseSortType.future) {
            futureList.value = list;
          }
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) => showToast(err.toString()));
  }

  void getPhaseActiveList(int type, Function(List<IcoPhase>) onList) async {
    IcoAPIRepository().getIcoPhaseActiveList(type).then((resp) {
      if (resp.success) {
        final list = List<IcoPhase>.from(resp.data!.map((x) => IcoPhase.fromJson(x)));
        onList(list);
      } else {
        showToast(resp.message);
        onList([]);
      }
    }, onError: (err) {
      showToast(err.toString());
      onList([]);
    });
  }

  void getIcoActivePhaseDetails(int id, Function(IcoPhase) onData) async {
    IcoAPIRepository().getIcoActivePhaseDetails(id).then((resp) {
      if (resp.success) {
        final phase = IcoPhase.fromJson(resp.data);
        onData(phase);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) => showToast(err.toString()));
  }
}
