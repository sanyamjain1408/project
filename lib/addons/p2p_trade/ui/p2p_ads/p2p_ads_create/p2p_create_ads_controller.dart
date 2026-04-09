import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../../../../../helper/app_helper.dart';
import '../../../models/p2p_ads.dart';
import '../../../models/p2p_settings.dart';
import '../../../p2p_api_repository.dart';
import '../../../p2p_constants.dart';
import '../p2p_ads_controller.dart';

class P2pCreateAdsController extends GetxController {
  bool isDataLoading = true;
  P2PAdsCreateSettings? adsSettings;
  final pageController = PageController();
  int currentPageCreate = 0;
  P2PAds? currentAds = P2PAds();
  RxInt selectedAdType = 0.obs;
  bool isEdit = false;
  bool isUpdatePrice = true;

  ///Page One
  Rx<P2PAdsPrice> adsPrice = P2PAdsPrice().obs;
  final priceEditController = TextEditingController();
  RxInt selectedCoin = 0.obs;
  RxInt selectedCurrency = 0.obs;
  RxInt selectedPriceType = P2pPriceType.fixed.obs;

  ///Page Two
  final amountEditController = TextEditingController();
  final minEditController = TextEditingController();
  final maxEditController = TextEditingController();
  var paymentTagController = StringTagController();
  RxInt selectedTime = 0.obs;
  List<String> selectedPayMethods = <String>[];

  ///Page Three
  final termsEditController = TextEditingController();
  final replyEditController = TextEditingController();
  final regiEditController = TextEditingController();
  final holdingEditController = TextEditingController();
  var countryTagController = StringTagController();
  RxList<String> selectedCountryList = <String>[].obs;

  void getAdsCreateSetting(Function() onSuccess) {
    P2pAPIRepository().getAdsCreateSetting().then((resp) {
      isDataLoading = false;
      if (resp.success && resp.data != null) {
        adsSettings = P2PAdsCreateSettings.fromJson(resp.data);
        onSuccess();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isDataLoading = false;
      showToast(err.toString());
    });
  }

  List<String> getCoinNameList() {
    if ((adsSettings?.assets ?? []).isValid) {
      return adsSettings!.assets!.map((e) => e.coinType ?? "").toList();
    }
    return [];
  }

  List<String> getCurrencyNameList() {
    if ((adsSettings?.currency ?? []).isValid) {
      return adsSettings!.currency!.map((e) => e.name ?? "").toList();
    }
    return [];
  }

  List<String> getTimeLimitList() {
    List<String> list = [];
    if ((adsSettings?.paymentTime ?? []).isValid) {
      list = adsSettings!.paymentTime!.map((e) => minutesString(e.time)).toList();
    }
    list.insert(0, "None".tr);
    return list;
  }

  List<String> getPaymentNameList() {
    if ((adsSettings?.paymentMethods ?? []).isValid) {
      return adsSettings!.paymentMethods!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return [];
  }

  List<String> getCountryNameList() {
    if ((adsSettings?.country ?? []).isValid) {
      return adsSettings!.country!.map((e) => e.value ?? "").toList();
    }
    return [];
  }

  void getAdsPrice(String coinType, String currency) {
    P2pAPIRepository().getAdsPrice(coinType, currency).then((resp) {
      if (resp.success && resp.data != null) {
        adsPrice.value = P2PAdsPrice.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  void adsAvailableBalance() {
    showLoadingDialog();
    final coinType = adsSettings?.assets?[selectedCoin.value].coinType ?? "";
    P2pAPIRepository().adsAvailableBalance(coinType, "", 1).then((resp) {
      hideLoadingDialog();
      if (resp.success && resp.data != null) {
        final balance = makeDouble(resp.data[P2pAPIKeyConstants.balance]);
        amountEditController.text = coinFormat(balance);
        amountEditController.selection = TextSelection.fromPosition(TextPosition(offset: amountEditController.text.length));
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void saveOrEditAds(BuildContext context) async {
    if (currentAds == null) return;
    showLoadingDialog();
    final type = selectedAdType.value == 0 ? 1 : 2;
    ServerResponse? resp;
    try {
      if (isEdit) {
        resp = await P2pAPIRepository().editUserAds(type, currentAds!);
      } else {
        resp = await P2pAPIRepository().saveUserAds(type, currentAds!);
      }
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) => showToast(message, isError: !success, isLong: true));
        if (success) {
          Get.back();
          Get.find<P2pAdsController>().updateList(type);
        }
      } else {
        showToast(resp.message, isLong: true);
      }
    } catch (err) {
      hideLoadingDialog();
      showToast(err.toString());
    }
  }
}
