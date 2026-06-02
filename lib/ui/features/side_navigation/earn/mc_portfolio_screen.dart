import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart' show McStakingController;
import 'mc_staking_models.dart';
import 'mc_my_stakes_screen.dart';
import 'mc_withdraw_history_screen.dart';
import 'mc_staking_screen.dart' show McRewardsScreen, McReferralRewardsScreen;

const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF0A0B0D);
const _kCard = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF111111);

class McPortfolioScreen extends StatefulWidget {
  const McPortfolioScreen({super.key});

  @override
  State<McPortfolioScreen> createState() => _McPortfolioScreenState();
}

class _McPortfolioScreenState extends State<McPortfolioScreen> {
  late McStakingController _c;

  double _totalEarned = 0;
  double _availableToWithdraw = 0;
  double _sessionEarned = 0;
  int _uptime = 0;
  double _totalPerSec = 0;

  final Map<String, _StakeBase> _stakeBases = {};
  bool _counterReady = false;
  Timer? _ticker;

  _WithdrawInfo? _withdrawInfo;
  bool _isConfirmingWithdraw = false;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await _c.fetchPortfolio();
    _initCounter();
  }

  void _initCounter() {
    final portfolio = _c.portfolio.value;
    if (portfolio == null || portfolio.portfolio.isEmpty) return;
    if (_counterReady) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    double initTotal = 0, initAvail = 0, totalPerSec = 0;

    for (final item in portfolio.portfolio) {
      final perSec = item.perSecUsdt;
      totalPerSec += perSec;
      final startMs =
          _parseDate(
            item.stakedAt ?? item.endDate ?? '',
          )?.millisecondsSinceEpoch ??
          now;
      final secsSince = ((now - startMs) / 1000).clamp(0.0, double.infinity);
      final earned = perSec * secsSince;
      final withdrawn =
          item.totalWithdrawn *
          (item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1);
      final avail = (earned - withdrawn).clamp(0.0, double.infinity);
      initTotal += earned;
      initAvail += avail;
      _stakeBases[item.stakeUid] = _StakeBase(
        base: avail,
        perSec: perSec,
        baseTime: DateTime.now().millisecondsSinceEpoch,
      );
    }

    _totalEarned = initTotal;
    _availableToWithdraw = initAvail;
    _totalPerSec = totalPerSec;
    _counterReady = true;
    final sessionStart = DateTime.now().millisecondsSinceEpoch;

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final sinceSession = (nowMs - sessionStart) / 1000;
      setState(() {
        _totalEarned = initTotal + _totalPerSec * sinceSession;
        _availableToWithdraw = (initAvail + _totalPerSec * sinceSession).clamp(
          0.0,
          double.infinity,
        );
        _sessionEarned = _totalPerSec * sinceSession;
        _uptime = sinceSession.toInt();
      });
    });
  }

  DateTime? _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double _stakeAvailable(String uid) {
    final sb = _stakeBases[uid];
    if (sb == null) return 0;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - sb.baseTime) / 1000;
    return (sb.base + sb.perSec * elapsed).clamp(0.0, double.infinity);
  }

  double get _totalDailyReward {
    final p = _c.portfolio.value;
    if (p == null) return 0;
    return p.portfolio.fold(
      0.0,
      (s, i) => s + i.stakedAmount * (i.dailyRate / 100),
    );
  }

  // Compute portfolio value from positions if totalUsdtValue is 0
  double get _portfolioValue {
    final p = _c.portfolio.value;
    if (p == null) return 0;
    if (p.totalUsdtValue > 0) return p.totalUsdtValue;
    return p.portfolio.fold(0.0, (s, i) => s + i.usdtValue);
  }

  void _openWithdrawModal(McPortfolioItem item) {
    final earnedUsdt = _stakeAvailable(item.stakeUid);
    final earnedCoin = item.coinPriceUsdt > 0
        ? earnedUsdt / item.coinPriceUsdt
        : earnedUsdt;
    if (earnedUsdt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No rewards to withdraw yet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(
      () => _withdrawInfo = _WithdrawInfo(
        uid: item.stakeUid,
        earnedCoin: earnedCoin,
        earnedUsdt: earnedUsdt,
        symbol: item.coinSymbol,
      ),
    );
  }

  Future<void> _confirmWithdraw() async {
    final info = _withdrawInfo;
    if (info == null) return;
    setState(() {
      _isConfirmingWithdraw = true;
      _withdrawInfo = null;
    });
    final ok = await _c.withdrawReward(info.uid, info.earnedUsdt);
    if (ok) {
      final sb = _stakeBases[info.uid];
      if (sb != null) {
        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - sb.baseTime) / 1000;
        final cur = sb.base + sb.perSec * elapsed;
        sb.base = (cur - info.earnedUsdt).clamp(0.0, double.infinity);
        sb.baseTime = DateTime.now().millisecondsSinceEpoch;
      }
    }
    setState(() => _isConfirmingWithdraw = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Obx(() {
        if (_c.isLoadingPortfolio.value) {
          return const Center(child: CircularProgressIndicator(color: _kGreen));
        }
        final portfolio = _c.portfolio.value;
        final hasStakes = (portfolio?.portfolio.isNotEmpty) ?? false;

        return Stack(
          children: [
            RefreshIndicator(
              color: _kGreen,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  // Back arrow — scrolls with content, left-aligned
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildPageHeader(),
                  const SizedBox(height: 20),
                  _buildLiveCard(hasStakes),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  _buildTierCard(
                    portfolio?.userTier ??
                        McUserTier(
                          tierName: 'Basic',
                          level1Percent: 0,
                          level2Percent: 0,
                          level3Percent: 0,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (hasStakes) _buildPositionsTable(portfolio!.portfolio),
                  const SizedBox(height: 20),
                  _buildNavCards(),
                ],
              ),
            ),
            if (_withdrawInfo != null) _buildWithdrawModal(),
          ],
        );
      }),
    );
  }

  // ── PAGE HEADER (title + subtitle + buttons — outside the card) ──────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Real-time staking earnings — updating every 10 seconds',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            // "+ New Stake" outlined — compact size
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kGreen),
                ),
                child: const Text(
                  '+ New Stake',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // "My Stake" green filled — compact size
            GestureDetector(
              onTap: () => Get.to(() => const McMyStakesScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'My Stake',
                  style: TextStyle(
                    color: Colors.black,0
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── LIVE EARNING CARD (Figma exact) ──────────────────────────────────────
  Widget _buildLiveCard(bool hasStakes) {
    if (!hasStakes) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.symmetric(
              vertical: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -100,
                top: -40,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/images/wallet_green_wave.png',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Earning',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'No Active Stakes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start staking to see your live earnings dashboard',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                        fontFamily: 'DMSans',
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.symmetric(
            horizontal: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        child: Stack(
          children: [
            // Green wave — positioned right like the overview hero
            Positioned(
              right: -100,
              top: -40,
              child: Transform.rotate(
                angle: -0.4,
                child: Opacity(
                  opacity: 0.55,
                  child: Image.asset(
                    'assets/images/wallet_green_wave.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Live Earning" label — top-left, small
                  const Text(
                    'Live Earning',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 12,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Big $ number — left-aligned
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\$ ${_totalEarned.toStringAsFixed(8)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DMSans',
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Available to Withdraw — plain text, left-aligned
                  Row(
                    children: [
                      Text(
                        'Available to Withdraw: ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      Text(
                        _availableToWithdraw.toStringAsFixed(7),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 20),
                  // 3 stats with vertical dividers
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _statCol(
                          'Per Second',
                          '+${_totalPerSec.toStringAsFixed(8)}',
                          const Color(0xFF00B052),
                        ),
                        _vDivider(),
                        _statCol(
                          'Daily Total',
                          _totalDailyReward.toStringAsFixed(6),
                          const Color(0xFF00B052),
                        ),
                        _vDivider(),
                        _statCol(
                          'Session Earned',
                          _sessionEarned.toStringAsFixed(8),
                          const Color(0xFF00B052),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Session timer — bottom
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⏱',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          'Session: ${_fmtTime(_uptime)} · Actual rewards credited every 24h at midnight',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'DMSans',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color valueColor) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSans',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  Widget _vDivider() => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: 2),
    color: Colors.white.withValues(alpha: 0.12),
  );

  // ── STATS GRID ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final stats = _c.statistics.value;
    final portfolioVal = _portfolioValue;
    final items = [
      {
        'label': 'Portfolio Value',
        'value': '${portfolioVal.toStringAsFixed(2)}',
        'sub': 'USDT',
        'color': const Color(0xFFCCFF00),
        'icon': '💼',
      },
      {
        'label': 'Active Stakes',
        'value': '${stats?.totalActiveStakes ?? 0}',
        'sub': 'Positions',
        'color': const Color(0xFFE946FF),
        'icon': '📈',
      },
      {
        'label': 'Total Earned',
        'value': (stats?.totalRewardEarned ?? 0).toStringAsFixed(4),
        'sub': 'All time',
        'color': const Color(0xFF00B052),
        'icon': '💰',
      },
      {
        'label': 'Referrals',
        'value': '${stats?.totalReferralCommissions ?? 0}',
        'sub': 'Commissions',
        'color': const Color(0xFF00E5FF),
        'icon': '🔗',
      },
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.6,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      Text(
                        item['icon'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      color: item['color'] as Color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  Text(
                    item['sub'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _tierEmoji(String name) {
    switch (name.toLowerCase()) {
      case 'diamond':
        return '💎';
      case 'platinum':
        return '🔵';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      default:
        return '🥉';
    }
  }

  // ── TIER CARD (Figma: shows tier + levels + Portfolio Value on right) ─────
  Widget _buildTierCard(McUserTier tier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tierEmoji(tier.tierName),
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Referral Tier',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tier.tierName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Portfolio Value',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${_portfolioValue.toStringAsFixed(2)} USDT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tierLevelBox('Level 1', tier.level1Percent),
              _tierLevelBox('Level 2', tier.level2Percent),
              _tierLevelBox('Level 3', tier.level3Percent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tierLevelBox(String label, double pct) => Column(
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: 'DMSans',
        ),
      ),
      const SizedBox(height: 5),
      Text(
        '${pct.toStringAsFixed(4)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'DMSans',
        ),
      ),
    ],
  );

  // ── ACTIVE POSITIONS TABLE ────────────────────────────────────────────────
  Widget _buildPositionsTable(List<McPortfolioItem> positions) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Positions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00B052),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF00B052),
                        fontSize: 12,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
         
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Container(
                  height: 1,
                  width: 930,
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                ),
                // Table header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _thdr('Coin', 110),
                      _thdr('Plan', 140),
                      _thdr('Staked Amount', 110),
                      _thdr('Daily Rate', 90),
                      _thdr('Live Earned', 160),
                      _thdr('USDT Value', 90),
                      _thdr('Ends', 100),
                      _thdr('Action', 130),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  width: 930,
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                ...positions.map((item) => _positionRowNew(item)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
  }

  Widget _thdr(String t, double w) => SizedBox(
    width: w,
    child: Text(
      t,
      style: const TextStyle(
        color: Color(0x66FFFFFF),
        fontSize: 11,
        fontFamily: 'DMSans',
      ),
    ),
  );

  // ── ACTIVE POSITIONS ROW — per-column text styles (customize each one) ─────
  //
  // COIN column
  static const _tCoinSymbol = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  static const _tCoinSub = TextStyle(
    color: Color(0x66FFFFFF),
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // PLAN column
  static const _tPlanName = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  static const _tPlanDays = TextStyle(
    color: Color(0x80FFFFFF),
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // STAKED AMOUNT column
  static const _tStakedAmt = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // DAILY RATE column
  static const _tDailyRate = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // LIVE EARNED column — coin value (top)
  static const _tLiveEarnedCoin = TextStyle(
    color: Color(0xFF00B052),
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // LIVE EARNED column — USDT sub (bottom)
  static const _tLiveEarnedUsdt = TextStyle(
    color: Color(0x66FFFFFF),
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // USDT VALUE column
  static const _tUsdtValue = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // ENDS column
  static const _tEndsDate = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'DMSans',
  );
  // ACTION button — label
  static const _tWithdrawLabel = TextStyle(
    color: Colors.black,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamily: 'DMSans',
  );
  // ACTION button — coin amount sub
  static const _tWithdrawAmt = TextStyle(
    color: Colors.black,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.3,
    fontFamily: 'DMSans',
  );

  Widget _positionRowNew(McPortfolioItem item) {
    final earnedUsdt = _stakeAvailable(item.stakeUid);
    final earnedCoin = item.coinPriceUsdt > 0
        ? earnedUsdt / item.coinPriceUsdt
        : earnedUsdt;
    final nameParts = _splitPlanName(item.planName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Coin ──────────────────────────────────────────────────────────
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.coinSymbol, style: _tCoinSymbol),
                Text('Live Dashboard →', style: _tCoinSub),
              ],
            ),
          ),
          // ── Plan ──────────────────────────────────────────────────────────
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nameParts.$1, style: _tPlanName),
                if (nameParts.$2.isNotEmpty)
                  Text(nameParts.$2, style: _tPlanDays),
              ],
            ),
          ),
          // ── Staked Amount ─────────────────────────────────────────────────
          SizedBox(
            width: 110,
            child: Text(_fmt(item.stakedAmount), style: _tStakedAmt),
          ),
          // ── Daily Rate ────────────────────────────────────────────────────
          SizedBox(
            width: 90,
            child: Text(
              '${item.dailyRate.toStringAsFixed(2)}%',
              style: _tDailyRate,
            ),
          ),
          // ── Live Earned ───────────────────────────────────────────────────
          Builder(
            builder: (_) {
              final eu = _stakeAvailable(item.stakeUid);
              final ec = item.coinPriceUsdt > 0 ? eu / item.coinPriceUsdt : eu;
              return SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ec.toStringAsFixed(8)} ${item.coinSymbol}',
                      style: _tLiveEarnedCoin,
                    ),
                    Text(
                      '≈ \$${eu.toStringAsFixed(4)} USDT',
                      style: _tLiveEarnedUsdt,
                    ),
                  ],
                ),
              );
            },
          ),
          // ── USDT Value ────────────────────────────────────────────────────
          SizedBox(
            width: 90,
            child: Text(
              '\$${item.usdtValue.toStringAsFixed(0)}',
              style: _tUsdtValue,
            ),
          ),
          // ── Ends ──────────────────────────────────────────────────────────
          SizedBox(
            width: 100,
            child: Text(
              item.endDate?.split('T').first ?? '—',
              style: _tEndsDate,
            ),
          ),
          // ── Action — Withdraw button ───────────────────────────────────────
          SizedBox(
            width: 130,
            child: Obx(() {
              final withdrawing = _c.isWithdrawing.value == item.stakeUid;
              return GestureDetector(
                onTap: withdrawing ? null : () => _openWithdrawModal(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: withdrawing
                        ? _kGreen.withValues(alpha: 0.3)
                        : _kGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💰 ', style: TextStyle(fontSize: 10)),
                          Text(
                            withdrawing ? '...' : 'Withdraw',
                            style: _tWithdrawLabel,
                          ),
                        ],
                      ),
                      Text(
                        '${earnedCoin.toStringAsFixed(4)} ${item.coinSymbol}',
                        style: _tWithdrawAmt,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  (String, String) _splitPlanName(String name) {
    final match = RegExp(
      r'^(.*?)\s+(\d+\s*Days)$',
      caseSensitive: false,
    ).firstMatch(name);
    if (match != null) return (match.group(1)!, match.group(2)!);
    return (name, '');
  }

  // ── NAV CARDS (matches Figma bottom grid) ─────────────────────────────────
  Widget _buildNavCards() {
    final navItems = [
      _NavCard(
        Icons.flash_on,
        'New Stake',
        'Add Stake to Earn',
        () => Get.until((route) => route.isFirst),
      ),
      _NavCard(Icons.people_outline, 'My Network', 'Referral', () {}),
      _NavCard(
        Icons.link,
        'Referral Earnings',
        'Commission history',
        () => Get.to(() => const McReferralRewardsScreen()),
      ),
      _NavCard(
        Icons.monetization_on_outlined,
        'Reward History',
        'Daily logs',
        () => Get.to(() => const McRewardsScreen()),
      ),
      _NavCard(
        Icons.account_balance_outlined,
        'Withdraw History',
        'Check History',
        () => Get.to(() => const McWithdrawHistoryScreen()),
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: navItems
          .map(
            (item) => GestureDetector(
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: _kGreen, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          Text(
                            item.desc,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                              fontFamily: 'DMSans',
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

  // ── WITHDRAW MODAL ────────────────────────────────────────────────────────
  Widget _buildWithdrawModal() {
    final info = _withdrawInfo!;
    final fee = info.earnedCoin * 0.02;
    final receive = info.earnedCoin * 0.98;
    return GestureDetector(
      onTap: () => setState(() => _withdrawInfo = null),
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  const Text(
                    'Confirm Withdrawal',
                    style: TextStyle(
                      color: _kGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rewards will be sent to your spot wallet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCard2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _modalRow(
                          'Gross Reward',
                          '${info.earnedCoin.toStringAsFixed(8)} ${info.symbol}',
                          Colors.white,
                        ),
                        const Divider(color: Color(0xFF222222)),
                        _modalRow(
                          'Service Fee (2%)',
                          '- ${fee.toStringAsFixed(8)} ${info.symbol}',
                          const Color(0xFFF87171),
                        ),
                        const Divider(color: Color(0xFF222222)),
                        _modalRow(
                          'You Receive',
                          '${receive.toStringAsFixed(8)} ${info.symbol}',
                          _kGreen,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _withdrawInfo = null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Color(0xFF333333)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isConfirmingWithdraw
                              ? null
                              : _confirmWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Confirm Withdraw',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontFamily: 'DMSans',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    ),
  );

  String _fmtTime(int s) =>
      '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _StakeBase {
  double base;
  final double perSec;
  int baseTime;
  _StakeBase({
    required this.base,
    required this.perSec,
    required this.baseTime,
  });
}

class _WithdrawInfo {
  final String uid;
  final double earnedCoin;
  final double earnedUsdt;
  final String symbol;
  _WithdrawInfo({
    required this.uid,
    required this.earnedCoin,
    required this.earnedUsdt,
    required this.symbol,
  });
}

class _NavCard {
  final IconData icon;
  final String label, desc;
  final VoidCallback onTap;
  _NavCard(this.icon, this.label, this.desc, this.onTap);
}
