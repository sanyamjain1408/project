import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/referral.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

// ─── IBStats Model ────────────────────────────────────────────────────────────
class IBStats {
  int? userId;
  String? referralLink;
  String? referralCode;
  int? totalReferrals;
  double? totalEarned;
  String? tierName;
  int? activeReferrals;
  double? pendingBalance;

  IBStats({
    this.userId,
    this.referralLink,
    this.referralCode,
    this.totalReferrals,
    this.totalEarned,
    this.tierName,
    this.activeReferrals,
    this.pendingBalance,
  });
}

// ─── Controller ───────────────────────────────────────────────────────────────
class IBController extends GetxController {
  var stats          = IBStats().obs;
  var networkMembers = <Map<String, dynamic>>[].obs;
  var isWithdrawing  = false.obs;

  static const String _apiBase = 'https://api.trapix.com/api';

  // ── Load initial data then fetch from /referral/stats + /referral/tree ─────
  void getIBData() {
    showLoadingDialog();
    APIRepository().getReferralApp().then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final data = ReferralData.fromJson(resp.data);

        // Seed with whatever getReferralApp returns
        stats.value = IBStats(
          userId:         data.user?.id,
          referralLink:   data.referralLink ?? data.url,
          referralCode:   data.referralCode ?? data.user?.affiliate?.code,
          totalReferrals: data.countReferrals ?? 0,
          totalEarned:    data.totalReward ?? 0.0,
          tierName:       data.select,
          activeReferrals: data.activeReferrals ?? 0,
          pendingBalance: data.pendingBalance ?? 0.0,
        );

        final userId = data.user?.id;
        if (userId != null) {
          // Same two endpoints the website uses
          _fetchReferralStats(userId);
          _fetchReferralTree(userId);
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  // ── GET /referral/stats ───────────────────────────────────────────────────
  // Website: fetch(`https://api.trapix.com/api/referral/stats?user_id=${userId}`)
  // Returns: referral_link, referral_code, total_referrals, total_earned,
  //          tier_name, active_referrals, pending_balance
  Future<void> _fetchReferralStats(int userId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_apiBase/referral/stats?user_id=$userId'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final d = json['data'] as Map<String, dynamic>;
          stats.value = IBStats(
            userId:         stats.value.userId,
            referralLink:   d['referral_link']  as String? ?? stats.value.referralLink,
            referralCode:   d['referral_code']  as String? ?? stats.value.referralCode,
            totalReferrals: _parseInt(d['total_referrals'])    ?? stats.value.totalReferrals,
            totalEarned:    _parseDouble(d['total_earned'])    ?? stats.value.totalEarned,
            tierName:       d['tier_name']       as String?    ?? stats.value.tierName,
            activeReferrals: _parseInt(d['active_referrals']) ?? stats.value.activeReferrals,
            pendingBalance: _parseDouble(d['pending_balance']) ?? stats.value.pendingBalance,
          );
        }
      }
    } catch (_) {}
  }

  // ── GET /referral/tree ────────────────────────────────────────────────────
  // Website: fetch(`https://api.trapix.com/api/referral/tree?user_id=${userId}`)
  // Returns: data.direct_referrals[] with name, email, joined_at,
  //          trade_volume, you_earned, their_referrals
  Future<void> _fetchReferralTree(int userId) async {
    try {
      final resp = await http.get(
        Uri.parse('$_apiBase/referral/tree?user_id=$userId'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final directReferrals =
              (json['data']['direct_referrals'] as List<dynamic>?) ?? [];
          networkMembers.value = directReferrals.map((r) {
            return <String, dynamic>{
              'name':            r['name']      ?? '',
              'email':           r['email']     ?? '',
              'joined_at':       r['joined_at'] ?? '',
              'trade_volume':    _parseDouble(r['trade_volume'])   ?? 0.0,
              'you_earned':      _parseDouble(r['you_earned'])     ?? 0.0,
              'their_referrals': _parseInt(r['their_referrals'])   ?? 0,
            };
          }).toList();
        }
      }
    } catch (_) {}
  }

  // ── POST /referral/withdraw-to-wallet ─────────────────────────────────────
  // Website: fetch("https://api.trapix.com/api/referral/withdraw-to-wallet", ...)
  Future<void> withdrawToWallet() async {
    final balance = stats.value.pendingBalance ?? 0.0;
    if (balance <= 0) {
      showToast("No pending rewards to withdraw");
      return;
    }

    final userId = stats.value.userId;
    if (userId == null) {
      showToast("User ID not found");
      return;
    }

    isWithdrawing.value = true;
    showLoadingDialog();

    try {
      final response = await http.post(
        Uri.parse('$_apiBase/referral/withdraw-to-wallet'),
        headers: _headers(),
        body: jsonEncode({'user_id': userId}),
      );
      hideLoadingDialog();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          showToast("IB Rewards withdrawn to your Rewards Wallet!");
          getIBData();
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

  void copyIBLink() {
    final link = stats.value.referralLink ?? '';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      "Copied",
      "IB referral link copied!",
      backgroundColor: const Color(0xFFD7FF00),
      colorText: const Color(0xFF111111),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Map<String, String> _headers() {
    final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
    final type  = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
    return {
      'Content-Type':  'application/json',
      'Accept':        'application/json',
      'Authorization': '$type $token',
    };
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
