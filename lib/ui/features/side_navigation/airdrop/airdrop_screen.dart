import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';

const _kBase = 'https://api.trapix.com';
const _lime = Color(0xFFCCFF00);
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _grey = Color(0xFF888888);
const _border = Color(0xFF2A2A2A);

// ─────────────────────────── helpers ──────────────────────────────────────────
String get _uid {
  try {
    return gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';
  } catch (_) {
    return '';
  }
}

Future<Map<String, dynamic>> _get(String path) async {
  final res = await http.get(Uri.parse('$_kBase$path'));
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _post(String path, Map body) async {
  final res = await http.post(
    Uri.parse('$_kBase$path'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// ─────────────────────────── countdown ────────────────────────────────────────
class _CountdownText extends StatefulWidget {
  final int initialSeconds;
  const _CountdownText(this.initialSeconds);
  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late int _secs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secs = widget.initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secs = (_secs - 1).clamp(0, 999999));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _h => (_secs ~/ 3600).toString().padLeft(2, '0');
  String get _m => ((_secs % 3600) ~/ 60).toString().padLeft(2, '0');
  String get _s => (_secs % 60).toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_h}h : ${_m}m : ${_s}s',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ─────────────────────────── airdrop list ─────────────────────────────────────
class AirdropScreen extends StatefulWidget {
  const AirdropScreen({super.key});

  @override
  State<AirdropScreen> createState() => _AirdropScreenState();
}

class _AirdropScreenState extends State<AirdropScreen> {
  List<dynamic> _airdrops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _get('/api/airdrops?user_id=$_uid');
      if (mounted) setState(() => _airdrops = data['data'] ?? []);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: Get.back,
        ),
        title: const Text(
          'Airdrop Campaigns',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : _airdrops.isEmpty
              ? _empty()
              : RefreshIndicator(
                  color: _lime,
                  backgroundColor: _card,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _airdrops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _AirdropCard(
                      airdrop: _airdrops[i],
                      onTap: () => Get.to(() => AirdropDetailScreen(airdropId: _airdrops[i]['id'].toString())),
                    ),
                  ),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icons/airdrop.png', width: 64, height: 64, color: _grey),
          const SizedBox(height: 16),
          const Text('No Active Airdrops', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Check back soon for upcoming campaigns', style: TextStyle(color: _grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────── airdrop card ─────────────────────────────────────
class _AirdropCard extends StatelessWidget {
  final dynamic airdrop;
  final VoidCallback onTap;
  const _AirdropCard({required this.airdrop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double reward = double.tryParse(airdrop['reward_amount']?.toString() ?? '0') ?? 0;
    final int total = (airdrop['total_slots'] ?? 0) as int;
    final int claimed = (airdrop['claimed_slots'] ?? 0) as int;
    final int slotsLeft = (airdrop['slots_left'] ?? 0) as int;
    final double progress = total > 0 ? (claimed / total).clamp(0.0, 1.0) : 0;
    final bool isActive = airdrop['is_active'] == true || airdrop['is_active'] == 1;
    final String coin = airdrop['coin_type'] ?? '';
    final int secsLeft = (airdrop['seconds_left'] ?? 0) as int;
    final String? banner = airdrop['banner_image'];
    final String? claimStatus = airdrop['participant']?['claim_status'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banner != null && banner.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  '$_kBase/storage/$banner',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, e) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _lime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _lime),
                        ),
                        child: Text(coin, style: const TextStyle(color: _lime, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive ? _lime : _grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'LIVE' : 'ENDED',
                            style: TextStyle(color: isActive ? _lime : _grey, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    airdrop['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (airdrop['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      airdrop['description'],
                      style: const TextStyle(color: _grey, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${reward.toStringAsFixed(reward.truncateToDouble() == reward ? 0 : 2)} $coin',
                        style: const TextStyle(color: _lime, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      const Text('per user', style: TextStyle(color: _grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$claimed claimed', style: const TextStyle(color: _grey, fontSize: 11)),
                      Text('$slotsLeft left', style: const TextStyle(color: _grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: _border,
                      valueColor: const AlwaysStoppedAnimation(_lime),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: _grey, size: 13),
                      const SizedBox(width: 4),
                      _CountdownText(secsLeft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        claimStatus == 'claimed' || claimStatus == 'transferred'
                            ? '✓ Claimed'
                            : airdrop['participant'] != null
                                ? 'Continue Tasks'
                                : 'Claim Now',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── task metadata ────────────────────────────────────
const _taskMeta = {
  'twitter': {'label': 'Follow on X (Twitter)', 'desc': 'Follow @TrapixExchange on X', 'btn': 'Follow & Verify', 'social': true},
  'telegram': {'label': 'Join Telegram Channel', 'desc': 'Join our official Telegram channel', 'btn': 'Join & Verify', 'social': true},
  'instagram': {'label': 'Follow on Instagram', 'desc': 'Follow @TrapixExchange on Instagram', 'btn': 'Follow & Verify', 'social': true},
  'facebook': {'label': 'Like on Facebook', 'desc': 'Like & follow Trapix on Facebook', 'btn': 'Like & Verify', 'social': true},
  'referral': {'label': 'Refer a Friend', 'desc': 'Invite a friend who registers on Trapix', 'btn': 'Invite Friend', 'social': true},
  'email_verify': {'label': 'Verify Email', 'desc': 'Verify your Trapix email address', 'btn': 'Verify Now', 'social': false, 'hint': 'Settings → Security → Verify Email'},
  'phone_verify': {'label': 'Verify Phone Number', 'desc': 'Verify your phone number', 'btn': 'Verify Now', 'social': false, 'hint': 'Settings → Security → Phone Verification'},
  'kyc': {'label': 'Complete KYC', 'desc': 'Complete identity verification', 'btn': 'Verify Now', 'social': false, 'hint': 'Settings → KYC Verification'},
  'first_deposit': {'label': 'Make First Deposit', 'desc': 'Deposit any cryptocurrency', 'btn': 'Deposit Now', 'social': false, 'hint': 'Wallet → Deposit'},
  'first_trade': {'label': 'Place First Trade', 'desc': 'Place your first buy or sell order', 'btn': 'Trade Now', 'social': false, 'hint': 'Exchange → Spot Trading'},
  'two_fa': {'label': 'Enable 2FA', 'desc': 'Enable Google Authenticator', 'btn': 'Enable Now', 'social': false, 'hint': 'Settings → Security → Enable 2FA'},
};

// ─────────────────────────── detail screen ────────────────────────────────────
class AirdropDetailScreen extends StatefulWidget {
  final String airdropId;
  const AirdropDetailScreen({super.key, required this.airdropId});

  @override
  State<AirdropDetailScreen> createState() => _AirdropDetailScreenState();
}

class _AirdropDetailScreenState extends State<AirdropDetailScreen> {
  dynamic _airdrop;
  dynamic _participant;
  bool _loading = true;
  String? _verifying;
  bool _claiming = false;
  double _airdropBalance = 0;
  final _transferCtrl = TextEditingController();
  bool _transferring = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _transferCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _get('/api/airdrops/${widget.airdropId}?user_id=$_uid');
      final d = data['data'];
      if (mounted) {
        setState(() {
          _airdrop = d;
          _participant = d['participant'];
        });
        if (_uid.isNotEmpty && d['coin_type'] != null) _fetchBalance(d['coin_type']);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchBalance(String coinType) async {
    try {
      final data = await _get('/api/airdrops/wallet-balance?user_id=$_uid');
      final list = data['data'] as List? ?? [];
      final w = list.firstWhereOrNull((x) => x['coin_type'] == coinType);
      if (w != null && mounted) setState(() => _airdropBalance = double.tryParse(w['balance'].toString()) ?? 0);
    } catch (_) {}
  }

  bool _isTaskDone(String task) => _participant?['task_$task'] == true || _participant?['task_$task'] == 1;

  List<String> get _enabledTasks {
    final raw = _airdrop?['enabled_tasks'];
    if (raw is List) return raw.cast<String>();
    return [];
  }

  bool get _allTasksDone => _enabledTasks.isNotEmpty && _enabledTasks.every(_isTaskDone);
  int get _doneCount => _enabledTasks.where(_isTaskDone).length;

  Future<void> _verify(String task) async {
    if (_uid.isEmpty) { _toast('Please login first', err: true); return; }
    if (_isTaskDone(task)) return;
    setState(() => _verifying = task);
    try {
      final data = await _post('/api/airdrops/${widget.airdropId}/verify-task', {'user_id': _uid, 'task': task});
      if (data['status'] == true) {
        setState(() => _participant = data['data']);
        _toast('${_taskMeta[task]?['label'] ?? task} verified!');
      } else {
        _toast(data['message'] ?? 'Verification failed', err: true);
      }
    } catch (_) {
      _toast('Verification failed', err: true);
    }
    if (mounted) setState(() => _verifying = null);
  }

  Future<void> _claim() async {
    if (_uid.isEmpty) { _toast('Please login first', err: true); return; }
    setState(() => _claiming = true);
    try {
      final data = await _post('/api/airdrops/${widget.airdropId}/claim', {'user_id': _uid});
      if (data['status'] == true) {
        setState(() {
          _participant = {...(_participant ?? {}), 'claim_status': 'claimed'};
          _airdropBalance = double.tryParse(data['data']?['airdrop_balance']?.toString() ?? '0') ?? 0;
        });
        _toast('${_airdrop['reward_amount']} ${_airdrop['coin_type']} claimed!');
      } else {
        _toast(data['message'] ?? 'Claim failed', err: true);
      }
    } catch (_) {
      _toast('Claim failed', err: true);
    }
    if (mounted) setState(() => _claiming = false);
  }

  Future<void> _transfer() async {
    final amount = double.tryParse(_transferCtrl.text.trim()) ?? 0;
    if (amount <= 0 || amount > _airdropBalance) { _toast('Enter a valid amount', err: true); return; }
    setState(() => _transferring = true);
    try {
      final data = await _post('/api/airdrops/transfer-to-spot', {
        'user_id': _uid,
        'coin_type': _airdrop['coin_type'],
        'amount': amount,
      });
      if (data['status'] == true) {
        setState(() {
          _airdropBalance = double.tryParse(data['data']?['airdrop_balance']?.toString() ?? '0') ?? 0;
          _transferCtrl.clear();
        });
        _toast('$amount ${_airdrop['coin_type']} moved to Spot!');
      } else {
        _toast(data['message'] ?? 'Transfer failed', err: true);
      }
    } catch (_) {
      _toast('Transfer failed', err: true);
    }
    if (mounted) setState(() => _transferring = false);
  }

  void _toast(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: err ? const Color(0xFF5C1A1A) : const Color(0xFF1A3A0A),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(backgroundColor: _bg, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: Get.back)),
        body: const Center(child: CircularProgressIndicator(color: _lime)),
      );
    }
    if (_airdrop == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(backgroundColor: _bg, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: Get.back)),
        body: const Center(child: Text('Airdrop not found', style: TextStyle(color: _grey))),
      );
    }

    final bool claimed = _participant?['claim_status'] == 'claimed' || _participant?['claim_status'] == 'transferred';
    final double reward = double.tryParse(_airdrop['reward_amount']?.toString() ?? '0') ?? 0;
    final String coin = _airdrop['coin_type'] ?? '';
    final bool isActive = _airdrop['is_active'] == true || _airdrop['is_active'] == 1;
    final int secsLeft = (_airdrop['seconds_left'] ?? 0) as int;
    final int slotsLeft = (_airdrop['slots_left'] ?? 0) as int;
    final int claimedSlots = (_airdrop['claimed_slots'] ?? 0) as int;
    final String? banner = _airdrop['banner_image'];
    final int total = _enabledTasks.length;
    final double progress = total > 0 ? (_doneCount / total) : 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          _airdrop['title'] ?? 'Airdrop',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (banner != null && banner.isNotEmpty)
                    Image.network('$_kBase/storage/$banner', height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, e) => const SizedBox.shrink()),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _tag(coin),
                            Row(children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: isActive ? _lime : _grey, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(isActive ? 'LIVE' : 'ENDED', style: TextStyle(color: isActive ? _lime : _grey, fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(_airdrop['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        if (_airdrop['description'] != null) ...[
                          const SizedBox(height: 6),
                          Text(_airdrop['description'], style: const TextStyle(color: _grey, fontSize: 13, height: 1.5)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _statBox('${reward.toStringAsFixed(reward.truncateToDouble() == reward ? 0 : 4)} $coin', 'Reward per user', lime: true),
                            const SizedBox(width: 8),
                            _statBox(slotsLeft.toString(), 'Slots left'),
                            const SizedBox(width: 8),
                            _statBox(claimedSlots.toString(), 'Claimed'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text('Ends in: ', style: TextStyle(color: _grey, fontSize: 12)),
                            _CountdownText(secsLeft),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Progress ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('COMPLETE TASKS', style: TextStyle(color: _grey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                Text('$_doneCount/$total', style: const TextStyle(color: _lime, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: _border,
                valueColor: const AlwaysStoppedAnimation(_lime),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tasks ──────────────────────────────────────────────────────
            ..._enabledTasks.asMap().entries.map((entry) {
              final i = entry.key;
              final task = entry.value;
              final meta = _taskMeta[task] ?? {'label': task, 'desc': '', 'btn': 'Verify', 'social': false};
              final done = _isTaskDone(task);
              final isVerifying = _verifying == task;
              final prevDone = i == 0 || _isTaskDone(_enabledTasks[i - 1]);
              final locked = !prevDone && !done;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Opacity(
                  opacity: locked ? 0.4 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF0E150A) : _card,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: done ? const Color(0xFF2A3A14) : _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                          child: _taskIcon(task),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meta['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                done ? '✓ Verified' : locked ? 'Complete previous task first' : (meta['hint'] ?? meta['desc']) as String,
                                style: const TextStyle(color: _grey, fontSize: 11, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (done)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.black, size: 14),
                          )
                        else if (locked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                            child: const Text('Locked', style: TextStyle(color: _grey, fontSize: 11, fontWeight: FontWeight.w600)),
                          )
                        else if (isVerifying)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _lime))
                        else
                          GestureDetector(
                            onTap: () => _verify(task),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(8)),
                              child: Text(meta['btn'] as String, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // ── Claim ──────────────────────────────────────────────────────
            Opacity(
              opacity: _allTasksDone ? 1 : 0.4,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _lime.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOUR REWARD', style: TextStyle(color: _grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: _lime, fontWeight: FontWeight.w800),
                            children: [
                              TextSpan(text: '${reward.toStringAsFixed(reward.truncateToDouble() == reward ? 0 : 4)} ', style: const TextStyle(fontSize: 22)),
                              TextSpan(text: coin, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _allTasksDone && !claimed && !_claiming ? _claim : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: claimed ? const Color(0xFF1A3A0A) : _lime,
                        foregroundColor: claimed ? _lime : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor: claimed ? const Color(0xFF1A3A0A) : _lime.withValues(alpha: 0.3),
                        disabledForegroundColor: claimed ? _lime : Colors.black45,
                      ),
                      child: Text(
                        claimed ? '✓ Claimed' : _claiming ? 'Claiming...' : 'Claim $coin',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Airdrop Wallet (after claim) ───────────────────────────────
            if (claimed) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _lime.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Airdrop Wallet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_airdropBalance.toStringAsFixed(8), style: const TextStyle(color: _lime, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(coin, style: const TextStyle(color: _grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Transfer to Spot wallet for trading', style: TextStyle(color: _grey, fontSize: 12)),
                    if (_airdropBalance > 0) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _transferCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _bg,
                                hintText: 'Amount (max ${_airdropBalance.toStringAsFixed(8)})',
                                hintStyle: const TextStyle(color: _grey, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: _border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: _border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: _lime)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _transferCtrl.text = _airdropBalance.toString()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _lime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: _lime),
                              ),
                              child: const Text('MAX', style: TextStyle(color: _lime, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _transferring ? null : _transfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _card,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: _border),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            _transferring ? 'Transferring...' : 'Transfer to Spot Wallet →',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    if (_airdropBalance <= 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(child: Text('All funds transferred to Spot wallet', style: TextStyle(color: _grey, fontSize: 12))),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String coin) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: _lime)),
    child: Text(coin, style: const TextStyle(color: _lime, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _statBox(String val, String label, {bool lime = false}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: TextStyle(color: lime ? _lime : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _grey, fontSize: 10)),
        ],
      ),
    ),
  );

  Widget _taskIcon(String task) {
    final icons = {
      'twitter': Icons.alternate_email,
      'telegram': Icons.send,
      'instagram': Icons.camera_alt_outlined,
      'facebook': Icons.facebook,
      'referral': Icons.group_add_outlined,
      'email_verify': Icons.email_outlined,
      'phone_verify': Icons.phone_outlined,
      'kyc': Icons.badge_outlined,
      'first_deposit': Icons.account_balance_wallet_outlined,
      'first_trade': Icons.show_chart,
      'two_fa': Icons.lock_outlined,
    };
    return Icon(icons[task] ?? Icons.star_outline, color: _lime, size: 18);
  }
}
