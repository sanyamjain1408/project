import 'dart:convert';

import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import 'p2p_settings.dart';

P2PAds p2PAdsFromJson(String str) => P2PAds.fromJson(json.decode(str));

class P2PAds {
  int? id;
  String? uid;
  int? userId;
  int? coinId;
  String? coinType;
  int? walletId;
  double? available;
  double? sold;
  String? country;
  String? currency;
  String? ip;
  int? paymentTimes;
  String? paymentMethod;
  double? amount;
  double? priceRate;
  double? ratePercentage;
  double? price;
  int? priceType;
  double? minimumTradeSize;
  double? maximumTradeSize;
  String? terms;
  String? autoReply;
  int? registerDays;
  double? coinHolding;
  int? kycCompleted;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? adminPaymentMethod;
  // List<P2pPaymentInfo>? paymentMethodList;
  List<DynamicBank>? paymentMethodList;
  User? user;
  String? paymentTimeId;

  P2PAds({
    this.id,
    this.uid,
    this.userId,
    this.coinId,
    this.coinType,
    this.walletId,
    this.available,
    this.sold,
    this.country,
    this.currency,
    this.ip,
    this.paymentTimes,
    this.paymentMethod,
    this.amount,
    this.priceRate,
    this.ratePercentage,
    this.price,
    this.priceType,
    this.minimumTradeSize,
    this.maximumTradeSize,
    this.terms,
    this.autoReply,
    this.registerDays,
    this.coinHolding,
    this.kycCompleted,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.adminPaymentMethod,
    this.paymentMethodList,
    this.user,
    this.paymentTimeId
  });

  factory P2PAds.fromJson(Map<String, dynamic> json) => P2PAds(
        id: json["id"],
        uid: json["uid"],
        userId: json["user_id"],
        coinId: json["coin_id"],
        coinType: json["coin_type"],
        walletId: json["wallet_id"],
        available: makeDouble(json["available"]),
        sold: makeDouble(json["sold"]),
        country: json["country"],
        currency: json["currency"],
        ip: json["ip"],
        paymentTimes: json["payment_times"],
        paymentMethod: json["payment_method"],
        amount: makeDouble(json["amount"]),
        priceRate: makeDouble(json["price_rate"]),
        ratePercentage: makeDouble(json["rate_percentage"]),
        price: makeDouble(json["price"]),
        priceType: json["price_type"],
        minimumTradeSize: makeDouble(json["minimum_trade_size"]),
        maximumTradeSize: makeDouble(json["maximum_trade_size"]),
        terms: json["terms"],
        autoReply: json["auto_reply"],
        registerDays: json["register_days"],
        coinHolding: makeDouble(json["coin_holding"]),
        kycCompleted: json["kyc_completed"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        adminPaymentMethod: json["admin_payment_method"],
        // paymentMethodList: json["payment_method_list"] == null ? null : List<P2pPaymentInfo>.from(json["payment_method_list"].map((x) => P2pPaymentInfo.fromJson(x))),
        paymentMethodList: json["payment_method_list"] == null ? null : List<DynamicBank>.from(json["payment_method_list"].map((x) => DynamicBank.fromJson(x))),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
    "coin_type": coinType,
    "fiat_type": currency,
    "price_type": priceType,
    "price": price,
    "price_rate": priceRate,
    "amount": amount,
    "min_limit": minimumTradeSize,
    "max_limit": maximumTradeSize,
    "time_limit": paymentTimeId,
    "register_days": registerDays,
    "coin_holding": coinHolding,
    "terms": terms,
    "auto_reply": autoReply,
    "countrys": country,
    "payment_methods": paymentMethod,
  };
}

class P2pPaymentInfo {
  int? id;
  String? uid;
  int? userId;
  String? username;
  String? paymentUid;
  String? bankName;
  String? bankAccountNumber;
  String? accountOpeningBranch;
  String? transactionReference;
  String? cardNumber;
  int? cardType;
  String? mobileAccountNumber;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  P2PPaymentMethod? adminPaymentMethod;

  P2pPaymentInfo({
    this.id,
    this.uid,
    this.userId,
    this.username,
    this.paymentUid,
    this.bankName,
    this.bankAccountNumber,
    this.accountOpeningBranch,
    this.transactionReference,
    this.cardNumber,
    this.cardType,
    this.mobileAccountNumber,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.adminPaymentMethod,
  });

  factory P2pPaymentInfo.fromJson(Map<String, dynamic> json) => P2pPaymentInfo(
        id: json["id"],
        uid: json["uid"],
        userId: json["user_id"],
        username: json["username"],
        paymentUid: json["payment_uid"],
        bankName: json["bank_name"],
        bankAccountNumber: json["bank_account_number"],
        accountOpeningBranch: json["account_opening_branch"],
        transactionReference: json["transaction_reference"],
        cardNumber: json["card_number"],
        cardType: makeInt(json["card_type"]),
        mobileAccountNumber: json["mobile_account_number"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        adminPaymentMethod: json["admin_pamynt_method"] == null ? null : P2PPaymentMethod.fromJson(json["admin_pamynt_method"]),
      );
}

class P2PAdsDetails {
  // List<P2pPaymentInfo>? paymentMethods;
  List<DynamicBank>? paymentMethods;
  P2PAds? ads;
  int? orders;
  double? completion;
  double? price;
  double? available;
  int? paymentTime;
  String? termsAndCondition;
  double? minimumPrice;
  double? maximumPrice;

  P2PAdsDetails({
    this.paymentMethods,
    this.ads,
    this.orders,
    this.completion,
    this.price,
    this.available,
    this.paymentTime,
    this.termsAndCondition,
    this.minimumPrice,
    this.maximumPrice,
  });

  factory P2PAdsDetails.fromJson(Map<String, dynamic> json) => P2PAdsDetails(
        // paymentMethods: json["payment_methods"] == null ? null : List<P2pPaymentInfo>.from(json["payment_methods"].map((x) => P2pPaymentInfo.fromJson(x))),
        paymentMethods: json["payment_methods"] == null ? null : List<DynamicBank>.from(json["payment_methods"].map((x) => DynamicBank.fromJson(x))),
        ads: json["ads"] == null ? null : P2PAds.fromJson(json["ads"]),
        orders: json["orders"],
        completion: makeDouble(json["completion"]),
        price: makeDouble(json["price"]),
        available: makeDouble(json["available"]),
        paymentTime: json["payment_time"],
        termsAndCondition: json["termsAndCondition"],
        minimumPrice: makeDouble(json["minimum_price"]),
        maximumPrice: makeDouble(json["maximaum_price"]),
      );
}

class OrderRate {
  double? rate;
  double? amountPrice;
  double? amount;

  OrderRate({this.rate, this.amountPrice, this.amount});

  factory OrderRate.fromJson(Map<String, dynamic> json) =>
      OrderRate(rate: makeDouble(json["rate"]), amountPrice: makeDouble(json["amount_price"]), amount: makeDouble(json["amount"]));
}

class P2PAdsPrice {
  double? highestPrice;
  double? lowestPrice;
  double? price;

  P2PAdsPrice({this.highestPrice, this.lowestPrice, this.price});

  factory P2PAdsPrice.fromJson(Map<String, dynamic> json) => P2PAdsPrice(
        highestPrice: makeDouble(json["highest_price"]),
        lowestPrice: makeDouble(json["lowest_price"]),
        price: makeDouble(json["price"]),
      );
}
