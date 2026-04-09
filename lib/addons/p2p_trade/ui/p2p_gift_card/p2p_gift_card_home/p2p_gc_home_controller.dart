import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../../../models/p2p_gift_card.dart';
import '../../../models/p2p_settings.dart';
import '../../../p2p_api_repository.dart';

class P2pGCHomeController extends GetxController {
  P2PAdsCreateSettings settings = P2PAdsCreateSettings();
  RxList<P2PGiftCardAd> adsList = <P2PGiftCardAd>[].obs;
  final priceEditController = TextEditingController();
  RxInt selectedPaymentType = 0.obs;
  RxInt selectedPaymentMethod = 0.obs;
  RxInt selectedCurrency = 0.obs;
  RxInt selectedCountry = 0.obs;
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isDataLoading = true.obs;
  bool hasFilterChanged = false;

  Future<void> getGiftCardCSettings(Function() onSuccess) async {
    P2pAPIRepository().getP2pGiftCardPageData().then((resp) {
      if (resp.success && resp.data != null) {
        settings = P2PAdsCreateSettings.fromJson(resp.data);
        onSuccess();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  void getP2pGiftCardAllList(bool isFromLoadMore) {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      adsList.clear();
    }
    isDataLoading.value = true;
    loadedPage++;

    final amount = makeDouble(priceEditController.text.trim());
    final amountStr = amount > 0 ? amount.toString() : "";
    final payType = selectedPaymentType.value == 0 ? "" : selectedPaymentType.value.toString();
    var currency = "", payUid = "";
    if (selectedPaymentType.value == 1 && selectedCurrency.value > 0) {
      currency = settings.currency![selectedCurrency.value - 1].currencyCode ?? "";
      if (selectedPaymentMethod.value > 0) {
        // payUid = settings.paymentMethods![selectedPaymentMethod.value - 1].uid ?? "";
        payUid = (settings.paymentMethods![selectedPaymentMethod.value - 1].id ?? "").toString();
      }
    } else if (selectedPaymentType.value == 2 && selectedCurrency.value > 0) {
      currency = settings.assets![selectedCurrency.value - 1].coinType ?? "";
    }
    final country = selectedCountry.value == 0 ? "" : settings.country![selectedCountry.value - 1].key ?? "";

    P2pAPIRepository().getP2pGiftCardAllList(loadedPage, amountStr, payType, currency, payUid, country).then((resp) {
      if (resp.success && resp.data != null) {
        ListResponse listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        if (listResponse.data != null) {
          List<P2PGiftCardAd> list = List<P2PGiftCardAd>.from(listResponse.data!.map((x) => P2PGiftCardAd.fromJson(x)));
          adsList.addAll(list);
        }
      } else {
        showToast(resp.message);
      }
      isDataLoading.value = false;
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  void checkFilterChange() {
    if (hasFilterChanged) {
      getP2pGiftCardAllList(false);
      hasFilterChanged = false;
    }
  }

  List<String> getCountryNameList() {
    List<String> list = [];
    if (settings.country.isValid) {
      list = settings.country!.map((e) => e.label ?? "").toList();
    }
    list.insert(0, "Any".tr);
    return list;
  }

  List<String> getPaymentNameList() {
    List<String> list = <String>[];
    if (settings.paymentMethods.isValid) {
      // list = settings.paymentMethods!.map((e) => e.adminPaymentMethod?.name ?? "").toList();
      list = settings.paymentMethods!.map((e) => e.bankForm?.title ?? "").toList();
    }
    list.insert(0, "Any".tr);
    return list;
  }

  List<String> getCurrencyNameList() {
    List<String> list = [];
    if (selectedPaymentType.value == 1) {
      if (settings.currency.isValid) {
        list = settings.currency!.map((e) => e.label ?? "").toList();
      }
    } else if (selectedPaymentType.value == 2) {
      if (settings.assets.isValid) {
        list = settings.assets!.map((e) => e.coinType ?? "").toList();
      }
    }
    list.insert(0, "Any".tr);
    return list;
  }

  /// *** Buy Gift Card *** ///
  Future<void> getP2pGiftCardAdDetails(String uid, Function(P2PGiftCardAd) onSuccess) async {
    P2pAPIRepository().getP2pGiftCardAdDetails(uid).then((resp) {
      if (resp.success && resp.data != null) {
        final p2pGcAd = P2PGiftCardAd.fromJson(resp.data);
        onSuccess(p2pGcAd);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> p2pGiftCardPlaceAd(P2PGiftCardAd card, String? payUid) async {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardPlaceAd(card.id ?? 0, payUid: payUid).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        adsList.remove(card);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
