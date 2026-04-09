import 'dart:io';

import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

class IcoPhase {
  int? id;
  int? icoTokenId;
  int? userId;
  double? coinPrice;
  String? coinCurrency;
  double? totalTokenSupply;
  double? availableTokenSupply;
  double? soldPhaseTokens;
  DateTime? startDate;
  DateTime? endDate;
  String? phaseTitle;
  String? description;
  String? detailsRule;
  String? image;
  String? videoLink;
  String? websiteLink;
  String? socialLink;
  int? status;
  int? isFeatured;
  int? isUpdated;
  DateTime? createdAt;
  DateTime? updatedAt;
  double? minimumPurchasePrice;
  double? maximumPurchasePrice;
  String? tokenName;
  String? coinType;
  String? baseCoin;
  String? network;
  String? contractAddress;
  int? tokenId;
  int? totalParticipated;
  List<PhaseAdditionalInfo>? icoPhaseAdditionalDetails;

  IcoPhase({
    this.id,
    this.icoTokenId,
    this.userId,
    this.coinPrice,
    this.coinCurrency,
    this.totalTokenSupply,
    this.availableTokenSupply,
    this.soldPhaseTokens,
    this.startDate,
    this.endDate,
    this.phaseTitle,
    this.description,
    this.detailsRule,
    this.image,
    this.videoLink,
    this.websiteLink,
    this.socialLink,
    this.status,
    this.isFeatured,
    this.isUpdated,
    this.createdAt,
    this.updatedAt,
    this.minimumPurchasePrice,
    this.maximumPurchasePrice,
    this.tokenName,
    this.coinType,
    this.baseCoin,
    this.network,
    this.contractAddress,
    this.tokenId,
    this.totalParticipated,
    this.icoPhaseAdditionalDetails,
  });

  factory IcoPhase.fromJson(Map<String, dynamic> json) => IcoPhase(
        id: json["id"],
        icoTokenId: json["ico_token_id"],
        userId: json["user_id"],
        coinPrice: makeDouble(json["coin_price"]),
        coinCurrency: json["coin_currency"],
        totalTokenSupply: makeDouble(json["total_token_supply"]),
        availableTokenSupply: makeDouble(json["available_token_supply"]),
        soldPhaseTokens: makeDouble(json["sold_phase_tokens"]),
        startDate: json["start_date"] == null ? null : DateTime.parse(json["start_date"]),
        endDate: json["end_date"] == null ? null : DateTime.parse(json["end_date"]),
        phaseTitle: json["phase_title"],
        description: json["description"],
        detailsRule: json["details_rule"],
        image: json["image"],
        videoLink: json["video_link"],
        websiteLink: json["website_link"],
        socialLink: json["social_link"],
        status: json["status"],
        isFeatured: json["is_featured"],
        isUpdated: json["is_updated"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        icoPhaseAdditionalDetails: json["ico_phase_additional_details"] == null
            ? null
            : List<PhaseAdditionalInfo>.from(json["ico_phase_additional_details"].map((x) => PhaseAdditionalInfo.fromJson(x))),
        minimumPurchasePrice: makeDouble(json["minimum_purchase_price"]),
        maximumPurchasePrice: makeDouble(json["maximum_purchase_price"]),
        tokenName: json["token_name"],
        coinType: json["coin_type"],
        baseCoin: json["base_coin"],
        network: json["network"],
        contractAddress: json["contract_address"],
        tokenId: json["token_id"],
        totalParticipated: json["total_participated"],
      );

  Future<Map<String, dynamic>> toJson() async {
    final mapObj = <String, dynamic>{};
    if (id != null) mapObj["id"] = id;
    mapObj["ico_token_id"] = icoTokenId;
    mapObj["coin_price"] = coinPrice;
    mapObj["maximum_purchase_price"] = maximumPurchasePrice;
    mapObj["minimum_purchase_price"] = minimumPurchasePrice;
    mapObj["coin_currency"] = coinCurrency;
    mapObj["phase_title"] = phaseTitle;
    mapObj["start_date"] = formatDate(startDate, format: dateFormatYyyyMMDd);
    mapObj["end_date"] = formatDate(endDate, format: dateFormatYyyyMMDd);
    mapObj["description"] = description;
    mapObj["video_link"] = videoLink;
    mapObj["total_token_supply"] = totalTokenSupply;
    return mapObj;
  }
}

class IcoCreateBuyToken {
  IcoCreateBuyToken({
    this.phaseId,
    this.tokenId,
    this.paymentMethod,
    this.bankSlip,
    this.bankId,
    this.amount,
    this.currency,
    this.bankRef,
    this.stripeToken,
    this.paypalToken,
    this.payerWallet,
  });

  int? phaseId;
  int? tokenId;
  int? paymentMethod;
  File? bankSlip;
  int? bankId;
  int? payerWallet;
  double? amount;
  String? currency;
  String? bankRef;
  String? stripeToken;
  String? paypalToken;

  Future<Map<String, dynamic>> toJson() async {
    final mapObj = <String, dynamic>{};
    mapObj["phase_id"] = phaseId;
    mapObj["token_id"] = tokenId;
    mapObj["payment_method"] = paymentMethod;
    mapObj[APIKeyConstants.amount] = amount;
    if (currency.isValid) mapObj["pay_currency"] = currency;
    if (bankId != null) {
      mapObj[APIKeyConstants.bankId] = bankId;
      if (bankSlip != null) mapObj["bank_slep"] = await APIRepository().makeMultipartFile(bankSlip!);
      if (bankRef != null) mapObj["bank_ref"] = bankRef;
    }

    if (stripeToken.isValid) mapObj[APIKeyConstants.stripeToken] = stripeToken;
    if (paypalToken.isValid) mapObj["trx_id"] = paypalToken;
    if (payerWallet != null) mapObj["payer_wallet"] = payerWallet;
    return mapObj;
  }
}

class IcoCurrency {
  int? id;
  String? name;
  String? coinType;
  int? currencyType;
  dynamic currencyId;
  int? status;
  int? adminApproval;
  int? network;
  int? isWithdrawal;
  int? isDeposit;
  int? isDemoTrade;
  int? isBuy;
  int? isSell;
  String? coinIcon;
  int? isBase;
  int? isCurrency;
  dynamic isPrimary;
  int? isWallet;
  int? isTransferable;
  int? isVirtualAmount;
  int? tradeStatus;
  dynamic sign;
  String? minimumBuyAmount;
  String? maximumBuyAmount;
  String? minimumSellAmount;
  String? maximumSellAmount;
  String? minimumWithdrawal;
  String? maximumWithdrawal;
  String? maxSendLimit;
  String? withdrawalFees;
  int? withdrawalFeesType;
  String? coinPrice;
  int? icoId;
  int? isListed;
  int? lastBlockNumber;
  int? lastTimestamp;
  DateTime? createdAt;
  DateTime? updatedAt;

  IcoCurrency({
    this.id,
    this.name,
    this.coinType,
    this.currencyType,
    this.currencyId,
    this.status,
    this.adminApproval,
    this.network,
    this.isWithdrawal,
    this.isDeposit,
    this.isDemoTrade,
    this.isBuy,
    this.isSell,
    this.coinIcon,
    this.isBase,
    this.isCurrency,
    this.isPrimary,
    this.isWallet,
    this.isTransferable,
    this.isVirtualAmount,
    this.tradeStatus,
    this.sign,
    this.minimumBuyAmount,
    this.maximumBuyAmount,
    this.minimumSellAmount,
    this.maximumSellAmount,
    this.minimumWithdrawal,
    this.maximumWithdrawal,
    this.maxSendLimit,
    this.withdrawalFees,
    this.withdrawalFeesType,
    this.coinPrice,
    this.icoId,
    this.isListed,
    this.lastBlockNumber,
    this.lastTimestamp,
    this.createdAt,
    this.updatedAt,
  });

  factory IcoCurrency.fromJson(Map<String, dynamic> json) => IcoCurrency(
        id: json["id"],
        name: json["name"],
        coinType: json["coin_type"],
        currencyType: json["currency_type"],
        currencyId: json["currency_id"],
        status: json["status"],
        adminApproval: json["admin_approval"],
        network: json["network"],
        isWithdrawal: json["is_withdrawal"],
        isDeposit: json["is_deposit"],
        isDemoTrade: json["is_demo_trade"],
        isBuy: json["is_buy"],
        isSell: json["is_sell"],
        coinIcon: json["coin_icon"],
        isBase: json["is_base"],
        isCurrency: json["is_currency"],
        isPrimary: json["is_primary"],
        isWallet: json["is_wallet"],
        isTransferable: json["is_transferable"],
        isVirtualAmount: json["is_virtual_amount"],
        tradeStatus: json["trade_status"],
        sign: json["sign"],
        minimumBuyAmount: json["minimum_buy_amount"],
        maximumBuyAmount: json["maximum_buy_amount"],
        minimumSellAmount: json["minimum_sell_amount"],
        maximumSellAmount: json["maximum_sell_amount"],
        minimumWithdrawal: json["minimum_withdrawal"],
        maximumWithdrawal: json["maximum_withdrawal"],
        maxSendLimit: json["max_send_limit"],
        withdrawalFees: json["withdrawal_fees"],
        withdrawalFeesType: json["withdrawal_fees_type"],
        coinPrice: json["coin_price"],
        icoId: json["ico_id"],
        isListed: json["is_listed"],
        lastBlockNumber: json["last_block_number"],
        lastTimestamp: json["last_timestamp"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );
}

class PhaseAdditionalInfo {
  int? id;
  int? icoPhaseId;
  String? title;
  String? value;
  String? file;
  int? isUpdated;
  DateTime? createdAt;
  DateTime? updatedAt;
  File? localFile;

  PhaseAdditionalInfo({
    this.id,
    this.icoPhaseId,
    this.title,
    this.value,
    this.file,
    this.isUpdated,
    this.createdAt,
    this.updatedAt,
    this.localFile,
  });

  factory PhaseAdditionalInfo.fromJson(Map<String, dynamic> json) => PhaseAdditionalInfo(
        id: json["id"],
        icoPhaseId: json["ico_phase_id"],
        title: json["title"],
        value: json["value"],
        file: json["file"],
        isUpdated: json["is_updated"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );
}

class IcoWithdraw {
  int? id;
  int? userId;
  double? requestAmount;
  String? requestCurrency;
  double? convertAmount;
  String? convertCurrency;
  int? tranType;
  int? approvedStatus;
  int? approvedById;
  double? fee;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? paymentDetails;
  String? paymentSleep;

  IcoWithdraw({
    this.id,
    this.userId,
    this.requestAmount,
    this.requestCurrency,
    this.convertAmount,
    this.convertCurrency,
    this.tranType,
    this.approvedStatus,
    this.approvedById,
    this.fee,
    this.createdAt,
    this.updatedAt,
    this.paymentDetails,
    this.paymentSleep,
  });

  factory IcoWithdraw.fromJson(Map<String, dynamic> json) => IcoWithdraw(
        id: json["id"],
        userId: json["user_id"],
        requestAmount: makeDouble(json["request_amount"]),
        requestCurrency: json["request_currency"],
        convertAmount: makeDouble(json["convert_amount"]),
        convertCurrency: json["convert_currency"],
        tranType: json["tran_type"],
        approvedStatus: json["approved_status"],
        approvedById: json["approved_by_id"],
        fee: makeDouble(json["fee"]),
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        paymentDetails: json["payment_details"],
        paymentSleep: json["payment_sleep"],
      );
}
