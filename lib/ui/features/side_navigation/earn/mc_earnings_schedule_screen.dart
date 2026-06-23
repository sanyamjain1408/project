import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart';
import 'mc_staking_models.dart';
import 'mc_my_stakes_screen.dart';

const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF0A0B0D);
const _kCard = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF111111);

class McEarningsScheduleScreen extends StatefulWidget {
  final String stakeUid;
  const McEarningsScheduleScreen({super.key, required this.stakeUid});

  @override
  State<McEarningsScheduleScreen> createState() => _McEarningsScheduleScreenState();
}

class _McEarningsScheduleScreenState extends State<McEarningsScheduleScreen> {
  late McStakingController _c;
  McStake? _stake;
  Set<String> _creditedDates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // Load stake
    var found = _c.stakes.firstWhereOrNull((s) => s.uid == widget.stakeUid);
    if (found == null) {
      await _c.fetchMyStakes(page: 1);
      found = _c.stakes.firstWhereOrNull((s) => s.uid == widget.stakeUid);
    }

    // Fetch real reward history from API — store as "YYYY-MM-DD" strings
    Set<String> credited = {};
    try {
      final res = await _c.fetchStakeRewards(widget.stakeUid);
      for (final r in res) {
        final dateStr = (r['reward_date']?.toString() ?? '').substring(0, 10 < (r['reward_date']?.toString() ?? '').length ? 10 : (r['reward_date']?.toString() ?? '').length);
        if (dateStr.length == 10) credited.add(dateStr);
      }
    } catch (_) {}

    setState(() {
      _stake = found;
      _creditedDates = credited;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: const Text('Earnings Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
        actions: [
          TextButton(
            onPressed: () => Get.to(() => const McMyStakesScreen()),
            child: const Text('My Stakes', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _stake == null
              ? _buildNotFound()
              : _buildContent(_stake!),
    );
  }

  Widget _buildNotFound() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('❌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Stake Not Found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.black),
            child: const Text('Back'),
          ),
        ]),
      );

  Widget _buildContent(McStake stake) {
    final startDate = _parseDate(stake.startDate) ?? DateTime.now();
    final endDate = stake.endDate != null
        ? _parseDate(stake.endDate ?? '')
        : startDate.add(const Duration(days: 100));
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final dailyEarning = stake.amount * (stake.dailyRate / 100);
    final totalDays = endDate != null
        ? (endDate.difference(startDate).inDays + 1).clamp(1, 9999)
        : 100;
    final totalReward = dailyEarning * totalDays;
    final earnedSoFar = stake.totalRewardEarned;
    final remaining = (totalReward - earnedSoFar).clamp(0.0, double.infinity);

    final daysElapsed = today.difference(startDate).inDays + 1;
    // Use actual credited dates count for daysCompleted
    final todayYMDStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final daysCompleted = _creditedDates.where((d) => d != todayYMDStr).length.clamp(0, totalDays);
    final daysRemaining = (totalDays - daysElapsed).clamp(0, totalDays);
    final progressPct = totalDays > 0
        ? (daysCompleted / totalDays * 100).clamp(0.0, 100.0)
        : 0.0;

    // Build schedule rows — days 1 to totalDays
    final rows = List.generate(totalDays, (i) {
      final d = i + 1; // day number 1..totalDays
      final rowDate = startDate.add(Duration(days: i + 1));
      final rowDateNormalized = DateTime(rowDate.year, rowDate.month, rowDate.day);
      final rowYMD = '${rowDateNormalized.year}-${rowDateNormalized.month.toString().padLeft(2,'0')}-${rowDateNormalized.day.toString().padLeft(2,'0')}';
      final todayYMD = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      final isToday = rowYMD == todayYMD;
      final isDone = _creditedDates.contains(rowYMD) && !isToday;
      return _ScheduleRow(
        day: d,
        date: _fmtDate(rowDate),
        earning: dailyEarning,
        cumulative: dailyEarning * d,
        isDone: isDone,
        isToday: isToday,
      );
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${stake.coin?.symbol ?? ''} · $totalDays Days · ${stake.dailyRate.toStringAsFixed(2)}% daily',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
          children: [
            _summaryCard('Staked Amount', '${stake.amount.toStringAsFixed(2)} ${stake.coin?.symbol ?? ''}', _kGreen),
            _summaryCard('Daily Earning', '${dailyEarning.toStringAsFixed(8)} ${stake.coin?.symbol ?? ''}', const Color(0xFFA78BFA)),
            _summaryCard('Total Reward', '${totalReward.toStringAsFixed(8)} ${stake.coin?.symbol ?? ''}', const Color(0xFF00B052)),
            _summaryCard('Days Remaining', '$daysRemaining / $totalDays days', const Color(0xFF00E5FF)),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              Text('${progressPct.toStringAsFixed(0)}% · Day $daysElapsed of $totalDays · $daysCompleted completed',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progressPct / 100,
                backgroundColor: _kCard2,
                valueColor: const AlwaysStoppedAnimation(_kGreen),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(stake.startDate ?? '', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              Text(stake.endDate ?? 'Flexible', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const _TH('Day', flex: 1),
                const _TH('Date', flex: 3),
                const _TH('Daily Earning', flex: 3),
                const _TH('Cumulative', flex: 3),
                const _TH('', flex: 1),
              ]),
            ),
            const Divider(color: Color(0xFF222222), height: 1),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => _buildRow(rows[i], stake.coin?.symbol ?? ''),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _totalRow('Earned So Far', '+${earnedSoFar.toStringAsFixed(8)}', stake.coin?.symbol ?? '', const Color(0xFFA78BFA)),
            const Divider(color: Color(0xFF222222)),
            _totalRow('Remaining Profit', remaining.toStringAsFixed(8), stake.coin?.symbol ?? '', const Color(0xFF00E5FF)),
            const Divider(color: Color(0xFF222222)),
            _totalRow('TOTAL REWARD', totalReward.toStringAsFixed(8), stake.coin?.symbol ?? '', const Color(0xFF00B052), bold: true),
          ]),
        ),
      ],
    );
  }

  Widget _buildRow(_ScheduleRow row, String symbol) {
    final textColor = row.isToday ? _kGreen : row.isDone ? Colors.white : Colors.white38;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: row.isToday ? _kGreen : Colors.transparent, width: 3)),
        color: row.isToday ? _kGreen.withOpacity(0.03) : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          Expanded(flex: 1, child: Text('${row.day}',
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: row.isToday ? FontWeight.w700 : FontWeight.w400))),
          Expanded(flex: 3, child: Text(row.date,
              style: TextStyle(color: textColor, fontSize: 12))),
          Expanded(flex: 3, child: Text('+${row.earning.toStringAsFixed(8)}',
              style: TextStyle(color: row.isDone ? Colors.white : Colors.white38, fontSize: 11))),
          Expanded(flex: 3, child: Text(row.cumulative.toStringAsFixed(8),
              style: const TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Center(child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kGreen, width: 2),
              color: row.isDone ? _kGreen : Colors.transparent,
            ),
            child: row.isDone
                ? const Icon(Icons.check, size: 10, color: Colors.black)
                : null,
          ))),
        ]),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _totalRow(String label, String value, String symbol, Color color, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          Row(children: [
            Text(value, style: TextStyle(color: color, fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
            const SizedBox(width: 6),
            Text(symbol, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ]),
      );

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]} ${d.year}';
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      );
}

class _ScheduleRow {
  final int day;
  final String date;
  final double earning;
  final double cumulative;
  final bool isDone;
  final bool isToday;
  const _ScheduleRow({required this.day, required this.date, required this.earning,
      required this.cumulative, required this.isDone, required this.isToday});
}
