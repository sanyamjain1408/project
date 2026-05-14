import 'dart:convert';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

ReferralData referralFromJson(String str) => ReferralData.fromJson(json.decode(str));

String referralToJson(ReferralData data) => json.encode(data.toJson());

class ReferralData {
  ReferralData({
    this.title,
    this.user,
    this.referrals,
    this.url,
    this.referralLink,
    this.referralCode,
    this.referralLevel,
    this.select,
    this.maxReferralLevel,
    this.totalReward,
    this.countReferrals,
    this.pendingBalance,
    this.activeReferrals,
  });

  String? title;
  User? user;
  List<Referral>? referrals;
  String? url;
  String? referralLink;
  String? referralCode;
  Map<String, int>? referralLevel;
  String? select;
  int? maxReferralLevel;
  double? totalReward;
  int? countReferrals;
  double? pendingBalance;
  int? activeReferrals;

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    final user = json["user"] == null ? null : User.fromJson(json["user"]);
    final rawLink = json["referral_link"] ?? json["url"];
    final rawCode = json["referral_code"] ?? user?.affiliate?.code;
    return ReferralData(
      title: json["title"],
      user: user,
      referrals: json["referrals"] == null
          ? null
          : List<Referral>.from(json["referrals"].map((x) => Referral.fromJson(x))),
      url: rawLink,
      referralLink: rawLink,
      referralCode: rawCode,
      referralLevel: json["referralLevel"] == null
          ? null
          : Map.from(json["referralLevel"]).map((k, v) => MapEntry<String, int>(k, v)),
      select: json["select"],
      maxReferralLevel: json["max_referral_level"],
      totalReward: makeDouble(json["total_earned"] ?? json["total_reward"]),
      countReferrals: json["count_referrals"] ?? json["total_referrals"],
      pendingBalance: makeDouble(json["pending_balance"]),
      activeReferrals: json["active_referrals"],
    );
  }

  Map<String, dynamic> toJson() => {
        "title": title,
        "user": user?.toJson(),
        "referrals": referrals == null ? null : List<dynamic>.from(referrals!.map((x) => x.toJson())),
        "url": url,
        "referral_link": referralLink,
        "referral_code": referralCode,
        "referralLevel": referralLevel == null ? null : Map.from(referralLevel!).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "select": select,
        "max_referral_level": maxReferralLevel,
        "total_reward": totalReward,
        "count_referrals": countReferrals,
        "pending_balance": pendingBalance,
        "active_referrals": activeReferrals,
      };
}

class Referral {
  Referral({
    this.id,
    this.fullName,
    this.email,
    this.joiningDate,
    this.level,
    this.tradeVolume,
    this.youEarned,
  });

  int? id;
  String? fullName;
  String? email;
  DateTime? joiningDate;
  String? level;
  double? tradeVolume;
  double? youEarned;

  factory Referral.fromJson(Map<String, dynamic> json) {
    final rawDate = json["joining_date"] ?? json["joined_at"];
    return Referral(
      id: json["id"],
      fullName: json["full_name"] ?? json["name"],
      email: json["email"],
      joiningDate: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
      level: json["level"],
      tradeVolume: makeDouble(json["trade_volume"]),
      youEarned: makeDouble(json["you_earned"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "full_name": fullName,
        "email": email,
        "joining_date": joiningDate?.toIso8601String(),
        "level": level,
        "trade_volume": tradeVolume,
        "you_earned": youEarned,
      };
}

class Affiliate {
  Affiliate({
    required this.id,
    this.userId,
    this.code,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  int id;
  int? userId;
  String? code;
  int? status;
  DateTime? deletedAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory Affiliate.fromJson(Map<String, dynamic> json) => Affiliate(
        id: json["id"],
        userId: json["user_id"],
        code: json["code"],
        status: json["status"],
        deletedAt: json["deleted_at"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "code": code,
        "status": status,
        "deleted_at": deletedAt?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

Earning earningFromJson(String str) => Earning.fromJson(json.decode(str));

String earningToJson(Earning data) => json.encode(data.toJson());

class Earning {
  Earning({
    required this.id,
    this.coinType,
    this.transactionId,
    this.amount,
    this.level,
  });

  int id;
  String? coinType;
  String? transactionId;
  double? amount;
  int? level;

  factory Earning.fromJson(Map<String, dynamic> json) => Earning(
        id: json["id"],
        coinType: json["coin_type"],
        transactionId: json["transaction_id"],
        level: json["level"],
        amount: makeDouble(json["amount"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "coin_type": coinType,
        "transaction_id": transactionId,
        "amount": amount,
        "level": level,
      };
}

ReferralHistory referralHistoryFromJson(String str) => ReferralHistory.fromJson(json.decode(str));

String referralHistoryToJson(ReferralHistory data) => json.encode(data.toJson());

class ReferralHistory {
  ReferralHistory({
    required this.id,
    this.tradeBy,
    this.userId,
    this.childId,
    this.amount,
    this.percentageAmount,
    this.transactionId,
    this.level,
    this.coinType,
    this.walletId,
    this.createdAt,
    this.updatedAt,
    this.referenceUserEmail,
    this.referralUserEmail,
  });

  int id;
  int? tradeBy;
  int? userId;
  int? childId;
  double? amount;
  double? percentageAmount;
  String? transactionId;
  int? level;
  String? coinType;
  int? walletId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? referenceUserEmail;
  String? referralUserEmail;

  factory ReferralHistory.fromJson(Map<String, dynamic> json) => ReferralHistory(
        id: json["id"],
        tradeBy: json["trade_by"],
        userId: json["user_id"],
        childId: json["child_ id"],
        amount: makeDouble(json["amount"]),
        percentageAmount: makeDouble(json["percentage amount"]),
        transactionId: json["transaction_id"],
        level: json["level"],
        coinType: json["coin_type"],
        walletId: json["wallet_id"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        referenceUserEmail: json["reference_user_email"],
        referralUserEmail: json["referral_user_email"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "trade_by": tradeBy,
        "user_id": userId,
        "child_ id": childId,
        "amount": amount,
        "percentage amount": percentageAmount,
        "transaction_id": transactionId,
        "level": level,
        "coin_type": coinType,
        "wallet_id": walletId,
        "created_at": createdAt,
        "updated at": updatedAt,
        "reference_user_email": referenceUserEmail,
        "referral_user_email": referralUserEmail,
      };
}
