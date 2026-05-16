import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
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

String get _uid {
  try {
    return gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';
  } catch (_) {
    return '';
  }
}

const List<double> _kSegmentStopAngles = [
  5.0,
  335.0,
  305.0,
  275.0,
  245.0,
  215.0,
  185.0,
  155.0,
  125.0,
  95.0,
  65.0,
  35.0,
];

double _segmentTargetDeg(int n) =>
    (n >= 0 && n < _kSegmentStopAngles.length) ? _kSegmentStopAngles[n] : 0.0;

const _winMessages = {
  'lose': '😢 Better luck next time! Try again',
  'small': '🎉 Congrats! Reward credited to your wallet',
  'token': '🎁 Bonus tokens received!',
  'medium': '🔥 Great win! Reward credited',
  'jackpot': '🚀 JACKPOT! Huge reward credited',
};

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFCCFF00)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF7AAA00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final sx = size.width / 32;
    final sy = size.height / 44;

    final path = Path()
      ..moveTo(4 * sx, 0)
      ..lineTo(28 * sx, 0)
      ..lineTo(16 * sx, 32 * sy)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    canvas.drawCircle(Offset(16 * sx, 38 * sy), 5 * sy, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpinWinScreen extends StatefulWidget {
  const SpinWinScreen({super.key});

  @override
  State<SpinWinScreen> createState() => _SpinWinScreenState();
}

class _SpinWinScreenState extends State<SpinWinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  Animation<double> _wheelAnim = const AlwaysStoppedAnimation(0.0);
  double _totalTurns = 0.0;

  late ConfettiController _confettiCtrl;

  bool _loading = true;
  bool _spinning = false;
  int _spinsLeft = 0;
  int _spinsUsedToday = 0;
  int _cooldownMs = 0;
  double _cumVolume = 0;
  int _maxSpinsPerDay = 10;
  List<Map<String, dynamic>> _depositTiers = [];
  List<Map<String, dynamic>> _spotSteps = [];
  List<Map<String, dynamic>> _faqs = [];

  dynamic _lastReward;
  String? _message;
  bool _showResult = false;
  bool _showResultOverlay = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _fetchStatus();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _wheelCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    if (_uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_kApiBase/spin/status?user_id=$_uid'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && mounted) {
          setState(() {
            _spinsLeft = (data['bonus_spins'] ?? 0) as int;
            _spinsUsedToday = (data['spins_used_today'] ?? 0) as int;
            _cooldownMs = (data['cooldown_ms'] ?? 0) as int;
            _cumVolume = (data['cumulative_volume'] ?? 0.0).toDouble();
            _maxSpinsPerDay =
                (data['max_per_day'] ?? data['max_spins_per_day'] ?? 10) as int;

            final rawTiers =
                data['deposit_tiers'] ?? data['deposit_spin_tiers'] ?? [];
            if (rawTiers is List && rawTiers.isNotEmpty) {
              _depositTiers = rawTiers
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              _depositTiers = [
                {'range': '\$1 – \$20', 'spins': 1},
                {'range': '\$21 – \$50', 'spins': 2},
                {'range': '\$51 – \$100', 'spins': 3},
                {'range': '\$101 – \$200', 'spins': 5},
                {'range': '\$201 – \$500', 'spins': 7},
                {'range': '\$500+', 'spins': 10},
              ];
            }

            final rawSteps =
                data['spot_milestones'] ??
                data['trading_steps'] ??
                data['trading_milestones'] ??
                [];
            if (rawSteps is List && rawSteps.isNotEmpty) {
              _spotSteps = rawSteps
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              _spotSteps = [
                {'target': 500, 'spins': 1},
                {'target': 1000, 'spins': 2},
                {'target': 2000, 'spins': 4},
                {'target': 5000, 'spins': 10},
                {'target': 10000, 'spins': 20},
                {'target': 20000, 'spins': 50},
                {'target': 30000, 'spins': 75},
                {'target': 50000, 'spins': 100},
              ];
            }

            final rawFaqs = data['faqs'] ?? data['faq'] ?? [];
            if (rawFaqs is List && rawFaqs.isNotEmpty) {
              _faqs = rawFaqs
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              _faqs = [
                {
                  'q': 'How long does it take for rewards to be distributed?',
                  'a':
                      'Tokens and futures bonuses are distributed in real time (a few minutes).',
                },
                {
                  'q': 'Where can I view the status of my rewards?',
                  'a':
                      'You can view the reward distribution status in your rewards history.',
                },
                {
                  'q': 'Who should I contact if I encounter any issues?',
                  'a':
                      'Please contact our customer support if you have any questions or issues.',
                },
              ];
            }
          });
          _startCooldownTimer();
        }
      }
    } catch (e) {
      // silent
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

  Future<void> _spin() async {
    if (_spinning || _spinsLeft <= 0 || _uid.isEmpty || _loading) return;
    if (_spinsUsedToday >= _maxSpinsPerDay) {
      setState(
        () => _message =
            '🚫 Daily limit reached! Max $_maxSpinsPerDay spins per 24 hours.',
      );
      return;
    }

    setState(() {
      _spinning = true;
      _showResult = false;
      _showResultOverlay = false;
      _message = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_kApiBase/spin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _uid}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final reward = data['reward'] as Map<String, dynamic>;
        final int winIndex =
            (reward['slot_index'] ?? reward['win_index'] ?? 0) as int;

        final double segmentAngle = _segmentTargetDeg(winIndex) / 360.0;
        final double currentNorm = _totalTurns % 1.0;
        double needed = (segmentAngle - currentNorm + 1.0) % 1.0;
        if (needed < 0.01) needed += 1.0;
        final double targetTurns = _totalTurns + 8.0 + needed;

        setState(() {
          _wheelAnim = Tween<double>(begin: _totalTurns, end: targetTurns)
              .animate(
                CurvedAnimation(
                  parent: _wheelCtrl,
                  curve: const Cubic(0.17, 0.67, 0.12, 0.99),
                ),
              );
          _totalTurns = targetTurns;
        });

        await _wheelCtrl.forward(from: 0.0);

        if (mounted) {
          final tier = reward['tier'] as String? ?? 'small';
          final isLose = tier == 'lose';

          setState(() {
            _lastReward = reward;
            _showResult = true;
            _showResultOverlay = true;
            _spinsLeft = (data['spins_remaining'] ?? _spinsLeft - 1) as int;
            _spinsUsedToday =
                (data['spins_used_today'] ?? _spinsUsedToday + 1) as int;
            if (data['cooldown_ms'] != null) {
              _cooldownMs = data['cooldown_ms'] as int;
            }
            if (data['cumulative_volume'] != null) {
              _cumVolume = (data['cumulative_volume'] as num).toDouble();
            }
            _message = _winMessages[tier] ?? _winMessages['small'];
            _spinning = false;
          });

          if (!isLose) {
            _confettiCtrl.play();
          }

          _startCooldownTimer();
        }
      } else {
        if (mounted) {
          setState(() {
            _spinning = false;
            _message = ' ${data['message'] ?? 'Something went wrong'}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _spinning = false;
          _message = ' Something went wrong. Please try again.';
        });
      }
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
    if (_uid.isEmpty) return 'Login to Spin';
    if (_loading) return 'Loading...';
    if (_spinning) return 'Spinning...';
    if (_spinsUsedToday >= _maxSpinsPerDay) return 'Daily Limit Reached';
    if (_spinsLeft > 0) return 'Spin & Win';
    return 'No Spins Left';
  }

  bool get _canSpin =>
      !_spinning &&
      _spinsLeft > 0 &&
      _uid.isNotEmpty &&
      !_loading &&
      _spinsUsedToday < _maxSpinsPerDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          // ── Main Content ──
          _loading
              ? const Center(child: CircularProgressIndicator(color: _lime))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.only(left: 20),
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: Get.back,
                        ),
                      ),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Spin ',
                              style: TextStyle(
                                color: Color(0xFFCCFF00),
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                                height: 40 / 30,
                              ),
                            ),
                            TextSpan(
                              text: '& ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                                height: 40 / 30,
                              ),
                            ),
                            TextSpan(
                              text: 'Win',
                              style: TextStyle(
                                color: Color(0xFFCCFF00),
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                                height: 40 / 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSpinsChip(),
                          _buildWheelSection(),
                          if (_message != null && !_showResult)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _buildMessage(),
                            ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSpotMilestones(),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildDepositTiers(),
                          ),
                          const SizedBox(height: 40),
                          if (_faqs.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildFaq(),
                            ),
                          const SizedBox(height: 35),
                        ],
                      ),
                    ],
                  ),
                ),

          // ── Result Overlay ──
          if (_showResultOverlay && _lastReward != null)
            _buildResultOverlay(),
        ],
      ),
    );
  }

  // Wheel segment definitions — index matches slot_index from the API
  static const _kSegments = [
    {'lose': true},                             // 0
    {'coin': 'USDT', 'raw': 0.1},              // 1
    {'coin': 'POL',  'raw': 5.0},              // 2
    {'coin': 'PEPE', 'raw': 5000.0},           // 3  → 5K PEPE
    {'coin': 'USDT', 'raw': 0.1},              // 4
    {'coin': 'DOGE', 'raw': 10.0},             // 5
    {'coin': 'TRX',  'raw': 5.0},              // 6
    {'coin': 'USDT', 'raw': 2.0},              // 7
    {'coin': 'BONK', 'raw': 10000.0},          // 8  → 10K BONK
    {'coin': 'USDT', 'raw': 2.0},              // 9
    {'lose': true},                             // 10
    {'coin': 'USDT', 'raw': 5.0},              // 11
  ];

  // ── Result Overlay ───────────────────────────────────────────────────────────
  Widget _buildResultOverlay() {
    final int slotIndex =
        (_lastReward['slot_index'] ?? _lastReward['win_index'] ?? -1) as int;
    final seg = (slotIndex >= 0 && slotIndex < _kSegments.length)
        ? _kSegments[slotIndex]
        : null;

    final bool isLose =
        seg?['lose'] == true ||
        (_lastReward['tier'] as String? ?? '') == 'lose';
    final String coinType =
        (seg?['coin'] as String?) ??
        (_lastReward['coin_type']?.toString() ?? '');
    final String amount = seg != null && seg['raw'] != null
        ? _formatAmount((seg['raw'] as double).toString())
        : _formatAmount(_lastReward['amount']?.toString() ?? '');

    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black.withOpacity(0.88),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Confetti (only on win) ──
            if (!isLose)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 35,
                  gravity: 0.25,
                  emissionFrequency: 0.04,
                  maxBlastForce: 25,
                  minBlastForce: 10,
                  colors: const [
                    Color(0xFFCCFF00),
                    Color(0xFF00E6FF),
                    Colors.orange,
                    Colors.pink,
                    Colors.purple,
                    Colors.red,
                    Colors.blue,
                    Colors.yellow,
                  ],
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),

            // ── Modal Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLose
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFCCFF00).withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLose
                          ? Colors.black.withOpacity(0.6)
                          : const Color(0xFFCCFF00).withOpacity(0.12),
                      blurRadius: 50,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: isLose
                    ? _buildLoseContent()
                    : _buildWinContent(amount, coinType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // POL is Polygon's renamed symbol — CDN still has it under "matic"
  static const _kCoinCdnBase =
      'https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@master/128/color';
  static const _kCdnSymbolOverride = {'pol': 'matic'};

  String _formatAmount(String raw) {
    final val = double.tryParse(raw);
    if (val == null) return raw;
    if (val >= 1000) {
      final k = val / 1000;
      return k == k.truncateToDouble()
          ? '${k.toInt()}K'
          : '${k.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    }
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'\.?0+$'), '');
  }

  Widget _buildCoinIcon(String coinType, {double size = 38}) {
    final lower = coinType.toLowerCase();
    final cdnSymbol = _kCdnSymbolOverride[lower] ?? lower;
    final networkUrl = '$_kCoinCdnBase/$cdnSymbol.png';

    Widget letterFallback() => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        coinType.isNotEmpty ? coinType[0].toUpperCase() : '?',
        style: const TextStyle(
          color: _lime,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          fontFamily: 'DMSans',
        ),
      ),
    );

    return Image.asset(
      'assets/images/$lower.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (ctx1, e1, st1) => Image.network(
        networkUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (ctx2, e2, st2) => letterFallback(),
      ),
    );
  }

  // ── Win Content ──────────────────────────────────────────────────────────────
  // amount is already formatted by the caller
  Widget _buildWinContent(String amount, String coinType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoinIcon(coinType, size: 38),
            const SizedBox(width: 10),
            Text(
              '$amount $coinType',
              style: const TextStyle(
                color: Color(0xFFCCFF00),
                fontSize: 34,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Image.asset(
          'assets/images/won.png',
          height: 72,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 22),
        const Text(
          'Claim your prize',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Claim your prize and dive into the world of Trapix.\nCome back every 24 hours to spin and unlock more rewards.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () {
            _confettiCtrl.stop();
            setState(() => _showResultOverlay = false);
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00E6FF),
                  Color(0xFFCCFF00),
                  Color(0xFF77D215),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Claim Price',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Lose Content ─────────────────────────────────────────────────────────────
  Widget _buildLoseContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('😢', style: TextStyle(fontSize: 54)),
        const SizedBox(height: 16),
        const Text(
          'Better Luck\nNext Time!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Come back every 24 hours to spin and unlock more rewards.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => setState(() => _showResultOverlay = false),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Spins chip ───────────────────────────────────────────────────────────────
  Widget _buildSpinsChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/icons/spinner.png",
              height: 25,
              width: 25,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              '$_spinsLeft Spins Available',
              style: const TextStyle(
                color: Color(0xFFCCFF00),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                height: 20 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wheel + button ───────────────────────────────────────────────────────────
  Widget _buildWheelSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Cooldown Timer (wheel ke upar, sirf tab dikhega jab spins nahi) ──
          if (_cooldownMs > 0 && _spinsLeft <= 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: _lime, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Next spin in: $_cooldownLabel',
                    style: const TextStyle(
                      color: _lime,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Wheel ──
          Container(
            width: double.infinity,
            height: 342,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 342,
                  height: 350,
                  child: AnimatedBuilder(
                    animation: _wheelCtrl,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _wheelAnim.value * 2 * pi,
                        child: Image.asset(
                          'assets/icons/spin_win.png',
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCCFF00).withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        size: const Size(42, 54),
                        painter: _ArrowPainter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Spin Button ──
          GestureDetector(
            onTap: _canSpin ? _spin : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: _canSpin
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF00E6FF),
                          Color(0xFFCCFF00),
                          Color(0xFF77D215),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      )
                    : null,
                color: _canSpin ? null : _card2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _spinsUsedToday >= _maxSpinsPerDay && _cooldownMs > 0
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _buttonLabel,
                          style: const TextStyle(
                            color: _grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                            height: 20 / 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_clock_outlined,
                              color: _lime,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Lock opens in: $_cooldownLabel',
                              style: const TextStyle(
                                color: _lime,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'DMSans',
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_canSpin) ...[
                          Image.asset(
                            "assets/icons/spinner.png",
                            height: 25,
                            width: 25,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          _buttonLabel,
                          style: TextStyle(
                            color: _canSpin ? Colors.black : _grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                            height: 20 / 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMessage() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Text(
      _message!,
      style: const TextStyle(color: _grey, fontSize: 13),
      textAlign: TextAlign.center,
    ),
  );

  // ── Spot milestones ──────────────────────────────────────────────────────────
  Widget _buildSpotMilestones() {
    if (_spotSteps.isEmpty) return const SizedBox.shrink();

    final completedCount = _spotSteps
        .where((s) => _cumVolume >= (s['target'] as num).toDouble())
        .length;
    final totalCount = _spotSteps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spot Trading Rewards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                height: 1,
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD7FF00),
                borderRadius: BorderRadius.circular(54),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Trade Now',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Volume',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontFamily: 'DMSans',
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '\$${_cumVolume.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 30),
                        Text(
                          '$completedCount/$totalCount Milestones',
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DMSans',
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: 'DMSans',
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '← Swipe to explore all $totalCount milestones →',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'DMSans',
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Row(
                  children: List.generate(_spotSteps.length, (i) {
                    final step = _spotSteps[i];
                    final target = (step['target'] as num).toInt();
                    final spins = (step['spins'] as num).toInt();
                    final reached = _cumVolume >= target;
                    final nextReached = i < _spotSteps.length - 1
                        ? _cumVolume >=
                              ((_spotSteps[i + 1]['target'] as num).toInt())
                        : false;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: 60,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/icons/spinner.png',
                                      width: 25,
                                      height: 25,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '\$$spins',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF111111),
                                border: Border.all(
                                  color: reached
                                      ? const Color(0xFFCCFF00)
                                      : const Color(0xFF111111),
                                  width: 3,
                                ),
                              ),
                              child: reached
                                  ? const Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 60,
                              child: Text(
                                target >= 1000
                                    ? '${target ~/ 1000}K'
                                    : '$target',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: reached
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'DMSans',
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (i < _spotSteps.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 65),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: nextReached
                                    ? const Color(0xFFCCFF00)
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Deposit tiers ────────────────────────────────────────────────────────────
  Widget _buildDepositTiers() {
    if (_depositTiers.isEmpty) return const SizedBox.shrink();

    final List<List<String>> tierIcons = [
      ['💎'],
      ['💎', '💎'],
      ['💎', '💎', '💎'],
      ['🔥'],
      ['🔥', '🔥'],
      ['🚀'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deposit Spin Rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Deposit any coin → get instant bonus spins',
                    style: TextStyle(
                      color: Color(0x80FFFFFF),
                      fontSize: 12,
                      fontFamily: 'DMSans',
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            _actionPill('Deposit Now', const Color(0xFF111111)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'DEPOSIT AMOUNT (USD)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    Text(
                      'BONUS SPIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              ..._depositTiers.asMap().entries.map((entry) {
                final i = entry.key;
                final tier = entry.value;
                final range =
                    tier['range']?.toString() ??
                    tier['amount_range']?.toString() ??
                    '';
                final spins =
                    (tier['spins'] as num?)?.toInt() ??
                    (tier['bonus_spins'] as num?)?.toInt() ??
                    0;
                final icons = i < tierIcons.length ? tierIcons[i] : ['💎'];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: icons
                            .map(
                              (emoji) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          range,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                            height: 1,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          '$spins Spin${spins > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── FAQ ──────────────────────────────────────────────────────────────────────
  Widget _buildFaq() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FAQ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
            height: 20 / 16,
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: _faqs.asMap().entries.map((entry) {
            final i = entry.key;
            final faq = entry.value;
            final q =
                faq['q']?.toString() ?? faq['question']?.toString() ?? '';
            final a =
                faq['a']?.toString() ?? faq['answer']?.toString() ?? '';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Question ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}: ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                          height: 20 / 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          q,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DMSans',
                            height: 20 / 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ── Answer ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}: ',
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                          height: 20 / 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          a,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DMSans',
                            height: 16 / 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Shared pill widget ───────────────────────────────────────────────────────
  Widget _actionPill(String label, Color dotColor) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}