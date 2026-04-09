import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_settings.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/faq.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../../models/p2p_ads.dart';
import '../../p2p_api_repository.dart';

class P2PHomeController extends GetxController {
  RxInt selectedTransactionType = 1.obs;
  RxInt selectedCoin = 0.obs;
  RxInt selectedCurrency = 0.obs;
  RxInt selectedPayment = 0.obs;
  RxInt selectedCountry = 0.obs;
  P2PAdsSettings settings = P2PAdsSettings();
  RxList<P2PAds> adsList = <P2PAds>[].obs;
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isLoading = true.obs;
  final amountEditController = TextEditingController();
  bool hasFilterChanged = false;

  Future<void> getHomeData(Function() onSuccess) async {
    P2pAPIRepository().getP2pAdsMarketSettings().then((resp) {
      if (resp.success && resp.data != null) {
        settings = P2PAdsSettings.fromJson(resp.data);
        onSuccess();
        getAdsList(false);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  List<String> getCoinNameList() {
    if (settings.assets.isValid) {
      return settings.assets!.map((e) => e.coinType ?? "").toList();
    }
    return [];
  }

  List<String> getCurrencyNameList() {
    List<String> list = [];
    if (settings.currency.isValid) {
      list = settings.currency!.map((e) => e.name ?? "").toList();
    }
    list.insert(0, "All".tr);
    return list;
  }

  List<String> getPaymentNameList() {
    List<String> list = [];
    if (settings.paymentMethods.isValid) {
      list = settings.paymentMethods!.map((e) => e.name ?? "").toList();
    }
    list.insert(0, "All".tr);
    return list;
  }

  List<String> getCountryNameList() {
    List<String> list = [];
    if (settings.country.isValid) {
      list = settings.country!.map((e) => e.value ?? "").toList();
    }
    list.insert(0, "All".tr);
    return list;
  }

  void checkFilterChange() {
    if (hasFilterChanged) {
      getAdsList(false);
      hasFilterChanged = false;
    }
  }

  Future<void> getAdsList(bool isFromLoadMore) async {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      adsList.clear();
    }
    isLoading.value = true;
    loadedPage++;
    final coin = settings.assets?[selectedCoin.value].coinType ?? "";
    final amount = makeDouble(amountEditController.text.trim());
    final currency = selectedCurrency.value == 0 ? FromKey.all : settings.currency?[selectedCurrency.value - 1].currencyCode ?? FromKey.all;
    final country = selectedCountry.value == 0 ? FromKey.all : settings.country?[selectedCountry.value - 1].key ?? FromKey.all;
    final payment = selectedPayment.value == 0 ? FromKey.all : settings.paymentMethods?[selectedPayment.value - 1].uid ?? FromKey.all;

    P2pAPIRepository().getP2pAdsList(selectedTransactionType.value, amount, coin, currency, payment, country, loadedPage).then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        ListResponse listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        if (listResponse.data != null) {
          List<P2PAds> list = List<P2PAds>.from(listResponse.data!.map((x) => P2PAds.fromJson(x)));
          adsList.addAll(list);
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> getFAQList(int type, Function(List<FAQ>) onList) async {
    APIRepository().getFAQList(1, type: type).then((resp) {
      if (resp.success) {
        ListResponse response = ListResponse.fromJson(resp.data);
        if (response.data != null) {
          List<FAQ> list = List<FAQ>.from(response.data!.map((x) => FAQ.fromJson(x)));
          onList(list);
        }
      }
    }, onError: (err) {});
  }
}
