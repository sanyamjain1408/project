import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart';
import 'mc_staking_models.dart';

const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF111111);
const _kCard = Color(0xFF1A1A1A);

class McWithdrawHistoryScreen extends StatefulWidget {
  /// 0 = Withdraw History, 1 = Reward History, 2 = Referral History
  final int initialTab;
  const McWithdrawHistoryScreen({super.key, this.initialTab = 0});

  @override
  State<McWithdrawHistoryScreen> createState() => _McWithdrawHistoryScreenState();
}

class _McWithdrawHistoryScreenState extends State<McWithdrawHistoryScreen> {
  late McStakingController _c;
  late int _tab;
  int _withdrawPage = 1;
  int _rewardPage = 1;
  int _referralPage = 1;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentTab());
  }

  void _loadCurrentTab() {
    if (_tab == 0) _c.fetchWithdrawHistory(page: _withdrawPage);
    if (_tab == 1) _c.fetchRewards(page: _rewardPage);
    if (_tab == 2) _c.fetchReferralRewards(page: _referralPage);
  }

  void _switchTab(int t) {
    setState(() => _tab = t);
    if (t == 0 && _c.withdrawHistory.isEmpty) _c.fetchWithdrawHistory(page: _withdrawPage);
    if (t == 1 && _c.rewards.isEmpty) _c.fetchRewards(page: _rewardPage);
    if (t == 2 && _c.referralRewards.isEmpty) _c.fetchReferralRewards(page: _referralPage);
  }

  // ── Tab labels ────────────────────────────────────────────────────────────
  static const _tabLabels = ['Withdraw History', 'Reward History', 'Referral History'];
  static const _tabTitles = ['Withdraw History', 'Reward History', 'Referral History'];
  static const _tabSubs = [
    'All your reward withdrawals',
    'All your rewards',
    "Commission earned from your referrals' staking rewards",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back + tab row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    for (int i = 0; i < _tabLabels.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      _tabBtn(i, _tabLabels[i]),
                    ],
                  ],
                ),
              ),
            ),

            // ── Title + subtitle ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
              child: Text(
                _tabTitles[_tab],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                _tabSubs[_tab],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontFamily: 'DMSans',
                ),
              ),
            ),

            // ── Stats cards ─────────────────────────────────────────────────
            if (_tab == 0) _buildWithdrawStats(),
            if (_tab == 1) _buildRewardStats(),
            if (_tab == 2) _buildReferralStats(),

            const SizedBox(height: 14),

            // ── Content list ────────────────────────────────────────────────
            Expanded(
              child: _tab == 0
                  ? _buildWithdrawList()
                  : _tab == 1
                      ? _buildRewardList()
                      : _buildReferralList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(int t, String label) {
    final active = _tab == t;
    return GestureDetector(
      onTap: () => _switchTab(t),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.white.withOpacity(0.4),
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }

  // ── Stats cards ───────────────────────────────────────────────────────────

  Widget _buildWithdrawStats() {
    return Obx(() {
      final list = _c.withdrawHistory;
      final totalReceived = list.fold(0.0, (s, r) => s + r.rewardAmount);
      final totalFees = list.fold(0.0, (s, r) => s + r.feeAmount);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _statCard('Total Withdrawals', '${_c.withdrawMeta.value?['total'] ?? list.length}', 'Transactions', _kGreen, '📈')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Total Received', totalReceived.toStringAsFixed(6), 'Net amount', const Color(0xFFE946FF), '💰')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('Total Fees Paid', totalFees.toStringAsFixed(6), '2% service fee', const Color(0xFF00B052), '🏦')),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),
          ],
        ),
      );
    });
  }

  Widget _buildRewardStats() {
    return Obx(() {
      final list = _c.rewards;
      final total = list.fold(0.0, (s, r) => s + r.rewardAmount);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _statCard('Total Rewards', total.toStringAsFixed(6), 'Earned', const Color(0xFF00B052), '⚡')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Reward Records', '${list.length}', 'Entries', _kGreen, '📊')),
        ]),
      );
    });
  }

  Widget _buildReferralStats() {
    return Obx(() {
      final list = _c.referralRewards;
      final total = list.fold(0.0, (s, r) => s + r.rewardAmount);
      final lvl1 = list.where((r) => r.referralLevel == 1).fold(0.0, (s, r) => s + r.rewardAmount);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _statCard('Total Commission', total.toStringAsFixed(6), 'All levels', _kGreen, '💎')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('L1 · 10%', lvl1.toStringAsFixed(6), 'Direct referral', const Color(0xFFE946FF), '🏆')),
        ]),
      );
    });
  }

  Widget _statCard(String label, String value, String sub, Color color, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'DMSans')),
              ),
              Text(emoji, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'DMSans')),
        ],
      ),
    );
  }

  // ── Withdraw list ─────────────────────────────────────────────────────────

  Widget _buildWithdrawList() {
    return Obx(() {
      if (_c.isLoadingWithdraw.value) {
        return const Center(child: CircularProgressIndicator(color: _kGreen));
      }
      if (_c.withdrawHistory.isEmpty) {
        return _empty('No withdrawals yet', 'Withdraw your staking rewards to see history here');
      }
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 680,
                  child: Column(children: [
                    _headerRow(const [
                      _Col('No.', 36),
                      _Col('Date & Time', 130),
                      _Col('Coin', 60),
                      _Col('Gross Amount', 110),
                      _Col('Fee (2%)', 100),
                      _Col('You Received', 120),
                      _Col('TX REF', 104),
                    ]),
                    ..._c.withdrawHistory.asMap().entries.map((e) => _withdrawRow(e.key, e.value)),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _paginationWidget(_c.withdrawMeta.value, (p) {
              setState(() => _withdrawPage = p);
              _c.fetchWithdrawHistory(page: p);
            }),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _withdrawRow(int idx, McWithdrawRecord r) {
    final dt = _parseDate(r.createdAt);
    final isLast = idx == _c.withdrawHistory.length - 1;
    return _dataRow(isLast, [
      _textCell('${(_withdrawPage - 1) * 20 + idx + 1}', 36),
      _dateCell(dt.$1, dt.$2, 130),
      _textCell(r.coin?.symbol ?? '—', 60, bold: true),
      _textCell(r.grossAmount.toStringAsFixed(8), 110),
      _textCell('− ${r.feeAmount.toStringAsFixed(8)}', 100),
      _richCell('${r.rewardAmount.toStringAsFixed(8)} ', r.coin?.symbol ?? 'USDT', 120, const Color(0xFF00B052)),
      _textCell(r.txRef ?? '—', 104, color: _kGreen, small: true),
    ]);
  }

  // ── Reward list ───────────────────────────────────────────────────────────

  Widget _buildRewardList() {
    return Obx(() {
      if (_c.isLoadingRewards.value) {
        return const Center(child: CircularProgressIndicator(color: _kGreen));
      }
      if (_c.rewards.isEmpty) {
        return _empty('No rewards yet', 'Start staking to earn daily rewards');
      }
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 520,
                  child: Column(children: [
                    _headerRow(const [
                      _Col('No.', 36),
                      _Col('Coin', 60),
                      _Col('Reward Amount', 150),
                      _Col('Daily Rate', 110),
                      _Col('Date', 144),
                    ]),
                    ..._c.rewards.asMap().entries.map((e) => _rewardRow(e.key, e.value)),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _paginationWidget(_c.rewardsMeta.value, (p) {
              setState(() => _rewardPage = p);
              _c.fetchRewards(page: p);
            }),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _rewardRow(int idx, McStakingReward r) {
    final dt = _parseDate(r.rewardDate);
    final isLast = idx == _c.rewards.length - 1;
    return _dataRow(isLast, [
      _textCell('${(_rewardPage - 1) * 15 + idx + 1}', 36),
      _textCell(r.coin?.symbol ?? '—', 60, bold: true),
      _textCell(r.rewardAmount.toStringAsFixed(8), 150, color: const Color(0xFF00B052)),
      _textCell('${r.dailyRate.toStringAsFixed(6)}%', 110),
      _dateCell(dt.$1, dt.$2, 144),
    ]);
  }

  // ── Referral list ─────────────────────────────────────────────────────────

  Widget _buildReferralList() {
    return Obx(() {
      if (_c.isLoadingReferral.value) {
        return const Center(child: CircularProgressIndicator(color: _kGreen));
      }
      if (_c.referralRewards.isEmpty) {
        return _empty('No referral commissions yet', 'Invite friends to earn commissions from their staking');
      }
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 590,
                  child: Column(children: [
                    _headerRow(const [
                      _Col('No.', 36),
                      _Col('Member', 170),
                      _Col('Level', 64),
                      _Col('You Commission', 140),
                      _Col('Date & Time', 160),
                    ]),
                    ..._c.referralRewards.asMap().entries.map((e) => _referralRow(e.key, e.value)),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _paginationWidget(_c.referralMeta.value, (p) {
              setState(() => _referralPage = p);
              _c.fetchReferralRewards(page: p);
            }),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _referralRow(int idx, McReferralReward r) {
    final name = (r.fromName?.isNotEmpty == true) ? r.fromName! : 'Trapix User';
    final email = r.fromEmail ?? '';
    final lvl = r.referralLevel;
    final lvlColor = lvl == 1 ? _kGreen : lvl == 2 ? const Color(0xFFE946FF) : const Color(0xFF00B052);
    final lvlPct = lvl == 1 ? '10%' : lvl == 2 ? '5%' : '3%';
    final dt = _parseDate(r.rewardDate);
    final isLast = idx == _c.referralRewards.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 0, 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: Text('${(_referralPage - 1) * 15 + idx + 1}',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontFamily: 'DMSans')),
        ),
        SizedBox(
          width: 170,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
            if (email.isNotEmpty)
              Text(email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'DMSans')),
          ]),
        ),
        SizedBox(
          width: 64,
          child: Text('L$lvl · $lvlPct',
              style: TextStyle(
                  color: lvlColor, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
        ),
        SizedBox(
          width: 140,
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: '+${r.rewardAmount.toStringAsFixed(7)} ',
                style: const TextStyle(
                    color: Color(0xFF00B052), fontSize: 12, fontFamily: 'DMSans')),
            TextSpan(
                text: r.coin?.symbol ?? 'USDT',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DMSans')),
          ])),
        ),
        SizedBox(
          width: 160,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dt.$1,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
            if (dt.$2.isNotEmpty)
              Text(dt.$2,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'DMSans')),
          ]),
        ),
      ]),
    );
  }

  // ── Table helpers ─────────────────────────────────────────────────────────

  Widget _headerRow(List<_Col> cols) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        color: _kCard,
      ),
      child: Row(
        children: cols.map((c) => SizedBox(
          width: c.width,
          child: Text(c.label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'DMSans')),
        )).toList(),
      ),
    );
  }

  Widget _dataRow(bool isLast, List<Widget> cells) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 0, 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: Row(children: cells),
    );
  }

  Widget _textCell(String text, double width,
      {bool bold = false, Color color = Colors.white, bool small = false}) {
    return SizedBox(
      width: width,
      child: Text(text,
          style: TextStyle(
            color: color,
            fontSize: small ? 11 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'DMSans',
          )),
    );
  }

  Widget _dateCell(String date, String time, double width) {
    return SizedBox(
      width: width,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(date,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
        if (time.isNotEmpty)
          Text(time,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'DMSans')),
      ]),
    );
  }

  Widget _richCell(String val, String coin, double width, Color valColor) {
    return SizedBox(
      width: width,
      child: Text.rich(TextSpan(children: [
        TextSpan(text: val, style: TextStyle(color: valColor, fontSize: 12, fontFamily: 'DMSans')),
        TextSpan(text: coin, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DMSans')),
      ])),
    );
  }

  Widget _empty(String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
          const SizedBox(height: 8),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'DMSans')),
        ]),
      ),
    );
  }

  Widget _paginationWidget(Map<String, dynamic>? meta, void Function(int) onPage) {
    if (meta == null) return const SizedBox.shrink();
    final cur = (meta['current_page'] as num?)?.toInt() ?? 1;
    final last = (meta['last_page'] as num?)?.toInt() ?? 1;
    if (last <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pageBtn(Icons.chevron_left, cur > 1 ? () => onPage(cur - 1) : null),
        const SizedBox(width: 10),
        Text('$cur / $last',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DMSans')),
        const SizedBox(width: 10),
        _pageBtn(Icons.chevron_right, cur < last ? () => onPage(cur + 1) : null),
      ],
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? _kCard : const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: onTap != null ? Colors.white : Colors.white24, size: 18),
      ),
    );
  }

  (String, String) _parseDate(String? raw) {
    if (raw == null) return ('—', '');
    try {
      final d = DateTime.parse(raw).toLocal();
      final date = '${d.month}/${d.day}/${d.year}';
      final h = d.hour;
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
      final time =
          '$h12:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')} $ampm';
      return (date, time);
    } catch (_) {
      return (raw, '');
    }
  }
}

class _Col {
  final String label;
  final double width;
  const _Col(this.label, this.width);
}
