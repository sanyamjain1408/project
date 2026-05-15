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

// ─────────────────────────── wheel segment config (mirrors TSX segmentConfig) ─
//
// spin_win.png layout — segments go CLOCKWISE, arrow is fixed at the TOP.
// At rotation = 0 the dividing line between index-0 and index-1 is at 12 o'clock,
// so every segment centre is offset 15° from its boundary.
//
// Each entry = clockwise degrees the wheel must rotate to place that segment
// exactly under the arrow.  Equivalent to TSX's getSegmentRotation(index).
//
//  idx │ prize              │ centre in image │ stop angle
//  ────┼────────────────────┼─────────────────┼───────────
//   0  │ Better Luck Next   │  345°           │   15°
//   1  │ 0.1 USDT           │   15°           │  345°
//   2  │ 5 POL              │   45°           │  315°
//   3  │ 0.5 PEPE           │   75°           │  285°
//   4  │ 0.5 USDT           │  105°           │  255°
//   5  │ 10 DOGE            │  135°           │  225°
//   6  │ 5 TRX              │  165°           │  195°
//   7  │ 2 USDT             │  195°           │  165°
//   8  │ 10K BONK           │  225°           │  135°
//   9  │ 0.2 USDC           │  255°           │  105°
//  10  │ Better Luck Next   │  285°           │   75°
//  11  │ 5 USDT (jackpot)   │  315°           │   45°
//
// To fine-tune one segment: change its stop angle by ±1–5°.
// To shift the whole wheel: add the same value to every entry.
const List<double> _kSegmentStopAngles = [
   5.0,  // 0  – Better Luck Next Time
  335.0,  // 1  – 0.1 USDT
  305.0,  // 2  – 5 POL
  275.0,  // 3  – 0.5 PEPE
  245.0,  // 4  – 0.5 USDT
  215.0,  // 5  – 10 DOGE
  185.0,  // 6  – 5 TRX
  155.0,  // 7  – 2 USDT
  125.0,  // 8  – 10K BONK
  95.0,   // 9  – 0.2 USDC
  65.0,   // 10 – Better Luck Next Time
  35.0,   // 11 – 5 USDT (jackpot)
];

// Returns the clockwise stop-angle (0–360°) for a given backend slot_index.
double _segmentTargetDeg(int n) =>
    (n >= 0 && n < _kSegmentStopAngles.length) ? _kSegmentStopAngles[n] : 0.0;

const _winMessages = {
  'lose': '😢 Better luck next time! Try again',
  'small': '🎉 Congrats! Reward credited to your wallet',
  'token': '🎁 Bonus tokens received!',
  'medium': '🔥 Great win! Reward credited',
  'jackpot': '🚀 JACKPOT! Huge reward credited',
};

// ─────────────────────────── fixed arrow above wheel ──────────────────────────
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

    // Downward-pointing triangle (polygon points="4,0 28,0 16,32")
    final path = Path()
      ..moveTo(4 * sx, 0)
      ..lineTo(28 * sx, 0)
      ..lineTo(16 * sx, 32 * sy)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Circle at tip (cx=16 cy=38 r=5)
    canvas.drawCircle(Offset(16 * sx, 38 * sy), 5 * sy, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────── main screen ──────────────────────────────────────
class SpinWinScreen extends StatefulWidget {
  const SpinWinScreen({super.key});

  @override
  State<SpinWinScreen> createState() => _SpinWinScreenState();
}

class _SpinWinScreenState extends State<SpinWinScreen>
    with SingleTickerProviderStateMixin {
  // ── Wheel animation ─────────────────────────────────────────────────────────
  late AnimationController _wheelCtrl;
  Animation<double> _wheelAnim = const AlwaysStoppedAnimation(0.0);
  double _totalTurns = 0.0;

  // ── State from backend ──────────────────────────────────────────────────────
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
  int? _expandedFaq;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _fetchStatus();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _wheelCtrl.dispose();
    super.dispose();
  }

  // ── Fetch spin status ───────────────────────────────────────────────────────
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

  // ── Spin ────────────────────────────────────────────────────────────────────
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

        // Clockwise segment layout: bring segment winIndex to the arrow (top).
        final double segmentAngle = _segmentTargetDeg(winIndex) / 360.0;
        final double currentNorm = _totalTurns % 1.0;
        double needed = (segmentAngle - currentNorm + 1.0) % 1.0;
        if (needed < 0.01) needed += 1.0; // ensure visible motion
        final double targetTurns = _totalTurns + 8.0 + needed; // 8 full spins

        // Animate the wheel — cubic-bezier matching the TSX
        setState(() {
          _wheelAnim = Tween<double>(
            begin: _totalTurns,
            end: targetTurns,
          ).animate(CurvedAnimation(
            parent: _wheelCtrl,
            curve: const Cubic(0.17, 0.67, 0.12, 0.99),
          ));
          _totalTurns = targetTurns;
        });

        await _wheelCtrl.forward(from: 0.0);

        if (mounted) {
          setState(() {
            _lastReward = reward;
            _showResult = true;
            _spinsLeft = (data['spins_remaining'] ?? _spinsLeft - 1) as int;
            _spinsUsedToday =
                (data['spins_used_today'] ?? _spinsUsedToday + 1) as int;
            if (data['cooldown_ms'] != null) {
              _cooldownMs = data['cooldown_ms'] as int;
            }
            if (data['cumulative_volume'] != null) {
              _cumVolume = (data['cumulative_volume'] as num).toDouble();
            }
            final tier = reward['tier'] as String? ?? 'small';
            _message = _winMessages[tier] ?? _winMessages['small'];
            _spinning = false;
          });
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

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.only(left: 20),
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
                      if (_showResult && _lastReward != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: _buildResultCard(),
                        ),
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
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildDepositTiers(),
                      ),
                      const SizedBox(height: 16),
                      if (_faqs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildFaq(),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // ── Spins chip ───────────────────────────────────────────────────────────────
  Widget _buildSpinsChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          decoration: BoxDecoration(color: Colors.transparent),
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
      ),
    );
  }

  // ── Wheel + button ───────────────────────────────────────────────────────────
  Widget _buildWheelSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Wheel card with fixed arrow overlay
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
                // Wheel — only animates when button is pressed
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

                // Fixed arrow at top center — does NOT rotate with the wheel
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:  Color(0xFFCCFF00).withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
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
          // Spin button — full width gradient
          GestureDetector(
            onTap: _canSpin ? _spin : null,
            child: Container(
              width: double.infinity,
              height: 50,
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
              child: Row(
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
          if (_cooldownMs > 0 && _spinsLeft <= 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: _grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Next spin in: $_cooldownLabel',
                  style: const TextStyle(color: _grey, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Result card ──────────────────────────────────────────────────────────────
  Widget _buildResultCard() {
    final tier = _lastReward['tier'] as String? ?? 'small';
    final amount = _lastReward['amount']?.toString() ?? '';
    final coinType = _lastReward['coin_type']?.toString() ?? '';
    final isLose = tier == 'lose';
    final tierColors = {
      'lose': Colors.grey,
      'small': const Color(0xFF26A17B),
      'token': const Color(0xFFF5A623),
      'medium': const Color(0xFF00BCD4),
      'jackpot': _lime,
    };
    final color = tierColors[tier] ?? _lime;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            isLose ? 'Better Luck Next Time!' : 'You Won!',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!isLose && amount.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '$amount $coinType',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _message ?? '',
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
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
        /// TOP HEADER
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
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

        /// MAIN CARD
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.transparent),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP CONTENT
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
                              color: Colors.white.withValues(alpha: 0.5),
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
                        Text(
                          '$completedCount/$totalCount Milestones',
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DMSans',
                            height: 1,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
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
              SizedBox(height: 20),

              /// SWIPE TEXT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '← Swipe to explore all $totalCount milestones →',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: 'DMSans',
                    height: 1,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// MILESTONE TRACK
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _spotSteps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final step = entry.value;

                    final target = (step['target'] as num).toInt();
                    final spins = (step['spins'] as num).toInt();

                    final reached = _cumVolume >= target;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            /// REWARD ROW
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/spinner.png',
                                  width: 26,
                                  height: 26,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  '\$$spins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// CIRCLE + LINE
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                /// PROGRESS CIRCLE
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: reached
                                        ? const Color(0xFFCCFF00)
                                        : Colors.black,
                                    border: Border.all(
                                      color: reached
                                          ? const Color(0xFFCCFF00)
                                          : Colors.black,
                                      width: 3,
                                    ),
                                  ),
                                  child: reached
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),

                                /// CONNECTING LINE
                                if (i < _spotSteps.length - 1)
                                  Container(
                                    width: 70,
                                    height: 6,
                                    color: reached
                                        ? const Color(0xFFCCFF00)
                                        : Colors.black,
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            /// TARGET
                            Text(
                              target >= 1000 ? '${target ~/ 1000}K' : '$target',
                              style: TextStyle(
                                color: reached
                                    ? Colors.white
                                    : const Color(0xFFB5B5B5),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'DMSans',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
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

    final tierIconColors = [
      const Color(0xFF2196F3),
      const Color(0xFF42A5F5),
      const Color(0xFF1565C0),
      const Color(0xFFFF5722),
      const Color(0xFF4CAF50),
      const Color(0xFFFFD700),
    ];
    final iconCounts = [1, 1, 3, 1, 1, 1];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                const Text(
                  'Deposit Spin Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
                const Spacer(),
                _actionPill('Deposit Now', const Color(0xFFFF8C00)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Deposit any coin → get instant bonus spins',
              style: TextStyle(
                color: _grey,
                fontSize: 11,
                fontFamily: 'DMSans',
              ),
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _border),
                bottom: BorderSide(color: _border),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'DEPOSIT AMOUNT (USD)',
                    style: TextStyle(
                      color: _grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'BONUS SPIN',
                  style: TextStyle(
                    color: _grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Rows
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
            final iconColor = i < tierIconColors.length
                ? tierIconColors[i]
                : tierIconColors.last;
            final count = i < iconCounts.length ? iconCounts[i] : 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border, width: 0.5)),
              ),
              child: Row(
                children: [
                  // Coin icons
                  Row(
                    children: List.generate(
                      count,
                      (j) => Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconColor.withValues(alpha: 0.2),
                            border: Border.all(color: iconColor, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '◆',
                              style: TextStyle(color: iconColor, fontSize: 8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      range,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                  Text(
                    '$spins Spin${spins > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 12),
        ..._faqs.asMap().entries.map((entry) {
          final i = entry.key;
          final faq = entry.value;
          final isOpen = _expandedFaq == i;
          final q = faq['q']?.toString() ?? faq['question']?.toString() ?? '';
          final a = faq['a']?.toString() ?? faq['answer']?.toString() ?? '';

          return GestureDetector(
            onTap: () => setState(() => _expandedFaq = isOpen ? null : i),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}: ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          q,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isOpen) ...[
                    const SizedBox(height: 8),
                    Text(
                      a,
                      style: const TextStyle(
                        color: _grey,
                        fontSize: 12,
                        fontFamily: 'DMSans',
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Shared pill widget ───────────────────────────────────────────────────────
  Widget _actionPill(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _card2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}
