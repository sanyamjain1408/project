import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/local/api_constants.dart';
import '../data/local/constants.dart';

class AppChecker {

  static List getStakingStatusData(int? status) {
    switch (status) {
      case StakingInvestmentStatus.running:
        return ["Running".tr, Colors.amber];
      case StakingInvestmentStatus.canceled:
        return ["Canceled".tr, Colors.redAccent];
      case StakingInvestmentStatus.unpaid:
        return ["Unpaid".tr, Colors.amber];
      case StakingInvestmentStatus.paid:
        return ["Paid".tr, Colors.green];
      case StakingInvestmentStatus.success:
        return ["Success".tr, Colors.green];
    }
    return ["", Get.theme.primaryColor];
  }

  static List getStakingTermsData(int? status) {
    switch (status) {
      case StakingTermsType.strict:
        return ["Locked".tr, Colors.amber];
      case StakingTermsType.flexible:
        return ["Flexible".tr, Colors.amber];
    }
    return ["", Get.theme.primaryColor];
  }

  static TextInputType getTextInputType(String? key) {
    switch (key) {
      case DynamicFieldTypes.email:
        return TextInputType.emailAddress;
      case DynamicFieldTypes.number:
        return const TextInputType.numberWithOptions(decimal: true);
      default:
        return TextInputType.text;
    }
  }

  static List getWalletFiatHistoryStatusData(int? status) {
    if (status == WalletFiatHistoryStatus.pending) {
      return ["Pending".tr, Colors.amber];
    } else if (status == WalletFiatHistoryStatus.accepted) {
      return ["Accepted".tr, Colors.green];
    } else if (status == WalletFiatHistoryStatus.rejected) {
      return ["Rejected".tr, Colors.red];
    }
    return ["".tr, Colors.transparent];
  }

  static List getWalletCryptoHistoryStatusData(int? status) {

    switch(status){
      case WalletCryptoHistoryStatus.pending:
        return ["Pending".tr, Colors.amber];
      case WalletCryptoHistoryStatus.success:
        return ["Success".tr, Colors.green];
      case WalletCryptoHistoryStatus.rejected:
        return ["Rejected".tr, Colors.red];
      case WalletCryptoHistoryStatus.failed:
        return ["Failed".tr, Colors.red];
      case WalletCryptoHistoryStatus.initial:
        return ["Initial".tr, Colors.grey];
      case WalletCryptoHistoryStatus.processing:
        return ["Processing".tr, Colors.blue];
      case WalletCryptoHistoryStatus.expire:
        return ["Expired".tr, Colors.red];
      default:
        return ["".tr, Colors.transparent];
    }
  }

  static List getActiveStatusData(int? status) {
    if (status == 1) {
      return ["Active".tr, Colors.green];
    } else {
      return ["Inactive".tr, Colors.red];
    }
  }

  static List getStatusData(int status) {
    switch (status) {
      case 0:
        return ["Pending".tr, Colors.amber];
      case 1:
        return ["Success".tr, Colors.green];
      case 2:
        return ["Failed".tr, Colors.red];
    }
    return ["", Colors.black];
  }

  static List getHistoryTypeData(String type) {
    switch (type) {
      case HistoryType.deposit:
        return ["Deposit", Colors.green];
      case HistoryType.withdraw:
        return ["Withdrawal", Colors.redAccent];
      case HistoryType.stopLimit:
        return ["Stop Limit", Colors.blue];
      case HistoryType.swap:
        return ["Swap", Colors.blue];
      case HistoryType.buyOrder:
        return ["Buy Order", Colors.green];
      case HistoryType.sellOrder:
        return ["Sell Order", Colors.redAccent];
      case HistoryType.transaction:
        return ["Transaction", Colors.blue];
      case HistoryType.fiatDeposit:
        return ["Fiat Deposit", Colors.green];
      case HistoryType.fiatWithdrawal:
        return ["Fiat Withdrawal", Colors.redAccent];
      case HistoryType.refEarningTrade:
        return ["From Trade", Colors.blue];
      case HistoryType.refEarningWithdrawal:
        return ["From Withdrawal", Colors.deepOrange];
    }
    return [];
  }

  static List getIdVerificationStatusData(String? status) {
    if (status == IdVerificationStatus.pending) {
      return ["Pending".tr, Colors.amber];
    } else if (status == IdVerificationStatus.accepted) {
      return ["Accepted".tr, Colors.green];
    } else if (status == IdVerificationStatus.rejected) {
      return ["Rejected".tr, Colors.red];
    }
    return ["Not submitted".tr, Colors.blueGrey];
  }

  static String getActivityActionText(String? status) {
    if (status == "1") {
      return "Login".tr;
    }
    return "";
  }

  static String getHistoryUrl(String type, {bool? isFiat}) {
    if (type == HistoryType.deposit) {
      return (isFiat ?? false) ? APIURLConstants.getWalletCurrencyDepositHistory : APIURLConstants.getWalletHistoryApp;
    } else if (type == HistoryType.withdraw) {
      return (isFiat ?? false) ? APIURLConstants.getWalletCurrencyWithdrawHistory : APIURLConstants.getWalletHistoryApp;
    } else if (type == HistoryType.swap) {
      return APIURLConstants.getCoinConvertHistoryApp;
    } else if (type == HistoryType.buyOrder) {
      return APIURLConstants.getAllBuyOrdersHistoryApp;
    } else if (type == HistoryType.sellOrder) {
      return APIURLConstants.getAllSellOrdersHistoryApp;
    } else if (type == HistoryType.transaction) {
      return APIURLConstants.getAllTransactionHistoryApp;
    } else if (type == HistoryType.fiatDeposit) {
      return APIURLConstants.getCurrencyDepositHistory;
    } else if (type == HistoryType.fiatWithdrawal) {
      return APIURLConstants.getFiatWithdrawalHistory;
    } else if (type == HistoryType.stopLimit) {
      return APIURLConstants.getAllStopLimitOrdersApp;
    } else if (type == HistoryType.refEarningTrade || type == HistoryType.refEarningWithdrawal) {
      return APIURLConstants.getReferralHistory;
    }
    return "";
  }

}
