import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_portfolio_screen.dart';
import 'mc_earnings_schedule_screen.dart';
import 'mc_staking_screen.dart' show McRewardsScreen, McReferralRewardsScreen;

const _kGreen = Color(0xFFCCFF00);
const _kCard = Color(0xFF1A1A1A);

Widget _coinImg(String? logo, {double size = 40, String? symbol}) {
  final url = mcLogoUrl(logo, symbol: symbol);
  if (url.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, e) => _fallback(size),
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
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16)],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _kGreen.withValues(alpha: 0.08) : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Text(e.value, style: TextStyle(
                                color: isSelected ? _kGreen : Colors.white,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                fontFamily: 'DMSans',
                              )),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.check, color: _kGreen, size: 16),
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

  void _load() {
    _c.fetchMyStakes(page: _page, status: _statusFilter);
    if (_c.coins.isEmpty) _c.fetchCoins();
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
          return RefreshIndicator(
            color: _kGreen,
            onRefresh: () async => _load(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(),
                if (_c.stakes.isEmpty)
                  _buildEmpty()
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        ..._c.stakes.map((s) => _buildStakeCard(s)),
                        const SizedBox(height: 12),
                        _buildPagination(),
                        const SizedBox(height: 16),
                        _buildNavCards(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'My Stakes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 10),
          // Subtitle
          const Text(
            'Earn rewards every second · Same coin in, same coin out',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 20),
          // Filter row
          Row(
            children: [
              // Active count chip
              Obx(() {
                final cnt = _c.stakes.where((s) => s.status == 1).length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color:  Color(0xFF00FF04).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$cnt Active',
                    style: const TextStyle(
                      color: Color(0xFF00FF04),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),
              // Status dropdown — custom
              Expanded(child: _buildStatusDropdown()),
              const SizedBox(width: 10),
              // New Stake button
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '+ New Stake',
                    style: TextStyle(
                      color: Color(0xFF111111),
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
      ),
    );
  }

  Widget _buildEmpty() => SizedBox(
        height: 400,
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No Stakes Found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Start staking to see your positions', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text('Start Staking', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ])),
      );

  // ── Custom Status Dropdown ────────────────────────────────────────────────
  static const _statusLabels = {'': 'All', '1': 'Active', '2': 'Completed', '3': 'Cancelled'};

  Widget _buildStatusDropdown() {
    final selectedLabel = _statusLabels[_statusFilter] ?? 'All';
    return GestureDetector(
      key: _dropdownKey,
      onTap: () => _dropdownOverlay == null ? _showDropdown() : _closeDropdown(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildStakeCard(McStake stake) {
    final planType = stake.plan?.planType ?? 1;
    final planTypeLabel = planType == 1 ? 'Flexible' : planType == 2 ? 'Locked' : 'Long-Term';
    final durationDays = stake.plan?.durationDays ?? 0;
    final planDays = durationDays > 0 ? '$durationDays Days' : (stake.plan?.planName ?? '—');
    final symbol = stake.coin?.symbol ?? '—';
    final isActive = stake.status == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top row: coin icon + name + status badge ──
        Row(
          children: [
            _coinImg(
              stake.coin?.logo ??
                  _c.coins
                      .firstWhereOrNull((c) => c.symbol == symbol)
                      ?.logo,
              size: 20,
              symbol: symbol,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '$symbol-USDT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$planDays · $planTypeLabel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'DMSans',
                  ),
                ),
              ]),
            ),
            // Status badge — green pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? _kGreen : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isActive ? 'Active' : (stake.status == 2 ? 'Completed' : 'Cancelled'),
                style: TextStyle(
                  color: isActive ? const Color(0xFF111111) : Color(0xFF111111).withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
       
        // ── Action buttons row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          _actionBtn('Earnings Schedule', Color(0xFF111111), _kGreen, () {
            Get.to(() => McEarningsScheduleScreen(stakeUid: stake.uid));
          }, border: Colors.transparent),
          const SizedBox(width: 5),
          _actionBtn('Withdraw', Color(0xFF111111), const Color(0xFF00E5FF), () {
            Get.to(() => const McPortfolioScreen());
          }, border: Colors.transparent),
          if (isActive && planType == 1) ...[
            const SizedBox(width: 5),
            Obx(() {
              final cancelling = _c.isCancelling.value == stake.uid;
              return _actionBtn(
                cancelling ? 'Cancelling...' : 'Cancel Stake',
                Color(0xFF111111),
                const Color(0xFFFF3B30),
                cancelling ? null : () async {
                  final ok = await _c.cancelStake(stake.uid);
                  if (ok) _load();
                },
                border: Colors.transparent,
              );
            }),
          ],
        ]),

        const SizedBox(height: 10),

        // ── Stats list ──
        _statRow('Staked Amount', '${stake.amount.toStringAsFixed(2)} $symbol', null, false),
        _statRow('Daily Rate', '${stake.dailyRate.toStringAsFixed(6)}%/day', _kGreen, false),
        _statRow('Total Earned', '${stake.totalRewardEarned.toStringAsFixed(4)} $symbol', const Color(0xFF00B052), false),
        _statRow('Period', '${stake.startDate ?? '—'} → ${stake.endDate ?? 'Flexible'}', null, true),
      ]),
    );
  }

  Widget _actionBtn(String label, Color bg, Color fg, VoidCallback? onTap, {Color? border}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
        ),
      );

  Widget _statRow(String label, String value, Color? valueColor, bool isLast) =>
      Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w400,
              )),
              const SizedBox(width: 16),
              Flexible(
                child: Text(value,
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
        ),
       ]);

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
            width: 36, height: 36, margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: p == _page ? _kGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p == _page ? _kGreen : Colors.white24),
            ),
            child: Center(child: Text('$p',
                style: TextStyle(color: p == _page ? Colors.black : Colors.white54, fontWeight: FontWeight.w600))),
          ),
        );
      }),
    );
  }

  Widget _buildNavCards() {
    final items = [
      _NavItem('assets/images/live.png', 'Live Dashboard', 'Real-time earnings',
          () => Get.to(() => const McPortfolioScreen())),
      _NavItem('assets/images/referral.png', 'Referral Earnings', 'Commission history',
          () => Get.to(() => const McReferralRewardsScreen())),
      _NavItem('assets/images/reward.png', 'Reward History', 'Daily logs',
          () => Get.to(() => const McRewardsScreen())),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: items.map((item) => GestureDetector(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Image.asset(item.image, width: 20, height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.star, color: _kGreen, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.label, style: const TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(item.desc, style: const TextStyle(
                      color: Colors.white, fontSize: 10,
                      fontFamily: 'DMSans', fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }


}

class _NavItem {
  final String image, label, desc;
  final VoidCallback onTap;
  _NavItem(this.image, this.label, this.desc, this.onTap);
}
