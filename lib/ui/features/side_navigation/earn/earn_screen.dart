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

// ─── Coin icon helper ─────────────────────────────────────────────────────────
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
  final Set<String> _expandedCoins = {};
  bool _isLoadingEasy = false;
  List<dynamic> _easyPositions = [];
  List<dynamic> _easyHistory = [];
  String _redeemError = "";
  String _historyError = "";

  bool _showEasyEarnHome = true;

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

  // ── Navigate to Easy Earn > History ──────────────────────────────────────
  // Called from Dual Investment hero "View my History" button
  void _goToEasyEarnHistory() {
    setState(() {
      _selectedMainTab = 1; // Easy Earn tab
      _showEasyEarnHome = false; // skip home, show list screen
      _selectedEasyTab = 1; // History sub-tab
    });
    _fetchEasyHistory();
  }

  // ── Calculator dialog ─────────────────────────────────────────────────────
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

  // ── BUILD ─────────────────────────────────────────────────────────────────
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
                  ? _buildDualInvestmentWithHero() // ← Dual tab
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
    return SizedBox(
      height: 35,
      child: Row(
        children: List.generate(_mainTabs.length, (index) {
          final isSel = _selectedMainTab == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMainTab = index;
                if (index == 1) _showEasyEarnHome = true;
              });
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
  // SHARED HERO
  //
  // Parameters:
  //   showCalculator — show the dark "Calculator" button (Overview only)
  //   primaryLabel   — label for the lime-green button
  //   onPrimaryTap   — callback; defaults to "View my Earnings" navigation
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewHero({
    required bool isLoggedIn,
    required double totalAssets,
    required double totalInterest,
    required int posCount,
    bool showCalculator = true,
    String primaryLabel = "View my Earnings",
    VoidCallback? onPrimaryTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Green wave background (same asset as wallet hero)
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
                    isLoggedIn
                        ? "\$${totalAssets.toStringAsFixed(2)}"
                        : "\$0.00",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      fontFamily: "DMSans",
                    ),
                  ),
                  const SizedBox(height: 18),
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

                  // ── Buttons row ──────────────────────────────────────────
                  Row(
                    children: [
                      // Primary (lime-green) button — always present
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              onPrimaryTap ??
                              () {
                                setState(() {
                                  _selectedMainTab = 1;
                                  _showEasyEarnHome = false;
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
                            child: Text(
                              primaryLabel,
                              style: const TextStyle(
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

                      // Second slot always present — keeps primary button at consistent width
                      const SizedBox(width: 14),
                      Expanded(
                        child: showCalculator
                            ? GestureDetector(
                                onTap: _showCalculatorDialog,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Calculator",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "DMSans",
                                      height: 20 / 15,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  // ══════════════════════════════════════════════════════════════════════════
  // Shared: Products list
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProductsSection(List<EarnProduct> products) {
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

    return Padding(
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
          const SizedBox(height: 16),
          if (_controller.isLoadingProducts.value)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFCCFF00)),
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
              final minApr = coinProducts
                  .map((p) => p.apr)
                  .reduce((a, b) => a < b ? a : b);
              final maxApr = coinProducts
                  .map((p) => p.apr)
                  .reduce((a, b) => a > b ? a : b);
              final iconUrl = coinProducts.first.coinIcon;
              final isExpanded = _expandedCoins.contains(coin);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Coin header row (tap to toggle) ──
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded)
                        _expandedCoins.remove(coin);
                      else
                        _expandedCoins.add(coin);
                    }),
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          _coinIcon(iconUrl, size: 34),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coin,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 24 / 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Flexible | Fixed",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    height: 16 / 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            minApr == maxApr
                                ? '${minApr.toStringAsFixed(2)}%'
                                : '${minApr.toStringAsFixed(2)}%=${maxApr.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: "DMSans",
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withOpacity(0.5),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Expanded product rows ──
                  if (isExpanded)
                    ...coinProducts.map((plan) {
                      final lockLabel = plan.lockDays == 0
                          ? 'Flexible'
                          : '${plan.lockDays} Days';
                      return GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _EasyEarnModal(
                            coin: coin,
                            plans: coinProducts,
                            initialPlan: plan,
                          ),
                        ),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              /// LEFT SIDE
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "Easy Earn ",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: "DMSans",
                                              height: 24 / 16,
                                            ),
                                          ),

                                          TextSpan(
                                            text: lockLabel, // Flexible / Fixed
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: "DMSans",
                                              height: 24 / 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// MAX + VALUE
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Max ",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "DMSans",
                                        height: 16 / 12,
                                      ),
                                    ),

                                    TextSpan(
                                      text: "${plan.apr.toStringAsFixed(2)}%",
                                      style: const TextStyle(
                                        color: Color(0xFF4ED78E),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: "DMSans",
                                        height: 24 / 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 5),

                              /// BUTTON
                              GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _EasyEarnModal(
                                    coin: coin,
                                    plans: coinProducts,
                                    initialPlan: plan,
                                  ),
                                ),
                                child: Container(
                                  width: 89,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFF00),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Suscribe',
                                    style: TextStyle(
                                      color: Color(0xFF000000),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "DMSans",
                                      height: 16 / 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared: Recommended horizontal scroll
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRecommendedSection(List<EarnProduct> products) {
    final topRec = ([
      ...products,
    ]..sort((a, b) => b.apr.compareTo(a.apr))).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Recommended",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: "DMSans",
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
              itemBuilder: (context, i) {
                final colors = [
                  const Color(0xFFFF6F00),
                  const Color(0xFF00E5FF),
                  const Color(0xFF0062FF),
                  const Color(0xFFCCFF00),
                ];
                return _buildRecommendedCard(topRec[i], colors[i % 4]);
              },
            ),
          ),
      ],
    );
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
  // OVERVIEW TAB  — hero with Calculator
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

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewHero(
              isLoggedIn: isLoggedIn,
              totalAssets: totalAssets,
              totalInterest: totalInterest,
              posCount: positions.length,
              showCalculator: true, // ← Calculator shown
              primaryLabel: "View my Earnings",
              onPrimaryTap: () {
                setState(() {
                  _selectedMainTab = 1;
                  _showEasyEarnHome = false;
                  _selectedEasyTab = 0;
                });
                _fetchEasyPositions();
              },
            ),
            const SizedBox(height: 20),
            _buildRecommendedSection(products),
            const SizedBox(height: 20),
            _buildProductsSection(products),
          ],
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DUAL INVESTMENT TAB — hero WITHOUT Calculator, "View my History" → Easy Earn History
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDualInvestmentWithHero() {
    return Obx(() {
      final positions = _controller.positions;
      final isLoggedIn = gUserRx.value.id > 0;
      final totalAssets = positions.fold(0.0, (s, p) => s + p.amount);
      final totalInterest = positions.fold(
        0.0,
        (s, p) => s + p.accruedInterest,
      );

      return SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: _buildOverviewHero(
                isLoggedIn: isLoggedIn,
                totalAssets: totalAssets,
                totalInterest: totalInterest,
                posCount: positions.length,
                showCalculator: false,
                primaryLabel: "View my History",
                onPrimaryTap: _goToEasyEarnHistory,
              ),
            ),
            const SizedBox(height: 8),
            const DualInvestmentScreen(),
          ],
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EASY EARN TAB — hero WITHOUT Calculator
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEasyEarnContent() {
    if (_showEasyEarnHome) {
      return Obx(() {
        final products = _controller.products;
        final positions = _controller.positions;
        final isLoggedIn = gUserRx.value.id > 0;
        final totalAssets = positions.fold(0.0, (s, p) => s + p.amount);
        final totalInterest = positions.fold(
          0.0,
          (s, p) => s + p.accruedInterest,
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewHero(
                isLoggedIn: isLoggedIn,
                totalAssets: totalAssets,
                totalInterest: totalInterest,
                posCount: positions.length,
                showCalculator: false, // ← no Calculator
                primaryLabel: "View my Earnings",
                onPrimaryTap: () {
                  setState(() {
                    _showEasyEarnHome = false;
                    _selectedEasyTab = 0;
                  });
                  _fetchEasyPositions();
                },
              ),
              const SizedBox(height: 20),
              _buildProductsSection(products),
            ],
          ),
        );
      });
    }

    // Position / History list screen
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _showEasyEarnHome = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Easy Earn",
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 20 / 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _easyTab("My Position", 0),
                  const SizedBox(width: 24),
                  _easyTab("History", 1),
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
              color: isA ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: isA ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Returns coin icon URL from API response, falling back to products list
  String? _resolveIconUrl(String coin, String? directIconUrl) {
    if (directIconUrl != null && directIconUrl.isNotEmpty) return directIconUrl;
    try {
      return _controller.products.firstWhere((p) => p.coin == coin).coinIcon;
    } catch (_) {
      return null;
    }
  }

  // ── My Position ───────────────────────────────────────────────────────────
  Widget _buildEasyPositionsTab() {
    if (_uid.isEmpty) {
      return const Center(
        child: Text(
          "Login to view positions",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    if (_isLoadingEasy) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB5F000)),
      );
    }

    if (_easyPositions.isEmpty) {
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

            SizedBox(height: 4),

            Text(
              "Subscribe to a product to start earning",
              style: TextStyle(color: Color(0xFF555555), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

          final coin = pos['coin'] ?? '';

          final iconUrl = _resolveIconUrl(coin, pos['coin_icon'] as String?);

          return Container(
            margin: const EdgeInsets.only(bottom: 20, top: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// LEFT SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TOP ROW
                      Row(
                        children: [
                          _coinIcon(
                            iconUrl,
                            size: 20,
                            fallbackColor: color.withOpacity(0.2),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            coin,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: "DMSans",
                              height: 1,
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// FLEXIBLE TAG
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),

                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withOpacity(0.95),
                                  const Color(0xFF111111),
                                ],
                              ),
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 12,
                                ),

                                const SizedBox(width: 2),

                                Text(
                                  planType == 'flexible'
                                      ? "Flexible"
                                      : "${lockDays}d Fixed",
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
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// STAKED + APR
                      Row(
                        children: [
                          Text(
                            "${double.tryParse(pos['amount']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'} Staked",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                              height: 1,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            "${double.tryParse(pos['apr']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'}% APR",
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
                    ],
                  ),
                ),

                

                /// RIGHT SIDE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    /// EARNED
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Earned",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: "DMSans",
                            height: 1,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "+${double.tryParse(pos['accrued_interest']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'} USDT",
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: "DMSans",
                            height: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 5),

                    /// REDEEM BUTTON
                    GestureDetector(
                      onTap: canRedeem
                          ? () => _handleRedeem(pos['id'].toString())
                          : null,
                      child: Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          height: 46,
                          width: 75,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),

                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withOpacity(0.95),
                                const Color(0xFF111111),
                              ],
                            ),
                          ),

                          child: Text(
                            "Redeem",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: "DMSans",
                              height: 1,
                            ),
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

  // ── History ───────────────────────────────────────────────────────────────
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
          final iconUrl = _resolveIconUrl(coin, tx['coin_icon'] as String?);
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
          final pillColor = isSubscribe
              ? const Color(0xFFB5F000)
              : const Color(0xFF00CCAA);
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
                          style: const TextStyle(
                            color: Colors.black,
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

// ─── Painters ────────────────────────────────────────────────────────────────
class _RecommendedCardPainter extends CustomPainter {
  final Color color;
  _RecommendedCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
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

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.92,
        size.width * 0.75,
        size.height * 0.30,
        size.width,
        size.height * 0.95,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width / 2, -45),
      70,
      Paint()
        ..color = color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// EASY EARN SUBSCRIBE MODAL
// ══════════════════════════════════════════════════════════════════════════════
class _EasyEarnModal extends StatefulWidget {
  final String coin;
  final List<EarnProduct> plans;
  final EarnProduct? initialPlan;
  const _EasyEarnModal({
    required this.coin,
    required this.plans,
    this.initialPlan,
  });

  @override
  State<_EasyEarnModal> createState() => _EasyEarnModalState();
}

class _EasyEarnModalState extends State<_EasyEarnModal> {
  late EarnProduct _selectedPlan;
  final _amountCtrl = TextEditingController();
  bool _agreed = false;
  bool _autoSub = false;
  bool _loading = false;
  String _error = "";
  String _success = "";

  String get _uid => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';

  @override
  void initState() {
    super.initState();
    _selectedPlan =
        widget.initialPlan ??
        (widget.plans.isNotEmpty
            ? widget.plans.first
            : EarnProduct(
                id: 0,
                coin: '',
                apr: 0,
                lockDays: 0,
                minAmount: 0,
                maxAmount: 0,
              ));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amountNum => double.tryParse(_amountCtrl.text) ?? 0;
  double get _dailyProfit =>
      _amountNum > 0 ? (_amountNum * _selectedPlan.apr) / 100 / 365 : 0;

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
            // Header
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

            // Plan selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.plans.map((p) {
                  final isA = _selectedPlan.id == p.id;
                  final label = p.lockDays == 0
                      ? "Flexible"
                      : "${p.lockDays} day's";
                  final sub = "${p.apr.toStringAsFixed(2)}% Max";
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

            // Amount
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

            // Profit estimate
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

            // Auto Subscribe toggle
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

            // Agreement
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
                        children: const [
                          TextSpan(text: "I have read and agree to "),
                          TextSpan(
                            text: "Trapix Earn User Agreement",
                            style: TextStyle(color: Color(0xFFB5F000)),
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

            // Preview Order button
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
