import 'dart:io';

import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/remote/api_provider.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

import 'ico_constants.dart';
import 'model/ico_dashboard.dart';
import 'model/ico_phase.dart';

class IcoAPIRepository {
  final provider = Get.find<APIProvider>();

  /// *** START of POST requests *** ///

  Future<ServerResponse> icoTokenBuyNew(IcoCreateBuyToken buyToken) async {
    final mapObj = await buyToken.toJson();
    return provider.postRequestFormData(IcoAPIURLConstants.icoTokenBuyNew, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> icoTokenWithdrawPrice(double amount, String currencyType, String currencyTo) async {
    final mapObj = <String, dynamic>{};
    mapObj[APIKeyConstants.amount] = amount;
    mapObj[APIKeyConstants.currencyType] = currencyType;
    mapObj["currency_to"] = currencyTo;
    return provider.postRequest(IcoAPIURLConstants.icoTokenWithdrawPrice, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> icoTokenWithdrawRequest(double amount, String currencyType, String currencyTo, {String? payDetails}) async {
    final mapObj = <String, dynamic>{};
    mapObj[APIKeyConstants.amount] = amount;
    mapObj[APIKeyConstants.currencyType] = currencyType;
    mapObj["currency_to"] = currencyTo;
    if(payDetails.isValid) mapObj["payment_details"] = payDetails;
    return provider.postRequest(IcoAPIURLConstants.icoTokenWithdrawRequest, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> icoChatConversationStore(int tokenId, int receiverId, {String? message, File? file}) async {
    final mapObj = <String, dynamic>{};
    mapObj["token_id"] = tokenId;
    mapObj["receiver_id"] = receiverId;
    mapObj[APIKeyConstants.message] = message;
    if (file != null) mapObj["file"] = await APIRepository().makeMultipartFile(file);
    return provider.postRequestFormData(IcoAPIURLConstants.icoChatConversationStore, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> icoSavePhaseStatus(int phaseId) async {
    final mapObj = <String, dynamic>{};
    mapObj[APIKeyConstants.id] = phaseId;
    return provider.postRequestFormData(IcoAPIURLConstants.icoSavePhaseStatus, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> icoGetContractAddressDetails(String address, {String? chainLink, int? network}) async {
    final mapObj = <String, dynamic>{};
    if(chainLink.isValid) mapObj["chain_link"] = chainLink;
    if(network != null) mapObj[APIKeyConstants.network] = network;
    mapObj["contract_address"] = address;
    return provider.postRequestFormData(IcoAPIURLConstants.icoGetContractAddressDetails, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> icoCreateUpdateToken(IcoToken icoToken, File file) async {
    final mapObj = await icoToken.toJson();
    if (file.path.isValid) mapObj[APIKeyConstants.image] = await APIRepository().makeMultipartFile(file);
    return provider.postRequestFormData(IcoAPIURLConstants.icoCreateUpdateToken, mapObj, APIRepository().authHeader());
  }

  Future<ServerResponse> icoCreateUpdateTokenPhase(IcoPhase icoPhase, File file, Map<int, String> sMap) async {
    final mapObj = await icoPhase.toJson();
    if (sMap.isNotEmpty) {
      for (var i = 0; i < sMap.length; i++) {
        final key = sMap.keys.toList()[i];
        mapObj["social_link[$key]"] = sMap[key];
      }
    }
    if (file.path.isValid) mapObj[APIKeyConstants.image] = await APIRepository().makeMultipartFile(file);
    return provider.postRequestFormData(IcoAPIURLConstants.icoCreateUpdateTokenPhase, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> icoDynamicFormSubmit(Map<String, dynamic> mapObj) async {
    return provider.postRequestFormData(IcoAPIURLConstants.icoDynamicFormSubmit, mapObj, APIRepository().authHeader(), isDynamic: true);
  }

  Future<ServerResponse> icoCreateUpdateTokenPhaseAdditional(Map<String, dynamic> mapObj) async {
    return provider.postRequestFormData(IcoAPIURLConstants.icoCreateUpdateTokenPhaseAdditional, mapObj, APIRepository().authHeader(),
        isDynamic: true);
  }

  /// *** START of GET requests *** ///

  Future<ServerResponse> getIcoLaunchpadSettings() async {
    return provider.getRequest(IcoAPIURLConstants.getIcoLaunchpadSettings, APIRepository().authHeader());
  }

  Future<ServerResponse> getIcoPhaseActiveList(int type, {int? limit}) async {
    var mapObj = <String, String>{};
    if (limit != null) mapObj[APIKeyConstants.perPage] = limit.toString();
    mapObj[APIKeyConstants.type] = type.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoPhaseActiveList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoActivePhaseDetails(int id) async {
    var mapObj = <String, String>{};
    mapObj[APIKeyConstants.id] = id.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoActivePhaseDetails, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoTokenBuyPage() async {
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenBuyPage, APIRepository().authHeader());
  }

  Future<ServerResponse> getIcoTokenPriceInfo(int phaseId, double amount, int tokenId, int paymentMethod, String payCurrency,
      {int? payerWallet}) async {
    var mapObj = <String, String>{};
    mapObj["phase_id"] = phaseId.toString();
    mapObj[APIKeyConstants.amount] = amount.toString();
    mapObj["token_id"] = tokenId.toString();
    mapObj["payment_method"] = paymentMethod.toString();
    mapObj["pay_currency"] = payCurrency;
    if (payerWallet != null) mapObj["payer_wallet"] = payerWallet.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenPriceInfo, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoSubmittedDynamicFormList(int page) async {
    var mapObj = getIcoDashBoardCommonMap(page);
    return provider.getRequest(IcoAPIURLConstants.getIcoSubmittedDynamicFormList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoTokenListUser(int page) async {
    var mapObj = getIcoDashBoardCommonMap(page);
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenListUser, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoTokenBuyHistory(int page) async {
    var mapObj = getIcoDashBoardCommonMap(page);
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenBuyHistory, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoMyTokenBalance(int page) async {
    var mapObj = getIcoDashBoardCommonMap(page);
    return provider.getRequest(IcoAPIURLConstants.getIcoMyTokenBalance, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoTokenWithdrawList(int page) async {
    var mapObj = getIcoDashBoardCommonMap(page);
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenWithdrawList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoTokenEarns() async {
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenEarns, APIRepository().authHeader());
  }

  Future<ServerResponse> getIcoChatDetails(int tokenId, int? adminId) async {
    var mapObj = <String, String>{};
    mapObj["token_id"] = tokenId.toString();
    if (adminId != null) mapObj["admin_id"] = adminId.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoChatDetails, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoTokenPhaseList(int page, int tokenId) async {
    var mapObj = getIcoDashBoardCommonMap(page);
    mapObj["ico_token_id"] = tokenId.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenPhaseList, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoCoinList() async {
    return provider.getRequest(IcoAPIURLConstants.getIcoCoinList, APIRepository().authHeader());
  }

  Future<ServerResponse> getIcoDynamicForm() async {
    return provider.getRequest(IcoAPIURLConstants.getIcoDynamicForm, APIRepository().authHeader());
  }

  Future<ServerResponse> getIcoTokenPhaseAdditionalDetails(int phaseId) async {
    var mapObj = <String, String>{};
    mapObj[APIKeyConstants.id] = phaseId.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoTokenPhaseAdditionalDetails, APIRepository().authHeader(), query: mapObj);
  }

  Future<ServerResponse> getIcoCreateTokenDetails(int? id) async {
    final mapObj = <String, dynamic>{};
    mapObj[APIKeyConstants.id] = id.toString();
    return provider.getRequest(IcoAPIURLConstants.getIcoCreateTokenDetails, APIRepository().authHeader(), query: mapObj);
  }

  /// *** START of Common Methods *** ///

  Map<String, String> getIcoDashBoardCommonMap(int page) {
    var mapObj = <String, String>{};
    mapObj[APIKeyConstants.page] = "$page";
    mapObj[APIKeyConstants.perPage] = DefaultValue.listLimitMedium.toString();
    mapObj[APIKeyConstants.columnName] = APIKeyConstants.createdAt;
    mapObj[APIKeyConstants.orderBy] = APIKeyConstants.vOrderDESC;
    return mapObj;
  }
}
