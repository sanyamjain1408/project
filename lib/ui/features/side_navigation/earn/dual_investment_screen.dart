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
        width: size, height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackCoinIcon(size),
      ),
    );
  }
  return _fallbackCoinIcon(size);
}

Widget _fallbackCoinIcon(double size) {
  return Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E2128)),
    child: const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 14),
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
  final RxInt _mainTab = 0.obs;   // 0=Market, 1=My Subscription

  @override
  void initState() {
    super.initState();
    _controller = Get.put(DualInvestmentController());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top stats banner (same style as wallet hero) ──
        _buildHeroBanner(),
        // ── Market / My Subscription tab ──
        _buildTabRow(),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() => _mainTab.value == 0 ? _buildMarketTab() : _buildSubscriptionsTab()),
        ),
      ],
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x4D1A1A1A),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Stack(
          children: [
            // Green wave right side
            Positioned(
              right: 0, top: 0, bottom: 0, width: 160,
              child: Image.asset(
                'assets/images/wallet_green_wave.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CustomPaint(painter: _GreenWavePainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Assets (USDT)", style: TextStyle(color: Color(0xFFFFFFFF80), fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text("\$1,546.01", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _bannerStat("Total Interest (USDT)", "0"),
                    const SizedBox(width: 32),
                    _bannerStat("Total Interest (USDT)", "0"),
                  ]),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () { _mainTab.value = 1; _controller.fetchSubscriptions(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFCCFF00), borderRadius: BorderRadius.circular(24)),
                      child: const Text("View my History", style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFFFFFFF60), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Market / My Subscription row ──────────────────────────────────────────
  Widget _buildTabRow() {
    return Obx(() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        _tabBtn("Market",          0),
        _tabBtn("My Subscription", 1),
        const Spacer(),
        // Search icon
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2128))),
            child: const Icon(Icons.search, color: Color(0xFF6B7280), size: 18),
          ),
        ),
      ]),
    ));
  }

  Widget _tabBtn(String label, int idx) {
    final isA = _mainTab.value == idx;
    return GestureDetector(
      onTap: () {
        _mainTab.value = idx;
        if (idx == 1) _controller.fetchSubscriptions();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Column(children: [
          Text(label, style: TextStyle(
            color: isA ? Colors.white : const Color(0xFF6B7280),
            fontSize: 15, fontWeight: isA ? FontWeight.w700 : FontWeight.w500,
          )),
          const SizedBox(height: 4),
          if (isA) Container(width: 20, height: 2, color: Colors.white),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MARKET TAB  (Image 4)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMarketTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ── Step 1: Select Coin ──
        _stepLabel("1", "Select Coin"),
        const SizedBox(height: 14),

        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _controller.pairs.map((pair) {
              final isSel = _controller.selectedPair.value?.baseCoin == pair.baseCoin;
              // Try to find icon from products list
              final prod  = _controller.products.firstWhereOrNull((p) => p.baseCoin == pair.baseCoin);
              return GestureDetector(
                onTap: () => _controller.setSelectedPair(pair),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFF111318),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? const Color(0xFFB5F000) : const Color(0xFF1E2128)),
                  ),
                  child: Column(children: [
                    // coin icon from backend
                    _coinIcon(prod?.coinIcon, size: 36),
                    const SizedBox(height: 6),
                    // APR range below coin name
                    Obx(() {
                      final prods = _controller.products.where((p) => p.baseCoin == pair.baseCoin).toList();
                      final aprs  = prods.map((p) => p.apr).toList();
                      final minA  = aprs.isNotEmpty ? aprs.reduce((a, b) => a < b ? a : b) : 0.0;
                      final maxA  = aprs.isNotEmpty ? aprs.reduce((a, b) => a > b ? a : b) : 0.0;
                      return Column(children: [
                        Text(pair.baseCoin, style: TextStyle(
                          color: isSel ? const Color(0xFFB5F000) : Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w700,
                        )),
                        if (aprs.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text("${minA.toStringAsFixed(2)}%~${maxA.toStringAsFixed(2)}%",
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
                        ],
                      ]);
                    }),
                  ]),
                ),
              );
            }).toList(),
          ),
        )),

        const SizedBox(height: 24),

        // ── Step 2: Start ──
        _stepLabel("2", "Start"),
        const SizedBox(height: 14),

        // Pair selector + Market Price row
        Obx(() {
          final pair = _controller.selectedPair.value;
          if (pair == null) return const SizedBox.shrink();
          return Row(children: [
            // Pair dropdown
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E2128))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _coinIcon(null, size: 18),
                  const SizedBox(width: 6),
                  Text("${pair.baseCoin}-${pair.quoteCoin}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 18),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            // Market price
            const Text("Market Price", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            const SizedBox(width: 6),
            const Text("72,543.34", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ]);
        }),

        const SizedBox(height: 14),

        // ── Buy Low / Sell High toggle ──
        Obx(() => Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _strategyBtn("buy_low",   "Buy Low"),
            _strategyBtn("sell_high", "Sell High"),
          ]),
        )),

        const SizedBox(height: 14),

        // ── Term Filter: All / 1 Day / 3 Days / 7 Days ──
        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _termBtn(null, "All"),
            _termBtn(1,    "1 Day"),
            _termBtn(3,    "3 Days"),
            _termBtn(7,    "7 Days"),
          ]),
        )),

        const SizedBox(height: 16),

        // ── Products Table ──
        Obx(() {
          if (_controller.isLoadingProducts.value) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFFB5F000))));
          }
          if (_controller.products.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No products available', style: TextStyle(color: Color(0xFF6B7280)))));
          }
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1014),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Column(children: [
              // Table header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: const [
                  Expanded(flex: 3, child: Text("Target Price", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text("APR",          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 3, child: Text("Expiry Date",  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text("Action",       style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFF1E2128)),

              ..._controller.products.map((p) {
                final isBuyLow   = p.strategy == 'buy_low';
                final stratColor = isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900);
                final yieldRate  = p.apr * p.termDays / 365 / 100;
                final isLoggedIn = gUserRx.value.id > 0;

                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      // Target Price column
                      Expanded(flex: 3, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.targetPrice.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: stratColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              "${(yieldRate * 100).toStringAsFixed(2)}% ${isBuyLow ? '↓' : '↑'}",
                              style: TextStyle(color: stratColor, fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )),
                      // APR column
                      Expanded(flex: 2, child: Text(
                        "${p.apr.toStringAsFixed(2)}%",
                        style: const TextStyle(color: Color(0xFF00B052), fontSize: 13, fontWeight: FontWeight.w700),
                      )),
                      // Expiry column
                      Expanded(flex: 3, child: Text(
                        "${p.expiryDate}\n${p.termDays}Days",
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10), maxLines: 2,
                      )),
                      // Subscribe button
                      Expanded(flex: 2, child: GestureDetector(
                        onTap: isLoggedIn ? () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DualSubscribeModal(product: p, controller: _controller),
                        ) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: isLoggedIn
                                ? LinearGradient(colors: isBuyLow
                                    ? [const Color(0xFF00E5FF), const Color(0xFF00BFFF)]
                                    : [const Color(0xFFB5F000), const Color(0xFF88BB00)])
                                : null,
                            color: isLoggedIn ? null : const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isLoggedIn ? "Subscribe" : "Login",
                            style: TextStyle(
                              color: isLoggedIn ? Colors.black : const Color(0xFF555555),
                              fontSize: 10, fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                    ]),
                  ),
                  const Divider(height: 1, color: Color(0xFF111318)),
                ]);
              }).toList(),
            ]),
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
      return const Center(child: Text('Login to view subscriptions', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return Obx(() {
      if (_controller.isLoadingSubs.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)));
      }
      if (_controller.subscriptions.isEmpty) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48),
          SizedBox(height: 12),
          Text('No subscriptions yet', style: TextStyle(color: Color(0xFF6B7280))),
        ]));
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _controller.subscriptions.length,
        itemBuilder: (context, index) {
          final sub      = _controller.subscriptions[index];
          final isActive = sub.status == 'active';
          final isSettled= sub.status == 'settled';
          final isBuyLow = sub.strategy == 'buy_low';
          final stratColor = isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900);
          final statusColor = isActive ? const Color(0xFFB5F000) : const Color(0xFF888888);

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
                Row(children: [
                  Text("${sub.baseCoin}-${sub.quoteCoin}", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  // Strategy pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: stratColor, borderRadius: BorderRadius.circular(10)),
                    child: Text(isBuyLow ? "Buy Low" : "Sell High", style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      sub.status[0].toUpperCase() + sub.status.substring(1),
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  if (isActive) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text("Settles on", style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
                    Text(sub.expiryDate, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                  if (isSettled && sub.payoutAmount != null) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text("Settlement", style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
                    Text("+${coinFormat(sub.payoutAmount!)} ${sub.payoutCoin}", style: const TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ]),
                const SizedBox(height: 12),
                // Details
                Wrap(spacing: 16, runSpacing: 6, children: [
                  _subInfo("Target",    "\$${sub.targetPrice.toStringAsFixed(0)}"),
                  _subInfo("Deposited", "${coinFormat(sub.amount)} ${sub.depositCoin}"),
                  _subInfo("APR",       "${sub.apr.toStringAsFixed(2)}%",     color: const Color(0xFF00FF88)),
                  _subInfo("Yield",     "${(sub.yieldRate * 100).toStringAsFixed(4)}%", color: const Color(0xFFB5F000)),
                ]),
              ],
            ),
          );
        },
      );
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _subInfo(String label, String value, {Color? color}) {
    return RichText(text: TextSpan(
      style: const TextStyle(fontSize: 12),
      children: [
        TextSpan(text: '$label: ', style: const TextStyle(color: Color(0xFF6B7280))),
        TextSpan(text: value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w600)),
      ],
    ));
  }

  Widget _stepLabel(String num, String label) {
    return Row(children: [
      Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB5F000)),
        child: Center(child: Text(num, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900))),
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _strategyBtn(String val, String label) {
    final isA      = _controller.strategy.value == val;
    final isBuyLow = val == 'buy_low';
    return GestureDetector(
      onTap: () => _controller.setStrategy(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: isA ? (isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900)) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          color: isA ? Colors.black : const Color(0xFF6B7280),
          fontSize: 13, fontWeight: FontWeight.w700,
        )),
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
          border: Border.all(color: isA ? Colors.transparent : const Color(0xFF1E2128)),
        ),
        child: Text(label, style: TextStyle(
          color: isA ? Colors.black : const Color(0xFF6B7280),
          fontSize: 12, fontWeight: FontWeight.w700,
        )),
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
      Paint()..shader = RadialGradient(
        colors: [const Color(0xFF7FFF00).withOpacity(0.6), const Color(0xFF39FF14).withOpacity(0.2), Colors.transparent],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.6, size.height * 0.3), radius: size.height * 0.7)),
    );
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}