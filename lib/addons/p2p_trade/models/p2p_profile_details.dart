import 'dart:convert';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

P2PProfileDetails p2PProfileDetailsFromJson(String str) => P2PProfileDetails.fromJson(json.decode(str));

class P2PProfileDetails {
  int? totalTrade;
  int? totalSuccessTrade;
  double? completionRate30D;
  int? firstOrderAt;
  int? userRegisterAt;
  List<P2pFeedback>? feedbackList;
  int? positive;
  int? negative;
  double? positiveFeedback;
  int? totalFeedback;
  User? user;

  P2PProfileDetails({
    this.totalTrade,
    this.totalSuccessTrade,
    this.completionRate30D,
    this.firstOrderAt,
    this.userRegisterAt,
    this.feedbackList,
    this.positive,
    this.negative,
    this.positiveFeedback,
    this.totalFeedback,
    this.user,
  });

  factory P2PProfileDetails.fromJson(Map<String, dynamic> json) => P2PProfileDetails(
        totalTrade: json["total_trade"],
        totalSuccessTrade: json["total_success_trade"],
        completionRate30D: makeDouble(json["completion_rate_30d"]),
        firstOrderAt: json["first_order_at"],
        userRegisterAt: json["user_register_at"],
        feedbackList: json["feedback_list"] == null ? null : List<P2pFeedback>.from(json["feedback_list"].map((x) => P2pFeedback.fromJson(x))),
        positive: json["positive"],
        negative: json["negative"],
        positiveFeedback: makeDouble(json["positive_feedback"]),
        totalFeedback: makeInt(json["total_feedback"]),
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );
}

class P2pFeedback {
  String? feedback;
  int? feedbackType;
  String? userName;
  String? userImg;

  P2pFeedback({this.feedback, this.feedbackType, this.userName, this.userImg});

  factory P2pFeedback.fromJson(Map<String, dynamic> json) =>
      P2pFeedback(feedback: json["feedback"], feedbackType: json["feedback_type"], userName: json["user_name"], userImg: json["user_img"]);
}
