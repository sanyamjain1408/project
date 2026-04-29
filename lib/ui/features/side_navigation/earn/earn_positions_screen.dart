import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';

class EarnPositionsScreen extends StatefulWidget {
  const EarnPositionsScreen({super.key});

  @override
  State<EarnPositionsScreen> createState() => _EarnPositionsScreenState();
}

class _EarnPositionsScreenState extends State<EarnPositionsScreen> {
  final _controller = Get.find<EarnController>();

  @override
  void initState() {
    super.initState();
    if (gUserRx.value.id > 0) _controller.fetchPositions();
  }

  @override
  Widget build(BuildContext context) {
    if (gUserRx.value.id <= 0) {
      return const Center(child: Text('Login to view positions', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return Obx(() {
      if (_controller.isLoadingPositions.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)));
      }
      if (_controller.positions.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48),
              SizedBox(height: 12),
              Text('No active positions', style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
              SizedBox(height: 4),
              Text('Subscribe to a product to start earning', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.positions.length,
        itemBuilder: (context, index) {
          final pos = _controller.positions[index];
          final planLabel = pos.planType == 'flexible' ? 'Flexible' : '${pos.lockDays}d Fixed';
          final canRedeem = pos.isRedeemable;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Coin + Plan Type
                    Expanded(
                      child: Row(
                        children: [
                          Text(pos.coin, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFB5F000).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(planLabel, style: const TextStyle(color: Color(0xFFB5F000), fontSize: 10)),
                          ),
                          if (pos.autoReinvest == 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2200),
                                border: Border.all(color: const Color(0xFFB5F000).withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('🔄 Auto', style: TextStyle(color: Color(0xFFB5F000), fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Redeem Button
                    GestureDetector(
                      onTap: canRedeem ? () => _controller.redeem(pos.id) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: canRedeem ? const Color(0xFFB5F000) : const Color(0xFF333333)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          canRedeem ? 'Redeem' : 'Locked',
                          style: TextStyle(
                            color: canRedeem ? const Color(0xFFB5F000) : const Color(0xFF444444),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${coinFormat(pos.amount)} staked · ${pos.apr.toStringAsFixed(2)}% APR',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                if (pos.planType == 'locked' && !canRedeem && pos.lockUntil != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${pos.daysLeft} day${pos.daysLeft != 1 ? 's' : ''} remaining · unlocks ${pos.lockUntil}',
                    style: const TextStyle(color: Color(0xFFB5F000), fontSize: 11),
                  ),
                ],
                if (pos.planType == 'locked' && canRedeem) ...[
                  const SizedBox(height: 4),
                  const Text('Ready to redeem', style: TextStyle(color: Color(0xFF00FF88), fontSize: 11)),
                ],
                if (pos.reinvestCount > 0) ...[
                  const SizedBox(height: 4),
                  Text('Re-invested ${pos.reinvestCount} time${pos.reinvestCount != 1 ? 's' : ''}',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                ],
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF1E2128), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Earned', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, letterSpacing: 0.5)),
                    Text(
                      '+${coinFormat(pos.accruedInterest)} ${pos.coin}',
                      style: const TextStyle(color: Color(0xFFB5F000), fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }
}