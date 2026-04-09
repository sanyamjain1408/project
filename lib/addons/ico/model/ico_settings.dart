import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

class IcoLaunchpad {
  String? launchpadCoverImage;
  String? launchpadMainImage;
  String? launchpadFirstTitle;
  String? launchpadFirstDescription;
  String? launchpadSecondTitle;
  String? launchpadSecondDescription;
  String? launchpadApplyToStatus;
  String? launchpadWhyChooseUsText;
  String? launchpadApplyToButtonText;
  int? projectLaunchpad;
  int? allTimeUniqueParticipants;
  double? totalFundsRaised;
  double? currentFundsLocked;
  List<IcoFeature>? featureList;

  IcoLaunchpad({
    this.launchpadCoverImage,
    this.launchpadMainImage,
    this.launchpadFirstTitle,
    this.launchpadFirstDescription,
    this.launchpadSecondTitle,
    this.launchpadSecondDescription,
    this.launchpadApplyToStatus,
    this.launchpadWhyChooseUsText,
    this.launchpadApplyToButtonText,
    this.projectLaunchpad,
    this.allTimeUniqueParticipants,
    this.totalFundsRaised,
    this.currentFundsLocked,
    this.featureList,
  });

  factory IcoLaunchpad.fromJson(Map<String, dynamic> json) => IcoLaunchpad(
        launchpadCoverImage: json["launchpad_cover_image"],
        launchpadMainImage: json["launchpad_main_image"],
        launchpadFirstTitle: json["launchpad_first_title"] is String? ? json["launchpad_first_title"] : null,
        launchpadFirstDescription: json["launchpad_first_description"]  is String? ? json["launchpad_first_description"] : null,
        launchpadSecondTitle: json["launchpad_second_title"]  is String? ? json["launchpad_second_title"] : null,
        launchpadSecondDescription: json["launchpad_second_description"]  is String? ? json["launchpad_second_description"] : null,
        launchpadApplyToStatus: json["launchpad_apply_to_status"],
        launchpadWhyChooseUsText: json["launchpad_why_choose_us_text"] is String? ? json["launchpad_why_choose_us_text"] : null,
        launchpadApplyToButtonText: json["launchpad_apply_to_button_text"] is String? ? json["launchpad_apply_to_button_text"] : null,
        projectLaunchpad: json["project_launchpad"],
        allTimeUniqueParticipants: json["all_time_unique_participants"],
        totalFundsRaised: makeDouble(json["total_funds_raised"]),
        currentFundsLocked: makeDouble(json["current_funds_locked"]),
        featureList: json["feature_list"] == null ? null : List<IcoFeature>.from(json["feature_list"].map((x) => IcoFeature.fromJson(x))),
      );
}

class IcoFeature {
  int? id;
  String? image;
  String? title;
  String? slug;
  dynamic pageLink;
  String? customPageDescription;
  String? description;
  int? pageType;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  IcoFeature({
    this.id,
    this.image,
    this.title,
    this.slug,
    this.pageLink,
    this.customPageDescription,
    this.description,
    this.pageType,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory IcoFeature.fromJson(Map<String, dynamic> json) => IcoFeature(
        id: json["id"],
        image: json["image"],
        title: json["title"],
        slug: json["slug"],
        pageLink: json["page_link"],
        customPageDescription: json["custom_page_description"],
        description: json["description"],
        pageType: json["page_type"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );
}

class IcoBuySettings {
  // List<Bank>? bank;
  List<DynamicBank>? bank;
  List<Wallet>? wallet;
  List<PaymentMethod>? paymentMethods;
  List<FiatCurrency>? currencyList;
  String? ref;

  IcoBuySettings({
    this.bank,
    this.wallet,
    this.paymentMethods,
    this.currencyList,
    this.ref,
  });

  factory IcoBuySettings.fromJson(Map<String, dynamic> json) => IcoBuySettings(
        // bank: json["bank"] == null ? null : List<Bank>.from(json["bank"].map((x) => Bank.fromJson(x))),
        bank: json["bank"] == null ? null : List<DynamicBank>.from(json["bank"].map((x) => DynamicBank.fromJson(x))),
        wallet: json["wallet"] == null ? null : List<Wallet>.from(json["wallet"].map((x) => Wallet.fromJson(x))),
        paymentMethods:
            json["payment_methods"] == null ? null : List<PaymentMethod>.from(json["payment_methods"].map((x) => PaymentMethod.fromJson(x))),
        currencyList: json["currency_list"] == null ? null : List<FiatCurrency>.from(json["currency_list"].map((x) => FiatCurrency.fromJson(x))),
        ref: json["ref"],
      );
}

class TokenPriceInfo {
  double? tokenPrice;
  String? tokenCurrency;
  double? tokenAmount;
  double? tokenTotalPrice;
  double? payAmount;
  String? payCurrency;

  TokenPriceInfo({
    this.tokenPrice,
    this.tokenCurrency,
    this.tokenAmount,
    this.tokenTotalPrice,
    this.payAmount,
    this.payCurrency,
  });

  factory TokenPriceInfo.fromJson(Map<String, dynamic> json) => TokenPriceInfo(
        tokenPrice: makeDouble(json["token_price"]),
        tokenCurrency: json["token_currency"],
        tokenAmount: makeDouble(json["token_amount"]),
        tokenTotalPrice: makeDouble(json["token_total_price"]),
        payAmount: makeDouble(json["pay_amount"]),
        payCurrency: json["pay_currency"],
      );
}

class Contract {
  Contract({this.chainId, this.symbol, this.name, this.tokenBalance, this.tokenDecimal});

  String? chainId;
  String? symbol;
  String? name;
  double? tokenBalance;
  int? tokenDecimal;

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        chainId: json["chain_id"].toString(),
        symbol: json["symbol"],
        name: json["name"],
        tokenBalance: makeDouble(json["token_balance"]),
        tokenDecimal: makeInt(json["token_decimal"]),
      );
}

