import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'dual_investment_controller.dart';
import 'dual_subscribe_modal.dart';
import 'package:intl/intl.dart';

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
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(DualInvestmentController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _searchFocus.unfocus(),
      child: Column(
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
      ),
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

            Container(
              height: 36,
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (v) =>
                          _searchQuery.value = v.trim().toLowerCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: "DMSans",
                      ),
                      decoration: InputDecoration(
                        hintText: "Search Coin",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFFCCFF00), size: 20),
                ],
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
          () {
            final q = _searchQuery.value;
            final filtered = _controller.pairs
                .where((p) =>
                    q.isEmpty || p.baseCoin.toLowerCase().contains(q))
                .toList();
            return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filtered.map((pair) {
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
                            ? Colors.white.withOpacity(0.5)
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
                          final prods = _controller.allProducts
                              .where((p) => p.baseCoin == pair.baseCoin)
                              .toList();

                          final aprs = prods.map((p) => p.apr).toList();

                          if (aprs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final minA = aprs.reduce((a, b) => a < b ? a : b);

                          final maxA = aprs.reduce((a, b) => a > b ? a : b);

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
          );
        }),

        const SizedBox(height: 24),

        // ── Step 2: Start ──
        _stepLabel("2", "Start"),
        const SizedBox(height: 20),

        // Pair selector + Market Price row
        Obx(() {
          final pair = _controller.selectedPair.value;

          if (pair == null) {
            return const SizedBox.shrink();
          }

          final icon = _controller.coinIcons[pair.baseCoin];

          return Container(
            color: Colors.transparent,
            child: Row(
              children: [
                // Coin Icon
                _coinIcon(icon, size: 20),

                const SizedBox(width: 10),

                // Pair Name
                Text(
                  "${pair.baseCoin}-${pair.quoteCoin}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                    height: 1,
                  ),
                ),

                const SizedBox(width: 10),

                // Dropdown Icon
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 22,
                ),

                const SizedBox(width: 10),

                // Divider
                Container(
                  width: 1,
                  height: 22,
                  color: Colors.white.withOpacity(0.5),
                ),

                const SizedBox(width: 10),

                // Market Price Label
                Text(
                  "Market Price",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1,
                  ),
                ),

                const SizedBox(width: 10),

                // Price
                Text(
                  () {
                    final p = _controller.coinPrices[pair.baseCoin.toUpperCase()] ?? 0;
                    return p > 0 ? coinFormat(p) : '--';
                  }(),
                  style: const TextStyle(
                    color: Color(0xFF00B052),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),

        // ── Buy Low / Sell High toggle ──
        Obx(
          () => Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _strategyBtn("buy_low", "Buy Low"),
                const SizedBox(width: 10),
                _strategyBtn("sell_high", "Sell High"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

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

        const SizedBox(height: 20),

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
          return Column(
            children: [
              ..._controller.products.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isBuyLow = p.strategy == 'buy_low';
                final stratColor = isBuyLow
                    ? const Color(0xFF00B052)
                    : const Color(0xFFFF9900);
                final yieldRate = p.apr * p.termDays / 365 / 100;
                final isLoggedIn = gUserRx.value.id > 0;

                return Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label row 1
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Target Price",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                              ),
                              Text(
                                "APR",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Value row 1
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      NumberFormat(
                                        '#,##,##0',
                                      ).format(p.targetPrice),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "DMSans",
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "${(yieldRate * 100).toStringAsFixed(2)}% ${isBuyLow ? '↓' : '↑'}",
                                      style: TextStyle(
                                        color: stratColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "DMSans",
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${p.apr.toStringAsFixed(2)}%",
                                style: const TextStyle(
                                  color: Color(0xFF00B052),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Label row 2
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Expiry Date",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                              ),
                              Text(
                                "Action",
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Value row 2
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "(${p.expiryDate}) ${p.termDays}Days",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoggedIn
                                    ? () => Get.to(() => Scaffold(
                                        backgroundColor: const Color(0xFF0F0F0F),
                                        body: SafeArea(
                                          child: DualSubscribeModal(
                                            product: p,
                                            controller: _controller,
                                          ),
                                        ),
                                      ))
                                    : null,
                                child: Container(
                                  height: 30,
                                  width: 136,

                                  alignment: Alignment.center, //  add this

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 38,
                                    vertical: 7,
                                  ),

                                  decoration: BoxDecoration(
                                    gradient: isLoggedIn
                                        ? const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFFCCFF00),
                                              Color(0xFF00E5FF),
                                            ],
                                          )
                                        : null,

                                    color: isLoggedIn
                                        ? null
                                        : const Color(0xFF222222),

                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: Text(
                                    isLoggedIn ? "Subscribe" : "Login",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "DMSans",
                                      height: 1,
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

      final q = _searchQuery.value;
      final filteredSubs = _controller.subscriptions
          .where((s) =>
              q.isEmpty ||
              s.baseCoin.toLowerCase().contains(q) ||
              s.quoteCoin.toLowerCase().contains(q))
          .toList();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filteredSubs.length,
        itemBuilder: (context, index) {
          final sub = filteredSubs[index];

          final isActive = sub.status == 'active';

          final isBuyLow = sub.strategy == 'buy_low';

          final statusColor = isActive
              ? const Color(0xFFCCFF00)
              : const Color(0xFF00FF37);

          return Container(
            color: Colors.transparent,
            margin: EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TOP ROW
                Row(
                  children: [
                    /// PAIR
                    Text(
                      "${sub.baseCoin}-${sub.quoteCoin}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                        height: 1,
                      ),
                    ),

                    const Spacer(),

                    /// STRATEGY BUTTON
                    Container(
                      width: 106,
                      height: 30,
                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: isBuyLow
                            ? const Color(0xFF00E5FF) // BUY color
                            : const Color(0xFFFF6F00), // SELL color

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        isBuyLow ? "Buy Low" : "Sell High",

                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 12,
                          fontWeight: isBuyLow
                              ? FontWeight
                                    .w400 // BUY weight
                              : FontWeight.w400, // SELL weight
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// STATUS BUTTON
                    Container(
                      width: 92,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sub.status[0].toUpperCase() + sub.status.substring(1),
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// DETAILS SECTION
                Column(
                  children: [
                    /// ROW 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TARGET
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Target : ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      "\$${sub.targetPrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// SETTLES ON
                        if (isActive)
                           Text(
                            "Settles on",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                              height: 1,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// ROW 2
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// DEPOSITED
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                 TextSpan(
                                  text: "Deposited: ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      "${coinFormat(sub.amount)} ${sub.depositCoin}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// DATE
                        if (isActive)
                          Text(
                            sub.expiryDate,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: "DMSans",
                              height: 1,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// ROW 3
                    Row(
                      children: [
                        /// APR
                        RichText(
                          text: TextSpan(
                            children: [
                               TextSpan(
                                text: "APR: ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: "${sub.apr.toStringAsFixed(2)}%",
                                style: const TextStyle(
                                  color: Color(0xFF00B052),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        /// YIELD
                        RichText(
                          text: TextSpan(
                            children: [
                               TextSpan(
                                text: "Yield: ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "${(sub.yieldRate * 100).toStringAsFixed(4)}%",
                                style: const TextStyle(
                                  color: Color(0xFFCCFF00),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  return GestureDetector(
    onTap: () => _controller.setStrategy(val),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isA
            ? (val == "sell_high"
                ? const Color(0XFFFF6F00) // SELL HIGH selected
                : const Color(0xFF00E5FF)) // BUY LOW selected
            : const Color(0xFF1A1A1A), // unselected

        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isA
              ? const Color(0xFF111111)
              : Colors.white.withOpacity(0.5),

          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: "DMSans",
          height: 1,
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
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isA ? const Color(0xFFCCFF00) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isA ? Colors.transparent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isA ? Color(0xFF1A1A1A) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: "DMSans",
            height: 1,
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
