import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../../models/p2p_ads.dart';
import '../../p2p_api_repository.dart';
import '../../p2p_constants.dart';

class P2pAdsDetailsController extends GetxController {
  P2PAdsDetails adsDetails = P2PAdsDetails();
  OrderRate orderRate = OrderRate();
  final priceEditController = TextEditingController();
  final amountEditController = TextEditingController();
  RxBool isDataLoading = false.obs;
  RxInt selectedPaymentM = 0.obs;
  Timer? _debounce;
  String fromKey = "";

  void onTextChanged(String uid, int adsType, String from) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      fromKey = from;
      getP2pOrderRate(uid, adsType, from);
    });
  }

  void getAdsDetails(String uid, int adsType) {
    isDataLoading.value = true;
    P2pAPIRepository().getP2pAdsDetails(uid, adsType).then((resp) {
      if (resp.success && resp.data != null) {
        adsDetails = P2PAdsDetails.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
      isDataLoading.value = false;
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  List<String> getPaymentNameList() {
    List<String> list = [];
    if (adsDetails.paymentMethods.isValid) {
      // list = adsDetails.paymentMethods!.map((e) => e.adminPaymentMethod?.name ?? "").toList();
      list = adsDetails.paymentMethods!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return list;
  }

  void getP2pOrderRate(String uid, int adsType, String from) {
    double? price, amount;
    if (from == FromKey.up) {
      price = makeDouble(priceEditController.text.trim());
    } else {
      amount = makeDouble(amountEditController.text.trim());
    }

    P2pAPIRepository().getP2pOrderRate(adsType, uid, price: price, amount: amount).then((resp) {
      hideLoadingDialog();
      if (resp.success && resp.data != null) {
        orderRate = OrderRate.fromJson(resp.data);
        from == FromKey.up ? amountEditController.text = coinFormat(orderRate.amount) : priceEditController.text = coinFormat(orderRate.amountPrice);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void adsAvailableBalance(String uid, String coinType, int adsType) {
    showLoadingDialog();
    P2pAPIRepository().adsAvailableBalance(coinType, uid, 2).then((resp) {
      if (resp.success && resp.data != null) {
        final balance = makeDouble(resp.data[P2pAPIKeyConstants.balance]);
        adsDetails.available = balance;
        amountEditController.text = coinFormat(balance);
        amountEditController.selection = TextSelection.fromPosition(TextPosition(offset: amountEditController.text.length));
        fromKey = FromKey.down;
        getP2pOrderRate(uid, adsType, fromKey);
      } else {
        hideLoadingDialog();
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void checkAndPlaceOrder(int adsType, String uid) {
    double? price, amount;
    if (fromKey == FromKey.up) {
      price = makeDouble(priceEditController.text.trim());
      if (price <= 0) {
        showToast("amount_must_greater_than_0".tr);
        return;
      }
    } else {
      amount = makeDouble(amountEditController.text.trim());
      if (amount <= 0) {
        showToast("amount_must_greater_than_0".tr);
        return;
      }
    }
    if (selectedPaymentM.value == -1) {
      showToast("Select_Payment_Method_message".tr);
      return;
    }
    // final payId = adsDetails.paymentMethods?[selectedPaymentM.value].uid ?? "";
    final payId = (adsDetails.paymentMethods?[selectedPaymentM.value].id ?? "").toString();
    hideKeyboard();
    showLoadingDialog();
    P2pAPIRepository().placeP2pOrder(adsType, uid, payId, price: price, amount: amount).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
