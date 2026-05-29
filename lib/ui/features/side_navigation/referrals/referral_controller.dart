import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/models/referral.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class SimpleReward {
  final int? id;
  final int? traderUserId;
  final String? tradeType;
  final double? tradeVolume;
  final double? exchangeFee;
  final double? commissionRate;
  final double? rewardAmount;
  final String? status;
  final DateTime? createdAt;

  SimpleReward({
    this.id,
    this.traderUserId,
    this.tradeType,
    this.tradeVolume,
    this.exchangeFee,
    this.commissionRate,
    this.rewardAmount,
    this.status,
    this.createdAt,
  });

  factory SimpleReward.fromJson(Map<String, dynamic> json) {
    return SimpleReward(
      id:             json['id'] as int?,
      traderUserId:   json['trader_user_id'] as int?,
      tradeType:      json['trade_type'] as String?,
      tradeVolume:    _toDouble(json['trade_volume']),
      exchangeFee:    _toDouble(json['exchange_fee']),
      commissionRate: _toDouble(json['commission_rate']),
      rewardAmount:   _toDouble(json['reward_amount']),
      status:         json['status'] as String?,
      createdAt:      json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class ReferralController extends GetxController {
  Rx<ReferralData> referralData = ReferralData().obs;
  var rewards      = <SimpleReward>[].obs;
  var isWithdrawing = false.obs;

  static const String _baseUrl = 'https://api.trapix.com/api/simple-referral';

  void getReferralData() {
    showLoadingDialog();
    APIRepository().getReferralApp().then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final data = ReferralData.fromJson(resp.data);
        referralData.value = data;
        final userId = data.user?.id;
        if (userId != null) {
          _fetchSimpleReferralData(userId);
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  Future<void> _fetchSimpleReferralData(int userId) async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/stats?user_id=$userId')),
        http.get(Uri.parse('$_baseUrl/network?user_id=$userId')),
        http.get(Uri.parse('$_baseUrl/rewards?user_id=$userId')),
      ]);

      // ── stats ──────────────────────────────────────────────────────────────
      final statsResp = results[0];
      if (statsResp.statusCode == 200) {
        final json = jsonDecode(statsResp.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final d = json['data'] as Map<String, dynamic>;
          referralData.value = ReferralData(
            user:                 referralData.value.user,
            referrals:            referralData.value.referrals,
            url:                  d['referral_link'] as String? ?? referralData.value.url,
            referralLink:         d['referral_link'] as String? ?? referralData.value.referralLink,
            referralCode:         d['referral_code'] as String? ?? referralData.value.referralCode,
            totalReward:          _toDouble(d['total_earned'])     ?? referralData.value.totalReward,
            countReferrals:       _toInt(d['total_referrals'])     ?? referralData.value.countReferrals,
            pendingBalance:       _toDouble(d['pending_balance'])  ?? referralData.value.pendingBalance,
            activeReferrals:      _toInt(d['active_referrals'])    ?? referralData.value.activeReferrals,
            commissionPercentage: _toDouble(d['commission'])       ?? referralData.value.commissionPercentage,
            feePercentage:        _toDouble(d['fee_percentage'])   ?? referralData.value.feePercentage,
          );
        }
      }

      // ── network members ────────────────────────────────────────────────────
      final networkResp = results[1];
      if (networkResp.statusCode == 200) {
        final json = jsonDecode(networkResp.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final list = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
          referralData.value = ReferralData(
            user:                 referralData.value.user,
            url:                  referralData.value.url,
            referralLink:         referralData.value.referralLink,
            referralCode:         referralData.value.referralCode,
            totalReward:          referralData.value.totalReward,
            countReferrals:       referralData.value.countReferrals,
            pendingBalance:       referralData.value.pendingBalance,
            activeReferrals:      referralData.value.activeReferrals,
            commissionPercentage: referralData.value.commissionPercentage,
            feePercentage:        referralData.value.feePercentage,
            referrals:            list.map((m) => Referral.fromJson(m)).toList(),
          );
        }
      }

      // ── rewards history ────────────────────────────────────────────────────
      final rewardsResp = results[2];
if (rewardsResp.statusCode == 200) {
        final json = jsonDecode(rewardsResp.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final list = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
          rewards.value = list.map((m) => SimpleReward.fromJson(m)).toList();
          print('=== FIRST REWARD tradeType: ${rewards.isNotEmpty ? rewards.first.tradeType : "empty"} ===');
        }
      }
    } catch (_) {
      // silently fail — existing data from getReferralApp() is already shown
    }
  }

  Future<void> withdrawToWallet() async {
    if ((referralData.value.pendingBalance ?? 0) <= 0) {
      showToast("No pending rewards to withdraw");
      return;
    }

    final userId = referralData.value.user?.id;
    if (userId == null) {
      showToast("User ID not found");
      return;
    }

    isWithdrawing.value = true;
    showLoadingDialog();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/withdraw-to-wallet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      hideLoadingDialog();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          showToast("Rewards withdrawn to your Rewards Wallet!");
          getReferralData();
        } else {
          showToast(json['message'] as String? ?? "Withdrawal failed");
        }
      } else {
        showToast("Something went wrong");
      }
    } catch (err) {
      hideLoadingDialog();
      showToast(err.toString());
    } finally {
      isWithdrawing.value = false;
    }
  }

  void copyReferralLink() {
    final link = referralData.value.referralLink ?? referralData.value.url ?? '';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      "Copied",
      "Referral link copied!",
      backgroundColor: const Color(0xFFD7FF00),
      colorText: const Color(0xFF111111),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
