import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/giveaway.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/champion_controller.dart';

const _kBase = 'https://api.trapix.com';

class PrefetchService extends GetxController {
  static PrefetchService get to => Get.find();

  // ── Spin Win ────────────────────────────────────────────────────────────────
  final spinStatus = Rxn<Map<String, dynamic>>();

  // ── Airdrop ─────────────────────────────────────────────────────────────────
  final airdropList = RxList<dynamic>([]);

  // ── Reward Hub ──────────────────────────────────────────────────────────────
  final rewardTasks    = RxList<dynamic>([]);
  final myRewards      = Rxn<Map<String, dynamic>>();

  // ── Signup Bonus ────────────────────────────────────────────────────────────
  final signupBonusStatus  = Rxn<Map<String, dynamic>>();
  final signupBonusCoupons = RxList<dynamic>([]);

  // ── Giveaway ────────────────────────────────────────────────────────────────
  final giveawayList = RxList<Giveaway>([]);

  // ── Listing ─────────────────────────────────────────────────────────────────
  final listingFormSections = RxList<dynamic>([]);

  // ── Refresh tracking ────────────────────────────────────────────────────────
  final isRefreshing = false.obs;
  Timer? _timer;

  String get _uid   => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';
  String get _token => GetStorage().read(PreferenceKey.accessToken) ?? '';
  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  @override
  void onInit() {
    super.onInit();
    fetchAll();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => fetchAll());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> fetchAll() async {
    if (_uid.isEmpty && _token.isEmpty) return;
    isRefreshing.value = true;
    await Future.wait([
      _fetchSpinStatus(),
      _fetchAirdrops(),
      _fetchRewardHub(),
      _fetchSignupBonus(),
      _fetchGiveaways(),
      _fetchListingForm(),
      _precacheChampionBanners(),
    ]);
    isRefreshing.value = false;
  }

  Future<void> _precacheChampionBanners() async {
    if (!Get.isRegistered<ChampionController>()) return;
    final comps = Get.find<ChampionController>().competitions;
    for (final comp in comps) {
      final url = comp.bannerImage;
      if (url != null && url.isNotEmpty) {
        try {
          final stream = CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
          stream.addListener(ImageStreamListener((i, s) {}, onError: (e, s) {}));
        } catch (_) {}
      }
    }
  }

  // ── Spin Win ────────────────────────────────────────────────────────────────
  Future<void> _fetchSpinStatus() async {
    if (_uid.isEmpty) return;
    try {
      final res = await http.get(Uri.parse('$_kBase/api/spin/status?user_id=$_uid'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) spinStatus.value = data;
      }
    } catch (_) {}
  }

  // ── Airdrop ─────────────────────────────────────────────────────────────────
  Future<void> _fetchAirdrops() async {
    try {
      final res = await http.get(Uri.parse('$_kBase/api/airdrops?user_id=$_uid'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['data'] ?? data['airdrops'] ?? data['result'] ?? []) as List;
        airdropList.assignAll(list);
      }
    } catch (_) {}
  }

  // ── Reward Hub ──────────────────────────────────────────────────────────────
  Future<void> _fetchRewardHub() async {
    if (_token.isEmpty) return;
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_kBase/api/v1/rewards/tasks'), headers: _authHeaders),
        http.get(Uri.parse('$_kBase/api/v1/rewards/my-rewards'), headers: _authHeaders),
      ]);
      final t = jsonDecode(results[0].body) as Map<String, dynamic>;
      final r = jsonDecode(results[1].body) as Map<String, dynamic>;
      rewardTasks.assignAll((t['data'] ?? []) as List);
      myRewards.value = (r['data'] ?? {}) as Map<String, dynamic>;
    } catch (_) {}
  }

  // ── Signup Bonus ────────────────────────────────────────────────────────────
  Future<void> _fetchSignupBonus() async {
    if (_uid.isEmpty) return;
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_kBase/api/signup-bonus/status?user_id=$_uid')),
        http.get(Uri.parse('$_kBase/api/simple-referral/network?user_id=$_uid')),
      ]);
      final s = jsonDecode(results[0].body) as Map<String, dynamic>;
      final n = jsonDecode(results[1].body) as Map<String, dynamic>;
      if (s['success'] == true) signupBonusStatus.value = s['data'] as Map<String, dynamic>?;
      if (n['success'] == true) signupBonusCoupons.assignAll((n['data'] ?? []) as List);
    } catch (_) {}
  }

  // ── Giveaway ────────────────────────────────────────────────────────────────
  Future<void> _fetchGiveaways() async {
    try {
      final r = await APIRepository().getGiveaways();
      if (r.success && r.data != null) {
        final raw = r.data is List ? r.data : (r.data['data'] ?? []);
        giveawayList.assignAll((raw as List).map((e) => Giveaway.fromJson(e)));
      }
    } catch (_) {}
  }

  // ── Listing Form ─────────────────────────────────────────────────────────────
  Future<void> _fetchListingForm() async {
    try {
      final res = await http.get(Uri.parse('$_kBase/api/v1/listing-form'), headers: _authHeaders);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final sections = (data['data'] ?? data['sections'] ?? []) as List;
        listingFormSections.assignAll(sections);
      }
    } catch (_) {}
  }
}
