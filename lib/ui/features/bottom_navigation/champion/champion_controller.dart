import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ApiCompetition {
  final int id;
  final String title;
  final String? description;
  final String? status;
  final String? bannerImage;
  final String? startAt;
  final String? endAt;
  final String? pairRestriction;
  final String? restrictedCoin;
  final String? restrictedPair;
  final double? minVolume;
  final int participantsCount;
  final bool joined;
  final int? myRank;
  final double? myVolume;
  final double? myDeposit;
  final double? totalDeposited;
  final String? availableBonus;
  final int? nextBonus;
  final List<ApiPrize> prizes;
  final List<ApiRule> rules;
  final List<ApiVolumeReward> volumeRewards;

  ApiCompetition({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.bannerImage,
    this.startAt,
    this.endAt,
    this.pairRestriction,
    this.restrictedCoin,
    this.restrictedPair,
    this.minVolume,
    this.participantsCount = 0,
    this.joined = false,
    this.myRank,
    this.myVolume,
    this.myDeposit,
    this.totalDeposited,
    this.availableBonus,
    this.nextBonus,
    this.prizes = const [],
    this.rules = const [],
    this.volumeRewards = const [],
  });

  factory ApiCompetition.fromJson(Map<String, dynamic> j) {
    return ApiCompetition(
      id: _parseInt(j['id']) ?? 0,
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      status: j['status'] as String?,
      bannerImage: j['banner_image'] as String?,
      startAt: j['start_at'] as String?,
      endAt: j['end_at'] as String?,
      pairRestriction: j['pair_restriction'] as String?,
      restrictedCoin: j['restricted_coin'] as String?,
      restrictedPair: j['restricted_pair'] as String?,
      minVolume: _parseDouble(j['min_volume']),
      participantsCount: _parseInt(j['participants_count']) ?? 0,
      joined: j['joined'] == true || j['joined'] == 1,
      myRank: _parseInt(j['my_rank']),
      myVolume: _parseDouble(j['my_volume']),
      myDeposit: _parseDouble(j['my_deposit']),
      totalDeposited: _parseDouble(j['total_deposited']),
      availableBonus: j['available_bonus'] as String?,
      nextBonus: _parseInt(j['next_bonus']),
      prizes: (j['prizes'] as List<dynamic>? ?? [])
          .map((p) => ApiPrize.fromJson(p as Map<String, dynamic>))
          .toList(),
      rules: (j['rules'] as List<dynamic>? ?? [])
          .map((r) => ApiRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      volumeRewards: (j['volume_rewards'] as List<dynamic>? ?? [])
          .map((v) => ApiVolumeReward.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiPrize {
  final int id;
  final int rank;
  final String? rankLabel;
  final String prizeDescription;
  final String? prizeType;

  ApiPrize({
    required this.id,
    required this.rank,
    this.rankLabel,
    required this.prizeDescription,
    this.prizeType,
  });

  factory ApiPrize.fromJson(Map<String, dynamic> j) {
    return ApiPrize(
      id: _parseInt(j['id']) ?? 0,
      rank: _parseInt(j['rank']) ?? 0,
      rankLabel: j['rank_label'] as String?,
      prizeDescription: j['prize_description'] as String? ?? '',
      prizeType: j['prize_type'] as String?,
    );
  }
}

class ApiRule {
  final int? id;
  final String title;
  final String? description;
  final List<String> bullets;
  final String? badge;
  final String? footer;

  ApiRule({
    this.id,
    required this.title,
    this.description,
    this.bullets = const [],
    this.badge,
    this.footer,
  });

  factory ApiRule.fromJson(Map<String, dynamic> j) {
    final rawBullets = j['bullets'] as List<dynamic>?
        ?? j['points'] as List<dynamic>?
        ?? [];
    return ApiRule(
      id: _parseInt(j['id']),
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      bullets: rawBullets.map((b) => b.toString()).toList(),
      badge: j['badge'] as String?,
      footer: j['footer'] as String?,
    );
  }
}

class ApiVolumeReward {
  final String volume;
  final String reward;

  ApiVolumeReward({required this.volume, required this.reward});

  factory ApiVolumeReward.fromJson(Map<String, dynamic> j) {
    return ApiVolumeReward(
      volume: j['volume'] as String? ?? j['trading_volume'] as String? ?? '',
      reward: j['reward'] as String? ?? j['reward_amount'] as String? ?? '',
    );
  }
}

class ApiLeaderboardEntry {
  final int? userId;
  final String nickname;
  final int rank;
  final double totalVolume;
  final double spotVolume;
  final double futureVolume;
  final String? prize;
  final String? volReward;
  final String? prizeStatus;

  ApiLeaderboardEntry({
    this.userId,
    required this.nickname,
    required this.rank,
    required this.totalVolume,
    this.spotVolume = 0,
    this.futureVolume = 0,
    this.prize,
    this.volReward,
    this.prizeStatus,
  });

  factory ApiLeaderboardEntry.fromJson(Map<String, dynamic> j) {
    final prizeStatus = j['prize_status'] as String?;
    return ApiLeaderboardEntry(
      userId: _parseInt(j['user_id']),
      nickname: j['nickname'] as String?
          ?? j['uid'] as String?
          ?? j['username'] as String?
          ?? j['name'] as String?
          ?? 'Unknown',
      rank: _parseInt(j['rank']) ?? _parseInt(j['position']) ?? 0,
      totalVolume: _parseDouble(j['total_volume'])
          ?? _parseDouble(j['volume'])
          ?? _parseDouble(j['trading_volume'])
          ?? 0,
      spotVolume: _parseDouble(j['spot_volume']) ?? 0,
      futureVolume: _parseDouble(j['future_volume']) ?? 0,
      prize: j['prize'] as String?,
      volReward: j['vol_reward'] as String? ?? j['volume_reward'] as String?,
      // 'none' means not yet distributed — treat as null
      prizeStatus: (prizeStatus == null || prizeStatus == 'none') ? null : prizeStatus,
    );
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

// ─── Deposit History Model ─────────────────────────────────────────────────────

class ApiDepositHistory {
  final String date;
  final String amount;
  final String coin;
  final String status;
  final String bonus;

  ApiDepositHistory({
    required this.date,
    required this.amount,
    required this.coin,
    required this.status,
    required this.bonus,
  });

  factory ApiDepositHistory.fromJson(Map<String, dynamic> j) {
    return ApiDepositHistory(
      date: j['date'] as String? ?? j['created_at'] as String? ?? '',
      amount: j['amount']?.toString() ?? '0',
      coin: j['coin'] as String? ?? j['currency'] as String? ?? 'USDT',
      status: j['status'] as String? ?? '',
      bonus: j['bonus']?.toString() ?? j['reward']?.toString() ?? '0',
    );
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class ChampionController extends GetxController {
  static const _base = 'https://api.trapix.com/api';

  var competitions     = <ApiCompetition>[].obs;
  var isLoadingList    = false.obs;
  var isLoadingDetail  = false.obs;
  var isJoining        = false.obs;

  var currentDetail    = Rxn<ApiCompetition>();
  var leaderboard      = <ApiLeaderboardEntry>[].obs;
  var depositHistory   = <ApiDepositHistory>[].obs;
  var isLoadingHistory = false.obs;

  // ── Fetch competitions list ───────────────────────────────────────────────
  Future<void> fetchCompetitions() async {
    isLoadingList.value = true;
    try {
      final userId = gUserRx.value.id;
      final url = '$_base/competitions?user_id=$userId';
      final resp = await http.get(Uri.parse(url), headers: _headers());
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final raw = json['data'];
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List;
        } else if (raw is Map && raw['competitions'] is List) {
          list = raw['competitions'] as List<dynamic>;
        }
        competitions.value = list
            .map((e) => ApiCompetition.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // debugPrint('fetchCompetitions error: $e');
    } finally {
      isLoadingList.value = false;
    }
  }

  // ── Fetch single competition detail ──────────────────────────────────────
  Future<void> fetchDetail(int id) async {
    isLoadingDetail.value = true;
    currentDetail.value = null;
    leaderboard.value = [];
    try {
      final userId = gUserRx.value.id;
      final url = '$_base/competitions/$id?user_id=$userId';
      final resp = await http.get(Uri.parse(url), headers: _headers());
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final d = json['data'];
        if (d != null) {
          currentDetail.value = ApiCompetition.fromJson(d as Map<String, dynamic>);
        }
      }
      await fetchLeaderboard(id);
    } catch (e) {
      // debugPrint('fetchDetail error: $e');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ── Fetch leaderboard ─────────────────────────────────────────────────────
  Future<void> fetchLeaderboard(int id) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/competitions/$id/leaderboard'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final raw = json['data'];
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = (raw['data'] as List<dynamic>?) ??
              (raw['leaderboard'] as List<dynamic>?) ??
              [];
        }
        final entries = list
            .asMap()
            .entries
            .map((entry) {
              final e = ApiLeaderboardEntry.fromJson(entry.value as Map<String, dynamic>);
              // If rank is 0/missing from API, use list index + 1
              if (e.rank == 0) {
                return ApiLeaderboardEntry(
                  userId: e.userId,
                  nickname: e.nickname,
                  rank: entry.key + 1,
                  totalVolume: e.totalVolume,
                  spotVolume: e.spotVolume,
                  futureVolume: e.futureVolume,
                  prize: e.prize,
                  volReward: e.volReward,
                  prizeStatus: e.prizeStatus,
                );
              }
              return e;
            })
            .toList();
        // Sort by rank ascending
        entries.sort((a, b) => a.rank.compareTo(b.rank));
        leaderboard.value = entries;
      }
    } catch (e) {
      // debugPrint('fetchLeaderboard error: $e');
    }
  }

  // ── Fetch deposit history ─────────────────────────────────────────────────
  Future<void> fetchDepositHistory(int competitionId) async {
    isLoadingHistory.value = true;
    depositHistory.value = [];
    try {
      final userId = gUserRx.value.id;
      final resp = await http.get(
        Uri.parse('$_base/competitions/$competitionId/deposit-history?user_id=$userId'),
        headers: _headers(),
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final raw = json['data'];
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = (raw['data'] as List<dynamic>?) ?? (raw['deposits'] as List<dynamic>?) ?? [];
        }
        depositHistory.value = list
            .map((e) => ApiDepositHistory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // debugPrint('fetchDepositHistory error: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ── Join competition ──────────────────────────────────────────────────────
  Future<bool> joinCompetition(int id) async {
    isJoining.value = true;
    try {
      final userId = gUserRx.value.id;
      final resp = await http.post(
        Uri.parse('$_base/competitions/$id/join'),
        headers: _headers(),
        body: jsonEncode({'user_id': userId}),
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final msg = json['message'] as String? ?? '';
        final isSuccess = json['success'] == true
            || json['status'] == 'success'
            || json['status'] == true
            || (json['success'] == null && json['status'] == null && msg.isNotEmpty && !msg.toLowerCase().contains('fail') && !msg.toLowerCase().contains('error') && !msg.toLowerCase().contains('already'));
        if (isSuccess) {
          Get.snackbar(
            'Success',
            msg.isNotEmpty ? msg : 'Joined successfully!',
            backgroundColor: const Color(0xFFCCFF00),
            colorText: Colors.black,
          );
          return true;
        }
        Get.snackbar('Error', msg.isNotEmpty ? msg : 'Failed to join',
            backgroundColor: Colors.red, colorText: Colors.white);
      } else if (resp.statusCode == 422 || resp.statusCode == 400) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final msg = json['message'] as String? ?? 'Failed to join';
        Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Something went wrong',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      // debugPrint('joinCompetition error: $e');
    } finally {
      isJoining.value = false;
    }
    return false;
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
}

// ─── Shared parse helpers ─────────────────────────────────────────────────────
int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}
