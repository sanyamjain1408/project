import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_my_stakes_screen.dart';
import 'mc_earnings_schedule_screen.dart';
import 'mc_certificate_screen.dart';

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

class _McPortfolioScreenState extends State<McPortfolioScreen> with WidgetsBindingObserver {
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
  _WithdrawSuccess? _withdrawSuccess;
  bool _isConfirmingWithdraw = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
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
        _c.fetchPortfolio(),
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
          durationDays: int.tryParse(pos['duration_days']?.toString() ?? '0') ?? 0,
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
    WidgetsBinding.instance.removeObserver(this);
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
      final fee = info.earnedCoin * 0.02;
      final received = info.earnedCoin * 0.98;
      if (mounted) setState(() => _withdrawSuccess = _WithdrawSuccess(
        amountReceived: received,
        serviceFee: fee,
        symbol: info.symbol,
      ));
      // Re-fetch fresh data so last_withdrawn_at resets and available goes to 0
      await Future.wait([
        _c.fetchPortfolio(),
        if (widget.coinId != null && widget.coinId! > 0)
          _c.fetchCoinDashboard(widget.coinId!).then((_) {
            _dashData = _c.coinDashboard.value;
          }),
      ]);
      _counterReady = false;
      _stakeBases.clear();
      _buildPositions();
      _initCounter();
    }
    if (mounted) setState(() => _isConfirmingWithdraw = false);
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
            if (_withdrawSuccess != null) _buildWithdrawSuccessModal(),
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
                            () => Get.to(() => const McMyStakesScreen())?.then((_) => _loadData()),
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
    final coinLogoFromDash = _dashData?['coin_logo'] as String?;
    final coinLogoFromList = _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo;
    final resolvedLogo = item.coinLogo ?? coinLogoFromDash ?? coinLogoFromList;
    final logoUrl = mcLogoUrl(resolvedLogo, symbol: symbol);
    final availableCoin = _stakeAvailable(item.stakeUid);
    final liveEarnedCoin = _stakeLiveEarned(item.stakeUid);
    final price = item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1.0;
    final liveEarnedUsdt = liveEarnedCoin * price;
    final rewardAccruedUsdt = item.totalEarned * price;
    final withdrawRewardUsdt = item.totalWithdrawn * price;
    final dailyRewardCoin = item.stakedAmount * (item.dailyRate / 100);
    final dailyRewardUsdt = dailyRewardCoin * price;
    final planDays = item.durationDays > 0 ? item.durationDays : _parseDays(item.planName);
    final stakedAtDt = item.stakedAt != null ? DateTime.tryParse(item.stakedAt!) : null;
    final endDt = item.endDate != null && item.endDate!.isNotEmpty
        ? DateTime.tryParse(item.endDate!)
        : (stakedAtDt != null && planDays > 0 ? stakedAtDt.add(Duration(days: planDays)) : null);
    final daysCompleted = stakedAtDt != null ? DateTime.now().difference(stakedAtDt).inDays : 0;
    final daysRemaining = endDt != null ? endDt.difference(DateTime.now()).inDays.clamp(0, planDays) : 0;
    final maturityFmt = endDt != null ? _fmtDateLong(endDt.toIso8601String()) : 'Flexible';
    final stakingType = item.planType == 1 ? 'Flexible Staking' : 'Locked Staking';
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: coin icon + name/subtitle + withdraw button ────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Container(
                  width: 36,
                  height: 36,
                  color: const Color(0xFF222222),
                  child: logoUrl.isNotEmpty
                      ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, e, s) => _initial(symbol, 36))
                      : _initial(symbol, 36),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$symbol-USDT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x4C00FF04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Active', style: TextStyle(color: Color(0xFF00FF04), fontSize: 12, fontFamily: 'DMSans')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${planDays > 0 ? '$planDays Days' : 'Open'} · ${item.planType == 1 ? 'Flexible' : 'Fixed'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                final busy = _c.isWithdrawing.value == item.stakeUid;
                return GestureDetector(
                  onTap: busy || availableCoin <= 0.000001 ? null : () => _openWithdrawModal(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: availableCoin > 0.000001 ? _kGreen : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: busy
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(
                            'Withdraw\n${availableCoin.toStringAsFixed(4)} $symbol',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF111111), fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400),
                          ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 14),

          // ── Action Pills row: Earnings Schedule | Cancel Stake ────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _darkPill('Earnings Schedule', const Color(0xFFCCFF00), () => Get.to(() => McEarningsScheduleScreen(stakeUid: item.stakeUid))),
                const SizedBox(width: 8),
                Obx(() {
                  final cancelling = _c.isCancelling.value == item.stakeUid;
                  return _darkPill(
                    cancelling ? 'Cancelling...' : 'Cancel Stake',
                    const Color(0xFFFF0000),
                    cancelling ? null : () => _openCancelConfirm(item),
                  );
                }),
                const SizedBox(width: 8),
                _darkPill('Certificate', const Color(0xFFCCFF00), () {
                  Get.to(() => McCertificateScreen(stake: {
                    'plan_name': item.planName,
                    'coin_symbol': symbol,
                    'coin_name': '',
                    'amount': item.stakedAmount,
                    'daily_rate': item.dailyRate,
                    'total_return': planDays > 0 ? (item.dailyRate * planDays).toStringAsFixed(2) : null,
                    'duration_days': planDays,
                    'start_date': item.stakedAt ?? '',
                    'end_date': item.endDate ?? '',
                    'plan_type': item.planType,
                    'user_name': 'Valued Staker',
                    'cert_no': 'TRPX-${item.stakeUid.length >= 8 ? item.stakeUid.substring(0, 8).toUpperCase() : item.stakeUid.toUpperCase()}',
                  }));
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Stat rows ────────────────────────────────────────────────────
          _statRow('Live Earnings', '${liveEarnedCoin.toStringAsFixed(6)} $symbol', Colors.white),
          _statRow('Reward Accrued', '${availableCoin.toStringAsFixed(6)} $symbol', Colors.white),
          _statRow('Withdraw Reward', '${item.totalWithdrawn.toStringAsFixed(6)} $symbol', Colors.white),
          _statRow('Total Stacked', '${item.stakedAmount.toStringAsFixed(0)} $symbol', const Color(0xFF4DD78D)),
          _statRow('USDT Value', '${item.usdtValue.toStringAsFixed(2)} USDT', Colors.white),
          _statRow('Daily Rate', '${item.dailyRate.toStringAsFixed(6)}%/days', Colors.white),
          _statRow('Daily Reward', '${dailyRewardCoin.toStringAsFixed(6)} $symbol', Colors.white),
          _statRow('Days Completed', '$daysCompleted / $planDays days', Colors.white),
          _statRow('Days Remaining', planDays > 0 ? '$daysRemaining days' : 'Flexible', Colors.white),
          _statRow('Maturity Date', maturityFmt, Colors.white),
          _statRow('Staking Type', stakingType, Colors.white),
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

  Widget _darkPill(String label, Color fg, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400), maxLines: 1),
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

  Widget _buildWithdrawSuccessModal() {
    final s = _withdrawSuccess!;
    return GestureDetector(
      onTap: () => setState(() => _withdrawSuccess = null),
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
                  // Green check circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kGreen, width: 2.5),
                    ),
                    child: const Icon(Icons.check_rounded, color: _kGreen, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Withdrawal Successful!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your staking rewards have been credited to your Spot Wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontFamily: 'DMSans',
                    ),
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
                        _modalRow('Amount Received',
                            '${s.amountReceived.toStringAsFixed(8)} ${s.symbol}', _kGreen),
                        const Divider(color: Color(0xFF222222)),
                        _modalRow('Service Fee (2%)',
                            '${s.serviceFee.toStringAsFixed(8)} ${s.symbol}', const Color(0xFFF87171)),
                        const Divider(color: Color(0xFF222222)),
                        _modalRow('Destination', 'Spot Wallet', Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _withdrawSuccess = null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'DMSans'),
                      ),
                    ),
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
  void _openCancelConfirm(McPortfolioItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CancelConfirmDialog(
        stakedAmount: item.stakedAmount,
        symbol: item.coinSymbol,
        onConfirm: () async {
          Navigator.of(context).pop();
          final result = await _c.cancelStake(item.stakeUid);
          if (result != null && mounted) {
            // Immediately remove from positions so card disappears right away
            _positions.removeWhere((p) => p.stakeUid == item.stakeUid);
            _c.stakes.removeWhere((s) => s.uid == item.stakeUid);
            if (mounted) setState(() {});
            await _loadData();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => _CancelSuccessDialog(
                stakedAmount: double.tryParse(result['staked_amount']?.toString() ?? '0') ?? item.stakedAmount,
                penalty: double.tryParse(result['penalty']?.toString() ?? '0') ?? 0,
                refund: double.tryParse(result['refund']?.toString() ?? '0') ?? 0,
                symbol: result['symbol']?.toString() ?? item.coinSymbol,
                txRef: result['tx_ref']?.toString() ?? '',
              ),
            );
          }
        },
      ),
    );
  }

  String _fmtDateLong(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return d; }
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

class _WithdrawSuccess {
  final double amountReceived;
  final double serviceFee;
  final String symbol;
  _WithdrawSuccess({required this.amountReceived, required this.serviceFee, required this.symbol});
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

// ── Cancel Confirm Dialog ─────────────────────────────────────────────────────
class _CancelConfirmDialog extends StatefulWidget {
  final double stakedAmount;
  final String symbol;
  final Future<void> Function() onConfirm;
  const _CancelConfirmDialog({required this.stakedAmount, required this.symbol, required this.onConfirm});
  @override State<_CancelConfirmDialog> createState() => _CancelConfirmDialogState();
}
class _CancelConfirmDialogState extends State<_CancelConfirmDialog> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final penalty = widget.stakedAmount * 0.20;
    final receive = widget.stakedAmount - penalty;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3D1A00)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 30),
            ),
            const SizedBox(height: 12),
            const Text('Early Cancellation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
            const SizedBox(height: 4),
            Text('You are cancelling before the plan completes.', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontFamily: 'DMSans')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Text('A 20% penalty will be deducted',
                  style: TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                const SizedBox(height: 10),
                _row('Staked', '${widget.stakedAmount.toStringAsFixed(0)} ${widget.symbol}', Colors.white),
                const Divider(color: Color(0xFF222222)),
                _row('Penalty (20%)', '-${penalty.toStringAsFixed(0)} ${widget.symbol}', const Color(0xFFF87171)),
                const Divider(color: Color(0xFF222222)),
                _row('You receive', '${receive.toStringAsFixed(0)} ${widget.symbol}', const Color(0xFFCCFF00), bold: true),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF333333)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Keep Staking', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : () async {
                    setState(() => _loading = true);
                    await widget.onConfirm();
                    if (mounted) setState(() => _loading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Cancel Anyway', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  Widget _row(String l, String v, Color vc, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
      Text(v, style: TextStyle(color: vc, fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontFamily: 'DMSans')),
    ]),
  );
}

// ── Cancel Success Dialog ─────────────────────────────────────────────────────
class _CancelSuccessDialog extends StatelessWidget {
  final double stakedAmount, penalty, refund;
  final String symbol, txRef;
  const _CancelSuccessDialog({required this.stakedAmount, required this.penalty, required this.refund, required this.symbol, required this.txRef});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCCFF00), width: 2.5)),
              child: const Icon(Icons.check_rounded, color: Color(0xFFCCFF00), size: 32),
            ),
            const SizedBox(height: 12),
            const Text('Stake Cancelled', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
            const SizedBox(height: 4),
            Text('Funds returned to your Spot Wallet.', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontFamily: 'DMSans')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _row('Staked Amount', '${stakedAmount.toStringAsFixed(0)} $symbol', Colors.white),
                const Divider(color: Color(0xFF222222)),
                _row('Early Fee (20%)', '-${penalty.toStringAsFixed(0)} $symbol', const Color(0xFFF87171)),
                const Divider(color: Color(0xFF222222)),
                _row('You Received', '${refund.toStringAsFixed(0)} $symbol', const Color(0xFFCCFF00), bold: true),
                const Divider(color: Color(0xFF222222)),
                _row('Destination', 'Spot Wallet', Colors.white),
                if (txRef.isNotEmpty) ...[
                  const Divider(color: Color(0xFF222222)),
                  _row('Transaction ID', txRef, Colors.white),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _row(String l, String v, Color vc, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(color: vc, fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontFamily: 'DMSans'))),
    ]),
  );
}
