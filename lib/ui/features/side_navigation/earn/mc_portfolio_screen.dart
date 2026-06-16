import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_my_stakes_screen.dart';
import 'mc_earnings_schedule_screen.dart';

const _kGreen = Color(0xFFCCFF00);
const _kCard = Color(0xFF1A1A1A);
const _kBg = Color(0xFF111111);

class McPortfolioScreen extends StatefulWidget {
  final String? stakeUid;
  final int? coinId;
  final String? coinSymbol;
  const McPortfolioScreen({super.key, this.stakeUid, this.coinId, this.coinSymbol});

  @override
  State<McPortfolioScreen> createState() => _McPortfolioScreenState();
}

class _McPortfolioScreenState extends State<McPortfolioScreen> {
  late McStakingController _c;

  double _totalEarned = 0;       // USDT total (for multi-coin)
  double _totalEarnedCoin = 0;   // coin units (for single-coin display)
  double _totalPerSec = 0;
  double _totalDailyRewardCoin = 0;

  // Local coin-dashboard data (not shared with controller)
  Map<String, dynamic>? _dashData;
  bool _isLoading = true;

  // All positions for this screen (coin-filtered or all)
  List<McPortfolioItem> _positions = [];

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
    _ticker?.cancel();
    _ticker = null;
    if (mounted) setState(() { _counterReady = false; _isLoading = true; });
    _stakeBases.clear();

    if (widget.coinId != null && widget.coinId! > 0) {
      // Load coin-specific dashboard from API
      await Future.wait([
        _c.fetchCoinDashboard(widget.coinId!).then((_) {
          _dashData = _c.coinDashboard.value;
        }),
        _c.fetchRewards(),
      ]);
    } else {
      await Future.wait([
        _c.fetchPortfolio(),
        _c.fetchRewards(),
      ]);
    }

    _buildPositions();
    _initCounter();
    if (mounted) setState(() => _isLoading = false);
  }

  // Build _positions list from dash or portfolio
  void _buildPositions() {
    final dash = _dashData;
    if (dash != null && widget.coinId != null) {
      final rawPositions = dash['positions'] as List? ?? [];
      final coinPrice = double.tryParse(dash['coin_price_usdt']?.toString() ?? '1') ?? 1;
      // Keep portfolio map for fallback fields (total_withdrawn, etc.)
      final portfolioMap = {
        for (final p in (_c.portfolio.value?.portfolio ?? [])) p.stakeUid: p
      };
      final built = <McPortfolioItem>[];
      for (final pos in rawPositions) {
        final uid = pos['stake_uid'] ?? pos['uid'] ?? '';
        final amount = double.tryParse(pos['amount']?.toString() ?? '0') ?? 0;
        final rate = double.tryParse(pos['daily_rate']?.toString() ?? '0') ?? 0;
        final dr = double.tryParse(pos['daily_reward']?.toString() ?? '0') ?? 0;
        final dailyReward = dr > 0 ? dr : amount * rate / 100;
        // coin-dashboard uses 'total_earned', portfolio uses 'total_reward_earned'/'total_reward'
        // Always fallback to portfolio data for accuracy
        final portfolioItem = portfolioMap[uid];
        final totalEarnedRaw = double.tryParse(
                (pos['total_earned'] ?? pos['total_reward_earned'] ?? pos['total_reward'])
                    ?.toString() ??
                    '');
        final totalEarned = totalEarnedRaw ?? portfolioItem?.totalEarned ?? 0;
        final twRaw = double.tryParse(pos['total_withdrawn']?.toString() ?? '');
        final totalWithdrawn = twRaw ?? portfolioItem?.totalWithdrawn ?? 0;
        // Use portfolio usdtValue if available (server-calculated)
        final usdtVal = portfolioItem?.usdtValue ?? amount * coinPrice;
        built.add(McPortfolioItem(
          stakeUid: uid,
          coinSymbol: widget.coinSymbol ?? '',
          coinId: widget.coinId!,
          coinLogo: pos['coin_logo'],
          stakedAmount: amount,
          dailyRate: rate,
          dailyReward: dailyReward,
          planName: pos['plan_name'] ?? '',
          planType: pos['plan_type'] ?? 1,
          endDate: pos['end_date'],
          stakedAt: pos['staked_at'] ?? pos['start_date'],
          lastWithdrawnAt: pos['last_withdrawn_at'] ?? portfolioItem?.lastWithdrawnAt,
          totalWithdrawn: totalWithdrawn,
          coinPriceUsdt: coinPrice,
          usdtValue: usdtVal,
          totalEarned: totalEarned,
        ));
      }
      if (built.isNotEmpty) {
        // If a specific stake was selected, show only that one
        if (widget.stakeUid != null && widget.stakeUid!.isNotEmpty) {
          final single = built.where((i) => i.stakeUid == widget.stakeUid).toList();
          _positions = single.isNotEmpty ? single : built;
        } else {
          _positions = built;
        }
        return;
      }
    }

    // Fallback to portfolio data, filtered by stakeUid first, then coinSymbol
    final all = _c.portfolio.value?.portfolio ?? [];
    if (widget.stakeUid != null && widget.stakeUid!.isNotEmpty) {
      final filtered = all.where((i) => i.stakeUid == widget.stakeUid).toList();
      _positions = filtered.isNotEmpty ? filtered : all;
    } else if (widget.coinSymbol != null && widget.coinSymbol!.isNotEmpty) {
      final filtered = all.where((i) => i.coinSymbol == widget.coinSymbol).toList();
      _positions = filtered.isNotEmpty ? filtered : all;
    } else {
      _positions = all;
    }
  }

  void _initCounter() {
    if (_counterReady || _positions.isEmpty) return;

    // Website formula (MobileStakingHistory):
    //   perSec = amount * (dailyRate/100) / 86400   (coin units/sec)
    //   liveEarned = perSec * secondsElapsedFromStartDate
    double initTotalUsdt = 0;
    double totalPerSecCoin = 0;
    double totalDailyCoin = 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (final item in _positions) {
      final price = item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1;
      final perSecCoin = item.stakedAmount * (item.dailyRate / 100) / 86400;
      final dailyCoin = item.stakedAmount * (item.dailyRate / 100);

      totalPerSecCoin += perSecCoin;
      totalDailyCoin += dailyCoin;

      // Compute elapsed seconds from start_date (website formula)
      final startDt = item.stakedAt != null ? DateTime.tryParse(item.stakedAt!) : null;
      final startMs = startDt?.millisecondsSinceEpoch ?? nowMs;
      final elapsedSec = ((nowMs - startMs) / 1000).clamp(0.0, double.infinity);

      // liveEarned in coin units = perSecCoin * totalElapsed
      final liveEarnedCoin = perSecCoin * elapsedSec;
      initTotalUsdt += liveEarnedCoin * price;
      _totalEarnedCoin += liveEarnedCoin;

      // _StakeBase tracks coin units from staked_at; lastWithdrawnMs for available calc
      final lastWMs = item.lastWithdrawnAt != null
          ? DateTime.tryParse(item.lastWithdrawnAt!)?.millisecondsSinceEpoch
          : null;
      _stakeBases[item.stakeUid] = _StakeBase(
        base: 0,
        perSec: perSecCoin,
        baseTime: startMs,
        totalWithdrawn: item.totalWithdrawn,
        lastWithdrawnMs: lastWMs,
      );
    }

    _totalEarned = initTotalUsdt;
    _totalPerSec = totalPerSecCoin;
    _totalDailyRewardCoin = totalDailyCoin;
    _counterReady = true;

    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      double totalUsdt = 0;
      double totalCoin = 0;
      for (final item in _positions) {
        final sb = _stakeBases[item.stakeUid];
        if (sb == null) continue;
        final price = item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1;
        final elapsedSec = ((now - sb.baseTime) / 1000).clamp(0.0, double.infinity);
        final liveEarnedCoin = sb.perSec * elapsedSec;
        totalUsdt += liveEarnedCoin * price;
        totalCoin += liveEarnedCoin;
      }
      setState(() {
        _totalEarned = totalUsdt;
        _totalEarnedCoin = totalCoin;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Returns available coin units — earned since last_withdrawn_at (same as web)
  double _stakeAvailable(String uid) {
    final sb = _stakeBases[uid];
    if (sb == null) return 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // Use last_withdrawn_at as start if available, else staked_at (baseTime)
    final availStartMs = sb.lastWithdrawnMs ?? sb.baseTime;
    final elapsed = ((nowMs - availStartMs) / 1000).clamp(0.0, double.infinity);
    return (sb.perSec * elapsed).clamp(0.0, double.infinity);
  }

  // Returns total live earned coin units (from start_date)
  double _stakeLiveEarned(String uid) {
    final sb = _stakeBases[uid];
    if (sb == null) return 0;
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - sb.baseTime) / 1000).clamp(0.0, double.infinity);
    return sb.perSec * elapsed;
  }

  // Daily Total in coin units (website: dailyEarning.toFixed(6) — coin units, not USD)
  double get _displayDailyCoin {
    if (_counterReady) return _totalDailyRewardCoin;
    return _positions.fold(0.0, (s, i) => s + i.stakedAmount * (i.dailyRate / 100));
  }

  void _openWithdrawModal(McPortfolioItem item) {
    // availableCoin = earned since last_withdrawn_at
    final availableCoin = _stakeAvailable(item.stakeUid);
    if (availableCoin <= 0.000001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rewards to withdraw yet.'), backgroundColor: Colors.red),
      );
      return;
    }
    // Send USDT value to backend (backend converts to coin) — same as web
    final price = item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1.0;
    final earnedUsdt = availableCoin * price;
    setState(() => _withdrawInfo = _WithdrawInfo(
          uid: item.stakeUid,
          earnedCoin: availableCoin,
          earnedUsdt: earnedUsdt,
          symbol: item.coinSymbol,
        ));
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
        final elapsed = (DateTime.now().millisecondsSinceEpoch - sb.baseTime) / 1000;
        final cur = sb.base + sb.perSec * elapsed;
        sb.base = (cur - info.earnedUsdt).clamp(0.0, double.infinity);
        sb.baseTime = DateTime.now().millisecondsSinceEpoch;
      }
    }
    setState(() => _isConfirmingWithdraw = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        // Trigger rebuild when controller loading state changes (for refresh)
        _c.isLoadingPortfolio.value;
        _c.isLoadingCoinDashboard.value;

        final hasStakes = _positions.isNotEmpty;
        final displayPositions = _positions;

        return Stack(
          children: [
            RefreshIndicator(
              color: _kGreen,
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Header ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Live Card ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: _buildLiveCard(hasStakes),
                  ),
                  const SizedBox(height: 20),

                  // ── Stake Cards ──────────────────────────────────────────────
                  if (hasStakes) ...[
                    if (displayPositions.length == 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStakeCard(displayPositions.first),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRewardHistoryTable(displayPositions.first),
                      ),
                    ] else ...[
                      ...displayPositions.map(
                        (item) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _buildStakeCard(item),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
            if (_withdrawInfo != null) _buildWithdrawModal(),
          ],
        );
      }),
    );
  }

  // ── LIVE CARD ────────────────────────────────────────────────────────────────
  Widget _buildLiveCard(bool hasStakes) {
    final screenW = MediaQuery.of(context).size.width;
    const cardH = 220.0;
    return SizedBox(
      width: screenW,
      height: hasStakes ? null : cardH,
      child: ClipPath(
        clipper: _PortfolioHeroClipper(cardW: screenW, cardH: cardH),
        child: Stack(
          children: [
            // SVG-shaped fill
            Positioned.fill(
              child: CustomPaint(
                painter: _PortfolioHeroPainter(
                  cardW: screenW,
                  cardH: cardH,
                  fillColor: const Color(0xFF111111),
                ),
              ),
            ),
            // Green wave — same placement as earn_screen
            Positioned(
              right: 25,
              top: 20,
              width: screenW * 0.42,
              height: cardH * 1.3,
              child: Transform.rotate(
                angle: 1.250,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/wallet_green_wave.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Border
            Positioned.fill(
              child: CustomPaint(
                painter: _PortfolioHeroBorderPainter(cardW: screenW, cardH: cardH),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "LIVE DASHBOARD" green label
                  const Text(
                    'LIVE DASHBOARD',
                    style: TextStyle(
                      color: _kGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // "Live Earning" grey sub-label
                  Text(
                    'Live Earning',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 4),

                  if (!hasStakes) ...[
                    const Text(
                      'No Active Stakes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start staking to see your live earnings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ] else ...[
                    // Big number
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _positions.length == 1
                            ? '${_totalEarnedCoin.toStringAsFixed(8)}'
                            : '\$ ${_totalEarned.toStringAsFixed(8)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                    // Show coin symbol label when single-coin view (like web)
                    if (_positions.length == 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        _positions.first.coinSymbol,
                        style: const TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],

                    // Per Second | Daily Total — same layout as earn screen hero
                    Row(
                      children: [
                        Expanded(child: _liveStatCol('Per Second', '+${_totalPerSec.toStringAsFixed(8)}')),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.10),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Expanded(child: _liveStatCol('Daily Total', _displayDailyCoin.toStringAsFixed(6))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Buttons: My Stake + Calculator — full width expanded
                    Row(
                      children: [
                        Expanded(
                          child: _cardBtn(
                            'My Stake',
                            _kGreen,
                            Colors.black,
                            () => Get.to(() => const McMyStakesScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _cardBtn(
                            'Calculator',
                            const Color(0xFF222222),
                            Colors.white,
                            () => {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveStatCol(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: 'DMSans',
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'DMSans',
          height: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  Widget _cardBtn(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      );

  // ── STAKE CARD ───────────────────────────────────────────────────────────────
  Widget _buildStakeCard(McPortfolioItem item) {
    final symbol = item.coinSymbol;
    // Try logo from item → dash top-level → coins list → CoinGecko fallback
    final coinLogoFromDash = _dashData?['coin_logo'] as String?;
    final coinLogoFromList = _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo;
    final resolvedLogo = item.coinLogo ?? coinLogoFromDash ?? coinLogoFromList;
    final logoUrl = mcLogoUrl(resolvedLogo, symbol: symbol);
    final earnedCoin = _stakeAvailable(item.stakeUid);
    final liveEarnedCoin = _stakeLiveEarned(item.stakeUid);
    final dailyRewardCoin = item.stakedAmount * (item.dailyRate / 100);
    final startFmt = _fmtDate(item.stakedAt);
    final planDays = _parseDays(item.planName);
    // Days remaining: compute from stakedAt + planDays if no endDate
    final stakedAtDt = item.stakedAt != null ? DateTime.tryParse(item.stakedAt!) : null;
    final endDt = item.endDate != null && item.endDate!.isNotEmpty
        ? DateTime.tryParse(item.endDate!)
        : (stakedAtDt != null && planDays > 0
            ? stakedAtDt.add(Duration(days: planDays))
            : null);
    // Show actual end date; if flexible with no endDate, compute from stakedAt + planDays
    final endFmt = endDt != null ? _fmtDate(endDt.toIso8601String()) : 'Flexible';

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Coin icon / initials
                ClipOval(
                  child: Container(
                    width: 36,
                    height: 36,
                    color: const Color(0xFF222222),
                    child: logoUrl.isNotEmpty
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => _initial(symbol, 36),
                          )
                        : _initial(symbol, 36),
                  ),
                ),
                const SizedBox(width: 10),
                // Symbol + plan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$symbol-USDT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Active badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF04).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00FF04).withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Color(0xFF00FF04),
                                fontSize: 11,
                                fontFamily: 'DMSans',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${planDays > 0 ? '$planDays Days' : 'Open'} · ${item.planType == 1 ? 'Flexible' : 'Fixed'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],
                  ),
                ),
                // Withdraw button
                Obx(() {
                  final busy = _c.isWithdrawing.value == item.stakeUid;
                  return GestureDetector(
                    onTap: busy ? null : () => _openWithdrawModal(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: busy ? _kGreen.withValues(alpha: 0.4) : _kGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Withdraw',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                                Text(
                                  '${earnedCoin.toStringAsFixed(4)} $symbol',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Action Pills ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _pill(
                  'Earnings Schedule',
                  _kGreen,
                  Colors.black,
                  () => Get.to(() => McEarningsScheduleScreen(stakeUid: item.stakeUid)),
                ),
                const SizedBox(width: 8),
                _pill(
                  'Cancel Stake',
                  Colors.transparent,
                  Colors.red,
                  () => _confirmCancel(item.stakeUid),
                  border: Colors.red.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          ),

          // ── Stat Rows ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _totalEarnedRow(liveEarnedCoin, item.coinPriceUsdt, symbol),
                _statRow(
                  'Total Stacked',
                  '${item.stakedAmount.toStringAsFixed(0)} $symbol',
                  Colors.white,
                ),
                _statRow(
                  'USDT Value',
                  '${item.usdtValue.toStringAsFixed(2)} USDT',
                  Colors.white,
                ),
                _statRow(
                  'Daily Earning',
                  '${dailyRewardCoin.toStringAsFixed(8)} $symbol',
                  Colors.white,
                ),
                _statRow(
                  'Daily Rate',
                  '${item.dailyRate.toStringAsFixed(6)}%/day',
                  Colors.white,
                ),
                _statRow(
                  'Date',
                  '$startFmt → $endFmt',
                  Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initial(String symbol, double size) => Center(
    child: Text(
      symbol.length >= 2 ? symbol.substring(0, 2) : (symbol.isNotEmpty ? symbol[0] : '?'),
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.28,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _pill(String label, Color bg, Color fg, VoidCallback onTap, {Color? border}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: border != null ? Border.all(color: border, width: 1) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSans',
            ),
          ),
        ),
      );

  Widget _totalEarnedRow(double liveEarned, double coinPrice, String symbol) {
    final usdVal = coinPrice > 0 ? liveEarned * coinPrice : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Earned',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${liveEarned.toStringAsFixed(8)} $symbol',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF00B052),
                    fontSize: 12,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (usdVal > 0)
                  Text(
                    '≈ \$${usdVal.toStringAsFixed(4)} USDT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontFamily: 'DMSans',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
            fontFamily: 'DMSans',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'DMSans',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  // ── REWARD HISTORY TABLE ─────────────────────────────────────────────────────
  Widget _buildRewardHistoryTable(McPortfolioItem item) {
    return Obx(() {
      // Filter by stakeUid first (exact match), fallback to coin symbol
      // Match by stakeId (integer) from McStake, since rewards don't carry stake_uid
      final matchingStake = _c.stakes.firstWhereOrNull((s) => s.uid == item.stakeUid);
      final stakeIntId = matchingStake?.id;
      final rewardsByStakeId = stakeIntId != null
          ? _c.rewards.where((r) => r.stakeId == stakeIntId).toList()
          : <McStakingReward>[];
      final rewards = rewardsByStakeId.isNotEmpty
          ? rewardsByStakeId
          : _c.rewards.where((r) => r.coin?.symbol == item.coinSymbol).toList();
      return Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: const Text(
                'Reward History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Date',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontFamily: 'DMSans')),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Reward Amount',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontFamily: 'DMSans')),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Rate',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontFamily: 'DMSans'),
                        textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            if (rewards.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No reward history yet',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                        fontFamily: 'DMSans')),
              )
            else
              ...rewards.take(10).map((r) => _rewardRow(r)),
          ],
        ),
      );
    });
  }

  Widget _rewardRow(McStakingReward r) {
    String dateFmt = r.rewardDate ?? '—';
    try {
      if (r.rewardDate != null) {
        final dt = DateTime.parse(r.rewardDate!);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        dateFmt = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(dateFmt,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DMSans')),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${r.rewardAmount.toStringAsFixed(6)} ${r.coin?.symbol ?? ''}',
              style: const TextStyle(color: _kGreen, fontSize: 12, fontFamily: 'DMSans'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${r.dailyRate.toStringAsFixed(4)}%',
              style: const TextStyle(color: Color(0xFF00B052), fontSize: 12, fontFamily: 'DMSans'),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── WITHDRAW MODAL ───────────────────────────────────────────────────────────
  Widget _buildWithdrawModal() {
    final info = _withdrawInfo!;
    final fee = info.earnedCoin * 0.02;
    final receive = info.earnedCoin * 0.98;
    return GestureDetector(
      onTap: () => setState(() => _withdrawInfo = null),
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
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
                  const Text('💰', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text(
                    'Confirm Withdrawal',
                    style: TextStyle(
                      color: _kGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rewards will be sent to your spot wallet',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontFamily: 'DMSans'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _modalRow('Gross Reward',
                            '${info.earnedCoin.toStringAsFixed(8)} ${info.symbol}', Colors.white),
                        const Divider(color: Color(0xFF222222)),
                        _modalRow('Service Fee (2%)',
                            '- ${fee.toStringAsFixed(8)} ${info.symbol}', const Color(0xFFF87171)),
                        const Divider(color: Color(0xFF222222)),
                        _modalRow('You Receive',
                            '${receive.toStringAsFixed(8)} ${info.symbol}', _kGreen, bold: true),
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
                              side: const BorderSide(color: Color(0xFF333333))),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isConfirmingWithdraw ? null : _confirmWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Confirm Withdraw',
                            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
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

  Widget _modalRow(String label, String value, Color color, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontFamily: 'DMSans')),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'DMSans')),
      ],
    ),
  );

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Future<void> _confirmCancel(String uid) async {
    final ok = await _c.cancelStake(uid);
    if (ok) _loadData();
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return d;
    }
  }

  int _parseDays(String planName) {
    // Try "600 Day" pattern first, then any trailing number (e.g. "TRPX VAULI 600")
    final m = RegExp(r'(\d+)\s*[Dd]ay').firstMatch(planName)
        ?? RegExp(r'(\d+)\s*$').firstMatch(planName);
    return m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
  }

}

// ── Supporting data classes ───────────────────────────────────────────────────
class _StakeBase {
  double base;
  final double perSec;
  int baseTime;
  final double totalWithdrawn;
  final int? lastWithdrawnMs; // for available calculation
  _StakeBase({required this.base, required this.perSec, required this.baseTime, this.totalWithdrawn = 0, this.lastWithdrawnMs});
}

class _WithdrawInfo {
  final String uid;
  final double earnedCoin;
  final double earnedUsdt;
  final String symbol;
  _WithdrawInfo(
      {required this.uid,
      required this.earnedCoin,
      required this.earnedUsdt,
      required this.symbol});
}

// ── Hero shape (same SVG path as earn_screen _EarnHeroPainter) ────────────────
const double _phSvgW = 362.0;
const double _phSvgH = 204.0;

Path _buildPortfolioHeroPath(double cardW, double cardH) {
  final sx = cardW / _phSvgW;
  final sy = cardH / _phSvgH;
  return Path()
    ..moveTo(0, 20 * sy)
    ..cubicTo(0, 8.9543 * sy, 8.95431 * sx, 0, 20 * sx, 0)
    ..lineTo(132.716 * sx, 0)
    ..cubicTo(138.02 * sx, 0, 143.107 * sx, 2.10714 * sy, 146.858 * sx, 5.85786 * sy)
    ..lineTo(155.142 * sx, 14.1421 * sy)
    ..cubicTo(158.893 * sx, 17.8929 * sy, 163.98 * sx, 20 * sy, 169.284 * sx, 20 * sy)
    ..lineTo(192.716 * sx, 20 * sy)
    ..cubicTo(198.02 * sx, 20 * sy, 203.107 * sx, 17.8929 * sy, 206.858 * sx, 14.1421 * sy)
    ..lineTo(215.142 * sx, 5.85786 * sy)
    ..cubicTo(218.893 * sx, 2.10713 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
    ..lineTo(342 * sx, 0)
    ..cubicTo(353.046 * sx, 0, 362 * sx, 8.95431 * sy, 362 * sx, 20 * sy)
    ..lineTo(362 * sx, 184 * sy)
    ..cubicTo(362 * sx, 195.046 * sy, 353.046 * sx, 204 * sy, 342 * sx, 204 * sy)
    ..lineTo(20 * sx, 204 * sy)
    ..cubicTo(8.9543 * sx, 204 * sy, 0, 195.046 * sy, 0, 184 * sy)
    ..lineTo(0, 20 * sy)
    ..close();
}

class _PortfolioHeroClipper extends CustomClipper<Path> {
  const _PortfolioHeroClipper({required this.cardW, required this.cardH});
  final double cardW, cardH;
  @override
  Path getClip(Size size) => _buildPortfolioHeroPath(cardW, cardH);
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _PortfolioHeroPainter extends CustomPainter {
  const _PortfolioHeroPainter({required this.cardW, required this.cardH, required this.fillColor});
  final double cardW, cardH;
  final Color fillColor;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_buildPortfolioHeroPath(cardW, cardH), Paint()..color = fillColor);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PortfolioHeroBorderPainter extends CustomPainter {
  const _PortfolioHeroBorderPainter({required this.cardW, required this.cardH});
  final double cardW, cardH;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _buildPortfolioHeroPath(cardW, cardH),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
