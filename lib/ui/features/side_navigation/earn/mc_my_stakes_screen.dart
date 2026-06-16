import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/mc_network_screen.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_portfolio_screen.dart';
import 'mc_earnings_schedule_screen.dart';
import 'mc_staking_screen.dart' show McRewardsScreen, McReferralRewardsScreen;

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
  String _statusFilter = '';

  OverlayEntry? _dropdownOverlay;
  final _dropdownKey = GlobalKey();

  void _closeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  void _showDropdown() {
    final box = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _dropdownOverlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 6,
              width: size.width,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _statusLabels.entries.map((e) {
                      final isSelected = _statusFilter == e.key;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _statusFilter = e.key;
                            _page = 1;
                          });
                          _load();
                          _closeDropdown();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          color: isSelected
                              ? _kGreen.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  color: isSelected ? _kGreen : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: _kGreen,
                                  size: 16,
                                ),
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
    Overlay.of(context).insert(_dropdownOverlay!);
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
    _closeDropdown();
    super.dispose();
  }

  void _load() {
    _c.fetchMyStakes(page: _page, status: _statusFilter);
    if (_c.coins.isEmpty) _c.fetchCoins();
  }

  static const _statusLabels = {
    '': 'All Stakes',
    '1': 'Active',
    '2': 'Completed',
    '3': 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Obx(() {
          if (_c.isLoadingStakes.value) {
            return const Center(
              child: CircularProgressIndicator(color: _kGreen),
            );
          }

          final grouped = <String, List<McStake>>{};
          for (final s in _c.stakes) {
            final sym = s.coin?.symbol ?? '—';
            grouped.putIfAbsent(sym, () => []).add(s);
          }

          return RefreshIndicator(
            color: _kGreen,
            backgroundColor: _kCard,
            onRefresh: () async => _load(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(),
                if (_c.stakes.isEmpty)
                  _buildEmpty()
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        ...grouped.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _CoinGroupWidget(
                              symbol: e.key,
                              stakes: e.value,
                              c: _c,
                              onReload: _load,
                            ),
                          ),
                        ),
                        _buildPagination(),
                        const SizedBox(height: 20),
                        // _buildNavCards(),
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
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 20),

              const Text(
                'My Stakes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(width: 170, height: 36, child: _buildStatusDropdown()),
            ],
          ),
          const SizedBox(height: 30),
          _buildStatsGrid(),
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

  Widget _buildStatusDropdown() {
    final selectedLabel = _statusLabels[_statusFilter] ?? 'All Stakes';
    return GestureDetector(
      key: _dropdownKey,
      onTap: () =>
          _dropdownOverlay == null ? _showDropdown() : _closeDropdown(),
      child: Container(
         height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
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
        () => Get.to(() => const McPortfolioScreen()),
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

// ─────────────────────────────────────────────────────────────────────────────
// Plan tab derived from actual stakes (mirrors website MobileStakingHistory)
// ─────────────────────────────────────────────────────────────────────────────
class _StakePlanTab {
  final String key;
  final String planName;
  final double dailyRate;
  final int? planId;

  const _StakePlanTab({
    required this.key,
    required this.planName,
    required this.dailyRate,
    this.planId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN GROUP WIDGET — website jaisa accordion
// ─────────────────────────────────────────────────────────────────────────────
class _CoinGroupWidget extends StatefulWidget {
  final String symbol;
  final List<McStake> stakes;
  final McStakingController c;
  final VoidCallback onReload;
  const _CoinGroupWidget({
    required this.symbol,
    required this.stakes,
    required this.c,
    required this.onReload,
  });

  @override
  State<_CoinGroupWidget> createState() => _CoinGroupWidgetState();
}

class _CoinGroupWidgetState extends State<_CoinGroupWidget> {
  bool _expanded = false;
  _StakePlanTab? _selectedTab;

  McStakingController get _c => widget.c;
  String get symbol => widget.symbol;

  // Derive plan tabs from actual stakes — same as website MobileStakingHistory
  List<_StakePlanTab> get _planTabs {
    final tabs = <_StakePlanTab>[];
    final seen = <String>{};
    for (final s in widget.stakes) {
      final key =
          '${s.plan?.id ?? s.plan?.planName ?? 'custom'}_${s.dailyRate}';
      if (seen.contains(key)) continue;
      seen.add(key);
      String name;
      if (s.plan?.planName.isNotEmpty == true) {
        name = s.plan!.planName;
      } else if (s.plan?.planType == 1) {
        name = 'Flexible';
      } else {
        name = 'Custom';
      }
      tabs.add(
        _StakePlanTab(
          key: key,
          planName: name,
          dailyRate: s.dailyRate,
          planId: s.plan?.id,
        ),
      );
    }
    return tabs;
  }

  void _onCoinTap() {
    setState(() => _expanded = !_expanded);
    if (_expanded && _selectedTab == null) {
      final tabs = _planTabs;
      if (tabs.isNotEmpty) _selectedTab = tabs.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stake = widget.stakes.first;
    final logo =
        stake.coin?.logo ??
        _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo;
    final coinName = stake.coin?.coinName ?? symbol;
    final activeCount = widget.stakes.where((s) => s.status == 1).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Coin row ──────────────────────────────────────────────────────────
        GestureDetector(
          onTap: _onCoinTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),

            child: Row(
              children: [
                // Coin icon
                _coinImg(logo, size: 30, symbol: symbol),
                const SizedBox(width: 15),
                // Symbol
                Expanded(
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
                // Coin full name (right side, like Figma)
                Text(
                  coinName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(width: 8),
                // Expand arrow
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? Colors.transparent
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _expanded
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expanded content ──────────────────────────────────────────────────
        if (_expanded) ...[
          const SizedBox(height: 15),

          // Plan tabs derived from actual stakes
          if (_planTabs.isNotEmpty) ...[
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: _planTabs.length,
                itemBuilder: (_, i) {
                  final tab = _planTabs[i];
                  final isSelected = _selectedTab?.key == tab.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 130,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kGreen : Colors.transparent,
                          width: isSelected ? 0.5 : 0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tab.planName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${tab.dailyRate.toStringAsFixed(3)}% ',
                                  style: TextStyle(
                                    color: isSelected ? _kGreen : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                                TextSpan(
                                  text: '/day',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
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
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Stake cards for ALL stakes matching selected plan (or all if no plan filter)
          ..._filteredStakes.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StakeCardWidget(
                key: ValueKey(s.uid),
                stake: s,
                c: _c,
                onReload: widget.onReload,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  List<McStake> get _filteredStakes {
    if (_selectedTab == null) return widget.stakes;
    final matching = widget.stakes.where((s) {
      final key =
          '${s.plan?.id ?? s.plan?.planName ?? 'custom'}_${s.dailyRate}';
      return key == _selectedTab!.key;
    }).toList();
    return matching.isEmpty ? widget.stakes : matching;
  }
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
    final statusLabel = isActive ? 'Active' : (stake.status == 2 ? 'Completed' : 'Cancelled');
    final startStr = _fmtDate(stake.startDate);
    final endStr = _fmtDate(stake.endDate);

    // Live earned USDT value
    final portfolioPrice = _c.portfolio.value?.portfolio
        .firstWhereOrNull((p) => p.stakeUid == stake.uid)?.coinPriceUsdt ?? 0;
    final coinPrice = portfolioPrice > 0 ? portfolioPrice : (stake.coinPriceUsdt > 0 ? stake.coinPriceUsdt : 0.0);
    final liveEarnedUsdt = coinPrice > 0 ? _liveEarned * coinPrice : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
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
              _coinImg(
                stake.coin?.logo ?? _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo,
                size: 30,
                symbol: symbol,
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
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x4C00FF04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(statusLabel, style: const TextStyle(color: Color(0xFF00FF04), fontSize: 12, fontFamily: 'DMSans')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalDays > 0 ? '$totalDays Days' : 'Open'} · ${planType == 1 ? 'Flexible' : 'Fixed'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Withdraw button (Figma: #CCFF00, rounded 10)
              if (isActive)
                Obx(() {
                  final withdrawing = _c.isWithdrawing.value == stake.uid;
                  return GestureDetector(
                    onTap: withdrawing || _availableCoin <= 0.000001 ? null : () async {
                      final price = coinPrice > 0 ? coinPrice : 1.0;
                      final ok = await _c.withdrawReward(stake.uid, _availableCoin * price);
                      if (ok) widget.onReload();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _availableCoin > 0.000001 ? const Color(0xFFCCFF00) : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        withdrawing ? 'Wait...\n$symbol' : 'Withdraw\n${_availableCoin.toStringAsFixed(4)} $symbol',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF111111), fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400),
                      ),
                    ),
                  );
                }),
            ],
          ),

          const SizedBox(height: 14),

          // ── Row 2: Live Price | Earnings Schedule | Cancel Stake ──────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _pill('Live Price', const Color(0xFF77D215), () => Get.to(() => McPortfolioScreen(stakeUid: stake.uid, coinId: stake.coin?.id, coinSymbol: stake.coin?.symbol))),
                const SizedBox(width: 8),
                _pill('Earnings Schedule', const Color(0xFFCCFF00), () => Get.to(() => McEarningsScheduleScreen(stakeUid: stake.uid))),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Obx(() {
                    final cancelling = _c.isCancelling.value == stake.uid;
                    return _pill(
                      cancelling ? 'Cancelling...' : 'Cancel Stake',
                      const Color(0xFFFF0000),
                      cancelling ? null : () async { final ok = await _c.cancelStake(stake.uid); if (ok) widget.onReload(); },
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Row 3: Certificate ────────────────────────────────────────────
          _pill('Certificate', const Color(0xFFCCFF00), () {}),

          const SizedBox(height: 16),

          // ── Stats rows ────────────────────────────────────────────────────
          _liveEarnedRow(symbol),
          _statRow('Staked Amount', '${stake.amount.toStringAsFixed(2)} $symbol', const Color(0xFF4DD78D)),
          _statRow('Day Completed', '$elapsed / $totalDays days', Colors.white),
          _statRow('Day Remaining', totalDays > 0 ? '$remaining days' : 'Flexible', Colors.white),

          const SizedBox(height: 12),

          // ── Progress ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
              Text('$progressPct% · Day $elapsed of $totalDays', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontFamily: 'DMSans')),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCCFF00)),
            ),
          ),
          const SizedBox(height: 6),

          // Start — End dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
              Text(endStr.isEmpty ? 'Flexible' : endStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color fg, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
        ),
      );

  // keep for backward compat
  Widget _actionPill(String label, Color fg, VoidCallback? onTap) => _pill(label, fg, onTap);

  Widget _statRow(String label, String value, Color? valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  // Live Earned row with optional USD sub-line (matches website ≈ $X.XXXX USDT)
  Widget _liveEarnedRow(String symbol) {
    final portfolioPrice = _c.portfolio.value?.portfolio
        .firstWhereOrNull((p) => p.stakeUid == stake.uid)
        ?.coinPriceUsdt ?? 0;
    final trpxPrice = _c.trpxPrice.value;
    final isTrpx = (stake.coin?.symbol ?? '').toUpperCase() == 'TRPX';
    final coinPrice = portfolioPrice > 0
        ? portfolioPrice
        : (stake.coinPriceUsdt > 0
            ? stake.coinPriceUsdt
            : (isTrpx && trpxPrice > 0 ? trpxPrice : 0.0));
    final usdVal = coinPrice > 0 ? _liveEarned * coinPrice : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Live Earned',
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
                  '${_liveEarned.toStringAsFixed(8)} $symbol',
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

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }
}
