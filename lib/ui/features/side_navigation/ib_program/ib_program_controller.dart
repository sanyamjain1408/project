import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/models/referral.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

// ─── IBStats Model ────────────────────────────────────────────────────────────
class IBStats {
  String? referralLink;
  String? referralCode;
  int? totalReferrals;
  double? totalEarned;
  String? tierName;
  int? activeReferrals;
  double? pendingBalance;

  IBStats({
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

  static const String _baseUrl = 'https://api.trapix.com/api/referral';

  // ── Step 1: load IB stats + network (mirrors ReferralController exactly) ───
  void getIBData() {
    showLoadingDialog();
    APIRepository().getReferralApp().then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final data = ReferralData.fromJson(resp.data);

        // Map ReferralData → IBStats
        stats.value = IBStats(
          referralLink:    data.referralLink ?? data.url,
          referralCode:    data.referralCode ?? data.user?.affiliate?.code,
          totalReferrals:  data.countReferrals ?? 0,
          totalEarned:     data.totalReward ?? 0.0,
          tierName:        data.select,
          activeReferrals: data.activeReferrals ?? 0,
          pendingBalance:  data.pendingBalance ?? 0.0,
        );

        // Map referrals list → networkMembers
        networkMembers.value = (data.referrals ?? []).map((r) {
          final joinedAt = r.joiningDate != null
              ? "${r.joiningDate!.year}-"
                "${r.joiningDate!.month.toString().padLeft(2, '0')}-"
                "${r.joiningDate!.day.toString().padLeft(2, '0')}"
              : '';
          return <String, dynamic>{
            'name':         r.fullName ?? '',
            'email':        r.email    ?? '',
            'joined_at':    joinedAt,
            'trade_volume': r.tradeVolume ?? 0.0,
            'you_earned':   r.youEarned   ?? 0.0,
          };
        }).toList();

        // Step 2: also fetch /stats and /tree to get backend data
        // (user?.id is the correct field — ReferralData has no userId)
        final userId = data.user?.id;
        if (userId != null) {
          _fetchStatsAndTree(userId);
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  // ── GET /api/referral/stats?user_id=X  +  GET /api/referral/tree?user_id=X ─
  Future<void> _fetchStatsAndTree(int userId) async {
    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('$_baseUrl/stats?user_id=$userId'),
          headers: _headers(),
        ),
        http.get(
          Uri.parse('$_baseUrl/tree?user_id=$userId'),
          headers: _headers(),
        ),
      ]);

      // ── /stats response ──────────────────────────────────────────────────
      final statsResp = results[0];
      if (statsResp.statusCode == 200) {
        final json = jsonDecode(statsResp.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final d = json['data'] as Map<String, dynamic>;
          stats.value = IBStats(
            referralLink:    d['referral_link']    as String? ?? stats.value.referralLink,
            referralCode:    d['referral_code']    as String? ?? stats.value.referralCode,
            totalReferrals:  _parseInt(d['total_referrals'])  ?? stats.value.totalReferrals,
            totalEarned:     _parseDouble(d['total_earned'])  ?? stats.value.totalEarned,
            tierName:        d['tier_name']         as String? ?? stats.value.tierName,
            activeReferrals: _parseInt(d['active_referrals']) ?? stats.value.activeReferrals,
            pendingBalance:  _parseDouble(d['pending_balance']) ?? stats.value.pendingBalance,
          );
        }
      }

      // ── /tree response ───────────────────────────────────────────────────
      final treeResp = results[1];
      if (treeResp.statusCode == 200) {
        final json = jsonDecode(treeResp.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final list =
              (json['data']?['direct_referrals'] as List<dynamic>?) ?? [];
          if (list.isNotEmpty) {
            networkMembers.value = list.map((r) {
              final m       = r as Map<String, dynamic>;
              final rawDate = m['joined_at'] as String?;
              String joinedAt = '';
              if (rawDate != null && rawDate.isNotEmpty) {
                final d = DateTime.tryParse(rawDate);
                if (d != null) {
                  joinedAt =
                      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                }
              }
              return <String, dynamic>{
                'name':         m['name']         ?? '',
                'email':        m['email']        ?? '',
                'joined_at':    joinedAt,
                'trade_volume': _toDouble(m['trade_volume']),
                'you_earned':   _toDouble(m['you_earned']),
              };
            }).toList();
          }
        }
      }
    } catch (_) {
      // silently fail — app already has data from getReferralApp()
    }
  }

  // ── POST /api/referral/withdraw-to-wallet ──────────────────────────────────
  Future<void> withdrawToWallet() async {
    final balance = stats.value.pendingBalance ?? 0.0;
    if (balance <= 0) {
      showToast("No pending rewards to withdraw");
      return;
    }

    isWithdrawing.value = true;
    showLoadingDialog();

    try {
      // Get userId — same pattern as getIBData()
      final resp = await APIRepository().getReferralApp();
      hideLoadingDialog();

      if (!resp.success) {
        showToast(resp.message);
        return;
      }

      final data   = ReferralData.fromJson(resp.data);
      final userId = data.user?.id; // ← correct field, no userId on ReferralData

      if (userId == null) {
        showToast("User ID not found");
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/withdraw-to-wallet'),
        headers: _headers(),
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          showToast("IB Rewards withdrawn to your Rewards Wallet!");
          getIBData(); // refresh
        } else {
          showToast(json['message'] ?? "Withdrawal failed");
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  Map<String, String> _headers() => {'Content-Type': 'application/json'};

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    return double.tryParse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0.0;
  }
}