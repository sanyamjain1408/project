import 'package:crisp_chat/crisp_chat.dart' as cc ;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/local/api_constants.dart';
import '../data/local/constants.dart';
import '../data/models/settings.dart';
import '../data/remote/api_repository.dart';
import '../ui/features/root/root_screen.dart';
import '../ui/features/root/root_controller.dart';
import '../data/models/fiat_deposit.dart';
import '../data/models/user.dart';
import '../utils/alert_util.dart';
import '../utils/colors.dart';
import '../utils/common_utils.dart';
import '../utils/extensions.dart';
import '../utils/number_util.dart';
import '../ui/features/bottom_navigation/trades/spot_trade/spot_trade_controller.dart';
import '../ui/ui_helper/app_widgets.dart';

Color getNumberColor(dynamic number) => isNegativeNum(number) ? gSellColor : gBuyColor;

(String, Color) getNumberData(dynamic number) => isNegativeNum(number) ? ("", gSellColor) : ("+", gBuyColor);


void logOutActions() {
  clearStorage();
  gUserRx.value = User(id: 0);
  APIRepository().unSubscribeAllChannels();
}

CommonSettings? getSettingsLocal() {
  var objMap = GetStorage().read(PreferenceKey.settingsObject);
  if (objMap != null) {
    try {
      CommonSettings settings = CommonSettings.fromJson(objMap);
      return settings;
    } catch (_) {
      printFunction("getSettingsLocal error", '');
    }
  }
  return null;
}

String getName(String? firstName, String? lastName) {
  String name = "";
  firstName = firstName ?? "";
  lastName = lastName ?? "";
  if (firstName.isNotEmpty) {
    name = firstName;
  }
  if (lastName.isNotEmpty) {
    name = "$name $lastName";
  }
  return name;
}

void updateGlobalUser() => getRootController().getMyProfile();

void updateCommonSettings() => getRootController().getCommonSettings();

RootController getRootController() {
  if (Get.isRegistered<RootController>()) {
    return Get.find<RootController>();
  } else {
    return Get.put(RootController());
  }
}

SpotTradeController getDashboardController() {
  if (Get.isRegistered<SpotTradeController>()) {
    return Get.find<SpotTradeController>();
  } else {
    return Get.put(SpotTradeController());
  }
}


void saveGlobalUser({User? user, Map<String, dynamic>? userMap}) {
  if (userMap != null) {
    GetStorage().write(PreferenceKey.userObject, userMap);
    gUserRx.value = User.fromJson(userMap);
  } else if (user != null) {
    gUserRx.value = user;
    GetStorage().write(PreferenceKey.userObject, user.toJson());
  }
}



List<String> getCurrencyList(List<FiatCurrency>? currencyList) {
  if (currencyList != null) {
    List<String> cList = currencyList.map((e) => e.name ?? "").toList();
    return cList;
  }
  return [];
}

void checkLoggedInStatus(BuildContext context, Function() onLoggedIn) {
  if (gUserRx.value.id == 0) {
    showModalSheetFullScreen(context, signInNeedView(isDrawer: true));
  } else {
    onLoggedIn();
  }
}

List getFutureTradeTransactionTypeData(int? status) {
  switch (status) {
    case FTTransactionType.transfer:
      return ["Transferred".tr, Colors.amber];
    case FTTransactionType.commission:
      return ["Commission".tr, Colors.amber];
    case FTTransactionType.fundingFee:
      return ["Funding Fees".tr, Colors.green];
    case FTTransactionType.realizedPnl:
      return ["Realized PNL".tr, Colors.green];
  }
  return ["", Get.theme.primaryColor];
}

List getFutureTradeSideData(int? tradeType, int? side) {
  switch (tradeType) {
    case FutureTradeType.open:
      if (side == TradeType.buy) {
        return ["Open Long".tr, Colors.green];
      } else if (side == TradeType.sell) {
        return ["Open Short".tr, Colors.green];
      }
    case FutureTradeType.close:
      if (side == TradeType.buy) {
        return ["Close Long".tr, Colors.red];
      } else if (side == TradeType.sell) {
        return ["Close Short".tr, Colors.green];
      }
    case FutureTradeType.takeProfitClose:
      if (side == TradeType.buy) {
        return ["Open Short".tr, Colors.green];
      } else if (side == TradeType.sell) {
        return ["Close Short".tr, Colors.green];
      }
    case FutureTradeType.stopLossClose:
      if (side == TradeType.buy) {
        return ["Open Long".tr, Colors.red];
      } else if (side == TradeType.sell) {
        return ["Close Long".tr, Colors.red];
      }
  }
  return ["", Get.theme.primaryColor];
}

List getFutureTradeFeeData(int? tradeType, int? isMarket) {
  switch (tradeType) {
    case FutureTradeType.open:
      if (isMarket == 0) return ["Limit".tr, Colors.green];
    case FutureTradeType.close:
      if (isMarket == 0) return ["Limit".tr, Colors.green];
    case FutureTradeType.takeProfitClose:
      return ["Take Profit Market".tr, Colors.green];
    case FutureTradeType.stopLossClose:
      return ["Stop Market".tr, Colors.green];
  }
  return ["Market".tr, Get.theme.primaryColor];
}

void initBuySellColor() {
  final cIndex = GetStorage().read(PreferenceKey.buySellColorIndex);
  final udIndex = GetStorage().read(PreferenceKey.buySellUpDown);
  gBuyColor = bsColorList[cIndex][udIndex == 0 ? 0 : 1];
  gSellColor = bsColorList[cIndex][udIndex == 0 ? 1 : 0];
}

void handleLoginSuccess(dynamic resp) {
  GetStorage().write(PreferenceKey.accessToken, resp[APIKeyConstants.accessToken] ?? "");
  GetStorage().write(PreferenceKey.accessType, resp[APIKeyConstants.accessType] ?? "");
  GetStorage().write(PreferenceKey.accessTokenEvm, resp[APIKeyConstants.accessTokenEvm] ?? "");
  var userMap = resp[APIKeyConstants.user] as Map?;
  if (userMap != null) {
    GetStorage().write(PreferenceKey.userObject, userMap);
    GetStorage().write(PreferenceKey.isLoggedIn, true);
    Future.delayed(const Duration(milliseconds: 100), () => Get.offAll(() => const RootScreen()));
  }
}

double getHeightForTextScaler(BuildContext context, double height, List<double> modified) {
  final textScaler = MediaQuery.of(context).textScaler;
  if (textScaler == const TextScaler.linear(1.1)) {
    return height + modified[0];
  } else if (textScaler == const TextScaler.linear(1.2)) {
    return height + modified[1];
  } else if (textScaler == const TextScaler.linear(1.3)) {
    return height + modified[2];
  }
  return height;
}


Future<void> openCrispChatView() async {
  final key = getSettingsLocal()?.liveChatKey ?? "";
  if (key.isValid && key != DefaultValue.crispKey) {
    cc.CrispConfig config = cc.CrispConfig(
        websiteID: key,
        user: cc.User(
            email: gUserRx.value.email ?? "",
            avatar: gUserRx.value.photo ?? "",
            nickName: gUserRx.value.firstName ?? "",
            phone: gUserRx.value.phone ?? ""));
    await cc.FlutterCrispChat.openCrispChat(config: config);

  } else {
    showToast("Invalided Crisp chat key".tr);
  }
}

String daysString(int? total, {bool sCase = true}) {
  total = total ?? 0;
  if(sCase){
    return "$total ${'day'.trPlural('days', total).toCapitalizeFirst()}";
  }
  return "$total ${'day'.trPlural('days', total)}";
}

String minutesString(int? total, {bool sCase = false}) {
  total = total ?? 0;
  if(sCase){
    return "$total ${'minute'.trPlural('minutes', total).toCapitalizeFirst()}";
  }
  return "$total ${'minute'.trPlural('minutes', total)}";
}
