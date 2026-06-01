import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart' show McStakingController, mcLogoUrl;
import 'mc_staking_models.dart';
import 'mc_portfolio_screen.dart';
import 'mc_earnings_schedule_screen.dart';

const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF0A0B0D);
const _kCard = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF111111);

Widget _coinImg(String? logo, {double size = 40, String? symbol}) {
  final url = mcLogoUrl(logo, symbol: symbol);
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

class McMyStakesScreen extends StatefulWidget {
  const McMyStakesScreen({super.key});
  @override
  State<McMyStakesScreen> createState() => _McMyStakesScreenState();
}

class _McMyStakesScreenState extends State<McMyStakesScreen> {
  late McStakingController _c;
  int _page = 1;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => _c.fetchMyStakes(page: _page, status: _statusFilter);

  static const _statusLabels = {'': 'All', '1': 'Active', '2': 'Completed', '3': 'Cancelled'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A0A),
      appBar: AppBar(
        backgroundColor: _kBg,
        title: const Text('My Stakes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
        actions: [
          TextButton(
            onPressed: () => Get.to(() => const McPortfolioScreen()),
            child: const Text('Dashboard', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(children: [
        // Filters
        _buildFilters(),
        Expanded(
          child: Obx(() {
            if (_c.isLoadingStakes.value) {
              return const Center(child: CircularProgressIndicator(color: _kGreen));
            }
            if (_c.stakes.isEmpty) {
              return _buildEmpty();
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._c.stakes.map((s) => _buildStakeCard(s)),
                const SizedBox(height: 12),
                _buildPagination(),
              ],
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusLabels.entries.map((e) {
            final active = _statusFilter == e.key;
            return GestureDetector(
              onTap: () { setState(() { _statusFilter = e.key; _page = 1; }); _load(); },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? _kGreen : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.value,
                    style: TextStyle(color: active ? Colors.black : Colors.white,
                        fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
        ]),
      );

  Widget _buildStakeCard(McStake stake) {
    final statusData = _statusStyle(stake.status);
    final planType = stake.plan?.planType ?? 1;
    final planTypeLabel = planType == 1 ? 'Flexible' : planType == 2 ? 'Locked' : 'Long-Term';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _coinImg(stake.coin?.logo, size: 40, symbol: stake.coin?.symbol),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(stake.coin?.symbol ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusData['bg'] as Color, borderRadius: BorderRadius.circular(12)),
                child: Text(statusData['label'] as String,
                    style: TextStyle(color: statusData['color'] as Color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 2),
            Text('${stake.plan?.planName ?? '—'} · $planTypeLabel',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        // Action buttons
        Row(children: [
          _actionBtn('Earnings Schedule', const Color(0xFFCCFF00), Colors.black, () {
            Get.to(() => McEarningsScheduleScreen(stakeUid: stake.uid));
          }),
          const SizedBox(width: 8),
          _actionBtn('Withdraw', const Color(0xFF00E5FF), Colors.black, () {
            Get.to(() => const McPortfolioScreen());
          }),
          if (stake.status == 1 && planType == 1) ...[
            const SizedBox(width: 8),
            Obx(() {
              final cancelling = _c.isCancelling.value == stake.uid;
              return _actionBtn(
                cancelling ? 'Cancelling...' : 'Cancel',
                Colors.transparent,
                const Color(0xFFFF3B30),
                cancelling ? null : () async {
                  final ok = await _c.cancelStake(stake.uid);
                  if (ok) _load();
                },
                border: const Color(0xFFFF3B30),
              );
            }),
          ],
        ]),
        const SizedBox(height: 12),
        // Stats grid
        Row(children: [
          _statBox('Staked Amount', '${stake.amount.toStringAsFixed(2)} ${stake.coin?.symbol ?? ''}'),
          const SizedBox(width: 8),
          _statBox('Daily Rate', '${stake.dailyRate.toStringAsFixed(6)}%/day', color: _kGreen),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _statBox('Total Earned', stake.totalRewardEarned.toStringAsFixed(6), color: const Color(0xFF00B052)),
          const SizedBox(width: 8),
          _statBox('Period', '${stake.startDate ?? '—'} → ${stake.endDate ?? 'Flexible'}'),
        ]),
      ]),
    );
  }

  Widget _actionBtn(String label, Color bg, Color fg, VoidCallback? onTap, {Color? border}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _statBox(String label, String value, {Color? color}) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _kCard2, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.03))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ]),
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

  Map<String, dynamic> _statusStyle(int s) {
    switch (s) {
      case 1: return {'label': 'Active', 'color': Colors.black, 'bg': _kGreen};
      case 2: return {'label': 'Completed', 'color': const Color(0xFF60A5FA), 'bg': const Color(0x3360A5FA)};
      case 3: return {'label': 'Cancelled', 'color': const Color(0xFFFF3B30), 'bg': const Color(0x33FF3B30)};
      default: return {'label': 'Active', 'color': Colors.black, 'bg': _kGreen};
    }
  }
}
