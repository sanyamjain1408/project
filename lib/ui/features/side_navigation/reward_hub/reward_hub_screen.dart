import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/landing/landing_controller.dart';
import 'package:tradexpro_flutter/ui/features/root/prefetch_service.dart';

const _kBg    = Color(0xFF0A0B0D);
const _kCard  = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF111111);
const _kGreen = Color(0xFFCCFF00);
const _kMuted = Color(0xFF555555);
const _kCyan  = Color(0xFF2EE8C8);
const _kPurple = Color(0xFFa78bfa);
const _base   = 'https://api.trapix.com';

class RewardHubScreen extends StatefulWidget {
  const RewardHubScreen({super.key});
  @override
  State<RewardHubScreen> createState() => _RewardHubScreenState();
}

class _RewardHubScreenState extends State<RewardHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  List<dynamic> _tasks     = [];
  Map<String, dynamic> _myRewards = {};
  String? _error;

  String get _token => GetStorage().read(PreferenceKey.accessToken) ?? '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    if (Get.isRegistered<PrefetchService>()) {
      final svc = PrefetchService.to;
      if (svc.rewardTasks.isNotEmpty) {
        _tasks = List.from(svc.rewardTasks);
        _myRewards = svc.myRewards.value ?? {};
        _loading = false;
      }
    }
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<void> _load() async {
    setState(() { if (_tasks.isEmpty) _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_base/api/v1/rewards/tasks'), headers: _headers),
        http.get(Uri.parse('$_base/api/v1/rewards/my-rewards'), headers: _headers),
      ]);
      final t = jsonDecode(results[0].body);
      final r = jsonDecode(results[1].body);
      if (mounted) {
        final tasks = (t['data'] ?? []) as List;
        final rewards = (r['data'] ?? {}) as Map<String, dynamic>;
        setState(() { _tasks = tasks; _myRewards = rewards; _loading = false; });
        if (Get.isRegistered<PrefetchService>()) {
          PrefetchService.to.rewardTasks.assignAll(tasks);
          PrefetchService.to.myRewards.value = rewards;
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _post(String path, Map<String, dynamic> body, {String? successMsg}) async {
    try {
      final res = await http.post(Uri.parse('$_base$path'),
          headers: _headers, body: jsonEncode(body));
      final data = jsonDecode(res.body);
      final ok = data['success'] == true;
      _snack(data['message'] ?? (ok ? 'Done!' : 'Failed'), ok);
      if (ok) _load();
    } catch (_) { _snack('Request failed', false); }
  }

  void _snack(String msg, bool ok) => Get.snackbar('', msg,
    backgroundColor: (ok ? _kGreen : Colors.red).withOpacity(0.12),
    colorText: ok ? _kGreen : Colors.red,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(12),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        scrolledUnderElevation: 0,
        surfaceTintColor: _kBg,
        title: const Text('Reward Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: _kGreen,
          unselectedLabelColor: _kMuted,
          indicatorColor: _kGreen,
          indicatorWeight: 2,
          tabs: const [Tab(text: 'Daily Tasks'), Tab(text: 'My Rewards')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _error != null ? _buildErr() : TabBarView(controller: _tab, children: [_buildTasks(), _buildMyRewards()]),
    ),
  );

  Widget _buildErr() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('Failed to load', style: TextStyle(color: Colors.white)),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: _load,
      style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.black),
      child: const Text('Retry')),
  ]));

  // ── TASKS TAB ──────────────────────────────────────────────────────────────
  Widget _buildTasks() {
    if (_tasks.isEmpty) return const Center(child: Text('No tasks available', style: TextStyle(color: _kMuted)));
    return RefreshIndicator(onRefresh: _load, color: _kGreen, child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Complete tasks and earn USDT & coupon rewards',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 16),
        ..._tasks.map(_taskCard),
      ],
    ));
  }

  Widget _taskCard(dynamic t) {
    final e        = t['enrollment'] as Map<String, dynamic>?;
    final status   = e?['status'] ?? '';
    final progress = ((e?['progress']) ?? 0.0) is int
        ? (e?['progress'] as int).toDouble()
        : (e?['progress'] ?? 0.0) as double;
    final target   = _toDouble(t['target_amount']) > 0 ? _toDouble(t['target_amount']) : 1.0;
    final pct      = (progress / target).clamp(0.0, 1.0);
    final type     = t['task_type'] ?? '';
    final isKyc    = type == 'kyc_completion';
    final rewardAmt = _toDouble(t['reward_amount']);

    final typeColor = type == 'futures_trade' ? const Color(0xFFF0B90B)
        : type == 'deposit' ? const Color(0xFF00C853)
        : isKyc ? _kPurple : const Color(0xFF2196F3);

    final typeLabel = {'spot_trade': 'Spot Trading', 'futures_trade': 'Futures Trading',
      'deposit': 'Deposit', 'register': 'Register', 'custom': 'Task',
      'kyc_completion': 'KYC Verification'}[type] ?? type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Wrap(spacing: 6, children: [
            _pill(typeLabel, typeColor),
            if (t['is_daily'] == true) _pill('Daily', _kGreen),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1),
              border: Border.all(color: _kGreen.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text('${_fmtAmt(rewardAmt)} USDT',
                style: const TextStyle(color: _kGreen, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(t['reward_type'] == 'usdt' ? 'cash reward' : (t['title'] ?? ''),
                style: const TextStyle(color: _kMuted, fontSize: 9)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Text(t['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        if ((t['description'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(t['description'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],
        if (t['end_date'] != null) ...[
          const SizedBox(height: 6),
          Text('Ends: ${t['end_date'].toString().substring(0, 10)}', style: const TextStyle(color: _kMuted, fontSize: 11)),
        ],
        if (isKyc && status != 'claimed') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kPurple.withOpacity(0.08),
              border: Border.all(color: _kPurple.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status == 'completed' ? '✅ KYC Verified — claim your reward!' : 'Complete your KYC verification to unlock this reward.',
              style: const TextStyle(color: _kPurple, fontSize: 12),
            ),
          ),
        ],
        if ((status == 'enrolled' || status == 'completed') && !isKyc) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progress', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            Text('${progress.toStringAsFixed(2)} / ${target.toStringAsFixed(0)} USDT',
              style: const TextStyle(color: _kCyan, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct, minHeight: 6,
              backgroundColor: _kCard2, valueColor: const AlwaysStoppedAnimation(_kGreen))),
        ],
        const SizedBox(height: 12),
        if (status == 'claimed')
          _btn('✓ Claimed', null, bg: Colors.green.withOpacity(0.15), fg: Colors.green)
        else if (status == 'completed')
          _btn('Claim Reward →', () => _post('/api/v1/rewards/claim', {'task_id': t['id']}), bg: _kGreen, fg: Colors.black)
        else if (status == 'enrolled')
          _btn(isKyc ? '⏳ Waiting for KYC Approval' : 'Enrolled — Complete Task', null,
            bg: isKyc ? _kPurple.withOpacity(0.1) : Colors.white.withOpacity(0.06),
            fg: isKyc ? _kPurple : _kMuted)
        else
          _btn(isKyc ? 'Start KYC →' : 'Enroll →',
            () => _post('/api/v1/rewards/enroll', {'task_id': t['id']})),
      ]),
    );
  }

  // ── MY REWARDS TAB ─────────────────────────────────────────────────────────
  Widget _buildMyRewards() {
    final coupons   = (_myRewards['coupons']  as List?) ?? [];
    final history   = (_myRewards['history']  as List?) ?? [];
    final balance   = _toDouble(_myRewards['withdrawable_balance']);
    final earned    = _toDouble(_myRewards['total_earned']);
    final withdrawn = _toDouble(_myRewards['total_withdrawn']);

    return RefreshIndicator(onRefresh: _load, color: _kGreen, child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Text('Token Rewards', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('${balance.toStringAsFixed(2)} USDT',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            Text('Withdrawable Balance', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('Total Earned', '${earned.toStringAsFixed(2)} USDT'),
              Container(width: 1, height: 30, color: Colors.white12),
              _stat('Withdrawn', '${withdrawn.toStringAsFixed(2)} USDT'),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        if (coupons.isNotEmpty) ...[
          const Text('Coupons', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...coupons.map(_couponCard),
          const SizedBox(height: 16),
        ],

        if (history.isNotEmpty) ...[
          const Text('Claim History', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...history.map(_historyRow),
        ],

        if (coupons.isEmpty && history.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('No rewards yet — complete tasks to earn!',
              style: TextStyle(color: _kMuted), textAlign: TextAlign.center)),
          ),
      ],
    ));
  }

  Widget _couponCard(dynamic c) {
    final isFutures  = c['coupon_type'] == 'coupon_futures';
    final value      = _toDouble(c['coupon_value']);
    final isUsed     = c['status'] == 'used';
    final label      = (c['coupon_label'] ?? '') as String;
    final isReferral = label.contains('Referral');
    final color      = isFutures ? _kCyan : _kGreen;

    final displayLabel = (label.isNotEmpty && label != '${value.toStringAsFixed(0)} USDT')
        ? label : isFutures ? 'Futures Bonus Coupon' : 'Spot Bonus Coupon';
    final subLabel = isFutures ? 'Futures Position Airdrop' : 'Spot Deduction Coupon';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isFutures ? const Color(0xFF0A1F1F) : const Color(0xFF0F1A07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [
        Container(
          width: 72, height: 90,
          decoration: BoxDecoration(
            color: isFutures ? const Color(0xFF0D2E2E) : const Color(0xFF1A2E0D),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_fmtAmt(value), style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 2),
            Text('USDT', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(subLabel, style: const TextStyle(color: _kMuted, fontSize: 11)),
            if (c['expires_at'] != null) ...[
              const SizedBox(height: 3),
              Text('Valid until ${c['expires_at'].toString().substring(0, 10)}',
                style: const TextStyle(color: _kMuted, fontSize: 10)),
            ],
          ]),
        )),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: isUsed
            ? const Text('Used', style: TextStyle(color: _kMuted, fontSize: 12))
            : GestureDetector(
                onTap: () => _post('/api/v1/rewards/use-coupon', {'coupon_id': c['id']}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                  child: const Text('Use', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
        ),
      ]),
    );
  }

  Widget _historyRow(dynamic h) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(h['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        if (h['claimed_at'] != null)
          Text(h['claimed_at'].toString().substring(0, 10), style: const TextStyle(color: _kMuted, fontSize: 11)),
      ])),
      Text('+${_toDouble(h['reward_amount']).toStringAsFixed(2)} USDT',
        style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
    ]),
  );

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _btn(String label, VoidCallback? onTap, {Color bg = _kCard2, Color fg = Colors.white}) =>
    GestureDetector(onTap: onTap, child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
    ));

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
  ]);

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _fmtAmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
