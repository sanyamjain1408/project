import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'earn_controller.dart';
import 'earn_screen.dart';

class EarnRecommendedSection extends StatelessWidget {
  const EarnRecommendedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<EarnController>()
        ? Get.find<EarnController>()
        : Get.put(EarnController());

    return Obx(() {
      final products = ctrl.products;

      final Map<String, EarnProduct> bestPerCoin = {};
      for (final p in products) {
        if (!bestPerCoin.containsKey(p.coin) || p.apr > bestPerCoin[p.coin]!.apr) {
          bestPerCoin[p.coin] = p;
        }
      }
      final topRec = bestPerCoin.values.toList()
        ..sort((a, b) => b.apr.compareTo(a.apr));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ctrl.isLoadingProducts.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFFCCFF00)),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: topRec.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  const colors = [
                    Color(0xFFFF6F00),
                    Color(0xFF00E5FF),
                    Color(0xFF0062FF),
                    Color(0xFFCCFF00),
                  ];
                  return _RecommendedCard(
                    product: topRec[i],
                    color: colors[i % 4],
                    allProducts: products.toList(),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

class _RecommendedCard extends StatelessWidget {
  final EarnProduct product;
  final Color color;
  final List<EarnProduct> allProducts;

  const _RecommendedCard({
    required this.product,
    required this.color,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: SafeArea(
            child: EasyEarnModal(
              coin: product.coin,
              plans: allProducts
                  .where((p) => p.coin == product.coin)
                  .toList()
                ..sort((a, b) => a.lockDays.compareTo(b.lockDays)),
            ),
          ),
        ),
      ),
      child: Container(
        width: 220,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1A1A),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 40,
                            width: 40,
                            child: _coinIcon(
                              product.coinIcon,
                              size: 24,
                              fallbackColor: color.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.coin,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 16 / 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Easy Earn | Flexible",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    height: 16 / 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF00B2E3),
                                Color(0xFFFFA600),
                                Color(0xFFF03A89),
                              ],
                              stops: [0.0, 0.5326, 1.0],
                            ).createShader(bounds),
                            child: Text(
                              "${product.apr.toStringAsFixed(2)}%",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              "APR",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 16 / 12,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _coinIcon(String? iconUrl, {double size = 32, Color? fallbackColor}) {
  final bg = fallbackColor ?? const Color(0xFF1E2128);
  if (iconUrl != null && iconUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(size, bg),
      ),
    );
  }
  return _fallbackIcon(size, bg);
}

Widget _fallbackIcon(double size, Color bg) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Icon(Icons.currency_bitcoin, color: Colors.white54, size: size * 0.55),
  );
}
