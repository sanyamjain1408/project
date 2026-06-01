import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_my_stakes_screen.dart';
import 'mc_withdraw_history_screen.dart';
import 'mc_staking_screen.dart' show McRewardsScreen, McReferralRewardsScreen;

const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF0A0B0D);
const _kCard = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF111111);

Widget _coinImg(String? logo, {double size = 40}) {
  final url = mcLogoUrl(logo);
  if (url.isNotEmpty) {
    return ClipOval(
      child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(size)),
    );
  }
  return _fallback(size);
}

Widget _fallback(double size) => Container(
      width: size, height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E2128)),
      child: const Icon(Icons.monetization_on, color: _kGreen, size: 16),
    );

class McPortfolioScreen extends StatefulWidget {
  const McPortfolioScreen({super.key});

  @override
  State<McPortfolioScreen> createState() => _McPortfolioScreenState();
}

class _McPortfolioScreenState extends State<McPortfolioScreen> {
  late McStakingController _c;

  // Live counter state
  double _totalEarned = 0;
  double _availableToWithdraw = 0;
  double _sessionEarned = 0;
  int _uptime = 0;
  double _totalPerSec = 0;

  // Per-stake independent bases
  final Map<String, _StakeBase> _stakeBases = {};
  bool _counterReady = false;
  Timer? _ticker;

  // Withdraw modal
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
      final startMs = _parseDate(item.stakedAt ?? item.endDate ?? '')?.millisecondsSinceEpoch ?? now;
      final secsSince = ((now - startMs) / 1000).clamp(0.0, double.infinity);
      final earned = perSec * secsSince;
      final withdrawn = item.totalWithdrawn * (item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1);
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
        _availableToWithdraw = (initAvail + _totalPerSec * sinceSession).clamp(0.0, double.infinity);
        _sessionEarned = _totalPerSec * sinceSession;
        _uptime = sinceSession.toInt();
      });
    });
  }

  DateTime? _parseDate(String s) {
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double _stakeAvailable(String uid) {
    final sb = _stakeBases[uid];
    if (sb == null) return 0;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - sb.baseTime) / 1000;
    return (sb.base + sb.perSec * elapsed).clamp(0.0, double.infinity);
  }

  double get _totalDailyReward {
    final p = _c.portfolio.value;
    if (p == null) return 0;
    return p.portfolio.fold(0.0, (s, i) => s + i.stakedAmount * (i.dailyRate / 100));
  }

  void _openWithdrawModal(McPortfolioItem item) {
    final earnedUsdt = _stakeAvailable(item.stakeUid);
    final earnedCoin = item.coinPriceUsdt > 0 ? earnedUsdt / item.coinPriceUsdt : earnedUsdt;
    if (earnedUsdt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rewards to withdraw yet.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _withdrawInfo = _WithdrawInfo(
        uid: item.stakeUid, earnedCoin: earnedCoin, earnedUsdt: earnedUsdt, symbol: item.coinSymbol));
  }

  Future<void> _confirmWithdraw() async {
    final info = _withdrawInfo;
    if (info == null) return;
    setState(() { _isConfirmingWithdraw = true; _withdrawInfo = null; });
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: const Text('Live Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
        actions: [
          TextButton(onPressed: () => Get.to(() => const McMyStakesScreen()),
              child: const Text('My Stakes', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700))),
        ],
      ),
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
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLiveCard(hasStakes),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  if (portfolio?.userTier != null) _buildTierCard(portfolio!.userTier!),
                  const SizedBox(height: 16),
                  if (hasStakes) _buildPositionsTable(portfolio!.portfolio),
                  const SizedBox(height: 16),
                  _buildNavCards(),
                ],
              ),
            ),
            // Withdraw modal overlay
            if (_withdrawInfo != null) _buildWithdrawModal(),
          ],
        );
      }),
    );
  }

  Widget _buildLiveCard(bool hasStakes) {
    if (!hasStakes) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const Icon(Icons.flash_on, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          const Text('No Active Stakes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Start staking to see your live earnings', style: TextStyle(color: Colors.white.withOpacity(0.4))),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00B052))),
          const SizedBox(width: 6),
          const Text('LIVE EARNING', style: TextStyle(color: Color(0xFF00B052), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 6),
        Text('Total Rewards Earned (All Time)', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 10),
        Text(_totalEarned.toStringAsFixed(8),
            style: const TextStyle(color: _kGreen, fontSize: 32, fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF04).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00FF04).withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Available to Withdraw: ', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            Text(_availableToWithdraw.toStringAsFixed(8),
                style: const TextStyle(color: Color(0xFF00FF04), fontWeight: FontWeight.w700, fontSize: 13,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _statMini('Per Second', '+${_totalPerSec.toStringAsFixed(8)}', Colors.white),
          _statMini('Daily Total', _totalDailyReward.toStringAsFixed(6), _kGreen),
          _statMini('Session Earned', _sessionEarned.toStringAsFixed(8), const Color(0xFF00B052)),
        ]),
        const SizedBox(height: 8),
        Text(
          '⏱ Session: ${_fmtTime(_uptime)} · Rewards credited every 24h',
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10),
        ),
      ]),
    );
  }

  Widget _statMini(String label, String value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()]),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _buildStatsGrid() {
    final stats = _c.statistics.value;
    final portfolio = _c.portfolio.value;
    final items = [
      {'label': 'Portfolio Value', 'value': '\$${(portfolio?.totalUsdtValue ?? 0).toStringAsFixed(2)}', 'sub': 'USDT', 'color': _kGreen},
      {'label': 'Active Stakes', 'value': '${stats?.totalActiveStakes ?? 0}', 'sub': 'Positions', 'color': const Color(0xFFA78BFA)},
      {'label': 'Total Earned', 'value': (stats?.totalRewardEarned ?? 0).toStringAsFixed(4), 'sub': 'All time', 'color': const Color(0xFF22C55E)},
      {'label': 'Referrals', 'value': '${stats?.totalReferralCommissions ?? 0}', 'sub': 'Commissions', 'color': const Color(0xFF60A5FA)},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          const SizedBox(height: 4),
          Text(item['value'] as String, style: TextStyle(color: item['color'] as Color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(item['sub'] as String, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
        ]),
      )).toList(),
    );
  }

  String _tierEmoji(String name) {
    switch (name.toLowerCase()) {
      case 'diamond': return '💎';
      case 'platinum': return '🔵';
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      default: return '🥉';
    }
  }

  Widget _buildTierCard(McUserTier tier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Text(_tierEmoji(tier.tierName), style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Referral Tier', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          Text(tier.tierName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ])),
        Row(children: [
          _tierLevel('L1', tier.level1Percent),
          const SizedBox(width: 16),
          _tierLevel('L2', tier.level2Percent),
          const SizedBox(width: 16),
          _tierLevel('L3', tier.level3Percent),
        ]),
      ]),
    );
  }

  Widget _tierLevel(String label, double pct) => Column(children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        const SizedBox(height: 2),
        Text('${pct.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ]);

  Widget _buildPositionsTable(List<McPortfolioItem> positions) {
    return Container(
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Active Positions', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(width: 6, height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E))),
              const SizedBox(width: 4),
              const Text('LIVE', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        ...positions.map((item) => _positionRow(item)),
      ]),
    );
  }

  Widget _positionRow(McPortfolioItem item) {
    final earnedUsdt = _stakeAvailable(item.stakeUid);
    final earnedCoin = item.coinPriceUsdt > 0 ? earnedUsdt / item.coinPriceUsdt : earnedUsdt;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(children: [
          _coinImg(item.coinLogo, size: 32),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.coinSymbol, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(item.planName, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ])),
          if (item.planType == 1) // flexible only
            Obx(() {
              final withdrawing = _c.isWithdrawing.value == item.stakeUid;
              return ElevatedButton(
                onPressed: withdrawing ? null : () => _openWithdrawModal(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: withdrawing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Withdraw', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              );
            }),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _miniStat('Staked', '${item.stakedAmount.toStringAsFixed(2)} ${item.coinSymbol}', Colors.white),
          _miniStat('Rate', '${item.dailyRate.toStringAsFixed(2)}%/day', _kGreen),
          _miniStat('Live Earned', '${earnedCoin.toStringAsFixed(6)} ${item.coinSymbol}', const Color(0xFF00B052)),
          _miniStat('Ends', item.endDate ?? 'Flexible', Colors.white70),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
        child: Column(children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _buildNavCards() {
    final navItems = [
      {'icon': Icons.flash_on, 'label': 'New Stake', 'desc': 'Add Stake to Earn'},
      {'icon': Icons.history, 'label': 'Withdraw History', 'desc': 'Check History'},
      {'icon': Icons.monetization_on, 'label': 'Reward History', 'desc': 'Daily logs'},
      {'icon': Icons.people, 'label': 'Referral Earnings', 'desc': 'Commission history'},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: navItems.asMap().entries.map((e) {
        final item = e.value;
        return GestureDetector(
          onTap: () {
            switch (e.key) {
              // Pop all the way back to earn_screen where Staking tab is
              case 0: Get.until((route) => route.isFirst); break;
              case 1: Get.to(() => const McWithdrawHistoryScreen()); break;
              case 2: Get.to(() => const McRewardsScreen()); break;
              case 3: Get.to(() => const McReferralRewardsScreen()); break;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Row(children: [
              Icon(item['icon'] as IconData, color: _kGreen, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                Text(item['desc'] as String, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
              ])),
            ]),
          ),
        );
      }).toList(),
    );
  }

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
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('💰', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text('Confirm Withdrawal', style: TextStyle(color: _kGreen, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rewards sent to your spot wallet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    _modalRow('Gross Reward', '${info.earnedCoin.toStringAsFixed(8)} ${info.symbol}', Colors.white),
                    const Divider(color: Color(0xFF222222)),
                    _modalRow('Service Fee (2%)', '- ${fee.toStringAsFixed(8)} ${info.symbol}', const Color(0xFFF87171)),
                    const Divider(color: Color(0xFF222222)),
                    _modalRow('You Receive', '${receive.toStringAsFixed(8)} ${info.symbol}', _kGreen, bold: true),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() => _withdrawInfo = null),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Color(0xFF333333))),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: _isConfirmingWithdraw ? null : _confirmWithdraw,
                    style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Confirm Withdraw', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalRow(String label, String value, Color color, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );

  String _fmtTime(int s) =>
      '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _StakeBase {
  double base;
  final double perSec;
  int baseTime;
  _StakeBase({required this.base, required this.perSec, required this.baseTime});
}

class _WithdrawInfo {
  final String uid;
  final double earnedCoin;
  final double earnedUsdt;
  final String symbol;
  _WithdrawInfo({required this.uid, required this.earnedCoin, required this.earnedUsdt, required this.symbol});
}
