import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/referral.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class ReferralController extends GetxController {
  Rx<ReferralData> referralData = ReferralData().obs;

  void getReferralData() {
    showLoadingDialog();
    APIRepository().getReferralApp().then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        referralData.value = ReferralData.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}