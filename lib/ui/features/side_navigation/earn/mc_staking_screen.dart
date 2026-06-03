import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_up/sign_up_screen.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_portfolio_screen.dart';
import 'mc_my_stakes_screen.dart';

const _green = Color(0xFFCCFF00);
const _card = Color(0xFF1A1A1A);
const _card2 = Color(0xFF0D0D0D);

// ── helpers ──────────────────────────────────────────────────────────────────
Widget _coinImg(String? logo, {double size = 40, String? symbol}) {
  final url = mcLogoUrl(logo, symbol: symbol);
  if (url.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(size),
      ),
    );
  }
  return _fallback(size);
}

Widget _fallback(double size) => ClipOval(
  child: Container(
    width: size,
    height: size,
    color: const Color(0xFF222222),
    child: Icon(Icons.monetization_on, color: _green, size: size * 0.5),
  ),
);

String _planTypeLabel(int t) => t == 1
    ? 'Flexible'
    : t == 2
    ? 'Locked'
    : 'Long-Term';

// ── McStakingScreen ───────────────────────────────────────────────────────────
class McStakingScreen extends StatefulWidget {
  const McStakingScreen({super.key});
  @override
  State<McStakingScreen> createState() => _McStakingScreenState();
}

class _McStakingScreenState extends State<McStakingScreen> {
  late McStakingController _c;
  McStakingCoin? _selectedCoin;
  McStakingPlan? _selectedPlan;
  McRateRule? _selectedRule;
  String _filterDuration = 'All';
  int _step = 1;
  final _amountCtrl = TextEditingController();
  Timer? _calcTimer;
  double _perSec = 0;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.fetchCoins();
      if (gUserRx.value.id > 0) _c.fetchPortfolio();
    });
  }

  @override
  void dispose() {
    _calcTimer?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectCoin(McStakingCoin coin) {
    setState(() {
      _selectedCoin = coin;
      _selectedPlan = null;
      _selectedRule = null;
      _filterDuration = 'All';
      _step = 2;
      _amountCtrl.clear();
      _c.calcResult.value = null;
    });
    _c.fetchPlans(coin.id);
  }

  void _selectPlanRow(McStakingPlan plan, McRateRule rule) {
    setState(() {
      _selectedPlan = plan;
      _selectedRule = rule;
      _step = 3;
      _amountCtrl.clear();
      _c.calcResult.value = null;
      _perSec = 0;
    });
  }

  void _onAmountChange(String val) {
    _calcTimer?.cancel();
    final amount = double.tryParse(val) ?? 0;
    if (amount <= 0 || _selectedPlan == null) {
      _c.calcResult.value = null;
      setState(() => _perSec = 0);
      return;
    }
    _calcTimer = Timer(const Duration(milliseconds: 600), () async {
      await _c.calculateReward(_selectedPlan!.id, amount);
      final cr = _c.calcResult.value;
      setState(
        () => _perSec = (cr != null && cr.dailyRate > 0)
            ? (amount * (cr.dailyRate / 100)) / 86400
            : 0,
      );
    });
  }

  Future<void> _handleStake() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (_selectedPlan == null || amount <= 0) return;
    final ok = await _c.submitStake(_selectedPlan!.id, amount);
    if (ok) {
      _amountCtrl.clear();
      _c.calcResult.value = null;
      setState(() => _perSec = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoinList(),
                const SizedBox(height: 20),
                _buildNavCards(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── COIN LIST (overview style) ────────────────────────────────────────────
  Widget _buildCoinList() {
    return Obx(() {
      if (_c.isLoadingCoins.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: _green),
          ),
        );
      }
      if (_c.coins.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No coins available.',
              style: TextStyle(color: Color(0xFF555555)),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 16),
          ..._c.coins.map((coin) {
            final isExpanded = _selectedCoin?.id == coin.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Coin header row ──
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _selectedCoin = null;
                        _selectedPlan = null;
                        _selectedRule = null;
                      } else {
                        _selectCoin(coin);
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        _coinImg(coin.logo, size: 34, symbol: coin.symbol),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coin.symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'DMSans',
                                  height: 24 / 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                coin.coinName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: 'DMSans',
                                  height: 16 / 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(() {
                          final dur = _c.coinDurations[coin.id];
                          if (dur == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF00B2E3),
                                  Color(0xFFFFA600),
                                  Color(0xFFF03A89),
                                ],
                                stops: [0.0, 0.5326, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                dur,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'DMSans',
                                  height: 24 / 16,
                                ),
                              ),
                            ),
                          );
                        }),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white.withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expanded plan rows ──
                if (isExpanded)
                  Obx(() {
                    if (_c.isLoadingPlans.value) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(color: _green),
                        ),
                      );
                    }
                    if (_c.plans.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'No plans for ${coin.symbol}.',
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    final rows = <_PlanRow>[];
                    for (final plan in _c.plans) {
                      if (plan.rateRules.isNotEmpty) {
                        for (final rule in plan.rateRules) {
                          rows.add(
                            _PlanRow(
                              plan: plan,
                              rule: rule,
                              rowId: '${plan.id}-${rule.id ?? rule.minAmount}',
                            ),
                          );
                        }
                      } else {
                        rows.add(
                          _PlanRow(
                            plan: plan,
                            rule: McRateRule(
                              minAmount: plan.minStake,
                              maxAmount: 0,
                              dailyRate: 0,
                            ),
                            rowId: '${plan.id}-fallback',
                          ),
                        );
                      }
                    }
                    return Column(
                      children: [
                        ...rows.map((r) {
                          final durationLabel = r.plan.durationDays == 0
                              ? 'Flexible'
                              : '${r.plan.durationDays} Days';
                          final totalRate = r.rule.dailyRate * r.plan.durationDays;
                          final totalRateLabel = r.plan.durationDays == 0
                              ? '${r.rule.dailyRate.toStringAsFixed(2)}% Daily'
                              : '${totalRate.toStringAsFixed(2)}% Total';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          durationLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'DMSans',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          totalRateLabel,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 12,
                                            fontFamily: 'DMSans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${r.rule.dailyRate.toStringAsFixed(2)}%',
                                          style: const TextStyle(
                                            color: Color(0xFF4ED78E),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'DMSans',
                                            height: 24 / 16,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' /day',
                                          style: TextStyle(
                                            color: Color(0xFF4ED78E),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: 'DMSans',
                                            height: 16 / 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      _selectPlanRow(r.plan, r.rule);
                                      Get.to(
                                        () => _StakingSubscribeScreen(
                                          coin: coin,
                                          initialPlan: r.plan,
                                          initialRule: r.rule,
                                          allRows: rows,
                                          controller: _c,
                                          amountCtrl: _amountCtrl,
                                          onPlanSelected: _selectPlanRow,
                                          onAmountChange: _onAmountChange,
                                          onStake: _handleStake,
                                          perSecGetter: () => _perSec,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Subscribe',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'DMSans',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                      ],
                    );
                  }),
              ],
            );
          }),
        ],
      );
    });
  }

  // ── HERO ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -140,
              top: -55,
              child: Transform.rotate(
                angle: -0.4,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/images/wallet_green_wave.png',
                    width: 340,
                    height: 350,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.to(() => const McPortfolioScreen()),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Live Dashboard',
                              style: TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 16,
                                height: 26 / 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.to(() => const McMyStakesScreen()),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'My Stake',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 26 / 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Step indicator
                  _buildSteps(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps() {
    final steps = ['Select Coin', 'Choose Plan', 'Stake Now'];
    return Column(
      children: [
        // Labels row
        Row(
          children: List.generate(3, (i) {
            final isFuture = _step < i + 1;
            return Expanded(
              child: Text(
                steps[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : i == 2
                    ? TextAlign.right
                    : TextAlign.center,
                style: TextStyle(
                  color: isFuture ? Colors.white : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: "DMSans",
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Circles + connecting lines
        SizedBox(
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left line (step 1 → step 2)
              Positioned(
                left: 18,
                right: MediaQuery.of(context).size.width / 2 - 16,
                child: Container(
                  height: 2,
                  color: _step > 1 ? _green : Colors.white.withOpacity(0.5),
                ),
              ),
              // Right line (step 2 → step 3)
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 16,
                right: 18,
                child: Container(
                  height: 2,
                  color: _step > 2 ? _green : Colors.white.withOpacity(0.5),
                ),
              ),
              // The 3 circles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (i) {
                  final n = i + 1;
                  final isActive = _step == n;
                  final isDone = _step > n;
                  return _stepCircle(n, isActive, isDone);
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepCircle(int n, bool isActive, bool isDone) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? _green : const Color(0xFF111111),
        border: Border.all(
          color: (isActive || isDone) ? _green : Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.black, size: 16)
            : isActive
            ? Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green,
                ),
              )
            : null,
      ),
    );
  }

  // ── MAIN CARD ─────────────────────────────────────────────────────────────
  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoinSection(),
          const SizedBox(height: 40),
          if (_selectedCoin != null) ...[
            const SizedBox(height: 20),
            _buildPlanSection(),
          ],
          const SizedBox(height: 40),
          if (_selectedPlan != null) ...[
            const SizedBox(height: 20),
            _buildStakeSection(),
          ],
        ],
      ),
    );
  }

  // ── SECTION 1: COINS ──────────────────────────────────────────────────────
  Widget _buildCoinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secTitle('1', 'Select Coin'),
        const SizedBox(height: 20),
        Obx(() {
          if (_c.isLoadingCoins.value)
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: _green),
              ),
            );
          if (_c.coins.isEmpty)
            return const Text(
              'No coins available.',
              style: TextStyle(color: Color(0xFF666666)),
            );
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _c.coins.map((coin) {
              final sel = _selectedCoin?.id == coin.id;
              return GestureDetector(
                onTap: () => _selectCoin(coin),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? _green : Colors.transparent,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _coinImg(coin.logo, size: 20, symbol: coin.symbol),
                      const SizedBox(height: 5),
                      Text(
                        coin.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        coin.coinName,
                        style: const TextStyle(
                          color: Color(0xFF00B052),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ── SECTION 2: PLANS ──────────────────────────────────────────────────────
  Widget _buildPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secTitle('2', 'Choose Staking Plan'),
        const SizedBox(height: 20),
        Obx(() {
          if (_c.isLoadingPlans.value)
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: _green),
              ),
            );
          if (_c.plans.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No plans for ${_selectedCoin?.symbol}.',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            );
          }

          // flat rows per rate rule
          final rows = <_PlanRow>[];
          for (final plan in _c.plans) {
            if (plan.rateRules.isNotEmpty) {
              for (final rule in plan.rateRules) {
                rows.add(
                  _PlanRow(
                    plan: plan,
                    rule: rule,
                    rowId: '${plan.id}-${rule.id ?? rule.minAmount}',
                  ),
                );
              }
            } else {
              rows.add(
                _PlanRow(
                  plan: plan,
                  rule: McRateRule(
                    minAmount: plan.minStake,
                    maxAmount: 0,
                    dailyRate: 0,
                  ),
                  rowId: '${plan.id}-fallback',
                ),
              );
            }
          }

          final durations = _c.plans.map((p) => p.durationDays).toSet().toList()
            ..sort();
          final tabs = [
            'All',
            ...durations.map((d) => d == 0 ? 'Flexible' : '$d Days'),
          ];
          final filtered = rows.where((r) {
            if (_filterDuration == 'All') return true;
            final label = r.plan.durationDays == 0
                ? 'Flexible'
                : '${r.plan.durationDays} Days';
            return label == _filterDuration;
          }).toList();

          final coinDisplay = (_selectedCoin?.symbol ?? '').contains('-')
              ? (_selectedCoin?.symbol ?? '')
              : '${_selectedCoin?.symbol ?? ''}-USDT';

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // coin heading
                Row(
                  children: [
                    _coinImg(
                      _selectedCoin?.logo,
                      size: 20,
                      symbol: _selectedCoin?.symbol,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      coinDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: "DMSans",
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // duration tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tabs.map((tab) {
                      final active = _filterDuration == tab;
                      return GestureDetector(
                        onTap: () => setState(() => _filterDuration = tab),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: active ? _green : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: active ? Color(0xFF1A1A1A) : Colors.white,
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w400
                                  : FontWeight.w400,
                              fontFamily: "DMSans",
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // table — horizontal scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 492,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // header
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'Duration',
                                  style: TextStyle(
                                    color: const Color(0x80FFFFFF),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  'Min Stake',
                                  style: TextStyle(
                                    color: const Color(0x80FFFFFF),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Rate Tiers',
                                  style: TextStyle(
                                    color: const Color(0x80FFFFFF),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Rate',
                                  style: TextStyle(
                                    color: const Color(0x80FFFFFF),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Action',
                                  style: TextStyle(
                                    color: const Color(0x80FFFFFF),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // rows
                        ...filtered.map((r) {
                          final selId = _selectedPlan != null
                              ? '${_selectedPlan!.id}-${_selectedRule?.id ?? _selectedRule?.minAmount}'
                              : '';
                          final isSel = selId == r.rowId;
                          return GestureDetector(
                            onTap: () => _selectPlanRow(r.plan, r.rule),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? _green.withValues(alpha: 0.05)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? _green : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      r.plan.durationDays == 0
                                          ? 'Flexible'
                                          : '${r.plan.durationDays} Days',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: "DMSans",
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      _fmtNum(r.plan.minStake),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: "DMSans",
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '${_fmtNum(r.rule.minAmount)} – ${r.rule.maxAmount > 0 ? _fmtNum(r.rule.maxAmount) : '∞'}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: "DMSans",
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '${r.rule.dailyRate.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: "DMSans",
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _selectPlanRow(r.plan, r.rule),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _green,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Subscribe',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: "DMSans",
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (filtered.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No plans for this duration.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── SECTION 3: STAKE ──────────────────────────────────────────────────────
  Widget _buildStakeSection() {
    final plan = _selectedPlan!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secTitle('3', 'Enter Amount & Stake'),
        const SizedBox(height: 20),

        // ── Amount input ─────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  onChanged: _onAmountChange,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 24 / 16,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Minimum ${_fmtNum(plan.minStake)}',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      height: 24 / 16,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Text(
                _selectedCoin?.symbol ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 20 / 16,
                  fontFamily: "DMSans",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Warning ──────────────────────────────────────────────────────────
        Obx(() {
          final cr = _c.calcResult.value;
          if (cr != null && cr.dailyRate == 0 && _amountCtrl.text.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x55F87171)),
              ),
              child: const Text(
                '⚠️ Amount doesn\'t match any rate tier.',
                style: TextStyle(color: Color(0xFFF87171), fontSize: 12),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // ── Plan Details ─────────────────────────────────────────────────────
        _buildPlanDetails(plan),
        const SizedBox(height: 20),

        // ── Live Reward Estimate ─────────────────────────────────────────────
        _buildRewardEstimate(plan),

        // ── Stake button ─────────────────────────────────────────────────────
      ],
    );
  }

  Widget _buildPlanDetails(McStakingPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Details',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: "DMSans",
              height: 20 / 16,
            ),
          ),
          const SizedBox(height: 10),
          _planRow('Plan Type', _planTypeLabel(plan.planType),valColor: Colors.white,),
          _planRow(
            'Lock Period',
            plan.durationDays > 0 ? '${plan.durationDays} days' : 'No Lock',
            valColor: Colors.white,
          ),
          _planRow(
            'Reward Coin',
            _selectedCoin?.symbol ?? '',
            valColor: _green,
          ),
          if (plan.rewardCap > 0)
            _planRow('Reward Cap', _fmtNum(plan.rewardCap)),
        ],
      ),
    );
  }

  Widget _planRow(String label, String val, {Color? valColor}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w400,
            height: 20 / 15,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            color: valColor ?? Colors.white,
            fontSize: 12,
            fontFamily: "DMSans",
            height: 20 / 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );

  Widget _buildRewardEstimate(McStakingPlan plan) {
    return Obx(() {
      final cr = _c.calcResult.value;
      final dailyRate =
          cr?.dailyRate ??
          (plan.rateRules.isNotEmpty ? plan.rateRules.first.dailyRate : 0);
      final dailyReward = cr?.dailyReward ?? 0.0;
      final totalReward = cr?.totalReward ?? 0.0;
      final lockText = plan.durationDays > 0
          ? '${plan.durationDays} days'
          : 'Flexible';
      final sym = _selectedCoin?.symbol ?? '';
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Live Reward Estimate',
              style: TextStyle(
                color: _green,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                fontFamily: "DMSans",
                height: 20 / 16,
              ),
            ),
            const SizedBox(height: 20),
            // 2x2 grid
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _rewardBox(
                      'Daily Rate',
                      '${dailyRate.toStringAsFixed(2)} %',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _rewardBox(
                      'Daily Reward',
                      '${dailyReward.toStringAsFixed(4)} $sym',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _rewardBox(
                      'Per Second',
                      '${_perSec.toStringAsFixed(4)} $sym',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _rewardBox(
                      'Total ($lockText)',
                      '${totalReward.toStringAsFixed(4)} $sym',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildStakeBtn(),
          ],
        ),
      );
    });
  }

  Widget _rewardBox(String label, String val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          height: 20,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          val,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: "DMSans",
            height: 20 / 16,
          ),
        ),
      ],
    ),
  );

  Widget _buildStakeBtn() {
    if (gUserRx.value.id <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              'Login to start staking and earning',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Get.to(() => const SignInPage()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Get.to(() => const SignUpScreen()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: _green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Obx(() {
      final loading = _c.isStaking.value;
      final cr = _c.calcResult.value;
      final hasAmt = _amountCtrl.text.isNotEmpty;
      final disabled = loading || !hasAmt || (cr != null && cr.dailyRate == 0);
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
          onPressed: disabled ? null : _handleStake,
          style: ElevatedButton.styleFrom(
            backgroundColor: disabled ? const Color(0xFF1A1A1A) : _green,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  '⚡ Stake ${_selectedCoin?.symbol ?? ''} Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                  ),
                ),
        ),
      );
    });
  }

  // ── NAV CARDS ─────────────────────────────────────────────────────────────
  Widget _buildNavCards() {
    if (gUserRx.value.id <= 0) return const SizedBox.shrink();
    final items = [
      _NavItem(
        'assets/images/live.png',
        'Live Dashboard',
        'Real-time earnings',
        () => Get.to(() => const McPortfolioScreen()),
      ),
      _NavItem(
        'assets/images/my.png',
        'My Stakes',
        'Manage positions',
        () => Get.to(() => const McMyStakesScreen()),
      ),
      _NavItem(
        'assets/images/referral.png',
        'Referral Earnings',
        'Commission history',
        () => Get.to(() => const McReferralRewardsScreen()),
      ),
      _NavItem(
        'assets/images/reward.png',
        'Reward History',
        'Daily logs',
        () => Get.to(() => const McRewardsScreen()),
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: items
          .map(
            (item) => GestureDetector(
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    Image.asset(item.image, width: 20, height: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: "DMSans",
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.desc,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: "DMSans",
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _secTitle(String n, String title) => Row(
    children: [
      Text(
        n,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: "DMSans",
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: "DMSans",
        ),
      ),
    ],
  );
}

// ── Subscribe Screen (opens on Subscribe tap) ─────────────────────────────────
class _StakingSubscribeScreen extends StatefulWidget {
  final McStakingCoin coin;
  final McStakingPlan initialPlan;
  final McRateRule initialRule;
  final List<_PlanRow> allRows;
  final McStakingController controller;
  final TextEditingController amountCtrl;
  final void Function(McStakingPlan, McRateRule) onPlanSelected;
  final void Function(String) onAmountChange;
  final Future<void> Function() onStake;
  final double Function() perSecGetter;

  const _StakingSubscribeScreen({
    required this.coin,
    required this.initialPlan,
    required this.initialRule,
    required this.allRows,
    required this.controller,
    required this.amountCtrl,
    required this.onPlanSelected,
    required this.onAmountChange,
    required this.onStake,
    required this.perSecGetter,
  });

  @override
  State<_StakingSubscribeScreen> createState() =>
      _StakingSubscribeScreenState();
}

class _StakingSubscribeScreenState extends State<_StakingSubscribeScreen> {
  McStakingController get _c => widget.controller;
  bool _agreed = false;
  late McStakingPlan _selectedPlan;
  late McRateRule _selectedRule;
  double _perSec = 0;
  Timer? _calcTimer;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
    _selectedRule = widget.initialRule;
  }

  @override
  void dispose() {
    _calcTimer?.cancel();
    super.dispose();
  }

  void _onAmountChange(String val) {
    _calcTimer?.cancel();
    final amount = double.tryParse(val) ?? 0;
    if (amount <= 0) {
      _c.calcResult.value = null;
      setState(() => _perSec = 0);
      return;
    }
    _calcTimer = Timer(const Duration(milliseconds: 600), () async {
      await _c.calculateReward(_selectedPlan.id, amount);
      final cr = _c.calcResult.value;
      setState(
        () => _perSec = (cr != null && cr.dailyRate > 0)
            ? (amount * (cr.dailyRate / 100)) / 86400
            : 0,
      );
    });
  }

  String _planTypeLabel(int t) => t == 1
      ? 'Flexible'
      : t == 2
      ? 'Locked'
      : 'Long-Term';

  @override
  Widget build(BuildContext context) {
    final plan = _selectedPlan;
    final rule = _selectedRule;
    final coin = widget.coin;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
      backgroundColor: const Color(0xFF111111),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _coinImg(coin.logo, size: 20, symbol: coin.symbol),
                        const SizedBox(width: 5),
                        Text(
                          "${coin.symbol} Subscribe",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: "DMSans",
                            height: 24 / 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Plan pills (all plans horizontal scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.allRows.map((r) {
                          final isA =
                              _selectedPlan.id == r.plan.id &&
                              _selectedRule.minAmount == r.rule.minAmount;
                          final label = r.plan.durationDays == 0
                              ? 'Flexible'
                              : "${r.plan.durationDays} Days";
                          final totalRate = r.rule.dailyRate * r.plan.durationDays;
                          final sub = r.plan.durationDays == 0
                              ? "${r.rule.dailyRate.toStringAsFixed(2)}% Daily"
                              : "${totalRate.toStringAsFixed(2)}% Total";
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlan = r.plan;
                                _selectedRule = r.rule;
                              });
                              widget.onPlanSelected(r.plan, r.rule);
                              widget.amountCtrl.clear();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: isA
                                    ? Colors.transparent
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isA ? _green : Colors.transparent,
                                  width: isA ? 0.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isA
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "DMSans",
                                      height: 24 / 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sub,
                                    style: TextStyle(
                                      color: isA
                                          ? _green
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontFamily: "DMSans",
                                      height: 24 / 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount label
                    const Text(
                      "Amount",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: "DMSans",
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Amount input box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: widget.amountCtrl,
                                  onChanged: (v) {
                                    _onAmountChange(v);
                                    setState(() {});
                                  },
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "DMSans",
                                    height: 24 / 16,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        "${_fmtNum(plan.minStake)} Minimum",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "DMSans",
                                      height: 24 / 16,
                                    ),
                                  ),
                                ),
                              ),
                             
                              Text(
                                coin.symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "DMSans",
                                  height: 20 / 15,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 10),
                          _rewardRow(
                            "Plan type",
                            _planTypeLabel(plan.planType),
                            valColor: Colors.white,
                          ),
                          _rewardRow(
                            "Lock Period",
                            plan.durationDays > 0
                                ? '${plan.durationDays} Days'
                                : 'No Lock',
                                valColor: Colors.white,
                          ),
                          _rewardRow(
                            "Reward Coin",
                            coin.symbol,
                            valColor: _green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Live Reward Estimate
                    const Text(
                      "Live Reward Estimate",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 20/16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "DMSans",
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final cr = _c.calcResult.value;
                      final dailyRate = cr?.dailyRate ?? rule.dailyRate;
                      final dailyReward = cr?.dailyReward ?? 0.0;
                      final perSec = _perSec;
                      final totalReward = cr?.totalReward ?? 0.0;
                      final sym = coin.symbol;
                      return Column(
                        children: [
                          _rewardRow(
                            "Daily Rate",
                            "${dailyRate.toStringAsFixed(2)}%",
                          ),
                          _rewardRow(
                            "Daily Reward",
                            "${dailyReward.toStringAsFixed(6)} $sym",
                          ),
                          _rewardRow(
                            "Per Second",
                            "${perSec.toStringAsFixed(8)} $sym",
                          ),
                          _rewardRow(
                            "Total Reward",
                            "${totalReward.toStringAsFixed(4)} $sym",
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Fixed bottom: Agreement + Button ────────────────────────
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _agreed ? _green : Colors.white,
                              width: 1,
                            ),
                            color: _agreed
                                ? const Color(0xFFB5F000)
                                : Colors.transparent,
                          ),
                          child: _agreed
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.black,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 16 / 12,
                                fontFamily: "DMSans",
                                fontWeight: FontWeight.w400,
                              ),
                              children: const [
                                TextSpan(text: "I have read and agree to "),
                                TextSpan(
                                  text: "Trapix Earn User Agreement",
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 12,
                                    height: 16 / 12,
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final loading = _c.isStaking.value;
                    final amt = double.tryParse(widget.amountCtrl.text) ?? 0;
                    final disabled =
                        loading || amt < _selectedPlan.minStake || !_agreed;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: disabled
                            ? null
                            : () async {
                                await widget.onStake();
                                await Future.delayed(
                                  const Duration(milliseconds: 1500),
                                );
                                Get.back();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: disabled
                              ? const Color(0xFF222222)
                              : _green,
                          disabledBackgroundColor: const Color(0xFF222222),
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "⚡ Stake ${widget.coin.symbol} Now",
                                style: TextStyle(
                                  color: disabled
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 24 / 16,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _rewardRow(String label, String val, {Color? valColor}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16/12,
            fontFamily: 'DMSans',
          ),
        ),
        Text(
          val,
          style: TextStyle(
            color: valColor ?? const Color(0xFF4ED78E),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 16/15,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    ),
  );
}

class _PlanRow {
  final McStakingPlan plan;
  final McRateRule rule;
  final String rowId;
  _PlanRow({required this.plan, required this.rule, required this.rowId});
}

class _NavItem {
  final String image;
  final String label, desc;
  final VoidCallback onTap;
  _NavItem(this.image, this.label, this.desc, this.onTap);
}

String _fmtNum(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ═══════════════════════════════════════════════════════════════════════════════
// REWARDS SCREEN  (Figma: "Reward History")
// ═══════════════════════════════════════════════════════════════════════════════
class McRewardsScreen extends StatefulWidget {
  const McRewardsScreen({super.key});
  @override
  State<McRewardsScreen> createState() => _McRewardsScreenState();
}

class _McRewardsScreenState extends State<McRewardsScreen> {
  late McStakingController _c;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.fetchRewards(page: _page);
      if (_c.portfolio.value == null) _c.fetchPortfolio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Text(
                      'Reward History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      'All your rewards',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
                    ),
                  ),
                ],
              ),
            ),
            // ── Tab pills ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  _tabPill('My Stake'),
                  const SizedBox(width: 10),
                  _tabPill('Referral Reward'),
                ],
              ),
            ),
            // ── Content ──────────────────────────────────────────────────
            Expanded(child: _buildMyStakeTab()),
          ],
        ),
      ),
    );
  }

  Widget _tabPill(String label) {
    final isMyStake = label == 'My Stake';
    return GestureDetector(
      onTap: () {
        if (isMyStake) {
          Get.to(() => const McMyStakesScreen());
        } else {
          Get.to(() => const McReferralRewardsScreen());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isMyStake ? _green : _green,
          borderRadius: BorderRadius.circular(10),
          border: isMyStake ? null : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isMyStake ? const Color(0xFF111111) : Color(0xFF111111),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSans',
          ),
        ),
      ),
    );
  }

  // ── My Stake tab ─────────────────────────────────────────────────────────
  Widget _buildMyStakeTab() {
    return Obx(() {
      if (_c.isLoadingRewards.value) {
        return const Center(child: CircularProgressIndicator(color: _green));
      }
      if (_c.rewards.isEmpty) {
        return _emptyState(
          'No rewards yet',
          'Start staking to earn daily rewards',
        );
      }
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 600,
                child: Column(
                  children: [
                    _rewardsTableHeader(),
                    ..._c.rewards.asMap().entries.map(
                      (e) => _rewardsTableRow(e.key, e.value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _pagination(_c.rewardsMeta.value, (p) {
            setState(() => _page = p);
            _c.fetchRewards(page: p);
          }),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _rewardsTableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration:  BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
    ),
    child:  Row(
      children: [
        SizedBox(width: 36, child: Text('No.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'), textAlign: TextAlign.center)),
        SizedBox(width: 76, child: Text('Coin', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'), textAlign: TextAlign.center)),
        SizedBox(width: 168, child: Text('Reward Amount', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'), textAlign: TextAlign.center)),
        SizedBox(width: 136, child: Text('Daily Rate', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'), textAlign: TextAlign.center)),
        SizedBox(width: 142, child: Text('Date', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'), textAlign: TextAlign.center)),
      ],
    ),
  );

  Widget _rewardsTableRow(int idx, McStakingReward r) {
    final dateStr = _formatRewardDate(r.rewardDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${(_page - 1) * 15 + idx + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 76,
            child: Text(
              r.coin?.symbol ?? '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 168,
            child: Text(
              r.rewardAmount.toStringAsFixed(8),
              style: const TextStyle(
                color: Color(0xFF00B052),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'DMSans',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 136,
            child: Text(
              '${r.dailyRate.toStringAsFixed(6)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'DMSans',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 152,
            child: Column(
              children: [
                Text(
                  dateStr.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                  textAlign: TextAlign.center,
                ),
                if (dateStr.$2.isNotEmpty)
                  Text(
                    dateStr.$2,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _formatRewardDate(String? raw) {
    if (raw == null) return ('—', '');
    try {
      final d = DateTime.parse(raw).toLocal();
      final date = '${d.month}/${d.day}/${d.year}';
      final h = d.hour;
      final time =
          '${h > 12 ? h - 12 : h == 0 ? 12 : h}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
      return (date, time);
    } catch (_) {
      return (raw, '');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REFERRAL REWARDS SCREEN  (Figma: "Referral Earnings")
// ═══════════════════════════════════════════════════════════════════════════════
class McReferralRewardsScreen extends StatefulWidget {
  const McReferralRewardsScreen({super.key});
  @override
  State<McReferralRewardsScreen> createState() =>
      _McReferralRewardsScreenState();
}

class _McReferralRewardsScreenState extends State<McReferralRewardsScreen> {
  late McStakingController _c;
  int _page = 1;

  static const _lvlColors = {
    1: _green,
    2: Color(0xFFE946FF),
    3: Color(0xFF00B052),
  };
  static const _lvlLabels = {
    1: 'Direct Referral',
    2: 'Their Referrals',
    3: '3rd Generation',
  };

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _c.fetchReferralRewards(page: _page);
      if (_c.portfolio.value == null) _c.fetchPortfolio();
    });
  }

  Map<int, String> _pcts() {
    final res = <int, String>{1: '—', 2: '—', 3: '—'};
    for (final r in _c.referralRewards) {
      final l = r.referralLevel;
      if (r.commissionPct != null && res[l] == '—')
        res[l] = '${r.commissionPct!.toStringAsFixed(0)}%';
    }
    final tier = _c.portfolio.value?.userTier;
    if (tier != null) {
      if (res[1] == '—') res[1] = '${tier.level1Percent.toStringAsFixed(0)}%';
      if (res[2] == '—') res[2] = '${tier.level2Percent.toStringAsFixed(0)}%';
      if (res[3] == '—') res[3] = '${tier.level3Percent.toStringAsFixed(0)}%';
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Obx(() {
        if (_c.isLoadingReferral.value) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final pcts = _pcts();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Header (Figma style: back arrow + title stacked) ─────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-15, 0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),
                     Container(
                      color: Colors.transparent,
                      child: Text(
                        'Referral Earnings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      color: Colors.transparent,
                      child: Text(
                        'Commission earned from your referrals\' staking rewards',
                        style: TextStyle(color: Colors.white,fontFamily: "DMSans", fontWeight: FontWeight.w400, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // ── Live Dashboard button (small, left-aligned) ──────────────
            GestureDetector(
              onTap: () => Get.to(() => const McPortfolioScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Live Dashboard',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 3 Level cards — 2×2 grid (Figma layout) ─────────────────
            Builder(builder: (_) {
              Widget levelCard(int lvl) {
                final color = _lvlColors[lvl] ?? _green;
                final label = _lvlLabels[lvl] ?? '';
                final pct = pcts[lvl] ?? '—';
                final earned = _c.referralRewards
                    .where((r) => r.referralLevel == lvl)
                    .fold(0.0, (s, r) => s + r.rewardAmount);
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level $lvl',
                            style:  TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pct,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                       Text(
                        'of referral\'s daily\nstaking reward',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                          height: 1.4,
                        ),
                      ),
                      if (earned > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Earned this page:\n+${earned.toStringAsFixed(8)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Row 1: Level 1 & Level 2 side by side
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: levelCard(1)),
                        const SizedBox(width: 20),
                        Expanded(child: levelCard(2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Row 2: Level 3 half-width left aligned
                  Row(
                    children: [
                      Expanded(child: levelCard(3)),
                      const SizedBox(width: 20),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // ── How it works ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 How Referral Earnings Work',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final p = _pcts();
                    return RichText(
                      text: TextSpan(
                        style:  TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          fontFamily: 'DMSans',
                        ),
                        children: [
                           TextSpan(
                            text:
                                'When your referred users earn staking rewards, you automatically receive a commission. If your Level 1 referral earns ',
                          ),
                          const TextSpan(
                            text: '\$100',
                            style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          fontFamily: 'DMSans',
                        ),
                          ),
                          const TextSpan(
                            text: ' in staking rewards, you earn ',
                          ),
                          TextSpan(
                            text: '\$10\n(${p[1] ?? '10%'})',
                            style: const TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' instantly credited to your wallet. Level 2 earns you ',
                          ),
                          TextSpan(
                            text: p[2] ?? '5%',
                            style: const TextStyle(
                              color: Color(0xFFE946FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const TextSpan(text: ' and Level 3 earns '),
                          TextSpan(
                            text: p[3] ?? '3%',
                            style: const TextStyle(
                              color: Color(0xFF00B052),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const TextSpan(
                            text: ' all automatically, every day.',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Table ────────────────────────────────────────────────────
            if (_c.referralRewards.isEmpty)
              _emptyState(
                'No Referral Earnings Yet',
                'Invite friends to stake and earn commissions',
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.transparent),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 680,
                    child: Column(
                      children: [
                        _refTblHeader(),
                        ..._c.referralRewards.asMap().entries.map(
                          (e) => _refTblRow(e.key, e.value, pcts),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

                  const SizedBox(height: 20),
                  _pagination(_c.referralMeta.value, (p) {
                    setState(() => _page = p);
                    _c.fetchReferralRewards(page: p);
                  }),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _refTblHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
    ),
    child: const Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            'No.',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 160,
          child: Text(
            'Date & Time',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 120,
          child: Text(
            'Level',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 160,
          child: Text(
            'Their Earning',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 160,
          child: Text(
            'Commission',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _refTblRow(int idx, McReferralReward r, Map<int, String> pcts) {
    const lvlColors = {1: _green, 2: Color(0xFFE946FF), 3: Color(0xFF00B052)};
    final color = lvlColors[r.referralLevel] ?? _green;
    final pct = r.commissionPct != null
        ? '${r.commissionPct!.toStringAsFixed(0)}%'
        : (pcts[r.referralLevel] ?? '—');
    final dateStr = _parseDate(r.rewardDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF222222), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${(_page - 1) * 15 + idx + 1}',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 160,
            child: Column(
              children: [
                Text(
                  dateStr.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (dateStr.$2.isNotEmpty)
                  Text(
                    dateStr.$2,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'L${r.referralLevel} · $pct',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 160,
            child: Column(
              children: [
                // From user name
                Text(
                  r.fromName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                // Their earning amount
                Text(
                  '+${r.fromEarning.toStringAsFixed(7).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} USDT',
                  style: const TextStyle(color: _green, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              '+${r.rewardAmount.toStringAsFixed(7).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} USDT',
              style: const TextStyle(
                color: Color(0xFF00B052),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _parseDate(String? raw) {
    if (raw == null) return ('—', '');
    try {
      final d = DateTime.parse(raw).toLocal();
      final date = '${d.month}/${d.day}/${d.year}';
      final h = d.hour;
      final time =
          '${h > 12
              ? h - 12
              : h == 0
              ? 12
              : h}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
      return (date, time);
    } catch (_) {
      return (raw, '');
    }
  }
}

// ── shared helpers ────────────────────────────────────────────────────────────
Widget _emptyState(String title, String sub) => Center(
  child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_rounded, color: Color(0xFF333333), size: 64),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);

Widget _pagination(Map<String, dynamic>? meta, Function(int) onPage) {
  final last = meta?['last_page'] ?? 1;
  if (last <= 1) return const SizedBox.shrink();
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(last, (i) {
      final p = i + 1;
      return GestureDetector(
        onTap: () => onPage(p),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Center(
            child: Text(
              '$p',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ),
      );
    }),
  );
}
