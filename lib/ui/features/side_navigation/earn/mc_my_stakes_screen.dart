import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        child: Stack(children: [
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)],
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _statusLabels.entries.map((e) {
                    final isSelected = _statusFilter == e.key;
                    return GestureDetector(
                      onTap: () {
                        setState(() { _statusFilter = e.key; _page = 1; });
                        _load();
                        _closeDropdown();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        color: isSelected ? _kGreen.withValues(alpha: 0.08) : Colors.transparent,
                        child: Row(children: [
                          Text(e.value, style: TextStyle(
                            color: isSelected ? _kGreen : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontFamily: 'DMSans',
                          )),
                          const Spacer(),
                          if (isSelected) const Icon(Icons.check_rounded, color: _kGreen, size: 16),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ]),
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

  static const _statusLabels = {'': 'All Stakes', '1': 'Active', '2': 'Completed', '3': 'Cancelled'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Obx(() {
          if (_c.isLoadingStakes.value) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(children: [
                      ...grouped.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _CoinGroupWidget(
                          symbol: e.key,
                          stakes: e.value,
                          c: _c,
                          onReload: _load,
                        ),
                      )),
                      _buildPagination(),
                      const SizedBox(height: 20),
                      _buildNavCards(),
                    ]),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 20),
        const Text('My Stakes',
          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
        const SizedBox(height: 5),
        Text('Earn rewards every second · Same coin in, same coin out',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12,fontWeight: FontWeight.w400, fontFamily: 'DMSans')),
        const SizedBox(height: 20),
        // Filter row: active badge + dropdown + new stake
        Row(children: [
          Obx(() {
            final cnt = _c.stakes.where((s) => s.status == 1).length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF04).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
               
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
              
                Text('$cnt Active',
                  style: const TextStyle(color: Color(0xFF00FF04), fontSize: 12,
                    fontWeight: FontWeight.w400, fontFamily: 'DMSans')),
              ]),
            );
          }),
          const SizedBox(width: 10),
          Expanded(child: _buildStatusDropdown()),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Color(0xFF111111), size: 15),
                SizedBox(width: 4),
                Text('New Stake',
                  style: TextStyle(color: Color(0xFF111111), fontSize: 12,
                    fontWeight: FontWeight.w400, fontFamily: 'DMSans')),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildStatusDropdown() {
    final selectedLabel = _statusLabels[_statusFilter] ?? 'All Stakes';
    return GestureDetector(
      key: _dropdownKey,
      onTap: () => _dropdownOverlay == null ? _showDropdown() : _closeDropdown(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Expanded(child: Text(selectedLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13,
              fontFamily: 'DMSans', fontWeight: FontWeight.w600))),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => SizedBox(
    height: 400,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(Icons.bar_chart_rounded, color: _kGreen, size: 36),
      ),
      const SizedBox(height: 16),
      const Text('No Stakes Found',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
      const SizedBox(height: 8),
      Text('Start staking to see your positions',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontFamily: 'DMSans')),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(12)),
          child: const Text('Start Staking',
            style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
        ),
      ),
    ])),
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
          onTap: () { setState(() => _page = p); _load(); },
          child: Container(
            width: 36, height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: p == _page ? _kGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p == _page ? _kGreen : Colors.white24),
            ),
            child: Center(child: Text('$p',
              style: TextStyle(color: p == _page ? Colors.black : Colors.white54,
                fontWeight: FontWeight.w700, fontFamily: 'DMSans'))),
          ),
        );
      }),
    );
  }

  Widget _buildNavCards() {
    final navItems = [
      _NavItem('assets/images/live.png', 'Live Dashboard', 'Real-time earnings',
          Icons.show_chart_rounded, () => Get.to(() => const McPortfolioScreen())),
      _NavItem('assets/images/referral.png', 'Referral Earnings', 'Commission history',
          Icons.people_alt_rounded, () => Get.to(() => const McReferralRewardsScreen())),
      _NavItem('assets/images/reward.png', 'Reward History', 'Daily reward logs',
          Icons.history_rounded, () => Get.to(() => const McRewardsScreen())),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: navItems.map((item) => GestureDetector(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: _kGreen, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label,
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(item.desc,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10,
                    fontFamily: 'DMSans'),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        ),
      )).toList(),
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
      final key = '${s.plan?.id ?? s.plan?.planName ?? 'custom'}_${s.dailyRate}';
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
      tabs.add(_StakePlanTab(
        key: key,
        planName: name,
        dailyRate: s.dailyRate,
        planId: s.plan?.id,
      ));
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
    final logo = stake.coin?.logo ?? _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo;
    final coinName = stake.coin?.coinName ?? symbol;
    final activeCount = widget.stakes.where((s) => s.status == 1).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Coin row ──────────────────────────────────────────────────────────
      GestureDetector(
        onTap: _onCoinTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          
          child: Row(children: [
            // Coin icon
            _coinImg(logo, size: 30, symbol: symbol),
            const SizedBox(width: 15),
            // Symbol + name
            Expanded(child: Text(symbol,
                style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700, fontFamily: 'DMSans')),),
            // Active stakes badge
            Text(symbol,
                style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
            // Expand arrow
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: _expanded ? Colors.transparent: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: _expanded ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5), size: 18),
              ),
            ),
          ]),
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
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      color: isSelected ? _kGreen.withValues(alpha: 0.01) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _kGreen : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(tab.planName,
                        style: TextStyle(
                          color: isSelected ? _kGreen : Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'DMSans'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Text('${tab.dailyRate.toStringAsFixed(3)}% / day',
                        style: const TextStyle(color: _kGreen, fontSize: 14,
                          fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Stake cards for ALL stakes matching selected plan (or all if no plan filter)
        ..._filteredStakes.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _StakeCardWidget(
            key: ValueKey(s.uid),
            stake: s,
            c: _c,
            onReload: widget.onReload,
          ),
        )),
        const SizedBox(height: 4),
      ],
    ]);
  }

  List<McStake> get _filteredStakes {
    if (_selectedTab == null) return widget.stakes;
    final matching = widget.stakes.where((s) {
      final key = '${s.plan?.id ?? s.plan?.planName ?? 'custom'}_${s.dailyRate}';
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

  McStakingController get _c => widget.c;
  McStake get stake => widget.stake;

  // Website formula: perSec = amount * (dailyRate/100) / 86400
  void _computeLive() {
    if (stake.status != 1) {
      _liveEarned = stake.totalRewardEarned;
      return;
    }
    final perSec = stake.amount * (stake.dailyRate / 100) / 86400;
    final startMs = stake.startDate != null
        ? (DateTime.tryParse(stake.startDate!)?.millisecondsSinceEpoch ?? 0)
        : 0;
    final secsElapsed = startMs > 0
        ? ((DateTime.now().millisecondsSinceEpoch - startMs) / 1000.0)
            .clamp(0.0, double.infinity)
        : 0.0;
    _liveEarned = perSec * secsElapsed;
  }

  @override
  void initState() {
    super.initState();
    _computeLive();
    if (stake.status == 1) {
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(_computeLive);
      });
    }
  }

  @override
  void didUpdateWidget(_StakeCardWidget old) {
    super.didUpdateWidget(old);
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
    final remaining = stake.daysRemaining;
    final progress = stake.progressFraction;
    final progressPct = (progress * 100).toStringAsFixed(0);
    final completedCount = 0;

    final statusLabel = isActive ? 'Active' : (stake.status == 2 ? 'Completed' : 'Cancelled');
    final statusColor = isActive ? _kGreen
        : (stake.status == 2 ? const Color(0xFF3B9EFF) : const Color(0xFFFF453A));

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _coinImg(
              stake.coin?.logo ?? _c.coins.firstWhereOrNull((c) => c.symbol == symbol)?.logo,
              size: 42, symbol: symbol,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Coin name + status badge inline
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Flexible(child: Text('$symbol-USDT',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w800, fontFamily: 'DMSans'))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isActive) ...[
                      Container(width: 5, height: 5,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                    ],
                    Text(statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11,
                        fontWeight: FontWeight.w600, fontFamily: 'DMSans')),
                  ]),
                ),
              ]),
              const SizedBox(height: 3),
              Text('${totalDays > 0 ? '$totalDays Days' : 'Open'} · ${planType == 1 ? 'Flexible' : 'Locked'}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12, fontFamily: 'DMSans')),
            ])),
            if (stake.status != 3) ...[
              const SizedBox(width: 8),
              // Withdraw button — only for non-cancelled stakes
              GestureDetector(
                onTap: () => Get.to(() => const McPortfolioScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const Text('Withdraw',
                      style: TextStyle(color: Color(0xFF0A0A0A), fontSize: 12,
                        fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
                    const SizedBox(height: 2),
                    Text('${_liveEarned.toStringAsFixed(4)} $symbol',
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 10,
                        fontFamily: 'DMSans', fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 14),

        // ── Action pills ──────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _actionPill('Live Dashboard', _kGreen,
              () => Get.to(() => const McPortfolioScreen())),
            const SizedBox(width: 8),
            _actionPill('Earnings Schedule', Colors.white,
              () => Get.to(() => McEarningsScheduleScreen(stakeUid: stake.uid))),
            if (isActive && planType == 1) ...[
              const SizedBox(width: 8),
              Obx(() {
                final cancelling = _c.isCancelling.value == stake.uid;
                return _actionPill(
                  cancelling ? 'Cancelling...' : 'Cancel Stake',
                  const Color(0xFFFF453A),
                  cancelling ? null : () async {
                    final ok = await _c.cancelStake(stake.uid);
                    if (ok) widget.onReload();
                  },
                );
              }),
            ],
          ]),
        ),

        // ── Divider ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
        ),

        // ── Stats ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Live Earned — special highlighted row
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Live Earned',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13, fontFamily: 'DMSans')),
                const Spacer(),
                Text('${_liveEarned.toStringAsFixed(8)} $symbol',
                  style: const TextStyle(color: _kGreen, fontSize: 13,
                    fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
              ]),
            ),

            _statRow('Staked Amount', '${stake.amount.toStringAsFixed(2)} $symbol', null),
            _statRow('Daily Rate', '${stake.dailyRate.toStringAsFixed(4)}% / day', _kGreen),
            _statRow('Total Earned', '${stake.totalRewardEarned.toStringAsFixed(6)} $symbol',
              const Color(0xFF30D158)),
            _statRow('Days Remaining',
              totalDays > 0 ? '$remaining / $totalDays days' : 'Flexible', null),

            const SizedBox(height: 10),

            // Progress text row
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12, fontFamily: 'DMSans')),
              RichText(text: TextSpan(children: [
                TextSpan(text: '$progressPct%',
                  style: const TextStyle(color: _kGreen, fontSize: 12,
                    fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
                TextSpan(text: '  ·  Day $elapsed of $totalDays  ·  $completedCount completed',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12, fontFamily: 'DMSans')),
              ])),
            ]),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
              ),
            ),
            const SizedBox(height: 8),

            // Start — End dates
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_fmtDate(stake.startDate),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11, fontFamily: 'DMSans')),
              Text(_fmtDate(stake.endDate) == '' ? 'Flexible' : _fmtDate(stake.endDate),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11, fontFamily: 'DMSans')),
            ]),
          ]),
        ),

        const SizedBox(height: 18),
      ]),
    );
  }

  Widget _actionPill(String label, Color fg, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(label,
        style: TextStyle(color: fg, fontSize: 12,
          fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
    ),
  );

  Widget _statRow(String label, String value, Color? valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
          fontSize: 13, fontFamily: 'DMSans')),
      const SizedBox(width: 16),
      Flexible(child: Text(value, textAlign: TextAlign.right,
        style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13,
          fontFamily: 'DMSans', fontWeight: FontWeight.w700))),
    ]),
  );

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
