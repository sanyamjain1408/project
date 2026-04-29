import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';
import 'earn_subscribe_modal.dart';

class EarnHomeScreen extends StatefulWidget {
  const EarnHomeScreen({super.key});

  @override
  State<EarnHomeScreen> createState() => _EarnHomeScreenState();
}

class _EarnHomeScreenState extends State<EarnHomeScreen> {
  final _controller = Get.find<EarnController>();
  final Map<String, bool> _expandedCoins = {};

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoadingProducts.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)));
      }

      final coins = _controller.products.map((p) => p.coin).toSet().toList();

      if (coins.isEmpty) {
        return const Center(
          child: Text('No products available', style: TextStyle(color: Color(0xFF6B7280))),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: coins.length,
        itemBuilder: (context, index) {
          final coin = coins[index];
          final coinProducts = _controller.products.where((p) => p.coin == coin).toList()
            ..sort((a, b) => a.lockDays.compareTo(b.lockDays));
          final isExpanded = _expandedCoins[coin] ?? false;
          final aprs = coinProducts.map((p) => p.apr).toList();
          final minApr = aprs.reduce((a, b) => a < b ? a : b);
          final maxApr = aprs.reduce((a, b) => a > b ? a : b);
          final hasFlexible = coinProducts.any((p) => p.lockDays == 0);
          final hasFixed = coinProducts.any((p) => p.lockDays > 0);
          final period = hasFlexible && hasFixed
              ? 'Flexible / Fixed'
              : hasFlexible
                  ? 'Flexible'
                  : 'Fixed';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Column(
              children: [
                // ── Coin Row ──
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _expandedCoins[coin] = !isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Coin Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E2128)),
                          child: coinProducts.first.coinIcon != null
                              ? ClipOval(child: Image.network(coinProducts.first.coinIcon!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 20)))
                              : const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Coin Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(coin, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              Text(period, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                            ],
                          ),
                        ),
                        // APR Range
                        Text(
                          minApr == maxApr ? '${minApr.toStringAsFixed(2)}%' : '${minApr.toStringAsFixed(2)}%~${maxApr.toStringAsFixed(2)}%',
                          style: const TextStyle(color: Color(0xFFB5F000), fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expanded Plan List ──
                if (isExpanded)
                  ...coinProducts.map((product) {
                    final label = product.lockDays == 0 ? 'Flexible' : '${product.lockDays} Days Fixed';
                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0F14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E2128)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(coin, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('APR', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('${product.apr.toStringAsFixed(2)}%', style: const TextStyle(color: Color(0xFFB5F000), fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Limits', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('${coinFormat(product.minAmount)}-${coinFormat(product.maxAmount)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => EarnSubscribeModal(product: product),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB5F000),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Subscribe', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      );
    });
  }
}