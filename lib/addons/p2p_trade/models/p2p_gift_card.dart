import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/data/models/gift_card.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import 'p2p_order.dart';

class P2PGiftCardAd {
  int? id;
  String? uid;
  int? userId;
  int? giftCardId;
  int? paymentCurrencyType;
  String? currencyType;
  String? price;
  String? amount;
  String? termsCondition;
  String? country;
  int? timeLimit;
  String? autoReply;
  dynamic userRegisteredBefore;
  String? paymentMethod;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? coinType;
  // List<P2pPaymentInfo>? paymentMethods;
  List<DynamicBank>? paymentMethods;
  User? user;
  GiftCard? giftCard;
  List<String>? countryList;
  List<String>? paymentMethodUidList;

  P2PGiftCardAd({
    this.id,
    this.uid,
    this.userId,
    this.giftCardId,
    this.paymentCurrencyType,
    this.currencyType,
    this.price,
    this.amount,
    this.termsCondition,
    this.country,
    this.timeLimit,
    this.autoReply,
    this.userRegisteredBefore,
    this.paymentMethod,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.coinType,
    this.paymentMethods,
    this.user,
    this.giftCard,
  });

  factory P2PGiftCardAd.fromJson(Map<String, dynamic> json) => P2PGiftCardAd(
        id: json["id"],
        uid: json["uid"],
        userId: json["user_id"],
        giftCardId: json["gift_card_id"],
        paymentCurrencyType: json["payment_currency_type"],
        currencyType: json["currency_type"],
        price: json["price"],
        amount: json["amount"],
        termsCondition: json["terms_condition"],
        country: json["country"],
        timeLimit: json["time_limit"],
        autoReply: json["auto_reply"],
        userRegisteredBefore: json["user_registered_before"],
        paymentMethod: json["payment_method"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        coinType: json["coin_type"],
        // paymentMethods: json["payment_methods"] == null ? null : List<P2pPaymentInfo>.from(json["payment_methods"].map((x) => P2pPaymentInfo.fromJson(x))),
        paymentMethods: json["payment_methods"] == null ? null : List<DynamicBank>.from(json["payment_methods"].map((x) => DynamicBank.fromJson(x))),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        giftCard: json["gift_card"] == null ? null : GiftCard.fromJson(json["gift_card"]),
      );

  Map<String, dynamic> toJson() => {
        "gift_card_id": giftCardId,
        "uid": uid,
        "payment_currency_type": paymentCurrencyType,
        "currency_type": currencyType,
        "price": price,
        "status": status,
        "payment_method[]": paymentMethodUidList,
        "country[]": countryList,
        "time_limit": timeLimit,
        "terms_condition": termsCondition,
      };
}

class P2PGiftCardOrder {
  int? id;
  String? uid;
  int? sellerId;
  int? buyerId;
  int? pGiftCardId;
  int? paymentCurrencyType;
  String? currencyType;
  double? price;
  double? amount;
  int? paymentTime;
  DateTime? paymentExpiredTime;
  String? paymentMethodId;
  String? paymentSleep;
  int? status;
  int? isReported;
  dynamic reportedUser;
  int? paymentStatus;
  int? isQueue;
  dynamic transactionId;
  dynamic adminNote;
  dynamic whoCancelled;
  int? isSuccess;
  int? buyerFeedbackType;
  String? buyerFeedback;
  int? sellerFeedbackType;
  String? sellerFeedback;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? orderId;
  String? statusName;
  P2pGiftCard? pGiftCard;
  P2PGiftCardFeedback? feedback;

  P2PGiftCardOrder({
    this.id,
    this.uid,
    this.sellerId,
    this.buyerId,
    this.pGiftCardId,
    this.paymentCurrencyType,
    this.currencyType,
    this.price,
    this.amount,
    this.paymentTime,
    this.paymentExpiredTime,
    this.paymentMethodId,
    this.paymentSleep,
    this.status,
    this.isReported,
    this.reportedUser,
    this.paymentStatus,
    this.isQueue,
    this.transactionId,
    this.adminNote,
    this.whoCancelled,
    this.isSuccess,
    this.buyerFeedbackType,
    this.buyerFeedback,
    this.sellerFeedbackType,
    this.sellerFeedback,
    this.createdAt,
    this.updatedAt,
    this.orderId,
    this.statusName,
    this.pGiftCard,
    this.feedback,
  });

  factory P2PGiftCardOrder.fromJson(Map<String, dynamic> json) => P2PGiftCardOrder(
        id: json["id"],
        uid: json["uid"],
        sellerId: json["seller_id"],
        buyerId: json["buyer_id"],
        pGiftCardId: json["p_gift_card_id"],
        paymentCurrencyType: json["payment_currency_type"],
        currencyType: json["currency_type"],
        price: makeDouble(json["price"]),
        amount: makeDouble(json["amount"]),
        paymentTime: json["payment_time"],
        paymentExpiredTime: json["payment_expired_time"] == null ? null : DateTime.parse(json["payment_expired_time"]),
        // paymentExpiredTime: json["payment_expired_time"] == null ? null : stringToDate(json["payment_expired_time"], format: "yyyy-MM-dd"),
        paymentMethodId: json["payment_method_id"],
        paymentSleep: json["payment_sleep"],
        status: json["status"],
        isReported: json["is_reported"],
        reportedUser: json["reported_user"],
        paymentStatus: json["payment_status"],
        isQueue: json["is_queue"],
        transactionId: json["transaction_id"],
        adminNote: json["admin_note"],
        whoCancelled: json["who_cancelled"],
        isSuccess: json["is_success"],
        buyerFeedbackType: json["buyer_feedback_type"],
        buyerFeedback: json["buyer_feedback"],
        sellerFeedbackType: json["seller_feedback_type"],
        sellerFeedback: json["seller_feedback"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        orderId: json["order_id"],
        statusName: json["status_name"],
        pGiftCard: json["p_gift_card"] == null ? null : P2pGiftCard.fromJson(json["p_gift_card"]),
        feedback: json["feedback"] == null ? null : P2PGiftCardFeedback.fromJson(json["feedback"]),
      );
}

class P2pGiftCard {
  int? id;
  int? giftCardId;
  GiftCard? giftCard;

  P2pGiftCard({this.id, this.giftCardId, this.giftCard});

  factory P2pGiftCard.fromJson(Map<String, dynamic> json) => P2pGiftCard(
        id: json["id"],
        giftCardId: json["gift_card_id"],
        giftCard: json["gift_card"] == null ? null : GiftCard.fromJson(json["gift_card"]),
      );
}

class P2PGiftCardOrderDetails {
  P2PGiftCardOrder? order;
  int? userType;
  User? userBuyer;
  User? userSeller;
  List<ChatMessage>? chatMessages;
  // P2pPaymentInfo? paymentMethods;
  DynamicBank? paymentMethods;
  DateTime? currentTime;
  int? dueMinute;
  P2PDispute? dispute;
  String? whoDispute;

  P2PGiftCardOrderDetails({
    this.order,
    this.userType,
    this.userBuyer,
    this.userSeller,
    this.chatMessages,
    this.paymentMethods,
    this.currentTime,
    this.dueMinute,
    this.dispute,
    this.whoDispute,
  });

  factory P2PGiftCardOrderDetails.fromJson(Map<String, dynamic> json) => P2PGiftCardOrderDetails(
        order: json["order"] == null ? null : P2PGiftCardOrder.fromJson(json["order"]),
        userType: json["user_type"],
        userBuyer: json["user_buyer"] == null ? null : User.fromJson(json["user_buyer"]),
        userSeller: json["user_seller"] == null ? null : User.fromJson(json["user_seller"]),
        chatMessages: json["chat_messages"] == null ? null : List<ChatMessage>.from(json["chat_messages"].map((x) => ChatMessage.fromJson(x))),
        // paymentMethods: json["payment_methods"] == null ? null : P2pPaymentInfo.fromJson(json["payment_methods"]),
        paymentMethods: json["payment_methods"] == null ? null : DynamicBank.fromJson(json["payment_methods"]),
        currentTime: json["current_time"] == null ? null : DateTime.parse(json["current_time"]),
        dueMinute: json["due_minute"],
        dispute: json["dispute"] == null ? null : P2PDispute.fromJson(json["dispute"]),
        whoDispute: json["who_dispute"],
      );
}

class P2PGiftCardFeedback {
  int? id;
  int? orderId;
  int? userId;
  int? toUserId;
  String? feedback;
  int? feedbackType;
  DateTime? createdAt;
  DateTime? updatedAt;

  P2PGiftCardFeedback({
    this.id,
    this.orderId,
    this.userId,
    this.toUserId,
    this.feedback,
    this.feedbackType,
    this.createdAt,
    this.updatedAt,
  });

  factory P2PGiftCardFeedback.fromJson(Map<String, dynamic> json) => P2PGiftCardFeedback(
        id: json["id"],
        orderId: json["order_id"],
        userId: json["user_id"],
        toUserId: json["to_user_id"],
        feedback: json["feedback"],
        feedbackType: json["feedback_type"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );
}
