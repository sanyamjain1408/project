import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/champion/champion_controller.dart';

class CompetitionDepositHistoryScreen extends StatefulWidget {
  final int competitionId;
  const CompetitionDepositHistoryScreen({super.key, required this.competitionId});

  @override
  State<CompetitionDepositHistoryScreen> createState() =>
      _CompetitionDepositHistoryScreenState();
}

class _CompetitionDepositHistoryScreenState
    extends State<CompetitionDepositHistoryScreen> {
  static const _bg = Color(0xFF111111);
  static const _card = Color(0xFF1A1A1A);
  static const _green = Color(0xFFCCFF00);
  static const _dmSans = 'DMSans';

  late final ChampionController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ChampionController>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ctrl.fetchDepositHistory(widget.competitionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back_outlined, color: Colors.white, size: 22),
          ),
        ),
        title: const Text(
          'Deposit History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
          ),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoadingHistory.value) {
          return const Center(
            child: CircularProgressIndicator(color: _green),
          );
        }
        final list = _ctrl.depositHistory;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_outlined, color: Colors.white24, size: 56),
                const SizedBox(height: 16),
                Text(
                  'No deposit history yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 15,
                    fontFamily: _dmSans,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _green,
          onRefresh: () => _ctrl.fetchDepositHistory(widget.competitionId),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildCard(list[i]),
          ),
        );
      }),
    );
  }

  Widget _buildCard(ApiDepositHistory item) {
    final statusColor = _statusColor(item.status);
    final bonusVal = double.tryParse(item.bonus) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('Date', item.date),
          const SizedBox(height: 10),
          _row('Amount', '\$${item.amount}'),
          const SizedBox(height: 10),
          _row('Coin', item.coin),
          const SizedBox(height: 10),
          _rowColored('Status', _capitalize(item.status), statusColor),
          const SizedBox(height: 10),
          _rowColored(
            'Bonus',
            '+${bonusVal.toStringAsFixed(2)}',
            _green,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            fontFamily: _dmSans,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: _dmSans,
          ),
        ),
      ],
    );
  }

  Widget _rowColored(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            fontFamily: _dmSans,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'success':
      case 'completed':
        return const Color(0xFF00C896);
      case 'pending':
        return const Color(0xFFF0B90B);
      case 'failed':
      case 'rejected':
        return const Color(0xFFE74C3C);
      default:
        return Colors.white54;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
