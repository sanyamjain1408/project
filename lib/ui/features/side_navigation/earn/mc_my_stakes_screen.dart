import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/mc_network_screen.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_portfolio_screen.dart';
import 'mc_earnings_schedule_screen.dart';
import 'mc_certificate_screen.dart';
import 'mc_staking_screen.dart' show McRewardsScreen, McReferralRewardsScreen;
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_widgets.dart' show RotatingIcon;
import 'mc_withdraw_history_screen.dart';

const _kGreen = Color(0xFFCCFF00);
const _kCard = Color(0xFF1A1A1A);
const _kBg = Color(0xFF111111);

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
    child: Icon(Icons.monetization_on, color: _kGreen, size: size * 0.5),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
class McMyStakesScreen extends StatefulWidget {
  const McMyStakesScreen({super.key});
  @override
  State<McMyStakesScreen> createState() => _McMyStakesScreenState();
}

class _McMyStakesScreenState extends State<McMyStakesScreen> {
  late McStakingController _c;
  int _page = 1;
  String _statusFilter = '';   // '' = all, '1' = active, '2' = completed, '3' = cancelled
  String? _coinFilter;         // null = all coins
  String? _planFilter;         // null = all plans, else duration days as string e.g. '30'

  // Overlay keys for each dropdown
  final _coinKey = GlobalKey();
  final _planKey = GlobalKey();
  final _statusKey = GlobalKey();
  OverlayEntry? _activeOverlay;

  void _closeOverlay() {
    _activeOverlay?.remove();
    _activeOverlay = null;
  }

  void _showOverlayMenu(GlobalKey key, List<_DropItem> items, String selected, void Function(String) onSelect) {
    _closeOverlay();
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    const menuWidth = 180.0;
    final screenWidth = MediaQuery.of(context).size.width;
    // Clamp so menu never goes off the right edge, min 8px margin
    final left = (offset.dx + menuWidth > screenWidth - 8)
        ? screenWidth - menuWidth - 8
        : offset.dx;

    _activeOverlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeOverlay,
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: offset.dy + size.height + 6,
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) {
                      final isSel = item.value == selected;
                      return GestureDetector(
                        onTap: () {
                          onSelect(item.value);
                          _closeOverlay();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: isSel ? _kGreen.withValues(alpha: 0.08) : Colors.transparent,
                          child: Row(
                            children: [
                              if (item.logo != null) ...[
                                _coinImg(null, size: 20, symbol: item.symbol),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSel ? _kGreen : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                              const Spacer(),
                              if (isSel) const Icon(Icons.check_rounded, color: _kGreen, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_activeOverlay!);
  }

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  void _load() {
    _c.fetchMyStakes(page: _page, status: _statusFilter);
    if (_c.coins.isEmpty) _c.fetchCoins();
  }

  // All unique coins from loaded stakes
  List<_DropItem> get _coinItems {
    final seen = <String>{};
    final items = <_DropItem>[_DropItem('', 'All Coins')];
    for (final s in _c.stakes) {
      final sym = s.coin?.symbol ?? '';
      if (sym.isEmpty || seen.contains(sym)) continue;
      seen.add(sym);
      items.add(_DropItem(sym, sym, logo: s.coin?.logo, symbol: sym));
    }
    return items;
  }

  // Unique plan durations from stakes filtered by selected coin
  List<_DropItem> get _planItems {
    final seen = <String>{};
    final items = <_DropItem>[_DropItem('', 'All Plans')];
    for (final s in _c.stakes) {
      if (_coinFilter != null && (s.coin?.symbol ?? '') != _coinFilter) continue;
      final days = s.plan?.durationDays ?? 0;
      final key = days.toString();
      if (seen.contains(key)) continue;
      seen.add(key);
      final label = days > 0 ? '$days Days' : 'Flexible';
      items.add(_DropItem(key, label));
    }
    return items;
  }

  // Filtered + grouped stakes
  List<McStake> get _filteredStakes {
    return _c.stakes.where((s) {
      if (_coinFilter != null && (s.coin?.symbol ?? '') != _coinFilter) return false;
      if (_planFilter != null) {
        final days = (s.plan?.durationDays ?? 0).toString();
        if (days != _planFilter) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Obx(() {
          if (_c.isLoadingStakes.value) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }

          final filtered = _filteredStakes;

          return RefreshIndicator(
            color: _kGreen,
            backgroundColor: _kCard,
            onRefresh: () async => _load(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(),
                if (filtered.isEmpty)
                  _buildEmpty()
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        ...filtered.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _StakeCardWidget(
                              key: ValueKey(s.uid),
                              stake: s,
                              c: _c,
                              onReload: _load,
                            ),
                          ),
                        ),
                        _buildPagination(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App bar row ──────────────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 20),
              const Text(
                'My Stakes',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.to(() => const McWithdrawHistoryScreen(initialTab: 0)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                  ),
                  child: const RotatingIcon(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 16),

          // ── Filter row: Coin | Plan | Status (below stats cards) ────────
          Obx(() {
            final coinItems = _coinItems;
            final planItems = _planItems;
            final coinLabel = _coinFilter ?? 'Coins';
            final planLabel = _planFilter != null
                ? (_planFilter == '0' ? 'Flexible' : '$_planFilter Days')
                : 'Plan';
            final statusLabel = _statusFilter == '1'
                ? 'Active'
                : _statusFilter == '2'
                    ? 'Completed'
                    : _statusFilter == '3'
                        ? 'Cancelled'
                        : 'Status';

            final selCoin = _coinFilter != null
                ? _c.coins.firstWhereOrNull((c) => c.symbol == _coinFilter)
                : null;

            return Row(
              children: [
                // Coin dropdown
                GestureDetector(
                  key: _coinKey,
                  onTap: () => _showOverlayMenu(
                    _coinKey,
                    coinItems,
                    _coinFilter ?? '',
                    (val) => setState(() {
                      _coinFilter = val.isEmpty ? null : val;
                      _planFilter = null;
                    }),
                  ),
                  child: Row(
                    children: [
                      if (selCoin != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _coinImg(selCoin.logo, size: 22, symbol: selCoin.symbol),
                        )
                      else
                        Container(
                          height: 22,
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Center(
                            child: Text('ALL', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
                          ),
                        ),
                      Text(coinLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),

                const Spacer(),

                // Plan dropdown
                GestureDetector(
                  key: _planKey,
                  onTap: () => _showOverlayMenu(
                    _planKey,
                    planItems,
                    _planFilter ?? '',
                    (val) => setState(() => _planFilter = val.isEmpty ? null : val),
                  ),
                  child: Row(
                    children: [
                      Text(planLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Status dropdown
                GestureDetector(
                  key: _statusKey,
                  onTap: () => _showOverlayMenu(
                    _statusKey,
                    const [
                      _DropItem('', 'All Status'),
                      _DropItem('1', 'Active'),
                      _DropItem('2', 'Completed'),
                      _DropItem('3', 'Cancelled'),
                    ],
                    _statusFilter,
                    (val) => setState(() {
                      _statusFilter = val;
                      _page = 1;
                      _load();
                    }),
                  ),
                  child: Row(
                    children: [
                      Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() {
      final stats = _c.statistics.value;
      final p = _c.portfolio.value;

      final stakingValue = p?.totalUsdtValue ?? 0.0;

      // Total Reward = live earning from _StakingLiveHero ticker via controller
      final totalReward = _c.liveEarningUsdt.value;

      return Transform.translate(
        offset: const Offset(0, -10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statsCard(
                label: 'Staking Value',
                value: stakingValue.toStringAsFixed(2),
                sub: 'Staked',
                color: const Color(0xFFCCFF00),
                imagePath: 'assets/images/stacking.png',
              ),
              _statsCard(
                label: 'Active Stakes',
                value: '${stats?.totalActiveStakes ?? 0}',
                sub: 'Positions',
                color: const Color(0xFFE946FF),
                imagePath: 'assets/images/active.png',
              ),
              _statsCard(
                label: 'Total Reward',
                value: totalReward.toStringAsFixed(4),
                sub: 'All time',
                color: const Color(0xFF00B052),
                imagePath: 'assets/images/total.png',
              ),
              _statsCard(
                label: 'Referrals',
                value: '${stats?.totalReferralCommissions ?? 0}',
                sub: 'Commissions',
                color: const Color(0xFF00E5FF),
                imagePath: 'assets/images/referrals.png',
                showArrow: true,
                onTap: () => Get.to(() => const McNetworkScreen()),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statsCard({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required String imagePath,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
            // arrow pinned to top-right, slightly outside padding
            if (showArrow)
              Positioned(
                top: 12,
                right: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A1A), Color(0xFF00282C)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.transparent, width: 1),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF00E5FF),
                    size: 13,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'DMSans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        sub,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DMSans',
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


  Widget _buildEmpty() => SizedBox(
    height: 400,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: _kGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Stakes Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start staking to see your positions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Start Staking',
                style: TextStyle(
                  color: Color(0xFF111111),
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

  Widget _buildPagination() {
    final meta = _c.stakesMeta.value;
    final lastPage = meta?['last_page'] ?? 1;
    if (lastPage <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(lastPage, (i) {
        final p = i + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _page = p);
            _load();
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: p == _page ? _kGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p == _page ? _kGreen : Colors.white24),
            ),
            child: Center(
              child: Text(
                '$p',
                style: TextStyle(
                  color: p == _page ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavCards() {
    final navItems = [
      _NavItem(
        'assets/images/live.png',
        'Live Dashboard',
        'Real-time earnings',
        Icons.show_chart_rounded,
        () => Get.to(() => const McPortfolioScreen())?.then((_) => _load()),
      ),
      _NavItem(
        'assets/images/referral.png',
        'Referral Earnings',
        'Commission history',
        Icons.people_alt_rounded,
        () => Get.to(() => const McReferralRewardsScreen()),
      ),
      _NavItem(
        'assets/images/reward.png',
        'Reward History',
        'Daily reward logs',
        Icons.history_rounded,
        () => Get.to(() => const McRewardsScreen()),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: _kGreen, size: 18),
                    ),
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
                              fontSize: 11,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.desc,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontFamily: 'DMSans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
}

class _NavItem {
  final String image, label, desc;
  final IconData icon;
  final VoidCallback onTap;
  _NavItem(this.image, this.label, this.desc, this.icon, this.onTap);
}

// Simple dropdown item model
class _DropItem {
  final String value;
  final String label;
  final String? logo;
  final String? symbol;
  const _DropItem(this.value, this.label, {this.logo, this.symbol});
}

// ─────────────────────────────────────────────────────────────────────────────
// STAKE CARD WIDGET — website jaisa exact card
// ─────────────────────────────────────────────────────────────────────────────
class _StakeCardWidget extends StatefulWidget {
  final McStake stake;
  final McStakingController c;
  final VoidCallback onReload;
  const _StakeCardWidget({
    super.key,
    required this.stake,
    required this.c,
    required this.onReload,
  });

  @override
  State<_StakeCardWidget> createState() => _StakeCardWidgetState();
}

class _StakeCardWidgetState extends State<_StakeCardWidget> {
  Timer? _ticker;
  double _liveEarned = 0.0;
  double _availableCoin = 0.0; // earned since last_withdrawn_at

  McStakingController get _c => widget.c;
  McStake get stake => widget.stake;

  late final double _perSec;
  late final int _startDateMs;
  late int _availStartMs; // last_withdrawn_at or staked_at — mutable for post-withdrawal reset

  void _computeLive() {
    if (stake.status != 1) {
      _liveEarned = stake.totalRewardEarned;
      _availableCoin = 0;
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final totalSecs = ((nowMs - _startDateMs) / 1000.0).clamp(0.0, double.infinity);
    _liveEarned = _perSec * totalSecs;
    // Available = earned since last_withdrawn_at (same as web)
    final availSecs = ((nowMs - _availStartMs) / 1000.0).clamp(0.0, double.infinity);
    _availableCoin = _perSec * availSecs;
  }

  @override
  void initState() {
    super.initState();
    _perSec = stake.amount * (stake.dailyRate / 100) / 86400;
    final startDt = stake.startDate != null ? DateTime.tryParse(stake.startDate!) : null;
    _startDateMs = startDt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    // Available starts from last_withdrawn_at if exists, else staked_at (same as web)
    final availDt = (stake.lastWithdrawnAt != null && stake.lastWithdrawnAt!.isNotEmpty)
        ? DateTime.tryParse(stake.lastWithdrawnAt!)
        : null;
    _availStartMs = availDt?.millisecondsSinceEpoch ?? _startDateMs;
    _computeLive();
    if (stake.status == 1) {
      _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (mounted) setState(_computeLive);
      });
    }
  }

  @override
  void didUpdateWidget(_StakeCardWidget old) {
    super.didUpdateWidget(old);
    // Reset available start time after withdrawal (new last_withdrawn_at from API)
    if (old.stake.lastWithdrawnAt != widget.stake.lastWithdrawnAt) {
      final availDt = (stake.lastWithdrawnAt != null && stake.lastWithdrawnAt!.isNotEmpty)
          ? DateTime.tryParse(stake.lastWithdrawnAt!)
          : null;
      setState(() {
        _availStartMs = availDt?.millisecondsSinceEpoch ?? _startDateMs;
      });
    }
  }

  Future<void> _doWithdraw() async {
    final symbol = stake.coin?.symbol ?? '—';
    final portfolioPrice = _c.portfolio.value?.portfolio
        .firstWhereOrNull((p) => p.stakeUid == stake.uid)?.coinPriceUsdt ?? 0;
    final coinPrice = portfolioPrice > 0 ? portfolioPrice : (stake.coinPriceUsdt > 0 ? stake.coinPriceUsdt : 1.0);
    final earnedUsdt = _availableCoin * coinPrice;
    final fee = _availableCoin * 0.02;
    final received = _availableCoin * 0.98;

    if (!mounted) return;
    Navigator.of(context).pop(); // close confirm dialog

    final ok = await _c.withdrawReward(stake.uid, earnedUsdt);
    if (ok && mounted) {
      widget.onReload();
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _WithdrawSuccessDialog(
          received: received,
          fee: fee,
          symbol: symbol,
        ),
      );
    }
  }

  void _openWithdrawConfirm() {
    final symbol = stake.coin?.symbol ?? '—';
    final fee = _availableCoin * 0.02;
    final received = _availableCoin * 0.98;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _WithdrawConfirmDialog(
        earnedCoin: _availableCoin,
        fee: fee,
        received: received,
        symbol: symbol,
        onConfirm: _doWithdraw,
      ),
    );
  }

  void _openCancelConfirm() {
    final symbol = stake.coin?.symbol ?? '—';
    final staked = stake.amount;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CancelConfirmDialog(
        stakedAmount: staked,
        symbol: symbol,
        onConfirm: () async {
          Navigator.of(context).pop();
          final result = await _c.cancelStake(stake.uid);
          if (result != null && mounted) {
            // Immediately remove from list so card disappears right away
            _c.stakes.removeWhere((s) => s.uid == stake.uid);
            // Also reload both lists fresh from API
            widget.onReload();
            _c.fetchPortfolio();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => _CancelSuccessDialog(
                stakedAmount: double.tryParse(result['staked_amount']?.toString() ?? '0') ?? staked,
                penalty: double.tryParse(result['penalty']?.toString() ?? '0') ?? 0,
                refund: double.tryParse(result['refund']?.toString() ?? '0') ?? 0,
                symbol: result['symbol']?.toString() ?? symbol,
                txRef: result['tx_ref']?.toString() ?? '',
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = stake.coin?.symbol ?? '—';
    final isActive = stake.status == 1;
    final planType = stake.plan?.planType ?? 1;
    final totalDays = stake.plan?.durationDays ?? 0;
    final elapsed = stake.daysElapsed;
    final remaining = totalDays > 0 ? (totalDays - elapsed).clamp(0, totalDays) : 0;
    final progress = stake.progressFraction;
    final progressPct = (progress * 100).toStringAsFixed(0);
    final statusLabel = isActive ? 'Active' : (stake.status == 2 ? 'Done' : 'Cancel');
    final startStr = _fmtDate(stake.startDate);
    final endStr = _fmtDate(stake.endDate);

    final portfolioPrice = _c.portfolio.value?.portfolio
        .firstWhereOrNull((p) => p.stakeUid == stake.uid)?.coinPriceUsdt ?? 0;
    final coinPrice = portfolioPrice > 0 ? portfolioPrice : (stake.coinPriceUsdt > 0 ? stake.coinPriceUsdt : 0.0);

    Color statusBgColor;
    Color statusTextColor;
    if (statusLabel == 'Cancel') {
      statusBgColor = const Color(0x4CFF3B30);
      statusTextColor = const Color(0xFFFF3B30);
    } else if (statusLabel == 'Completed') {
      statusBgColor = const Color(0x4C00B0FF);
      statusTextColor = const Color(0xFF00B0FF);
    } else {
      statusBgColor = const Color(0x4C00FF04);
      statusTextColor = const Color(0xFF00FF04);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SVG card ─────────────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final cardW = constraints.maxWidth;
            // SVG notch: from x=240 to x=362, y=0 to y=62 (in 362px design space)
            final notchX = cardW * (250 / 362);
            final notchW = cardW - notchX;
            final notchH = cardW * (52 / 352);
            return Stack(
          children: [
            SvgPicture.asset(
              'assets/svg/staking.svg',
              width: cardW,
              fit: BoxFit.fill,
            ),
            // Withdraw button — scaled to SVG notch position
            if (isActive)
              Positioned(
                top: 0,
                right: 0,
                width: notchW,
                height: notchH,
                child: Obx(() {
                  final withdrawing = _c.isWithdrawing.value == stake.uid;
                  return GestureDetector(
                    onTap: withdrawing || _availableCoin <= 0.000001 ? null : _openWithdrawConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: _availableCoin > 0.000001 ? const Color(0xCCCCFF00) : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        withdrawing ? 'Wait...\n$symbol' : 'Withdraw\n${_availableCoin.toStringAsFixed(4)} $symbol',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF111111), fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }),
              ),
            Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: coin icon + name/status ───────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _coinImg(
                      stake.coin?.logo ?? _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo,
                      size: 40,
                      symbol: symbol,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$symbol-USDT',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: statusTextColor, fontSize: 12,fontWeight: FontWeight.w400, fontFamily: 'DMSans'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${totalDays > 0 ? '$totalDays Days' : 'Open'} · ${planType == 1 ? 'Flexible' : 'Fixed'}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Stats: 2-column grid ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _statCol('Live Earned', _liveEarnedWidget(symbol, coinPrice))),
                    Expanded(child: _statCol('Staked Amount',
                      Text('${stake.amount.toStringAsFixed(2)} $symbol',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF4DD78D), fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
                      crossEnd: true)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _statCol('Day Completed',
                      Text('$elapsed / $totalDays days',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w400)))),
                    Expanded(child: _statCol('Day Remaining',
                      Text(totalDays > 0 ? '$remaining days' : 'Flexible',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
                      crossEnd: true)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Progress ──────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
                    Text('$progressPct% · Day $elapsed of $totalDays',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontFamily: 'DMSans')),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCCFF00)),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(startStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
                    Text(endStr.isEmpty ? 'Flexible' : endStr,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
                  ],
                ),

              ],
            ),
          ),
          ],
        );
          },
        ),

        // ── Action buttons 2×2 — SVG card ke BAHAR ──────────────────────────
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                'Live Dashboard',
                const Color(0xFF77D215),
                isActive
                    ? () => Get.to(() => McPortfolioScreen(stakeUid: stake.uid, coinId: stake.coin?.id, coinSymbol: stake.coin?.symbol))
                        ?.then((_) => widget.onReload())
                    : null,
                disabled: !isActive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                'Earnings Schedule',
                Colors.white,
                () => Get.to(() => McEarningsScheduleScreen(stakeUid: stake.uid, liveEarned: _liveEarned)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionBtn('Certificate', Colors.white, () {
                Get.to(() => McCertificateScreen(stake: {
                  'plan_name': stake.plan?.planName ?? '',
                  'coin_symbol': symbol,
                  'amount': stake.amount,
                  'daily_rate': stake.dailyRate,
                  'total_return': stake.plan != null && stake.plan!.durationDays > 0
                      ? (stake.dailyRate * stake.plan!.durationDays).toStringAsFixed(2)
                      : null,
                  'duration_days': stake.plan?.durationDays ?? 0,
                  'start_date': stake.startDate ?? '',
                  'end_date': stake.endDate ?? '',
                  'plan_type': stake.plan?.planType ?? 1,
                  'user_name': 'Valued Staker',
                  'cert_no': 'TRPX-${stake.uid.length >= 8 ? stake.uid.substring(0, 8).toUpperCase() : stake.uid.toUpperCase()}',
                }));
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() {
                final cancelling = _c.isCancelling.value == stake.uid;
                return _actionBtn(
                  cancelling ? 'Wait...' : 'Cancel Stake',
                  const Color(0xFFFF0000),
                  isActive && !cancelling ? _openCancelConfirm : null,
                  disabled: !isActive,
                );
              }),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _statCol(String label, Widget valueWidget, {bool crossEnd = false}) {
    return Column(
      crossAxisAlignment: crossEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }

  Widget _liveEarnedWidget(String symbol, double coinPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_liveEarned.toStringAsFixed(8)} $symbol',
          style: const TextStyle(color: Color(0xFF00B052), fontSize: 13, fontFamily: 'DMSans', fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color textColor, VoidCallback? onTap, {bool disabled = false}) {
    final effectiveColor = disabled ? textColor.withValues(alpha: 0.3) : textColor;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color:  Color(0xFF1A1A1A).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: disabled ? 0.08 : 0.18), width: 0.5),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: effectiveColor, fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }
}

// ── Withdraw Confirm Dialog ───────────────────────────────────────────────────
class _WithdrawConfirmDialog extends StatefulWidget {
  final double earnedCoin, fee, received;
  final String symbol;
  final Future<void> Function() onConfirm;
  const _WithdrawConfirmDialog({required this.earnedCoin, required this.fee, required this.received, required this.symbol, required this.onConfirm});
  @override State<_WithdrawConfirmDialog> createState() => _WithdrawConfirmDialogState();
}
class _WithdrawConfirmDialogState extends State<_WithdrawConfirmDialog> {
  bool _loading = false;
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
            const Text('💰', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            const Text('Confirm Withdrawal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
            const SizedBox(height: 4),
            Text('Rewards will be sent to your spot wallet', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontFamily: 'DMSans')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _row('Gross Reward', '${widget.earnedCoin.toStringAsFixed(8)} ${widget.symbol}', Colors.white),
                const Divider(color: Color(0xFF222222)),
                _row('Service Fee (2%)', '- ${widget.fee.toStringAsFixed(8)} ${widget.symbol}', const Color(0xFFF87171)),
                const Divider(color: Color(0xFF222222)),
                _row('You Receive', '${widget.received.toStringAsFixed(8)} ${widget.symbol}', const Color(0xFFCCFF00), bold: true),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () async {
                  setState(() => _loading = true);
                  await widget.onConfirm();
                  if (mounted) setState(() => _loading = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Confirm Withdraw', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontFamily: 'DMSans')),
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
      Text(v, style: TextStyle(color: vc, fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontFamily: 'DMSans')),
    ]),
  );
}

// ── Withdraw Success Dialog ───────────────────────────────────────────────────
class _WithdrawSuccessDialog extends StatelessWidget {
  final double received, fee;
  final String symbol;
  const _WithdrawSuccessDialog({required this.received, required this.fee, required this.symbol});
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
            const Text('Withdrawal Successful!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
            const SizedBox(height: 4),
            Text('Your staking rewards have been credited to your Spot Wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontFamily: 'DMSans')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _row('Amount Received', '${received.toStringAsFixed(8)} $symbol', const Color(0xFFCCFF00)),
                const Divider(color: Color(0xFF222222)),
                _row('Service Fee (2%)', '${fee.toStringAsFixed(8)} $symbol', const Color(0xFFF87171)),
                const Divider(color: Color(0xFF222222)),
                _row('Destination', 'Spot Wallet', Colors.white),
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
  Widget _row(String l, String v, Color vc) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
      Text(v, style: TextStyle(color: vc, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'DMSans')),
    ]),
  );
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3D1A00)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Early Cancellation', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
            const SizedBox(height: 6),
            Text('You are cancelling before the plan completes.', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, fontFamily: 'DMSans')),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                const Text('A 20% penalty will be deducted',
                  style: TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                const SizedBox(height: 12),
                _row('Staked', '${widget.stakedAmount.toStringAsFixed(0)} ${widget.symbol}', Colors.white),
                const SizedBox(height: 4),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 4),
                _row('Penalty (20%)', '-${penalty.toStringAsFixed(0)} ${widget.symbol}', const Color(0xFFF87171)),
                const SizedBox(height: 4),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 4),
                _row('You receive', '${receive.toStringAsFixed(0)} ${widget.symbol}', const Color(0xFFCCFF00), bold: true),
              ]),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF444444)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Keep Staking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                ),
              ),
              const SizedBox(width: 14),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Cancel Anyway', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  Widget _row(String l, String v, Color vc, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'DMSans')),
      Text(v, style: TextStyle(color: vc, fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontFamily: 'DMSans')),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCCFF00), width: 2.5)),
              child: const Icon(Icons.check_rounded, color: Color(0xFFCCFF00), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Stake Cancelled', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
            const SizedBox(height: 6),
            Text('Funds returned to your Spot Wallet.', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, fontFamily: 'DMSans')),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _row('Staked Amount', '${stakedAmount.toStringAsFixed(0)} $symbol', Colors.white),
                const SizedBox(height: 4),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 4),
                _row('Early Fee (20%)', '-${penalty.toStringAsFixed(0)} $symbol', const Color(0xFFF87171)),
                const SizedBox(height: 4),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 4),
                _row('You Received', '${refund.toStringAsFixed(0)} $symbol', const Color(0xFFCCFF00), bold: true),
                const SizedBox(height: 4),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 4),
                _row('Destination', 'Spot Wallet', Colors.white),
                if (txRef.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Divider(color: Color(0xFF2A2A2A)),
                  const SizedBox(height: 4),
                  _row('Transaction ID', txRef, Colors.white),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'DMSans')),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(color: vc, fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontFamily: 'DMSans'))),
    ]),
  );
}

