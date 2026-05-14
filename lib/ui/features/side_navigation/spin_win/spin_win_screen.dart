import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';

const _kApiBase = 'https://api.trapix.com/api';
const _lime = Color(0xFFCCFF00);
const _bg = Color(0xFF0A0A0A);
const _card = Color(0xFF111111);
const _card2 = Color(0xFF1A1A1A);
const _border = Color(0xFF2A2A2A);
const _grey = Color(0xFF888888);

// ─────────────────────────── helpers ──────────────────────────────────────────
String get _uid {
  try {
    return gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';
  } catch (_) {
    return '';
  }
}

// Win messages — UI layer only, tier names come from backend
const _winMessages = {
  'lose':    '😢 Better luck next time! Try again',
  'small':   '🎉 Congrats! Reward credited to your wallet',
  'token':   '🎁 Bonus tokens received!',
  'medium':  '🔥 Great win! Reward credited',
  'jackpot': '🚀 JACKPOT! Huge reward credited',
};

// ─────────────────────────── spinning wheel ───────────────────────────────────
// Continuously rotates like the drawer's RotatingSpinner (same image, same style)
class _SpinWheel extends StatefulWidget {
  const _SpinWheel();
  @override
  State<_SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<_SpinWheel> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Image.asset('assets/icons/spinner.png', fit: BoxFit.contain),
    );
  }
}

// ─────────────────────────── main screen ──────────────────────────────────────
class SpinWinScreen extends StatefulWidget {
  const SpinWinScreen({super.key});

  @override
  State<SpinWinScreen> createState() => _SpinWinScreenState();
}

class _SpinWinScreenState extends State<SpinWinScreen> {
  // ── State from backend ──────────────────────────────────────────────────────
  bool _loading = true;
  bool _spinning = false;
  int _spinsLeft = 0;
  int _spinsUsedToday = 0;
  int _cooldownMs = 0;
  double _cumVolume = 0;
  int _maxSpinsPerDay = 10;                  // from backend: max_spins_per_day
  List<Map<String, dynamic>> _depositTiers = []; // from backend: deposit_tiers
  List<Map<String, dynamic>> _spotSteps = [];    // from backend: spot_milestones
  List<Map<String, dynamic>> _faqs = [];         // from backend: faqs

  dynamic _lastReward;
  String? _message;
  bool _showResult = false;
  int? _expandedFaq;
  Timer? _cooldownTimer;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Fetch spin status — all config comes from here ──────────────────────────
  Future<void> _fetchStatus() async {
    if (_uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_kApiBase/spin/status?user_id=$_uid'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // debugPrint('══════════════ SPIN STATUS RESPONSE ══════════════');
        // debugPrint(const JsonEncoder.withIndent('  ').convert(data));
        // debugPrint('═══════════════════════════════════════════════════');

        if (data['success'] == true && mounted) {
          setState(() {
            _spinsLeft        = (data['bonus_spins'] ?? 0) as int;
            _spinsUsedToday   = (data['spins_used_today'] ?? 0) as int;
            _cooldownMs       = (data['cooldown_ms'] ?? 0) as int;
            _cumVolume        = (data['cumulative_volume'] ?? 0.0).toDouble();

            // ── Dynamic config fields ────────────────────────────────────────
            _maxSpinsPerDay   = (data['max_per_day'] ?? data['max_spins_per_day'] ?? 10) as int;

            // deposit_tiers — expected: [{range: "$1–$20", spins: 1}, ...]
            final rawTiers = data['deposit_tiers'] ?? data['deposit_spin_tiers'] ?? [];
            if (rawTiers is List && rawTiers.isNotEmpty) {
              _depositTiers = rawTiers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            } else {
              // fallback only if backend sends nothing
              _depositTiers = [
                {'range': '\$1 – \$20',   'spins': 1},
                {'range': '\$21 – \$50',  'spins': 2},
                {'range': '\$51 – \$100', 'spins': 3},
                {'range': '\$101 – \$200','spins': 5},
                {'range': '\$201 – \$500','spins': 7},
                {'range': '\$500+',       'spins': 10},
              ];
            }

            // spot_milestones — expected: [{target: 500, spins: 1}, ...]
            final rawSteps = data['spot_milestones']  ??
                             data['trading_steps']    ??
                             data['trading_milestones'] ?? [];
            if (rawSteps is List && rawSteps.isNotEmpty) {
              _spotSteps = rawSteps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            } else {
              _spotSteps = [
                {'target': 500,   'spins': 1},
                {'target': 1000,  'spins': 2},
                {'target': 2000,  'spins': 4},
                {'target': 5000,  'spins': 10},
                {'target': 10000, 'spins': 20},
                {'target': 20000, 'spins': 50},
                {'target': 30000, 'spins': 75},
                {'target': 50000, 'spins': 100},
              ];
            }

            // faqs — expected: [{q: "...", a: "..."}, ...]
            final rawFaqs = data['faqs'] ?? data['faq'] ?? [];
            if (rawFaqs is List && rawFaqs.isNotEmpty) {
              _faqs = rawFaqs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            } else {
              _faqs = [
                {'q': 'How are spin rewards credited?',           'a': 'Rewards are credited instantly to your Trapix wallet as soon as the spin completes.'},
                {'q': 'How many spins do I get as a new user?',   'a': 'Every new Trapix user receives 4 free welcome spins. After using them, you earn 1 free spin every 24 hours.'},
                {'q': 'What is the daily spin limit?',            'a': 'You can use a maximum of $_maxSpinsPerDay spins per 24-hour window.'},
                {'q': 'How do deposit spins work?',               'a': 'Every time you make a deposit, you receive bonus spins based on the USD value deposited.'},
                {'q': 'What are the prizes?',                     'a': 'Prizes include USDT, USDC, TRX, DOGE, PEPE, BONK and POL.'},
                {'q': 'What are the odds?',                       'a': 'Better Luck Next Time: 40%. Small prizes: 24%. Token prizes: 29%. Medium: 1.5%. Jackpot: 0.5%. All outcomes are server-side.'},
              ];
            }
          });
          _startCooldownTimer();
        }
      }
    } catch (e) {
      // debugPrint('Spin status error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    if (_cooldownMs <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _cooldownMs = (_cooldownMs - 1000).clamp(0, 999999999));
      if (_cooldownMs <= 0) {
        _cooldownTimer?.cancel();
        _fetchStatus();
      }
    });
  }

  // ── Spin ────────────────────────────────────────────────────────────────────
  Future<void> _spin() async {
    if (_spinning || _spinsLeft <= 0 || _uid.isEmpty || _loading) return;
    if (_spinsUsedToday >= _maxSpinsPerDay) {
      setState(() => _message = '🚫 Daily limit reached! Max $_maxSpinsPerDay spins per 24 hours.');
      return;
    }

    setState(() { _spinning = true; _showResult = false; _message = null; });

    try {
      final res = await http.post(
        Uri.parse('$_kApiBase/spin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _uid}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // debugPrint('══════════════ SPIN RESULT ══════════════');
      // debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      // debugPrint('═════════════════════════════════════════');

      if (data['success'] == true) {
        final reward = data['reward'] as Map<String, dynamic>;
        final int winIndex = (reward['slot_index'] ?? reward['win_index'] ?? 0) as int;

        final double segmentAngle = (2 * pi / 12) * winIndex;
        final double fullSpins = 8 * 2 * pi;
        final double needed = (segmentAngle - (_currentAngle % (2 * pi)) + 2 * pi) % (2 * pi);
        _currentAngle = _currentAngle + fullSpins + needed;

        // Wait for wheel to spin visually (continuous rotation shows spinning)
        await Future.delayed(const Duration(seconds: 5));

        if (mounted) {
          setState(() {
            _lastReward     = reward;
            _showResult     = true;
            _spinsLeft      = (data['spins_remaining'] ?? _spinsLeft - 1) as int;
            _spinsUsedToday = (data['spins_used_today'] ?? _spinsUsedToday + 1) as int;
            if (data['cooldown_ms'] != null)       _cooldownMs = data['cooldown_ms'] as int;
            if (data['cumulative_volume'] != null)  _cumVolume  = (data['cumulative_volume'] as num).toDouble();
            final tier = reward['tier'] as String? ?? 'small';
            _message   = _winMessages[tier] ?? _winMessages['small'];
            _spinning  = false;
          });
          _startCooldownTimer();
        }
      } else {
        if (mounted) setState(() { _spinning = false; _message = '❌ ${data['message'] ?? 'Something went wrong'}'; });
      }
    } catch (e) {
      // debugPrint('Spin error: $e');
      if (mounted) setState(() { _spinning = false; _message = '❌ Something went wrong. Please try again.'; });
    }
  }

  String get _cooldownLabel {
    final t = _cooldownMs ~/ 1000;
    final h = (t ~/ 3600).toString().padLeft(2, '0');
    final m = ((t % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (t % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  String get _buttonLabel {
    if (_uid.isEmpty)                          return 'LOGIN TO SPIN';
    if (_loading)                              return 'LOADING...';
    if (_spinning)                             return 'SPINNING...';
    if (_spinsUsedToday >= _maxSpinsPerDay)    return 'DAILY LIMIT REACHED';
    if (_spinsLeft > 0)                        return 'SPIN & WIN  ·  $_spinsLeft LEFT';
    return 'NO SPINS LEFT';
  }

  bool get _canSpin =>
      !_spinning && _spinsLeft > 0 && _uid.isNotEmpty &&
      !_loading && _spinsUsedToday < _maxSpinsPerDay;

  // ── Build ───────────────────────────────────────────────────────────────────
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
        title: const Text('Spin & Win', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _grey),
            onPressed: _loading ? null : _fetchStatus,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                children: [
                  _buildWheelSection(),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  if (_showResult && _lastReward != null) _buildResultCard(),
                  if (_message != null && !_showResult) _buildMessage(),
                  _buildSpotMilestones(),
                  const SizedBox(height: 24),
                  _buildDepositTiers(),
                  const SizedBox(height: 24),
                  if (_faqs.isNotEmpty) _buildFaq(),
                  const SizedBox(height: 24),
                  _buildDisclaimer(),
                ],
              ),
            ),
    );
  }

  // ── Wheel section ────────────────────────────────────────────────────────────
  Widget _buildWheelSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.arrow_drop_down, color: _lime, size: 40),
          const SizedBox(height: 4),
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _lime.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 8)],
                  ),
                ),
                const _SpinWheel(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _canSpin ? _spin : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              decoration: BoxDecoration(
                gradient: _canSpin ? const LinearGradient(colors: [Color(0xFFCCFF00), Color(0xFF99CC00)]) : null,
                color: _canSpin ? null : _card2,
                borderRadius: BorderRadius.circular(50),
                boxShadow: _canSpin
                    ? [BoxShadow(color: _lime.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
                    : null,
              ),
              child: Text(
                _buttonLabel,
                style: TextStyle(
                  color: _canSpin ? Colors.black : _grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (_cooldownMs > 0 && _spinsLeft <= 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: _grey, size: 14),
                const SizedBox(width: 4),
                Text('Next spin in: $_cooldownLabel', style: const TextStyle(color: _grey, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('$_spinsLeft', 'Spins Left', Icons.refresh),
        const SizedBox(width: 10),
        _statCard('$_spinsUsedToday / $_maxSpinsPerDay', "Today's Usage", Icons.today),
        const SizedBox(width: 10),
        _statCard('\$${_cumVolume.toStringAsFixed(0)}', 'Trade Volume', Icons.show_chart),
      ],
    );
  }

  Widget _statCard(String val, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        children: [
          Icon(icon, color: _lime, size: 18),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _grey, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  // ── Result card ──────────────────────────────────────────────────────────────
  Widget _buildResultCard() {
    final tier     = _lastReward['tier'] as String? ?? 'small';
    final amount   = _lastReward['amount']?.toString() ?? '';
    final coinType = _lastReward['coin_type']?.toString() ?? '';
    final isLose   = tier == 'lose';
    final tierColors = {
      'lose': Colors.grey, 'small': const Color(0xFF26A17B),
      'token': const Color(0xFFF5A623), 'medium': const Color(0xFF00BCD4), 'jackpot': _lime,
    };
    final color = tierColors[tier] ?? _lime;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(isLose ? '😢' : '🎉', style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(isLose ? 'Better Luck Next Time!' : 'You Won!',
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          if (!isLose && amount.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('$amount $coinType',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 8),
          Text(_message ?? '', style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMessage() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
    child: Text(_message!, style: const TextStyle(color: _grey, fontSize: 13), textAlign: TextAlign.center),
  );

  // ── Spot milestones (dynamic from backend) ───────────────────────────────────
  Widget _buildSpotMilestones() {
    if (_spotSteps.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spot Trading Rewards', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Trade more → unlock bonus spins', style: TextStyle(color: _grey, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFCCFF00), Color(0xFF99CC00)]),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text('Trade Now →', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '\$${_cumVolume.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                  text: '  your trading volume',
                  style: TextStyle(color: _grey, fontSize: 11),
                ),
              ]),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: _spotSteps.asMap().entries.map((entry) {
                final i      = entry.key;
                final step   = entry.value;
                final target = (step['target'] as num).toInt();
                final spins  = (step['spins'] as num).toInt();
                final reached = _cumVolume >= target;
                return Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          '+$spins spin${spins > 1 ? 's' : ''}',
                          style: TextStyle(color: reached ? _lime : _grey, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: reached ? 22 : 16,
                          height: reached ? 22 : 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: reached ? _lime : _card2,
                            border: Border.all(color: reached ? _lime : _border, width: 2),
                          ),
                          child: reached ? const Icon(Icons.check, size: 10, color: Colors.black) : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          target >= 1000 ? '${target ~/ 1000}K' : '$target',
                          style: TextStyle(color: reached ? _lime : _grey, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (i < _spotSteps.length - 1)
                      Container(width: 28, height: 2, margin: const EdgeInsets.only(bottom: 4), color: reached ? _lime : _border),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Deposit tiers (dynamic from backend) ─────────────────────────────────────
  Widget _buildDepositTiers() {
    if (_depositTiers.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deposit Spin Rewards', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Deposit any coin → get instant bonus spins', style: TextStyle(color: _grey, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFCCFF00), Color(0xFF99CC00)]),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text('Deposit →', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Expanded(child: Text('DEPOSIT (USD)', style: TextStyle(color: _grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))),
                Text('BONUS SPINS', style: TextStyle(color: _grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
          ..._depositTiers.asMap().entries.map((entry) {
            final i     = entry.key;
            final tier  = entry.value;
            final isTop = i == _depositTiers.length - 1;
            final range = tier['range']?.toString() ?? tier['amount_range']?.toString() ?? '';
            final spins = (tier['spins'] as num?)?.toInt() ?? (tier['bonus_spins'] as num?)?.toInt() ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isTop ? _lime.withValues(alpha: 0.06) : Colors.transparent,
                border: const Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Text(range, style: TextStyle(color: isTop ? Colors.white : const Color(0xFFAAAAAA), fontSize: 14, fontWeight: FontWeight.w600)),
                  if (isTop) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(4)),
                      child: const Text('BEST', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                  const Spacer(),
                  Text('$spins spin${spins > 1 ? 's' : ''}',
                      style: TextStyle(color: isTop ? _lime : Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚡ ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    'Spins are granted instantly after deposit confirmation. Each deposit qualifies once per transaction.',
                    style: TextStyle(color: _grey, fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAQ (dynamic from backend or fallback) ───────────────────────────────────
  Widget _buildFaq() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequently Asked Questions',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._faqs.asMap().entries.map((entry) {
          final i     = entry.key;
          final faq   = entry.value;
          final isOpen = _expandedFaq == i;
          final q = faq['q']?.toString() ?? faq['question']?.toString() ?? '';
          final a = faq['a']?.toString() ?? faq['answer']?.toString() ?? '';
          return GestureDetector(
            onTap: () => setState(() => _expandedFaq = isOpen ? null : i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOpen ? _lime.withValues(alpha: 0.3) : _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(child: Text(q, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                        Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _lime, size: 20),
                      ],
                    ),
                  ),
                  if (isOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(a, style: const TextStyle(color: _grey, fontSize: 12, height: 1.6)),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Disclaimer ───────────────────────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️ ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IMPORTANT DISCLAIMER',
                    style: TextStyle(color: _grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(
                  'The Trapix Spin & Win program is a promotional reward feature offered at Trapix\'s sole discretion. '
                  'Maximum $_maxSpinsPerDay spins per 24-hour window applies. Rewards are non-transferable.',
                  style: const TextStyle(color: _grey, fontSize: 11, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
