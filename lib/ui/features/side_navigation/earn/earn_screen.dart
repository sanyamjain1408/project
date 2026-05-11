import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';
import 'earn_subscribe_modal.dart';
import 'dual_investment_screen.dart';

const String _baseUrl = 'https://api.trapix.com';

Color getLockColor(int days) {
  switch (days) {
    case 0:
      return const Color(0xFFCCFF00);
    case 30:
      return const Color(0xFF00CCFF);
    case 60:
      return const Color(0xFFAA88FF);
    case 90:
      return const Color(0xFFFF9900);
    case 120:
      return const Color(0xFFFF4488);
    default:
      return const Color(0xFFCCFF00);
  }
}

// ─── Coin icon helper (same pattern as LandingMarketView) ────────────────────
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
    decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
    child: const Icon(
      Icons.monetization_on,
      color: Color(0xFFB5F000),
      size: 16,
    ),
  );
}

// ─── EarnScreen ──────────────────────────────────────────────────────────────
class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final _controller = Get.put(EarnController());

  int _selectedMainTab = 0;
  int _selectedEasyTab = 0; // 0=Position, 1=History
  final List<String> _mainTabs = ["Overview", "Easy Earn", "Dual Investment"];

  String _searchCoin = "";
  String _filterStatus = "All";
  bool _isLoadingEasy = false;
  List<dynamic> _easyPositions = [];
  List<dynamic> _easyHistory = [];
  String _redeemError = "";
  String _historyError = "";

  int _openFaqIndex = -1;
  final List<Map<String, String>> _faqs = [
    {
      "q": "What is Trapix Earn?",
      "a":
          "Trapix Earn lets you earn passive income on your crypto holdings through Flexible plans (redeem anytime) and Fixed/Locked plans (earn higher APR for a fixed period).",
    },
    {
      "q": "How is the yield generated?",
      "a":
          "Yield is generated from trading fees, lending activity, and platform operations. The APR shown is an estimate based on current market conditions.",
    },
    {
      "q": "Is the yield fixed?",
      "a":
          "Flexible plan yields may vary based on market conditions. Locked plan yields are fixed at the time of subscription for the entire lock period.",
    },
    {
      "q": "When does the interest start to accrue?",
      "a":
          "Interest starts accruing from the next day after your subscription is confirmed. It is calculated daily and added to your accrued interest balance.",
    },
    {
      "q": "When can I redeem my funds?",
      "a":
          "Flexible plans can be redeemed at any time. Locked plans can only be redeemed after the lock period expires. Early redemption is not available for locked plans.",
    },
    {
      "q": "Are there any risks?",
      "a":
          "Earn products carry inherent risks including market volatility and platform risk. Please only invest what you can afford and read the full terms before subscribing.",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchProducts();
      if (gUserRx.value.id > 0) {
        _controller.fetchPositions();
        _controller.fetchBalances();
        _fetchEasyPositions();
      }
    });
  }

  String get _uid => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';

  // ── fetch helpers ──────────────────────────────────────────────────────────
  Future<void> _fetchEasyPositions() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoadingEasy = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/tf/earn/positions?user_id=$_uid'),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() => _easyPositions = json['data'] ?? []);
      } else {
        setState(() => _easyPositions = []);
      }
    } catch (_) {
      setState(() => _easyPositions = []);
    }
    setState(() => _isLoadingEasy = false);
  }

  Future<void> _fetchEasyHistory() async {
    if (_uid.isEmpty) return;
    setState(() {
      _isLoadingEasy = true;
      _historyError = "";
    });
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/tf/earn/history?user_id=$_uid'),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        dynamic data;
        if (json['data'] is Map && json['data']['data'] != null) {
          data = json['data']['data'];
        } else if (json['data'] is List) {
          data = json['data'];
        } else {
          data = [];
        }
        setState(() => _easyHistory = data.toList());
      } else {
        setState(() => _easyHistory = []);
      }
    } catch (_) {
      setState(() {
        _easyHistory = [];
        _historyError = "Unable to load history. Please try again.";
      });
    }
    setState(() => _isLoadingEasy = false);
  }

  Future<void> _handleRedeem(String subId) async {
    if (_uid.isEmpty) return;
    setState(() => _redeemError = "");
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/tf/earn/redeem?user_id=$_uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"subscription_id": subId}),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          await _fetchEasyPositions();
          await _controller.fetchBalances();
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully redeemed!'),
                backgroundColor: Colors.green,
              ),
            );
        } else {
          setState(() => _redeemError = json['message'] ?? "Redeem failed");
        }
      } else {
        setState(() => _redeemError = "Redeem failed. Please try again.");
      }
    } catch (_) {
      setState(() => _redeemError = "Redeem failed: Network error");
    }
  }

  // ── Calculator dialog ──────────────────────────────────────────────────────
  void _showCalculatorDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String selectedCoin = 'USDT';
        String amount = '10000';
        int activeYear = 2;
        int? selectedPlanId;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final coins = _controller.products
                .map((p) => p.coin)
                .toSet()
                .toList();
            if (coins.isNotEmpty && !coins.contains(selectedCoin))
              selectedCoin = coins.first;

            final coinPlans =
                _controller.products
                    .where((p) => p.coin == selectedCoin)
                    .toList()
                  ..sort((a, b) => a.lockDays.compareTo(b.lockDays));

            EarnProduct? flexPlan, fixedPlan;
            for (final p in coinPlans) {
              if (p.lockDays == 0 && flexPlan == null) flexPlan = p;
              if (p.lockDays > 0 && fixedPlan == null) fixedPlan = p;
            }
            selectedPlanId ??= coinPlans.isNotEmpty ? coinPlans.first.id : null;

            final selectedPlan = coinPlans.firstWhere(
              (p) => p.id == selectedPlanId,
              orElse: () => coinPlans.isNotEmpty
                  ? coinPlans.first
                  : EarnProduct(
                      id: 0,
                      coin: '',
                      apr: 0,
                      lockDays: 0,
                      minAmount: 0,
                      maxAmount: 0,
                    ),
            );
            final estEarnings =
                (double.tryParse(amount) ?? 0) *
                (selectedPlan.apr / 100) *
                activeYear;
            final amtCtrl = TextEditingController(text: amount);

            return AlertDialog(
              backgroundColor: const Color(0xFF181818),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Earnings Calculator",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF777777),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "I want to invest",
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: amtCtrl,
                                    onChanged: (v) {
                                      amount = v;
                                      setStateDialog(() {});
                                    },
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                _buildCoinSelector(selectedCoin, coins, (c) {
                                  selectedCoin = c;
                                  selectedPlanId = null;
                                  setStateDialog(() {});
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Recommended",
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildCalcPlanCard(flexPlan, selectedPlanId, (
                                id,
                              ) {
                                selectedPlanId = id;
                                setStateDialog(() {});
                              }),
                              const SizedBox(width: 10),
                              _buildCalcPlanCard(fixedPlan, selectedPlanId, (
                                id,
                              ) {
                                selectedPlanId = id;
                                setStateDialog(() {});
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Est. Earnings",
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${estEarnings.toStringAsFixed(2)} $selectedCoin",
                            style: const TextStyle(
                              color: Color(0xFF00D68F),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [1, 2, 3, 4].map((y) {
                              final isA = activeYear == y;
                              return GestureDetector(
                                onTap: () {
                                  activeYear = y;
                                  setStateDialog(() {});
                                },
                                child: Text(
                                  "Year $y",
                                  style: TextStyle(
                                    color: isA
                                        ? const Color(0xFFE0E0E0)
                                        : const Color(0xFF4A4A4A),
                                    fontWeight: isA
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                "Subscribe",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoinSelector(
    String sel,
    List<String> coins,
    Function(String) onSelect,
  ) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: coins
              .map(
                (c) => ListTile(
                  title: Text(
                    c,
                    style: TextStyle(
                      color: sel == c ? const Color(0xFFCCFF00) : Colors.white,
                    ),
                  ),
                  onTap: () {
                    onSelect(c);
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCoinColor(sel),
            ),
            child: Center(
              child: Text(
                sel[0],
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            sel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF777777), size: 18),
        ],
      ),
    );
  }

  Color _getCoinColor(String coin) {
    switch (coin) {
      case 'USDT':
        return const Color(0xFF26A17B);
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'ETH':
        return const Color(0xFF627EEA);
      case 'BNB':
        return const Color(0xFFF3BA2F);
      default:
        return const Color(0xFF888888);
    }
  }

  Widget _buildCalcPlanCard(
    EarnProduct? plan,
    int? selId,
    Function(int?) onSelect,
  ) {
    if (plan == null) return const Expanded(child: SizedBox.shrink());
    final isSel = selId == plan.id;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(plan.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? const Color(0xFFB8E600) : const Color(0xFF2E2E2E),
              width: 1.5,
            ),
            color: const Color(0xFF1E1E1E),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Easy Earn",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${plan.apr.toStringAsFixed(2)}%",
                    style: const TextStyle(
                      color: Color(0xFF00D68F),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "APR",
                    style: TextStyle(color: Color(0xFF555555), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Easy Earn | ${plan.lockDays == 0 ? "Flexible" : "Fixed"}",
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMainTabs(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedMainTab == 2
                  ? const DualInvestmentScreen()
                  : _selectedMainTab == 1
                  ? _buildEasyEarnContent()
                  : _buildOverviewContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(_mainTabs.length, (index) {
          final isSel = _selectedMainTab == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedMainTab = index);

              if (index == 1 && _selectedEasyTab == 0) {
                _fetchEasyPositions();
              }

              if (index == 1 && _selectedEasyTab == 1) {
                _fetchEasyHistory();
              }
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

              child: Text(
                _mainTabs[index],
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white.withOpacity(0.5),

                  fontSize: 16,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                  height: 24 / 16,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewContent() {
    return Obx(() {
      final products = _controller.products;
      final positions = _controller.positions;
      final isLoggedIn = gUserRx.value.id > 0;
      final totalAssets = positions.fold(0.0, (s, p) => s + p.amount);
      final totalInterest = positions.fold(
        0.0,
        (s, p) => s + p.accruedInterest,
      );

      // Recommended: top 4 by APR
      final recommended = [...products]..sort((a, b) => b.apr.compareTo(a.apr));
      final topRec = recommended.take(4).toList();

      // Products table
      final uniqueCoins = products.map((p) => p.coin).toSet().toList();
      final filteredCoins = uniqueCoins.where((coin) {
        if (_searchCoin.isNotEmpty &&
            !coin.toLowerCase().contains(_searchCoin.toLowerCase()))
          return false;
        if (_filterStatus == "Flexible" &&
            !products.any((p) => p.coin == coin && p.lockDays == 0))
          return false;
        if (_filterStatus == "Fixed" &&
            !products.any((p) => p.coin == coin && p.lockDays > 0))
          return false;
        return true;
      }).toList();

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero / Stats Banner ────────────────────────────────────────
            _buildOverviewHero(
              isLoggedIn,
              totalAssets,
              totalInterest,
              positions.length,
            ),

            const SizedBox(height: 20),

            // ── Recommended ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                "Recommended",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: "DMSans",
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_controller.isLoadingProducts.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFCCFF00)),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: topRec.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final colors = [
                      const Color(0xFFFF6F00),
                      const Color(0xFF00E5FF),
                      const Color(0xFF0062FF),
                      const Color(0xFFCCFF00),
                    ];
                    return _buildRecommendedCard(
                      topRec[index],
                      colors[index % 4],
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // ── Products Table ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Products",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: "DMSans",
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildSearchBarCompact()),
                      const SizedBox(width: 10),
                      _buildFilterDropdownCompact(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Products rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                  ),

                  if (_controller.isLoadingProducts.value)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFCCFF00),
                        ),
                      ),
                    )
                  else if (filteredCoins.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          "No products found",
                          style: TextStyle(color: Color(0xFF555555)),
                        ),
                      ),
                    )
                  else
                    ...filteredCoins.map((coin) {
                      final coinProducts =
                          products.where((p) => p.coin == coin).toList()
                            ..sort((a, b) => a.lockDays.compareTo(b.lockDays));
                      final hasFlex = coinProducts.any((p) => p.lockDays == 0);
                      final hasFixed = coinProducts.any((p) => p.lockDays > 0);
                      final minApr = coinProducts
                          .map((p) => p.apr)
                          .reduce((a, b) => a < b ? a : b);
                      final maxApr = coinProducts
                          .map((p) => p.apr)
                          .reduce((a, b) => a > b ? a : b);
                      final period = hasFlex && hasFixed
                          ? "Flex/Fixed"
                          : hasFlex
                          ? "Flexible"
                          : "Fixed";
                      final iconUrl = coinProducts.first.coinIcon;

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _EasyEarnModal(
                                coin: coin,
                                plans: coinProducts,
                              ),
                            ),
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  // LEFT SIDE
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _coinIcon(iconUrl, size: 34),

                                        const SizedBox(width: 10),

                                        // COIN NAME + FLEX/FIXED
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              coin,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: "DMSans",
                                                height: 24/16
                                              ),
                                            ),

                                            const SizedBox(height: 2),

                                            Text(
                                              "Flex/Fixed",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: "DMSans",
                                                height: 16/12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // APR
                                  Text(
                                    minApr == maxApr
                                        ? '${minApr.toStringAsFixed(2)}%'
                                        : '${minApr.toStringAsFixed(2)}%~${maxApr.toStringAsFixed(2)}%',
                                    style: const TextStyle(
                                      color: Color(0xFFB5F000),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "DMSans",
                                      height: 24/16,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // SUBSCRIBE BUTTON
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFF00),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Subscribe',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "DMSans",
                                        height: 16/12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    SizedBox(height: 20,),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Overview Hero (same card shape as WalletOverviewPage hero) ─────────────
  Widget _buildOverviewHero(
    bool isLoggedIn,
    double totalAssets,
    double totalInterest,
    int posCount,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),

        // FULL BORDER
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -140,
            top: -55,
            child: Transform.rotate(
              angle: -0.4,
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/wallet_green_wave.png',
                  width: 340,
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Assets (USDT)",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  isLoggedIn ? "\$${totalAssets.toStringAsFixed(2)}" : "\$0.00",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                  ),
                ),

                const SizedBox(height: 18),

                // TOP WHITE LINE
                Container(height: 1, color: Colors.white.withOpacity(0.10)),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _heroStat(
                        "Total Interest (USDT)",
                        isLoggedIn ? totalInterest.toStringAsFixed(2) : "0",
                      ),
                    ),

                    // CENTER VERTICAL LINE
                    Container(
                      width: 1,
                      height: 55,
                      color: Colors.white.withOpacity(0.10),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),

                    Expanded(
                      child: _heroStat(
                        "Total Interest (USDT)",
                        isLoggedIn ? totalInterest.toStringAsFixed(2) : "0",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMainTab = 1;
                            _selectedEasyTab = 0;
                          });

                          _fetchEasyPositions();
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFF00),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "View my Earnings",
                            style: TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                              height: 20 / 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: GestureDetector(
                        onTap: _showCalculatorDialog,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.transparent),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Calculator",
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                              height: 20 / 15,
                            ),
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
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: "DMSans",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: "DMSans",
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _heroBtn(
    String label, {
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFCCFF00) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: isPrimary ? null : Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.black : const Color(0xFFCCCCCC),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackGreenWave() {
    return CustomPaint(painter: _GreenWavePainter());
  }

  Widget _buildRecommendedCard(EarnProduct product, Color color) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EasyEarnModal(
          coin: product.coin,
          plans:
              _controller.products.where((p) => p.coin == product.coin).toList()
                ..sort((a, b) => a.lockDays.compareTo(b.lockDays)),
        ),
      ),

      child: Container(
        width: 220,
        height: 110,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          /// 🔥 SAME AS TIER CARD
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.60),
              Colors.transparent,
              color.withOpacity(0.35),
            ],
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(1),

          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
            ),

            clipBehavior: Clip.hardEdge,

            child: Stack(
              children: [
                /// 🔥 SAME INNER EFFECT AS IMAGE
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RecommendedCardPainter(color: color),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// TOP
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(0),
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

                      /// APR
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
                                color: Colors.white, // required
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

  Widget _buildSearchBarCompact() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchCoin = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: "Search Coin",
                hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
            ),
          ),
          const Icon(Icons.search, color: Color(0xFFCCFF00), size: 16),
        ],
      ),
    );
  }

  Widget _buildFilterDropdownCompact() {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: ["All", "Flexible", "Fixed"]
              .map(
                (s) => ListTile(
                  title: Text(
                    s,
                    style: TextStyle(
                      color: _filterStatus == s
                          ? const Color(0xFFCCFF00)
                          : Colors.white,
                    ),
                  ),
                  onTap: () {
                    setState(() => _filterStatus = s);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Status ",
              style: TextStyle(color: Color(0xFF555555), fontSize: 13),
            ),
            Text(
              _filterStatus,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF777777),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EASY EARN TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEasyEarnContent() {
    return Column(
      children: [
        // Easy Earn header button + My Position / History tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB5F000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Easy Earn",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _easyTab("My Position", 0),
                  const SizedBox(width: 24),
                  _easyTab("History", 1),
                  const Spacer(),
                  // Status filter
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF111318),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ["All", "Active", "Redeemed"]
                              .map(
                                (s) => ListTile(
                                  title: Text(
                                    s,
                                    style: TextStyle(
                                      color: _filterStatus == s
                                          ? const Color(0xFFB5F000)
                                          : Colors.white,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() => _filterStatus = s);
                                    Navigator.pop(context);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _filterStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF6B7280),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _selectedEasyTab == 0
              ? _buildEasyPositionsTab()
              : _buildEasyHistoryTab(),
        ),
      ],
    );
  }

  Widget _easyTab(String label, int idx) {
    final isA = _selectedEasyTab == idx;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEasyTab = idx);
        if (idx == 0) _fetchEasyPositions();
        if (idx == 1) _fetchEasyHistory();
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isA ? Colors.white : const Color(0xFF6B7280),
              fontSize: 15,
              fontWeight: isA ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isA)
            Container(width: 24, height: 2, color: const Color(0xFFB5F000)),
        ],
      ),
    );
  }

  // ── My Position ────────────────────────────────────────────────────────────
  Widget _buildEasyPositionsTab() {
    if (_uid.isEmpty)
      return const Center(
        child: Text(
          "Login to view positions",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    if (_isLoadingEasy)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB5F000)),
      );
    if (_easyPositions.isEmpty)
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48),
            SizedBox(height: 12),
            Text(
              "No active positions",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
            Text(
              "Subscribe to a product to start earning",
              style: TextStyle(color: Color(0xFF555555), fontSize: 13),
            ),
          ],
        ),
      );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_redeemError.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF330000)),
            ),
            child: Text(
              _redeemError,
              style: const TextStyle(color: Color(0xFFFF6666), fontSize: 13),
            ),
          ),
        ..._easyPositions.map((pos) {
          final lockDays = (pos['lock_days'] ?? 0).toInt();
          final color = getLockColor(lockDays);
          final canRedeem = pos['is_redeemable'] == true;
          final planType = pos['plan_type'] ?? 'flexible';
          final iconUrl = pos['coin_icon'] as String?;
          final coin = pos['coin'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2128)),
            ),
            child: Row(
              children: [
                // Coin icon
                _coinIcon(
                  iconUrl,
                  size: 40,
                  fallbackColor: color.withOpacity(0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            coin,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on, color: color, size: 10),
                                Text(
                                  planType == 'flexible'
                                      ? "Flexible"
                                      : "${lockDays}d Fixed",
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${double.tryParse(pos['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'} Staked  ·  ${double.tryParse(pos['apr']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'}% APR",
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                      if (planType == 'locked' && !canRedeem) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${pos['days_left']} days remaining",
                          style: TextStyle(color: color, fontSize: 11),
                        ),
                      ],
                      if (planType == 'locked' && canRedeem) ...[
                        const SizedBox(height: 2),
                        const Text(
                          "Ready to redeem",
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Earned",
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "+${double.tryParse(pos['accrued_interest']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'} $coin",
                      style: const TextStyle(
                        color: Color(0xFFCCFF00),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: canRedeem
                          ? () => _handleRedeem(pos['id'].toString())
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // Redeem button: orange-red gradient when redeemable (matches image)
                          gradient: canRedeem
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFFF3300),
                                  ],
                                )
                              : null,
                          color: canRedeem ? null : const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Redeem",
                          style: TextStyle(
                            color: canRedeem
                                ? Colors.white
                                : const Color(0xFF444444),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ── History ────────────────────────────────────────────────────────────────
  Widget _buildEasyHistoryTab() {
    if (_uid.isEmpty)
      return const Center(
        child: Text(
          "Login to view history",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    if (_isLoadingEasy)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB5F000)),
      );
    if (_historyError.isNotEmpty)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6666), size: 48),
            const SizedBox(height: 12),
            Text(
              _historyError,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEasyHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5F000),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    if (_easyHistory.isEmpty)
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Color(0xFF6B7280), size: 48),
            SizedBox(height: 12),
            Text(
              "No transactions yet",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
          ],
        ),
      );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  'Type',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Coin',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Amount',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Time',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1E2128), height: 1),
        ..._easyHistory.map((tx) {
          final type = tx['type']?.toString().toLowerCase() ?? 'subscribe';
          final coin = tx['coin'] ?? 'USDT';
          final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
          final iconUrl = tx['coin_icon'] as String?;
          String timeStr = 'Unknown';
          if (tx['created_at'] != null) {
            try {
              final dt = DateTime.parse(tx['created_at'].toString()).toLocal();
              timeStr =
                  "${dt.month}/${dt.day}/${dt.year}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
            } catch (_) {
              timeStr = tx['created_at'].toString();
            }
          }
          final isSubscribe = type == 'subscribe';
          // Per image: Subscribe = yellow-green pill, Redeem = teal pill
          final pillColor = isSubscribe
              ? const Color(0xFFB5F000)
              : const Color(0xFF00CCAA);
          final pillTextColor = Colors.black;
          final amtColor = isSubscribe
              ? const Color(0xFFFF5555)
              : const Color(0xFF00FF88);
          final amtPrefix = isSubscribe ? '-' : '+';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type == 'subscribe' ? 'Subscribe' : 'Redeem',
                          style: TextStyle(
                            color: pillTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          _coinIcon(iconUrl, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              coin,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "$amtPrefix${amount.toStringAsFixed(7).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} $coin",
                        style: TextStyle(
                          color: amtColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF1E2128)),
            ],
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Fallback wave painter ────────────────────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════════════════════
// EASY EARN SUBSCRIBE MODAL  (matches Image 6 & 7)
// ══════════════════════════════════════════════════════════════════════════════
class _EasyEarnModal extends StatefulWidget {
  final String coin;
  final List<EarnProduct> plans;
  const _EasyEarnModal({required this.coin, required this.plans});

  @override
  State<_EasyEarnModal> createState() => _EasyEarnModalState();
}

class _EasyEarnModalState extends State<_EasyEarnModal> {
  late EarnProduct _selectedPlan;
  final _amountCtrl = TextEditingController();
  bool _agreed = false;
  bool _autoSub = false; // "Auto Subscribe" toggle (Image 7)
  bool _loading = false;
  String _error = "";
  String _success = "";

  String get _uid => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.plans.isNotEmpty
        ? widget.plans.first
        : EarnProduct(
            id: 0,
            coin: '',
            apr: 0,
            lockDays: 0,
            minAmount: 0,
            maxAmount: 0,
          );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amountNum => double.tryParse(_amountCtrl.text) ?? 0;
  double get _dailyProfit =>
      _amountNum > 0 ? (_amountNum * _selectedPlan.apr) / 100 / 365 : 0;
  double? get _totalProfit => _amountNum > 0 && _selectedPlan.lockDays > 0
      ? _dailyProfit * _selectedPlan.lockDays
      : null;

  // timeline dates (subscription → interest → payout → maturity)
  String _dateStr(int addDays) {
    final d = DateTime.now().add(Duration(days: addDays));
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  void _handleConfirm() async {
    if (_amountNum <= 0 || !_agreed || _uid.isEmpty) return;
    setState(() {
      _loading = true;
      _error = "";
      _success = "";
    });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/tf/earn/subscribe?user_id=$_uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "product_id": _selectedPlan.id,
          "amount": _amountCtrl.text,
          "auto_reinvest": _selectedPlan.lockDays > 0 ? _autoSub : false,
        }),
      );
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        setState(() => _success = "Subscribed successfully!");
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _error = json['message'] ?? "Failed");
      }
    } catch (_) {
      setState(() => _error = "Subscription failed");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFlexible = _selectedPlan.lockDays == 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                _coinIcon(_selectedPlan.coinIcon, size: 28),
                const SizedBox(width: 10),
                Text(
                  "${widget.coin} Subscribe",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF555555),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Plan selector tabs (Flexible / 30 day's / 60 day's …) ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.plans.map((p) {
                  final isA = _selectedPlan.id == p.id;
                  final label = p.lockDays == 0
                      ? "Flexible"
                      : "${p.lockDays} day's";
                  final sub = p.lockDays == 0
                      ? "${p.apr.toStringAsFixed(2)}% Max"
                      : "${p.apr.toStringAsFixed(2)}% Max";
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedPlan = p;
                      _autoSub = false;
                      _error = "";
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isA
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isA
                              ? const Color(0xFFB5F000)
                              : const Color(0xFF222222),
                          width: isA ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: isA
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub,
                            style: TextStyle(
                              color: isA
                                  ? const Color(0xFFB5F000)
                                  : const Color(0xFF555555),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Amount input ──
            const Text(
              "Amount",
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText:
                            "${coinFormat(_selectedPlan.minAmount)} Minimum",
                        hintStyle: const TextStyle(color: Color(0xFF555555)),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF333333)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Max",
                      style: TextStyle(
                        color: Color(0xFFB5F000),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      widget.coin,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Maximum  ${coinFormat(_selectedPlan.maxAmount)}",
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 11,
                  ),
                ),
                const Text(
                  "Balance  0.00",
                  style: TextStyle(color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Profit estimate box ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isFlexible
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Est. Daily Total Profit",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "${_dailyProfit.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '')} ${widget.coin}",
                              style: const TextStyle(
                                color: Color(0xFFB5F000),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1A1A1A), height: 16),
                        const Text(
                          "Hourly interest rate, access at any time",
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _timelineRow("Subscription Time", _dateStr(0)),
                        _timelineRow("Interest Start Time", _dateStr(0)),
                        _timelineRow("Interest Payout Time", _dateStr(0)),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Est. Total Profit",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            const Text(
                              "--",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Est. APR",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "${_selectedPlan.apr.toStringAsFixed(2)}%",
                              style: const TextStyle(
                                color: Color(0xFFB5F000),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1A1A1A), height: 16),
                        _timelineRow("Subscription Time", _dateStr(0)),
                        _timelineRow("Interest Start Time", _dateStr(1)),
                        _timelineRow("Interest Payout Time", _dateStr(1)),
                        _timelineRow(
                          "Maturity Time",
                          _dateStr(_selectedPlan.lockDays),
                        ),
                        _timelineRow(
                          "Fund Arrival Time",
                          _dateStr(_selectedPlan.lockDays),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // ── Auto Subscribe toggle (only for fixed, matches Image 7) ──
            if (!isFlexible)
              GestureDetector(
                onTap: () => setState(() => _autoSub = !_autoSub),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _autoSub
                          ? const Color(0xFFB5F000)
                          : const Color(0xFF1E1E1E),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Auto Subscribe",
                          style: TextStyle(
                            color: _autoSub
                                ? const Color(0xFFB5F000)
                                : const Color(0xFFAAAAAA),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // iOS-style toggle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _autoSub
                              ? const Color(0xFFB5F000)
                              : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _autoSub
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _autoSub
                                    ? Colors.black
                                    : const Color(0xFF555555),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Agreement ──
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _agreed
                            ? const Color(0xFFB5F000)
                            : const Color(0xFF444444),
                        width: 2,
                      ),
                      color: _agreed
                          ? const Color(0xFFB5F000)
                          : Colors.transparent,
                    ),
                    child: _agreed
                        ? const Icon(Icons.check, size: 12, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "I have read and agree to "),
                          TextSpan(
                            text: "Trapix Earn User Agreement",
                            style: const TextStyle(color: Color(0xFFB5F000)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error,
                  style: const TextStyle(
                    color: Color(0xFFFF6666),
                    fontSize: 13,
                  ),
                ),
              ),
            if (_success.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF001A00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _success,
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 13,
                  ),
                ),
              ),

            // ── Preview Order button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_loading || _amountNum <= 0 || !_agreed)
                    ? null
                    : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_loading || _amountNum <= 0 || !_agreed)
                      ? const Color(0xFF222222)
                      : const Color(0xFF1A1A1A),
                  disabledBackgroundColor: const Color(0xFF222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  side: BorderSide(
                    color: (_loading || _amountNum <= 0 || !_agreed)
                        ? const Color(0xFF333333)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _loading ? "Processing..." : "Preview Order",
                  style: TextStyle(
                    color: (_loading || _amountNum <= 0 || !_agreed)
                        ? const Color(0xFF555555)
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCardPainter extends CustomPainter {
  final Color color;

  _RecommendedCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    /// 🔥 Bottom Glow
    final rect = Rect.fromLTWH(
      -20,
      size.height * 0.55,
      size.width + 40,
      size.height,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.95),
          const Color(0xFFFFB781).withOpacity(0.55),
          const Color(0xFFFFE6D2).withOpacity(0.20),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);

    final path = Path();

    path.moveTo(0, size.height * 0.72);

    path.cubicTo(
      size.width * 0.15,
      size.height * 0.92,
      size.width * 0.75,
      size.height * 0.30,
      size.width,
      size.height * 0.95,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    /// 🔥 Top inner shadow
    final topPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);

    canvas.drawCircle(Offset(size.width / 2, -45), 70, topPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
