import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../../../../../data/models/response.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../utils/number_util.dart';
import '../../../../../helper/app_helper.dart';
import '../../../models/p2p_gift_card.dart';
import '../../../models/p2p_settings.dart';
import '../../../p2p_api_repository.dart';

class P2pGCCreateAdController extends GetxController {
  P2PAdsCreateSettings settings = P2PAdsCreateSettings();
  P2pGiftCard p2pGiftCard = P2pGiftCard();
  P2PGiftCardAd preAd = P2PGiftCardAd();
  final priceEditController = TextEditingController();
  final termsEditController = TextEditingController();
  RxInt selectedPaymentType = 0.obs;
  RxInt selectedCurrency = 0.obs;
  RxInt selectedStatus = 0.obs;
  RxInt selectedTime = 0.obs;
  final paymentTagController = StringTagController();
  List<String> selectedPayMethods = <String>[];
  final countryTagController = StringTagController();
  RxList<String> selectedCountryList = <String>[].obs;
  bool isEdit = false;
  bool isLoading = true;
  late Function() onUIUpdate;

  Future<void> getGiftCardCSettings() async {
    P2pAPIRepository().getP2pGiftCardPageData().then((resp) {
      if (resp.success && resp.data != null) {
        settings = P2PAdsCreateSettings.fromJson(resp.data);
        setPreAdData();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading = false;
      showToast(err.toString());
      onUIUpdate();
    });
  }

  Future<void> getP2pGiftCardDetails() async {
    P2pAPIRepository().getP2pGiftCardDetails(preAd.uid ?? "").then((resp) {
      if (resp.success && resp.data != null) {
        preAd = P2PGiftCardAd.fromJson(resp.data);
        p2pGiftCard = P2pGiftCard(giftCard: preAd.giftCard, giftCardId: preAd.giftCardId);
        setPreAdData();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading = false;
      showToast(err.toString());
      onUIUpdate();
    });
  }

  void setPreAdData() {
    if (!isEdit && settings.assets.isValid) {
      isLoading = false;
      onUIUpdate();
    } else if (preAd.uid.isValid && settings.assets.isValid) {
      selectedPaymentType.value = (preAd.paymentCurrencyType ?? 0) - 1;
      int index = selectedPaymentType.value == 0
          ? settings.currency!.indexWhere((element) => element.currencyCode == preAd.currencyType)
          : settings.assets!.indexWhere((element) => element.coinType == preAd.currencyType);
      if (index != -1) selectedCurrency.value = index;
      priceEditController.text = preAd.price ?? "";
      termsEditController.text = preAd.termsCondition ?? "";
      selectedStatus.value = preAd.status == 1 ? 0 : 1;

      final countryList = json.decode(preAd.country ?? "") ?? [];
      for (final code in countryList) {
        final country = settings.country?.firstWhere((element) => element.key == code).label;
        if (country.isValid) selectedCountryList.add(country!);
      }

      final payIdList = json.decode(preAd.paymentMethod ?? "") ?? [];
      for (final uid in payIdList) {
        // final payment = (settings.paymentMethods?? []).firstWhereOrNull((element) => element.uid == uid)?.adminPaymentMethod?.name;
        final payment = (settings.paymentMethods?? []).firstWhereOrNull((element) => element.id.toString() == uid)?.bankForm?.title;
        if (payment.isValid) selectedPayMethods.add(payment!);
      }

      if (preAd.timeLimit != null) {
        final index = settings.paymentTime?.indexWhere((element) => element.time == preAd.timeLimit);
        if (index != null && index != -1) selectedTime.value = index + 1;
      }
      isLoading = false;
      onUIUpdate();
    }
  }

  List<String> getCurrencyNameList() {
    List<String> list = [];
    if (selectedPaymentType.value == 0) {
      if (settings.currency.isValid) {
        list = settings.currency!.map((e) => e.label ?? "").toList();
      }
    } else if (selectedPaymentType.value == 1) {
      if (settings.assets.isValid) {
        list = settings.assets!.map((e) => e.coinType ?? "").toList();
      }
    }
    return list;
  }

  List<String> getPaymentNameList() {
    List<String> list = <String>[];
    if (settings.paymentMethods.isValid) {
      // list = settings.paymentMethods!.map((e) => e.adminPaymentMethod?.name ?? "").toList();
      list = settings.paymentMethods!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return list;
  }

  List<String> getCountryNameList() {
    List<String> list = [];
    if (settings.country.isValid) {
      list = settings.country!.map((e) => e.label ?? "").toList();
    }
    return list;
  }

  List<String> getTimeLimitList() {
    List<String> list = [];
    if (settings.paymentTime.isValid) {
      list = settings.paymentTime!.map((e) => minutesString(e.time)).toList();
    }
    list.insert(0, "None".tr);
    return list;
  }

  void checkInputData(BuildContext context) {
    final newGCAd = P2PGiftCardAd();
    if (isEdit) {
      newGCAd.uid = preAd.uid;
    } else {
      newGCAd.giftCardId = p2pGiftCard.giftCardId;
    }

    if (selectedPaymentType.value == -1) {
      showToast("Select payment type".tr);
      return;
    }
    newGCAd.paymentCurrencyType = selectedPaymentType.value + 1;

    if (selectedCurrency.value == -1) {
      showToast("select your currency".tr);
      return;
    }
    newGCAd.currencyType = selectedPaymentType.value == 0
        ? settings.currency![selectedCurrency.value].currencyCode ?? ""
        : settings.assets![selectedCurrency.value].coinType ?? "";

    final price = makeDouble(priceEditController.text.trim());
    if (price <= 0) {
      showToast("price_must_greater_than_0".tr);
      return;
    }
    newGCAd.price = price.toString();
    newGCAd.status = selectedStatus.value == 0 ? 1 : 0;

    if (selectedPaymentType.value == 0) {
      if (selectedPayMethods.isEmpty) {
        showToast("Select_Payment_Method_message".tr);
        return;
      }
      List<String> pList = [];
      for (final payment in selectedPayMethods) {
        // final uid = settings.paymentMethods?.firstWhere((element) => element.adminPaymentMethod?.name == payment).uid;
        final uid = settings.paymentMethods?.firstWhere((element) => element.bankForm?.title == payment).id.toString();
        if(uid.isValid)pList.add(uid!);
      }
      newGCAd.paymentMethodUidList = pList.toSet().toList();
    }

    if (selectedCountryList.isEmpty) {
      showToast("Select available regions".tr);
      return;
    }
    List<String> cList = [];
    for (final country in selectedCountryList) {
      final key = settings.country?.firstWhere((element) => element.label == country).key;
      if (key.isValid) cList.add(key!);
    }
    newGCAd.countryList = cList.toSet().toList();

    if (selectedTime.value > 0) {
      newGCAd.timeLimit = settings.paymentTime![selectedTime.value - 1].time ?? 0;
    }
    final terms = termsEditController.text.trim();
    if (terms.isEmpty) {
      showToast("enter the terms and conditions".tr);
      return;
    }
    newGCAd.termsCondition = terms;
    hideKeyboard(context: context);
    saveOrEditAds(newGCAd);
  }

  void saveOrEditAds(P2PGiftCardAd newAd) async {
    showLoadingDialog();
    ServerResponse? resp;
    try {
      if (newAd.uid.isValid) {
        resp = await P2pAPIRepository().p2pGiftCardUpdateAd(newAd);
      } else {
        resp = await P2pAPIRepository().p2pGiftCardStoreAd(newAd);
      }
      hideLoadingDialog();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => showToast(resp?.message ?? "", isError: !(resp?.success ?? false), isLong: true));
      if (resp.success) Get.back(result: true);
    } catch (err) {
      hideLoadingDialog();
      showToast(err.toString());
    }
  }
}
