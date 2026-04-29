import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';

class EarnHistoryScreen extends StatefulWidget {
  const EarnHistoryScreen({super.key});

  @override
  State<EarnHistoryScreen> createState() => _EarnHistoryScreenState();
}

class _EarnHistoryScreenState extends State<EarnHistoryScreen> {
  final _controller = Get.find<EarnController>();

  @override
  void initState() {
    super.initState();
    if (gUserRx.value.id > 0) _controller.fetchHistory();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'subscribe': return const Color(0xFFB5F000);
      case 'redeem':    return const Color(0xFF00CCCC);
      case 'interest':  return const Color(0xFF00FF88);
      case 'reinvest':  return const Color(0xFFAA88FF);
      default:          return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (gUserRx.value.id <= 0) {
      return const Center(child: Text('Login to view history', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return Obx(() {
      if (_controller.isLoadingHistory.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)));
      }
      if (_controller.history.isEmpty) {
        return const Center(child: Text('No transactions yet', style: TextStyle(color: Color(0xFF6B7280))));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.history.length,
        itemBuilder: (context, index) {
          final tx = _controller.history[index];
          final isOut = tx.type == 'subscribe';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor(tx.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _typeColor(tx.type).withOpacity(0.3)),
                  ),
                  child: Text(
                    tx.type.toUpperCase(),
                    style: TextStyle(color: _typeColor(tx.type), fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                // Coin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.coin, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(tx.createdAt, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '${isOut ? '-' : '+'}${coinFormat(tx.amount)} ${tx.coin}',
                  style: TextStyle(
                    color: isOut ? const Color(0xFFFF6666) : const Color(0xFF00FF88),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}