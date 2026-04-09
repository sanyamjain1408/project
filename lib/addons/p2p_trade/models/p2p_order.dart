import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import 'p2p_settings.dart';

class P2PMyOrdersSettings {
  List<P2PCoin>? coins;

  P2PMyOrdersSettings({this.coins});

  factory P2PMyOrdersSettings.fromJson(Map<String, dynamic> json) => P2PMyOrdersSettings(
        coins: json["coins"] == null ? null : List<P2PCoin>.from(json["coins"].map((x) => P2PCoin.fromJson(x))),
      );
}

class P2POrder {
  int? id;
  String? uid;
  String? orderId;
  int? buyerId;
  int? sellerId;
  int? buyerWalletId;
  int? sellerWalletId;
  int? sellId;
  int? buyId;
  String? coinType;
  String? currency;
  double? rate;
  double? amount;
  double? price;
  double? sellerFees;
  double? buyerFees;
  double? sellerFeesPercentage;
  double? buyerFeesPercentage;
  int? status;
  int? isReported;
  int? paymentStatus;
  int? isQueue;
  String? paymentId;
  String? paymentSleep;
  String? transactionId;
  int? paymentTime;
  DateTime? paymentExpiredTime;
  String? adminNote;
  int? whoOpened;
  int? whoCancelled;
  int? isSuccess;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? buyerFeedbackType;
  String? buyerFeedback;
  int? sellerFeedbackType;
  String? sellerFeedback;

  P2POrder({
    this.id,
    this.uid,
    this.orderId,
    this.buyerId,
    this.sellerId,
    this.buyerWalletId,
    this.sellerWalletId,
    this.sellId,
    this.buyId,
    this.coinType,
    this.currency,
    this.rate,
    this.amount,
    this.price,
    this.sellerFees,
    this.buyerFees,
    this.sellerFeesPercentage,
    this.buyerFeesPercentage,
    this.status,
    this.isReported,
    this.paymentStatus,
    this.isQueue,
    this.paymentId,
    this.paymentSleep,
    this.transactionId,
    this.paymentTime,
    this.paymentExpiredTime,
    this.adminNote,
    this.whoOpened,
    this.whoCancelled,
    this.isSuccess,
    this.createdAt,
    this.updatedAt,
    this.buyerFeedbackType,
    this.buyerFeedback,
    this.sellerFeedbackType,
    this.sellerFeedback,
  });

  factory P2POrder.fromJson(Map<String, dynamic> json) => P2POrder(
        id: json["id"],
        uid: json["uid"],
        orderId: json["order_id"],
        buyerId: json["buyer_id"],
        sellerId: json["seller_id"],
        buyerWalletId: json["buyer_wallet_id"],
        sellerWalletId: json["seller_wallet_id"],
        sellId: json["sell_id"],
        buyId: json["buy_id"],
        coinType: json["coin_type"],
        currency: json["currency"],
        rate: makeDouble(json["rate"]),
        amount: makeDouble(json["amount"]),
        price: makeDouble(json["price"]),
        sellerFees: makeDouble(json["seller_fees"]),
        buyerFees: makeDouble(json["buyer_fees"]),
        sellerFeesPercentage: makeDouble(json["seller_fees_percentage"]),
        buyerFeesPercentage: makeDouble(json["buyer_fees_percentage"]),
        status: json["status"],
        isReported: json["is_reported"],
        paymentStatus: json["payment_status"],
        isQueue: json["is_queue"],
        paymentId: json["payment_id"],
        paymentSleep: json["payment_sleep"],
        transactionId: json["transaction_id"],
        paymentTime: json["payment_time"],
        paymentExpiredTime: json["payment_expired_time"] == null ? null : DateTime.parse(json["payment_expired_time"]),
        adminNote: json["admin_note"],
        whoOpened: json["who_opened"],
        whoCancelled: json["who_cancelled"],
        isSuccess: json["is_success"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        buyerFeedbackType: json["buyer_feedback_type"],
        buyerFeedback: json["buyer_feedback"],
        sellerFeedbackType: json["seller_feedback_type"],
        sellerFeedback: json["seller_feedback"],
      );
}

class P2POrderDetails {
  P2POrder? order;
  P2PDispute? dispute;
  dynamic dueMinute;
  int? userType;
  User? userBuyer;
  User? userSeller;
  int? totalTrade;
  double? completionRate;
  // P2pPaymentInfo? paymentMethods;
  DynamicBank? paymentMethod;
  List<ChatMessage>? chatMessages;
  DateTime? currentTime;
  String? whoDispute;

  P2POrderDetails({
    this.order,
    this.dispute,
    this.dueMinute,
    this.userType,
    this.userBuyer,
    this.userSeller,
    this.totalTrade,
    this.completionRate,
    this.paymentMethod,
    this.chatMessages,
    this.currentTime,
    this.whoDispute
  });

  factory P2POrderDetails.fromJson(Map<String, dynamic> json) => P2POrderDetails(
        order: json["order"] == null ? null : P2POrder.fromJson(json["order"]),
        dispute: json["dispute"] == null ? null : (json["dispute"] is Map<String, dynamic> ? P2PDispute.fromJson(json["dispute"]) : null),
        dueMinute: json["due_minute"],
        userType: json["user_type"],
        whoDispute: json["who_dispute"],
        userBuyer: json["user_buyer"] == null ? null : User.fromJson(json["user_buyer"]),
        userSeller: json["user_seller"] == null ? null : User.fromJson(json["user_seller"]),
        totalTrade: json["total_trade"],
        completionRate: makeDouble(json["completion_rate"]),
        // paymentMethods: json["payment_methods"] == null ? null : P2pPaymentInfo.fromJson(json["payment_methods"]),
        paymentMethod: json["payment_method"] == null ? null : DynamicBank.fromJson(json["payment_method"]),
        chatMessages: json["chat_messages"] == null ? null : List<ChatMessage>.from(json["chat_messages"].map((x) => ChatMessage.fromJson(x))),
        currentTime: json["current_time"] == null ? null : DateTime.parse(json["current_time"]),
      );
}

class ChatMessage {
  int? id;
  int? senderId;
  int? receiverId;
  int? orderId;
  int? disputeId;
  String? message;
  dynamic file;
  int? seen;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? filePath;
  String? senderImageLink;
  int? userId;
  String? receiverImageLink;
  User? receiver;
  User? user;

  ChatMessage({
    this.id,
    this.senderId,
    this.receiverId,
    this.orderId,
    this.disputeId,
    this.message,
    this.file,
    this.seen,
    this.createdAt,
    this.updatedAt,
    this.filePath,
    this.senderImageLink,
    this.userId,
    this.receiverImageLink,
    this.receiver,
    this.user,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json["id"],
        senderId: json["sender_id"],
        receiverId: json["receiver_id"],
        orderId: json["order_id"],
        disputeId: json["dispute_id"],
        message: json["message"],
        file: json["file"],
        seen: json["seen"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        filePath: json["file_path"],
        senderImageLink: json["sender_image_link"],
        userId: json["user_id"],
        receiverImageLink: json["receiver_image_link"],
        receiver: json["receiver"] == null ? null : User.fromJson(json["receiver"]),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );
}

class P2PDispute {
  int? id;
  String? uid;
  int? orderId;
  int? userId;
  int? reportedUser;
  String? reasonHeading;
  String? details;
  String? image;
  int? status;
  dynamic updatedBy;
  dynamic assignedAdmin;
  dynamic expiredAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  P2PDispute({
    this.id,
    this.uid,
    this.orderId,
    this.userId,
    this.reportedUser,
    this.reasonHeading,
    this.details,
    this.image,
    this.status,
    this.updatedBy,
    this.assignedAdmin,
    this.expiredAt,
    this.createdAt,
    this.updatedAt,
  });

  factory P2PDispute.fromJson(Map<String, dynamic> json) => P2PDispute(
        id: json["id"],
        uid: json["uid"],
        orderId: json["order_id"],
        userId: json["user_id"],
        reportedUser: json["reported_user"],
        reasonHeading: json["reason_heading"],
        details: json["details"],
        image: json["image"],
        status: json["status"],
        updatedBy: json["updated_by"],
        assignedAdmin: json["assigned_admin"],
        expiredAt: json["expired_at"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );
}
