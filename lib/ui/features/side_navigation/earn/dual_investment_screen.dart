import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'dual_investment_controller.dart';
import 'dual_subscribe_modal.dart';

// ─── coin icon helper (uses backend URL, same as LandingMarketView) ───────────
Widget _coinIcon(String? url, {double size = 32}) {
  if (url != null && url.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackCoinIcon(size),
      ),
    );
  }
  return _fallbackCoinIcon(size);
}

Widget _fallbackCoinIcon(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFF1E2128),
    ),
    child: const Icon(
      Icons.monetization_on,
      color: Color(0xFFB5F000),
      size: 14,
    ),
  );
}

// ─── DualInvestmentScreen ─────────────────────────────────────────────────────
class DualInvestmentScreen extends StatefulWidget {
  const DualInvestmentScreen({super.key});

  @override
  State<DualInvestmentScreen> createState() => _DualInvestmentScreenState();
}

class _DualInvestmentScreenState extends State<DualInvestmentScreen> {
  late DualInvestmentController _controller;
  final RxInt _mainTab = 0.obs; // 0=Market, 1=My Subscription

  @override
  void initState() {
    super.initState();
    _controller = Get.put(DualInvestmentController());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabRow(),
        const SizedBox(height: 12),
        Obx(
          () => _mainTab.value == 0
              ? _buildMarketTab()
              : _buildSubscriptionsTab(),
        ),
      ],
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────

  Widget _bannerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFFFFFFF60), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Market / My Subscription row ──────────────────────────────────────────
  Widget _buildTabRow() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            _tabBtn("Market", 0),
            _tabBtn("My Subscription", 1),

            const Spacer(),

            GestureDetector(
              onTap: () {
                // Search action
              },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    Text(
                      "Search Coin",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: "DMSans", fontWeight: FontWeight.w400),
                    ),

                    SizedBox(width: 5),

                    Icon(Icons.search, color: Color(0xFFCCFF00), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final isA = _mainTab.value == idx;
    return GestureDetector(
      onTap: () {
        _mainTab.value = idx;
        if (idx == 1) _controller.fetchSubscriptions();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(
          label,
          style: TextStyle(
            color: isA ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: isA ? FontWeight.w700 : FontWeight.w400,
            fontFamily: "DMSans",
            height: 1,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MARKET TAB  (Image 4)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMarketTab() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // ── Step 1: Select Coin ──
        _stepLabel("1", "Select Coin"),
        const SizedBox(height: 10),

        Obx(
  () => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _controller.pairs.map((pair) {
        final isSel =
            _controller.selectedPair.value?.baseCoin == pair.baseCoin;

        final icon = _controller.coinIcons[pair.baseCoin];

        return GestureDetector(
          onTap: () => _controller.setSelectedPair(pair),
          child: Container(
            width: 110, // fixed width
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(18),

              // only border color changes
              border: Border.all(
                color: isSel
                    ? const Color(0xFFB5F000)
                    : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _coinIcon(icon, size: 38),

                const SizedBox(height: 10),

                Text(
                  pair.baseCoin,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Obx(() {
                  final prods = _controller.products
                      .where((p) => p.baseCoin == pair.baseCoin)
                      .toList();

                  final aprs = prods.map((p) => p.apr).toList();

                  if (aprs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final minA = aprs.reduce(
                    (a, b) => a < b ? a : b,
                  );

                  final maxA = aprs.reduce(
                    (a, b) => a > b ? a : b,
                  );

                  return Text(
                    "${minA.toStringAsFixed(2)}%~${maxA.toStringAsFixed(2)}%",
                    style: const TextStyle(
                      color: Color(0xFF00D26A),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  ),
),

        const SizedBox(height: 24),

        // ── Step 2: Start ──
        _stepLabel("2", "Start"),
        const SizedBox(height: 10),

        // Pair selector + Market Price row
        Obx(() {
          final pair = _controller.selectedPair.value;
          if (pair == null) return const SizedBox.shrink();
          final icon = _controller.coinIcons[pair.baseCoin];
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111318),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E2128)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _coinIcon(icon, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "${pair.baseCoin}-${pair.quoteCoin}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Market Price",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          );
        }),

        const SizedBox(height: 14),

        // ── Buy Low / Sell High toggle ──
        Obx(
          () => Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _strategyBtn("buy_low", "Buy Low"),
                _strategyBtn("sell_high", "Sell High"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Term Filter: All / 1 Day / 3 Days / 7 Days ──
        Obx(
          () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _termBtn(null, "All"),
                _termBtn(1, "1 Day"),
                _termBtn(3, "3 Days"),
                _termBtn(7, "7 Days"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Products Table ──
        Obx(() {
          if (_controller.isLoadingProducts.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFFB5F000)),
              ),
            );
          }
          if (_controller.products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No products available',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1014),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Column(
              children: [
                ..._controller.products.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isBuyLow = p.strategy == 'buy_low';
                  final stratColor = isBuyLow
                      ? const Color(0xFF00CCFF)
                      : const Color(0xFFFF9900);
                  final yieldRate = p.apr * p.termDays / 365 / 100;
                  final isLoggedIn = gUserRx.value.id > 0;

                  return Column(
                    children: [
                      if (idx > 0)
                        const Divider(height: 1, color: Color(0xFF1E2128)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label row 1
                            Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    "Target Price",
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  "APR",
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Value row 1
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        p.targetPrice.toStringAsFixed(0),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: stratColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "${(yieldRate * 100).toStringAsFixed(2)}% ${isBuyLow ? '↓' : '↑'}",
                                          style: TextStyle(
                                            color: stratColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${p.apr.toStringAsFixed(2)}%",
                                  style: const TextStyle(
                                    color: Color(0xFF00B052),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Label row 2
                            Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    "Expiry Date",
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  "Action",
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Value row 2
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    "(${p.expiryDate}) ${p.termDays}Days",
                                    style: const TextStyle(
                                      color: Color(0xFFCCCCCC),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: isLoggedIn
                                      ? () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => DualSubscribeModal(
                                            product: p,
                                            controller: _controller,
                                          ),
                                        )
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isLoggedIn
                                          ? LinearGradient(
                                              colors: isBuyLow
                                                  ? [
                                                      const Color(0xFF00E5FF),
                                                      const Color(0xFF00BFFF),
                                                    ]
                                                  : [
                                                      const Color(0xFFB5F000),
                                                      const Color(0xFF88BB00),
                                                    ],
                                            )
                                          : null,
                                      color: isLoggedIn
                                          ? null
                                          : const Color(0xFF222222),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isLoggedIn ? "Subscribe" : "Login",
                                      style: TextStyle(
                                        color: isLoggedIn
                                            ? Colors.black
                                            : const Color(0xFF555555),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MY SUBSCRIPTION TAB  (Image 5)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSubscriptionsTab() {
    final isLoggedIn = gUserRx.value.id > 0;
    if (!isLoggedIn) {
      return const Center(
        child: Text(
          'Login to view subscriptions',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return Obx(() {
      if (_controller.isLoadingSubs.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFB5F000)),
        );
      }
      if (_controller.subscriptions.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48),
              SizedBox(height: 12),
              Text(
                'No subscriptions yet',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _controller.subscriptions.length,
        itemBuilder: (context, index) {
          final sub = _controller.subscriptions[index];
          final isActive = sub.status == 'active';
          final isSettled = sub.status == 'settled';
          final isBuyLow = sub.strategy == 'buy_low';
          final stratColor = isBuyLow
              ? const Color(0xFF00CCFF)
              : const Color(0xFFFF9900);
          final statusColor = isActive
              ? const Color(0xFFB5F000)
              : const Color(0xFF888888);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(
                      "${sub.baseCoin}-${sub.quoteCoin}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Strategy pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: stratColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isBuyLow ? "Buy Low" : "Sell High",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sub.status[0].toUpperCase() + sub.status.substring(1),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Settles on",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            sub.expiryDate,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    if (isSettled && sub.payoutAmount != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Settlement",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            "+${coinFormat(sub.payoutAmount!)} ${sub.payoutCoin}",
                            style: const TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Details
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _subInfo(
                      "Target",
                      "\$${sub.targetPrice.toStringAsFixed(0)}",
                    ),
                    _subInfo(
                      "Deposited",
                      "${coinFormat(sub.amount)} ${sub.depositCoin}",
                    ),
                    _subInfo(
                      "APR",
                      "${sub.apr.toStringAsFixed(2)}%",
                      color: const Color(0xFF00FF88),
                    ),
                    _subInfo(
                      "Yield",
                      "${(sub.yieldRate * 100).toStringAsFixed(4)}%",
                      color: const Color(0xFFB5F000),
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _subInfo(String label, String value, {Color? color}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLabel(String num, String label) {
    return Row(
      children: [
         Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: "DMSans",
                height: 1,
              ),
            ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 1,
              ),
        ),
      ],
    );
  }

  Widget _strategyBtn(String val, String label) {
    final isA = _controller.strategy.value == val;
    final isBuyLow = val == 'buy_low';
    return GestureDetector(
      onTap: () => _controller.setStrategy(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: isA
              ? (isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isA ? Colors.black : const Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _termBtn(int? val, String label) {
    final isA = _controller.termFilter.value == val;
    return GestureDetector(
      onTap: () => _controller.setTermFilter(val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isA ? const Color(0xFFB5F000) : const Color(0xFF111318),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isA ? Colors.transparent : const Color(0xFF1E2128),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isA ? Colors.black : const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── green wave fallback ──────────────────────────────────────────────────────
class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.3),
      size.height * 0.7,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF7FFF00).withOpacity(0.6),
                const Color(0xFF39FF14).withOpacity(0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.6, size.height * 0.3),
                radius: size.height * 0.7,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
