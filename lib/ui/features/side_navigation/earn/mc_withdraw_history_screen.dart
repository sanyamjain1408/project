import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mc_staking_controller.dart';
import 'mc_staking_models.dart';
import 'mc_portfolio_screen.dart';

const _kGreen = Color(0xFFCCFF00);
const _kBg = Color(0xFF0A0B0D);
const _kCard = Color(0xFF1A1A1A);

class McWithdrawHistoryScreen extends StatefulWidget {
  const McWithdrawHistoryScreen({super.key});

  @override
  State<McWithdrawHistoryScreen> createState() => _McWithdrawHistoryScreenState();
}

class _McWithdrawHistoryScreenState extends State<McWithdrawHistoryScreen> {
  late McStakingController _c;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.fetchWithdrawHistory(page: _page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: const Text('Withdraw History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
        actions: [
          TextButton(
            onPressed: () => Get.to(() => const McPortfolioScreen()),
            child: const Text('Dashboard', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Obx(() {
        if (_c.isLoadingWithdraw.value) {
          return const Center(child: CircularProgressIndicator(color: _kGreen));
        }
        final records = _c.withdrawHistory;
        final meta = _c.withdrawMeta.value;
        final totalWithdrawn = records.fold(0.0, (s, r) => s + r.rewardAmount);
        final totalFees = records.fold(0.0, (s, r) => s + r.feeAmount);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary cards
            Row(children: [
              _summaryCard('Total Withdrawals', '${meta?['total'] ?? 0}', 'Transactions', _kGreen, Icons.receipt),
              const SizedBox(width: 10),
              _summaryCard('Total Received', totalWithdrawn.toStringAsFixed(6), 'Net amount', const Color(0xFFA78BFA), Icons.monetization_on),
              const SizedBox(width: 10),
              _summaryCard('Total Fees', totalFees.toStringAsFixed(6), '2% service fee', const Color(0xFF22C55E), Icons.percent),
            ]),
            const SizedBox(height: 16),

            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('😭', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text('No Withdrawals Yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Your withdrawal history will appear here',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ]),
              )
            else
              Container(
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _tableHeader(),
                  ...records.asMap().entries.map((e) => _tableRow(e.key, e.value)),
                ]),
              ),
            const SizedBox(height: 16),
            _buildPagination(meta),
          ],
        );
      }),
    );
  }

  Widget _summaryCard(String label, String value, String sub, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(label,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
              Icon(icon, color: Colors.white30, size: 18),
            ]),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
          ]),
        ),
      );

  Widget _tableHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF222222)))),
        child: Row(children: [
          _th('#', 1),
          _th('Date & Time', 3),
          _th('Coin', 2),
          _th('Gross', 3),
          _th('Fee (2%)', 3),
          _th('Received', 3),
          _th('TX REF', 3),
        ]),
      );

  Widget _th(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
            textAlign: TextAlign.center),
      );

  Widget _tableRow(int idx, McWithdrawRecord r) {
    final dt = r.createdAt != null ? _parseDateTime(r.createdAt!) : ('—', '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF111111)))),
      child: Row(children: [
        _td('${(_page - 1) * 20 + idx + 1}', 1, Colors.white38),
        Expanded(flex: 3, child: Column(children: [
          Text(dt.$1, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          if (dt.$2.isNotEmpty)
            Text(dt.$2, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9), textAlign: TextAlign.center),
        ])),
        _td(r.coin?.symbol ?? '—', 2, Colors.white),
        _td(r.grossAmount.toStringAsFixed(8), 3, Colors.white70, mono: true),
        _td('- ${r.feeAmount.toStringAsFixed(8)}', 3, const Color(0xFFEA4335), mono: true),
        _td(r.rewardAmount.toStringAsFixed(8), 3, const Color(0xFF00B052), mono: true),
        _td(r.txRef ?? '—', 3, _kGreen, mono: true),
      ]),
    );
  }

  Widget _td(String v, int flex, Color color, {bool mono = false}) => Expanded(
        flex: flex,
        child: Text(v,
            style: TextStyle(color: color, fontSize: 10,
                fontFeatures: mono ? const [FontFeature.tabularFigures()] : null),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
      );

  Widget _buildPagination(Map<String, dynamic>? meta) {
    final lastPage = meta?['last_page'] ?? 1;
    if (lastPage <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(lastPage, (i) {
        final p = i + 1;
        return GestureDetector(
          onTap: () { setState(() => _page = p); _c.fetchWithdrawHistory(page: p); },
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

  (String, String) _parseDateTime(String s) {
    try {
      final d = DateTime.parse(s);
      final date = '${d.day}/${d.month}/${d.year}';
      final time = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';
      return (date, time);
    } catch (_) {
      return (s, '');
    }
  }
}
