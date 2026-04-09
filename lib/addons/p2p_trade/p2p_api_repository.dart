import 'dart:io';

import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_gift_card.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/remote/api_provider.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

import '../../data/models/bank_data.dart';
import 'models/p2p_ads.dart';
import 'p2p_constants.dart';

class P2pAPIRepository {
  final provider = Get.find<APIProvider>();

  /// *** ------------ *** ///
  /// *** POST requests *** ///
  /// *** ------------ *** ///

  Future<ServerResponse> getP2pAdsList(
      int transactionType, double amount, String coin, String currency, String paymentMethod, String country, int page) async {
    final mapObj = {};
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitMedium;
    mapObj[APIKeyConstants.page] = page;
    mapObj[APIKeyConstants.type] = transactionType;
    mapObj[APIKeyConstants.amount] = amount;
    mapObj[APIKeyConstants.currency] = currency;
    mapObj[P2pAPIKeyConstants.coin] = coin;
    mapObj[P2pAPIKeyConstants.country] = country;
    mapObj[P2pAPIKeyConstants.paymentMethod] = paymentMethod;
    return provider.postRequest(P2pAPIURLConstants.p2pAdsFilterChange, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> getP2pOrderRate(int adsType, String uid, {double? price, double? amount}) async {
    final mapObj = {};
    if (price != null) {
      mapObj[APIKeyConstants.price] = price;
    }
    if (amount != null) {
      mapObj[APIKeyConstants.amount] = amount;
    }
    mapObj[P2pAPIKeyConstants.adsId] = uid;
    mapObj[P2pAPIKeyConstants.adsType] = adsType;
    return provider.postRequest(P2pAPIURLConstants.p2pOrderRate, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> adsAvailableBalance(String coinType, String uid, int type) async {
    final mapObj = {};
    if (uid.isNotEmpty) mapObj[P2pAPIKeyConstants.uid] = uid;
    mapObj[P2pAPIKeyConstants.coinType] = coinType;
    mapObj[APIKeyConstants.type] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pAdsAvailableBalance, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> editUserAds(int type, P2PAds ads) async {
    final mapObj = ads.toJson();
    mapObj[P2pAPIKeyConstants.adsType] = type;
    mapObj[P2pAPIKeyConstants.adsUid] = ads.uid;
    return provider.postRequestFormData(P2pAPIURLConstants.p2pUserAdsEdit, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> saveUserAds(int type, P2PAds ads) async {
    final mapObj = ads.toJson();
    mapObj[P2pAPIKeyConstants.adsType] = type;
    return provider.postRequestFormData(P2pAPIURLConstants.p2pUserAdsSave, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> placeP2pOrder(int adsType, String uid, String payUid, {double? price, double? amount}) async {
    final mapObj = {};
    mapObj[P2pAPIKeyConstants.adsType] = adsType;
    mapObj[P2pAPIKeyConstants.adsId] = uid;
    mapObj[P2pAPIKeyConstants.paymentId] = payUid;
    if (price != null) {
      mapObj[APIKeyConstants.price] = price;
    }
    if (amount != null) {
      mapObj[APIKeyConstants.amount] = amount;
    }
    return provider.postRequest(P2pAPIURLConstants.p2pPlaceP2pOrder, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pPaymentMethodSave(BankForm bankForm) async {
    var mapObj = bankForm.toJsonSave();
    return provider.postRequestFormData(P2pAPIURLConstants.p2pPaymentMethod, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> transferWalletBalance(String coinType, double amount, int type) async {
    final mapObj = {};
    mapObj[P2pAPIKeyConstants.coin] = coinType;
    mapObj[APIKeyConstants.amount] = amount;
    mapObj[APIKeyConstants.type] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pTransferWalletBalance, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> userAdsFilter(int type, int page) async {
    final mapObj = {};
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page;
    mapObj[P2pAPIKeyConstants.coin] = FromKey.all;
    mapObj[P2pAPIKeyConstants.adsStatus] = FromKey.all;
    mapObj[APIKeyConstants.type] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pUserAdsFilter, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pAdsStatusChange(String id, int type) async {
    final mapObj = {};
    mapObj[APIKeyConstants.id] = id;
    mapObj[APIKeyConstants.type] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pAdsStatusChange, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> p2pAdsDelete(String id, int type) async {
    final mapObj = {};
    mapObj[APIKeyConstants.uid] = id;
    mapObj[P2pAPIKeyConstants.adsType] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pAdsDelete, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> p2pOrderDetails(String uid) async {
    final mapObj = {};
    mapObj[P2pAPIKeyConstants.orderUid] = uid;
    return provider.postRequest(P2pAPIURLConstants.p2pOrderDetails, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pSendMessage(String orderUid, {String? text, File? file}) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.orderUid] = orderUid;
    if (text.isValid) mapObj[APIKeyConstants.message] = text;
    if (file?.path.isValid ?? false) {
      mapObj[P2pAPIKeyConstants.file] = await APIRepository().makeMultipartFile(file!);
    }
    return provider.postRequestFormData(P2pAPIURLConstants.p2pSendMessage, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pOrderPayment(String tradeId, File file) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.tradeId] = tradeId;
    if (file.path.isValid) {
      mapObj[P2pAPIKeyConstants.paymentSlip] = await APIRepository().makeMultipartFile(file);
    }
    return provider.postRequestFormData(P2pAPIURLConstants.p2pOrderPayment, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pOrderRelease(String tradeId) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.tradeId] = tradeId;
    return provider.postRequest(P2pAPIURLConstants.p2pOrderRelease, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pOrderFeedback(String tradeId, String review, int type) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.orderUid] = tradeId;
    mapObj[P2pAPIKeyConstants.feedback] = review;
    mapObj[P2pAPIKeyConstants.feedbackType] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pOrderFeedback, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pOrderCancel(String tradeId, String reason) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.orderUid] = tradeId;
    mapObj[P2pAPIKeyConstants.reason] = reason;
    return provider.postRequest(P2pAPIURLConstants.p2pOrderCancel, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pOrderDispute(String tradeId, String reasonTitle, String reasonDetails, File file) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.orderUid] = tradeId;
    mapObj[P2pAPIKeyConstants.reasonSubject] = reasonTitle;
    mapObj[P2pAPIKeyConstants.reasonDetails] = reasonDetails;
    if (file.path.isValid) {
      mapObj[APIKeyConstants.image] = await APIRepository().makeMultipartFile(file);
    }
    return provider.postRequestFormData(P2pAPIURLConstants.p2pOrderDispute, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> p2pGiftCardStoreAd(P2PGiftCardAd p2pGiftCardAd) async {
    final mapObj = p2pGiftCardAd.toJson();
    return provider.postRequestFormData(P2pAPIURLConstants.p2pGiftCardStoreAd, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardUpdateAd(P2PGiftCardAd p2pGiftCardAd) async {
    final mapObj = p2pGiftCardAd.toJson();
    return provider.postRequestFormData(P2pAPIURLConstants.p2pGiftCardUpdateAd, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardDeleteAd(int giftCardId) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardId] = giftCardId;
    return provider.postRequest(P2pAPIURLConstants.p2pGiftCardDeleteAd, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardPlaceAd(int giftCardId, {String? payUid}) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardId] = giftCardId;
    if (payUid.isValid) mapObj[P2pAPIKeyConstants.paymentMethodUid] = payUid;
    return provider.postRequest(P2pAPIURLConstants.p2pGiftCardPlaceAd, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardOrderPayNow(int orderId, File? file) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardOrderId] = orderId;
    if (file != null && file.path.isValid) {
      mapObj[P2pAPIKeyConstants.slip] = await APIRepository().makeMultipartFile(file);
    }
    return provider.postRequestFormData(P2pAPIURLConstants.p2pGiftCardOrderPayNow, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardOrderPaymentConfirm(int orderId) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardOrderId] = orderId;
    return provider.postRequest(P2pAPIURLConstants.p2pGiftCardOrderPaymentConfirm, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardOrderCancel(int orderId, String reason) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardOrderId] = orderId;
    mapObj[P2pAPIKeyConstants.reason] = reason;
    return provider.postRequest(P2pAPIURLConstants.p2pGiftCardOrderCancel, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardOrderDispute(int orderId, String reasonTitle, String reasonDetails) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardOrderId] = orderId;
    mapObj[P2pAPIKeyConstants.reasonSubject] = reasonTitle;
    mapObj[P2pAPIKeyConstants.reasonDetails] = reasonDetails;
    return provider.postRequestFormData(P2pAPIURLConstants.p2pGiftCardOrderDispute, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardFeedbackUpdate(String orderId, String review, int type) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.orderUid] = orderId;
    mapObj[P2pAPIKeyConstants.feedback] = review;
    mapObj[P2pAPIKeyConstants.feedbackType] = type;
    return provider.postRequest(P2pAPIURLConstants.p2pGiftCardFeedbackUpdate, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pGiftCardSendMessage(int orderId, {String? text, File? file}) async {
    final mapObj = <String, dynamic>{};
    mapObj[P2pAPIKeyConstants.giftCardOrderId] = orderId;
    if (text.isValid) mapObj[APIKeyConstants.message] = text;
    if (file?.path.isValid ?? false) {
      mapObj[P2pAPIKeyConstants.file] = await APIRepository().makeMultipartFile(file!);
    }
    return provider.postRequestFormData(P2pAPIURLConstants.p2pGiftCardSendMessage, mapObj, APIRepository().authHeader());
  }

  /// *** ------------ *** ///
  /// *** GET requests *** ///
  /// *** ------------ *** ///

  Future<ServerResponse> getP2pAdsMarketSettings() async {
    return provider.getRequest(P2pAPIURLConstants.getP2pAdsMarketSettings, APIRepository().authHeader());
  }

  Future<ServerResponse> getProfileDetails(int userId) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.id] = userId.toString();
    return provider.getRequest(P2pAPIURLConstants.getP2pUserProfile, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pUserCenter() async {
    return provider.getRequest(P2pAPIURLConstants.getP2pUserCenter, APIRepository().authHeader());
  }

  Future<ServerResponse> getP2pPaymentMethod() async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitLarge.toString();
    mapObj[APIKeyConstants.page] = "1";
    return provider.getRequest(P2pAPIURLConstants.getP2pPaymentMethod, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pAdminPaymentMethods() async {
    return provider.getRequest(P2pAPIURLConstants.getP2pAdminPaymentMethod, APIRepository().authHeader());
  }

  Future<ServerResponse> getP2pDetailsPaymentMethod(int id) async {
    final url = P2pAPIURLConstants.getP2pDetailsPaymentMethod+id.toString();
    return provider.getRequest(url, APIRepository().authHeader());
  }

  Future<ServerResponse> p2pPaymentMethodDelete(int id) async {
    final url = P2pAPIURLConstants.p2pPaymentMethodDelete+id.toString();
    return provider.getRequest(url, APIRepository().authHeader());
  }

  Future<ServerResponse> getP2pWallets(int page) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitLarge.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    return provider.getRequest(P2pAPIURLConstants.getP2pWallets, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pAdsDetails(String uid, int adsType) async {
    final mapObj = <String, String>{};
    mapObj[P2pAPIKeyConstants.uid] = uid;
    mapObj[P2pAPIKeyConstants.adsType] = adsType.toString();
    return provider.getRequest(P2pAPIURLConstants.getP2pAdsDetails, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pMyOrderListSettings() async {
    return provider.getRequest(P2pAPIURLConstants.getP2pMyOrderListData, APIRepository().authHeader());
  }

  Future<ServerResponse> getP2pMyOrdersList(int page, String adsStatus, String coinType, String fromDate, String toDate) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    mapObj[P2pAPIKeyConstants.adsStatus] = adsStatus;
    mapObj[P2pAPIKeyConstants.coin] = coinType;
    mapObj[P2pAPIKeyConstants.fromDate] = fromDate;
    mapObj[P2pAPIKeyConstants.toDate] = toDate;
    mapObj[APIKeyConstants.type] = FromKey.all;
    return provider.getRequest(P2pAPIURLConstants.getP2pMyOrdersList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pMyDisputeList(int page) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    mapObj[P2pAPIKeyConstants.coin] = FromKey.all;
    mapObj[APIKeyConstants.type] = FromKey.all;
    return provider.getRequest(P2pAPIURLConstants.getP2pMyDisputeList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getAdsCreateSetting() async {
    return provider.getRequest(P2pAPIURLConstants.getP2pAdsCreateSetting, APIRepository().authHeader());
  }

  Future<ServerResponse> getAdsPrice(String coinType, String currency) async {
    final mapObj = <String, String>{};
    mapObj[P2pAPIKeyConstants.coinType] = coinType;
    mapObj[APIKeyConstants.currency] = currency;
    return provider.getRequest(P2pAPIURLConstants.getP2pAdsPrice, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardPageData() async {
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardPageData, APIRepository().authHeader());
  }

  Future<ServerResponse> getP2pGiftCardAllList(int page, String price, String payType, String currencyType, String payMethod, String country) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.limit] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    mapObj[APIKeyConstants.price] = price;
    mapObj[P2pAPIKeyConstants.paymentCurrencyType] = payType;
    mapObj[P2pAPIKeyConstants.currencyType] = currencyType;
    mapObj[P2pAPIKeyConstants.paymentMethod] = payMethod;
    mapObj[P2pAPIKeyConstants.country] = country;
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardAllAdList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardAdDetails(String uid) async {
    final mapObj = <String, String>{};
    mapObj[P2pAPIKeyConstants.uid] = uid;
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardAdDetails, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardOrders(int page, String status) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.limit] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    mapObj[APIKeyConstants.status] = status;
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardOrders, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardList(int page) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.limit] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardUserAdList(int page, String status) async {
    final mapObj = <String, String>{};
    mapObj[APIKeyConstants.limit] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.page] = page.toString();
    mapObj[APIKeyConstants.status] = status;
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardUserAdList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardDetails(String uid) async {
    final mapObj = <String, String>{};
    mapObj[P2pAPIKeyConstants.uid] = uid;
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardDetails, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getP2pGiftCardOrderDetails(String uid) async {
    final mapObj = <String, String>{};
    mapObj[P2pAPIKeyConstants.orderUid] = uid;
    return provider.getRequest(P2pAPIURLConstants.getP2pGiftCardOrderDetails, query: mapObj, APIRepository().authHeader());
  }
}
