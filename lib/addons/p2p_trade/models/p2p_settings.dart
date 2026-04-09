import 'dart:convert';

import '../../../data/models/bank_data.dart';
import '../../../data/models/faq.dart';
import '../../../utils/number_util.dart';

P2PAdsSettings membershipHomeFromJson(String str) => P2PAdsSettings.fromJson(json.decode(str));

class P2PAdsSettings {
  List<P2PCoin>? assets;
  List<P2PCurrency>? currency;
  List<P2PCountry>? country;
  List<P2PPaymentMethod>? paymentMethods;
  int? totalTrade;
  String? completion;
  String? p2PBuyStep1Heading;
  String? p2PBuyStep1Des;
  String? p2PBuyStep1Icon;
  String? p2PBuyStep2Heading;
  String? p2PBuyStep2Des;
  String? p2PBuyStep2Icon;
  String? p2PBuyStep3Heading;
  String? p2PBuyStep3Des;
  String? p2PBuyStep3Icon;
  String? p2PSellStep1Heading;
  String? p2PSellStep1Des;
  String? p2PSellStep1Icon;
  String? p2PSellStep2Heading;
  String? p2PSellStep2Des;
  String? p2PSellStep2Icon;
  String? p2PSellStep3Heading;
  String? p2PSellStep3Des;
  String? p2PSellStep3Icon;
  String? p2PAdvantage1Heading;
  String? p2PAdvantage1Des;
  String? p2PAdvantage1Icon;
  String? p2PAdvantage2Heading;
  String? p2PAdvantage2Des;
  String? p2PAdvantage2Icon;
  String? p2PAdvantage3Heading;
  String? p2PAdvantage3Des;
  String? p2PAdvantage3Icon;
  String? p2PAdvantage4Heading;
  String? p2PAdvantage4Des;
  String? p2PAdvantage4Icon;
  String? p2PBannerImg;
  String? p2PBannerHeader;
  String? p2PBannerDes;
  String? p2PAdvantageRightImage;
  List<P2PPaymentMethod>? paymentMethodLanding;
  List<FAQ>? p2PFaq;

  P2PAdsSettings({
    this.assets,
    this.currency,
    this.paymentMethods,
    this.country,
    this.totalTrade,
    this.completion,
    this.p2PBuyStep1Heading,
    this.p2PBuyStep1Des,
    this.p2PBuyStep1Icon,
    this.p2PBuyStep2Heading,
    this.p2PBuyStep2Des,
    this.p2PBuyStep2Icon,
    this.p2PBuyStep3Heading,
    this.p2PBuyStep3Des,
    this.p2PBuyStep3Icon,
    this.p2PSellStep1Heading,
    this.p2PSellStep1Des,
    this.p2PSellStep1Icon,
    this.p2PSellStep2Heading,
    this.p2PSellStep2Des,
    this.p2PSellStep2Icon,
    this.p2PSellStep3Heading,
    this.p2PSellStep3Des,
    this.p2PSellStep3Icon,
    this.p2PAdvantage1Heading,
    this.p2PAdvantage1Des,
    this.p2PAdvantage1Icon,
    this.p2PAdvantage2Heading,
    this.p2PAdvantage2Des,
    this.p2PAdvantage2Icon,
    this.p2PAdvantage3Heading,
    this.p2PAdvantage3Des,
    this.p2PAdvantage3Icon,
    this.p2PAdvantage4Heading,
    this.p2PAdvantage4Des,
    this.p2PAdvantage4Icon,
    this.paymentMethodLanding,
    this.p2PFaq,
    this.p2PBannerImg,
    this.p2PBannerHeader,
    this.p2PAdvantageRightImage,
    this.p2PBannerDes,
  });

  factory P2PAdsSettings.fromJson(Map<String, dynamic> json) => P2PAdsSettings(
        assets: json["assets"] == null ? null : List<P2PCoin>.from(json["assets"].map((x) => P2PCoin.fromJson(x))),
        currency: json["currency"] == null ? null : List<P2PCurrency>.from(json["currency"].map((x) => P2PCurrency.fromJson(x))),
        country: json["country"] == null ? null : List<P2PCountry>.from(json["country"].map((x) => P2PCountry.fromJson(x))),
        paymentMethods:
            json["payment_method"] == null ? null : List<P2PPaymentMethod>.from(json["payment_method"].map((x) => P2PPaymentMethod.fromJson(x))),
        totalTrade: json["total_trade"],
        completion: json["completion"],
        p2PBuyStep1Heading: json["p2p_buy_step_1_heading"],
        p2PBuyStep1Des: json["p2p_buy_step_1_des"],
        p2PBuyStep1Icon: json["p2p_buy_step_1_icon"],
        p2PBuyStep2Heading: json["p2p_buy_step_2_heading"],
        p2PBuyStep2Des: json["p2p_buy_step_2_des"],
        p2PBuyStep2Icon: json["p2p_buy_step_2_icon"],
        p2PBuyStep3Heading: json["p2p_buy_step_3_heading"],
        p2PBuyStep3Des: json["p2p_buy_step_3_des"],
        p2PBuyStep3Icon: json["p2p_buy_step_3_icon"],
        p2PSellStep1Heading: json["p2p_sell_step_1_heading"],
        p2PSellStep1Des: json["p2p_sell_step_1_des"],
        p2PSellStep1Icon: json["p2p_sell_step_1_icon"],
        p2PSellStep2Heading: json["p2p_sell_step_2_heading"],
        p2PSellStep2Des: json["p2p_sell_step_2_des"],
        p2PSellStep2Icon: json["p2p_sell_step_2_icon"],
        p2PSellStep3Heading: json["p2p_sell_step_3_heading"],
        p2PSellStep3Des: json["p2p_sell_step_3_des"],
        p2PSellStep3Icon: json["p2p_sell_step_3_icon"],
        p2PAdvantage1Heading: json["p2p_advantage_1_heading"],
        p2PAdvantage1Des: json["p2p_advantage_1_des"],
        p2PAdvantage1Icon: json["p2p_advantage_1_icon"],
        p2PAdvantage2Heading: json["p2p_advantage_2_heading"],
        p2PAdvantage2Des: json["p2p_advantage_2_des"],
        p2PAdvantage2Icon: json["p2p_advantage_2_icon"],
        p2PAdvantage3Heading: json["p2p_advantage_3_heading"],
        p2PAdvantage3Des: json["p2p_advantage_3_des"],
        p2PAdvantage3Icon: json["p2p_advantage_3_icon"],
        p2PAdvantage4Heading: json["p2p_advantage_4_heading"],
        p2PAdvantage4Des: json["p2p_advantage_4_des"],
        p2PAdvantage4Icon: json["p2p_advantage_4_icon"],
        paymentMethodLanding: json["payment_method_landing"] == null
            ? null
            : List<P2PPaymentMethod>.from(json["payment_method_landing"].map((x) => P2PPaymentMethod.fromJson(x))),
        p2PFaq: json["p2p_faq"] == null ? null : List<FAQ>.from(json["p2p_faq"].map((x) => FAQ.fromJson(x))),
        p2PAdvantageRightImage: json["p2p_advantage_right_image"],
        p2PBannerImg: json["p2p_banner_img"],
        p2PBannerHeader: json["p2p_banner_header"],
        p2PBannerDes: json["p2p_banner_des"],
      );
}

class P2PCoin {
  String? name;
  String? coinType;
  double? maximumPrice;
  double? minimumPrice;

  P2PCoin({this.name, this.coinType, this.maximumPrice, this.minimumPrice});

  factory P2PCoin.fromJson(Map<String, dynamic> json) => P2PCoin(
      name: json["name"],
      coinType: json["coin_type"],
      maximumPrice: makeDouble(json["maximum_price"]),
      minimumPrice: makeDouble(json["minimum_price"]));
}

class P2PCurrency {
  String? name;
  double? maximumPrice;
  double? minimumPrice;
  String? currencyCode;
  String? label;

  P2PCurrency({this.name, this.maximumPrice, this.minimumPrice, this.currencyCode, this.label});

  factory P2PCurrency.fromJson(Map<String, dynamic> json) => P2PCurrency(
      name: json["name"],
      label: json["label"],
      currencyCode: json["currency_code"],
      maximumPrice: makeDouble(json["maximum_price"]),
      minimumPrice: makeDouble(json["minimum_price"]));
}

class P2PCountry {
  String? key;
  String? value;
  String? label;

  P2PCountry({this.key, this.value, this.label});

  factory P2PCountry.fromJson(Map<String, dynamic> json) => P2PCountry(key: json["key"], value: json["value"], label: json["label"]);
}

class P2PPaymentMethod {
  int? id;
  String? uid;
  String? name;
  int? paymentType;
  String? country;
  String? note;
  String? logo;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  BankForm? bankForm;

  P2PPaymentMethod({
    this.id,
    this.uid,
    this.name,
    this.paymentType,
    this.country,
    this.note,
    this.logo,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.bankForm,
  });

  factory P2PPaymentMethod.fromJson(Map<String, dynamic> json) => P2PPaymentMethod(
        id: json["id"],
        uid: json["uid"],
        name: json["name"],
        paymentType: json["payment_type"],
        country: json["country"],
        note: json["note"],
        logo: json["logo"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        bankForm: json["bank_form"] == null ? null : BankForm.fromJson(json["bank_form"]),
      );
}

class P2PAdsCreateSettings {
  List<P2PCoin>? assets;
  List<P2PCurrency>? currency;
  // List<P2pPaymentInfo>? paymentMethods;
  List<DynamicBank>? paymentMethods;
  bool? isPaymentMethodAvailable;
  List<PaymentTime>? paymentTime;
  List<P2PCountry>? country;
  bool? counterparty;

  P2PAdsCreateSettings({
    this.assets,
    this.currency,
    this.paymentMethods,
    this.isPaymentMethodAvailable,
    this.paymentTime,
    this.country,
    this.counterparty,
  });

  factory P2PAdsCreateSettings.fromJson(Map<String, dynamic> json) => P2PAdsCreateSettings(
        assets: json["assets"] == null ? null : List<P2PCoin>.from(json["assets"].map((x) => P2PCoin.fromJson(x))),
        currency: json["currency"] == null ? null : List<P2PCurrency>.from(json["currency"].map((x) => P2PCurrency.fromJson(x))),
        // paymentMethods: json["payment_method"] == null ? null : List<P2pPaymentInfo>.from(json["payment_method"].map((x) => P2pPaymentInfo.fromJson(x))),
        paymentMethods: json["payment_method"] == null ? null : List<DynamicBank>.from(json["payment_method"].map((x) => DynamicBank.fromJson(x))),
        isPaymentMethodAvailable: json["is_payment_method_available"],
        paymentTime: json["payment_time"] == null ? null : List<PaymentTime>.from(json["payment_time"].map((x) => PaymentTime.fromJson(x))),
        country: json["country"] == null ? null : List<P2PCountry>.from(json["country"].map((x) => P2PCountry.fromJson(x))),
        counterparty: json["counterparty"],
      );
}

class PaymentTime {
  String? uid;
  int? time;

  PaymentTime({this.uid, this.time});

  factory PaymentTime.fromJson(Map<String, dynamic> json) => PaymentTime(uid: json["uid"], time: json["time"]);
}
