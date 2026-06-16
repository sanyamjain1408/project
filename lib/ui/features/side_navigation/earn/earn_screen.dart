import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'earn_controller.dart';
import 'dual_investment_controller.dart';
import 'dual_investment_screen.dart';
import 'dual_subscribe_modal.dart';
import 'calc_plan_card.dart';
import 'mc_staking_screen.dart';
import 'mc_staking_controller.dart' show McStakingController; // ignore: unused_import
import 'mc_my_stakes_screen.dart';
import 'mc_withdraw_history_screen.dart';
import 'earn_history_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_widgets.dart' show RotatingIcon;

const String _baseUrl = 'https://api.trapix.com';

Color getLockColor(int days) {
  switch (days) {
    case 0:
      return const Color(0xFF0062FF);
    case 30:
      return const Color(0xFF00E5FF);
    case 60:
      return const Color(0xFFCCFF00);
    case 90:
      return const Color(0xFFFF6F00);
    case 120:
      return const Color(0xFFFF4488);
    default:
      return const Color(0xFFCCFF00);
  }
}

// â”€â”€â”€ Coin icon helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  final int initialTab;
  const EarnScreen({super.key, this.initialTab = 0});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final _controller = Get.put(EarnController());
  late DualInvestmentController _dualController;

  late int _selectedMainTab;
  int _selectedEasyTab = 0; // 0=Position, 1=History
  final List<String> _mainTabs = ["Overview", "Easy Earn", "Dual Investment", "Staking"];

  String _searchCoin = "";
  String _filterStatus = "All";
  String _positionStatusFilter = "All";
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
    _selectedMainTab = widget.initialTab;
    _dualController = Get.isRegistered<DualInvestmentController>()
        ? Get.find<DualInvestmentController>()
        : Get.put(DualInvestmentController());
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

  // â”€â”€ Navigate to Easy Earn > History â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Called from Dual Investment hero "View my History" button
  void _goToEasyEarnHistory() {
    setState(() {
      _selectedMainTab = 1; // Easy Earn tab
      _showEasyEarnHome = false; // skip home, show list screen
      _selectedEasyTab = 1; // History sub-tab
    });
    _fetchEasyHistory();
  }

  // â”€â”€ Calculator dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                              CalcPlanCard(
                                plan: flexPlan,
                                selectedId: selectedPlanId,
                                onSelect: (id) {
                                  selectedPlanId = id;
                                  setStateDialog(() {});
                                },
                              ),
                              const SizedBox(width: 10),
                              CalcPlanCard(
                                plan: fixedPlan,
                                selectedId: selectedPlanId,
                                onSelect: (id) {
                                  selectedPlanId = id;
                                  setStateDialog(() {});
                                },
                              ),
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

  // â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _selectedMainTab == 3
                  ? _buildStakingWithHero()
                  : _selectedMainTab == 2
                  ? _buildDualInvestmentWithHero() // â† Dual tab
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
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(_mainTabs.length, (index) {
            final isSel = _selectedMainTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainTab = index;
                  if (index == 1) _showEasyEarnHome = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Center(
                  child: Text(
                    _mainTabs[index],
                    style: TextStyle(
                      color: isSel ? Colors.white : Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabIndicatorStrip() {
    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(left: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(_mainTabs.length, (index) {
            final isSel = _selectedMainTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainTab = index;
                  if (index == 1) _showEasyEarnHome = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Center(
                  child: Text(
                    _mainTabs[index],
                    style: TextStyle(
                      color: isSel ? Colors.white : Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SHARED HERO
  //
  // Parameters:
  //   showCalculator â€” show the dark "Calculator" button (Overview only)
  //   primaryLabel   â€” label for the lime-green button
  //   onPrimaryTap   â€” callback; defaults to "View my Earnings" navigation
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildOverviewHero({
    required bool isLoggedIn,
    required double totalAssets,
    required double totalInterest,
    double todayProfit = 0,
    required int posCount,
    bool showCalculator = true,
    String primaryLabel = "View my Earnings",
    VoidCallback? onPrimaryTap,
    String? secondaryLabel,
    VoidCallback? onSecondaryTap,
    String tabLabel = "Overview",
    VoidCallback? onHistoryTap,
  }) {
    return _EarnHeroShell(
      onHistoryTap: onHistoryTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top group
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab label — green
                Text(
                  tabLabel,
                  style: const TextStyle(
                    color: Color(0xFFCCFF00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Total Assets (USDT)",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isLoggedIn ? "\$${totalAssets.toStringAsFixed(2)}" : "\$0.00",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: _heroStat(
                        "Cumulative Profit (USDT)",
                        isLoggedIn ? totalInterest.toStringAsFixed(2) : "0",
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withOpacity(0.10),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _heroStat(
                        "Today's Profit (USDT)",
                        isLoggedIn ? todayProfit.toStringAsFixed(2) : "0",
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Buttons row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPrimaryTap ?? () {
                      setState(() {
                        _selectedMainTab = 1;
                        _showEasyEarnHome = false;
                        _selectedEasyTab = 0;
                      });
                      _fetchEasyPositions();
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFF00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: "DMSans",
                        ),
                      ),
                    ),
                  ),
                ),
                if (showCalculator || secondaryLabel != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: showCalculator ? _showCalculatorDialog : onSecondaryTap,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          showCalculator ? "Calculator" : secondaryLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontFamily: "DMSans",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: "DMSans",
            height: 1,
          ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Shared: Products list
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
              final dualProducts = _dualController.allProducts
                  .where(
                    (dp) => dp.baseCoin.toUpperCase() == coin.toUpperCase(),
                  )
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // â”€â”€ Coin header row (tap to toggle) â”€â”€
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
                              minApr == maxApr
                                  ? '${minApr.toStringAsFixed(2)}%'
                                  : '${minApr.toStringAsFixed(2)}%â€“${maxApr.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: "DMSans",
                                height: 24 / 16,
                              ),
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

                  // â”€â”€ Expanded product rows â”€â”€
                  if (isExpanded) ...[
                    ...coinProducts.map((plan) {
                      final lockLabel = plan.lockDays == 0
                          ? 'Flexible'
                          : '${plan.lockDays} Days';
                      return GestureDetector(
                        onTap: () => Get.to(
                          () => Scaffold(
                            backgroundColor: const Color(0xFF0F0F0F),
                            body: SafeArea(
                              child: EasyEarnModal(
                                coin: coin,
                                plans: coinProducts,
                                initialPlan: plan,
                              ),
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// EASY EARN + LOCK LABEL
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
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    /// BELOW TEXT
                                    Text(
                                      lockLabel,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: "DMSans",
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                              GestureDetector(
                                onTap: () => Get.to(
                                  () => Scaffold(
                                    backgroundColor: const Color(0xFF0F0F0F),
                                    body: SafeArea(
                                      child: EasyEarnModal(
                                        coin: coin,
                                        plans: coinProducts,
                                        initialPlan: plan,
                                      ),
                                    ),
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
                    ...dualProducts.map((dp) {
                      final lockLabel = dp.termDays == 0
                          ? 'Flexible'
                          : '${dp.termDays} Days';
                      return GestureDetector(
                        onTap: () => Get.to(
                          () => Scaffold(
                            backgroundColor: const Color(0xFF0F0F0F),
                            body: SafeArea(
                              child: DualSubscribeModal(
                                product: dp,
                                controller: _dualController,
                              ),
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// TITLE + LABEL
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "Dual Investment ",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: "DMSans",
                                              height: 24 / 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    /// BELOW LABEL
                                    Text(
                                      lockLabel,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: "DMSans",
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                      text: "${dp.apr.toStringAsFixed(2)}%",
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
                              GestureDetector(
                                onTap: () => Get.to(
                                  () => Scaffold(
                                    backgroundColor: const Color(0xFF0F0F0F),
                                    body: SafeArea(
                                      child: DualSubscribeModal(
                                        product: dp,
                                        controller: _dualController,
                                      ),
                                    ),
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
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Shared: Recommended horizontal scroll
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildRecommendedSection(List<EarnProduct> products) {
    // One card per unique coin â€” pick the highest APR product for each coin
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
            height: 120,
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
      onTap: () => Get.to(
        () => Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: SafeArea(
            child: EasyEarnModal(
              coin: product.coin,
              plans:
                  _controller.products
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // OVERVIEW TAB  â€” hero with Calculator
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
              showCalculator: true, // â† Calculator shown
              primaryLabel: "View my Earnings",
              tabLabel: "Overview",
              onHistoryTap: () {
                setState(() {
                  _selectedMainTab = 1;
                  _showEasyEarnHome = false;
                  _selectedEasyTab = 1;
                });
                _fetchEasyHistory();
              },
              onPrimaryTap: () {
                setState(() {
                  _selectedMainTab = 1;
                  _showEasyEarnHome = false;
                  _selectedEasyTab = 0;
                });
                _fetchEasyPositions();
              },
            ),
            const SizedBox(height: 16),
            _buildTabIndicatorStrip(),
            const SizedBox(height: 20),
            _buildRecommendedSection(products),
            const SizedBox(height: 20),
            _buildProductsSection(products),
          ],
        ),
      );
    });
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DUAL INVESTMENT TAB â€” hero WITHOUT Calculator, "View my History" â†’ Easy Earn History
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
            _buildOverviewHero(
              isLoggedIn: isLoggedIn,
              totalAssets: totalAssets,
              totalInterest: totalInterest,
              posCount: positions.length,
              showCalculator: true,
              primaryLabel: "View my Earnings",
              tabLabel: "Dual Investment",
              onHistoryTap: () {
                setState(() {
                  _selectedMainTab = 1;
                  _showEasyEarnHome = false;
                  _selectedEasyTab = 1;
                });
                _fetchEasyHistory();
              },
            ),
            const SizedBox(height: 16),
            _buildTabIndicatorStrip(),
            const SizedBox(height: 8),
            const DualInvestmentScreen(),
          ],
        ),
      );
    });
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // STAKING TAB â€” live earning hero + coin list
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildStakingWithHero() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StakingLiveHero(),
          const SizedBox(height: 16),
          _buildTabIndicatorStrip(),
          const SizedBox(height: 16),
          const McStakingScreen(),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // EASY EARN TAB â€” hero WITHOUT Calculator
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
                showCalculator: true, // â† no Calculator
                primaryLabel: "View my Earnings",
                tabLabel: "Easy Earn",
                onHistoryTap: () {
                  setState(() {
                    _showEasyEarnHome = false;
                    _selectedEasyTab = 1;
                  });
                  _fetchEasyHistory();
                },
                onPrimaryTap: () {
                  setState(() {
                    _showEasyEarnHome = false;
                    _selectedEasyTab = 0;
                  });
                  _fetchEasyPositions();
                },
              ),
              const SizedBox(height: 16),
              _buildTabIndicatorStrip(),
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
                  const Spacer(),
                  if (_selectedEasyTab == 0) _buildPositionStatusDropdown(),
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

  Widget _buildPositionStatusDropdown() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...["All", "Flexible", "Lock Days"].map((opt) {
                  final isSel = _positionStatusFilter == opt;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _positionStatusFilter = opt);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.07),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt,
                            style: TextStyle(
                              color: isSel
                                  ? const Color(0xFFD4F000)
                                  : Colors.white,
                              fontSize: 14,
                              fontFamily: "DMSans",
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isSel)
                            const Icon(
                              Icons.check,
                              color: Color(0xFFD4F000),
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// FIXED STATUS TEXT
            Text(
              "Status",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),

            const SizedBox(width: 10),

            /// ONLY THIS VALUE CHANGES
            Text(
              _positionStatusFilter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),

            const SizedBox(width: 5),

            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
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

  // â”€â”€ My Position â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    final filteredPositions = _easyPositions.where((pos) {
      final planType = (pos['plan_type'] ?? 'flexible')
          .toString()
          .toLowerCase();
      if (_positionStatusFilter == "Flexible") return planType == 'flexible';
      if (_positionStatusFilter == "Lock Days") return planType != 'flexible';
      return true;
    }).toList();

    if (filteredPositions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48),
            SizedBox(height: 12),
            Text(
              "No positions found",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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

        ...filteredPositions.map((pos) {
          final lockDays = (pos['lock_days'] ?? 0).toInt();

          final color = getLockColor(lockDays);

          final canRedeem = pos['is_redeemable'] == true;

          final planType = pos['plan_type'] ?? 'flexible';

          final coin = pos['coin'] ?? '';

          final iconUrl = _resolveIconUrl(coin, pos['coin_icon'] as String?);

          // Parse unlock date for fixed plans
          DateTime? endDate;
          int daysRemaining = 0;
          String unlockDateLabel = '';
          if (lockDays > 0) {
            final endRaw =
                pos['end_date'] ??
                pos['maturity_date'] ??
                pos['unlock_date'] ??
                pos['lock_end_date'];
            if (endRaw != null) {
              try {
                endDate = DateTime.parse(endRaw.toString()).toLocal();
              } catch (_) {}
            }
            if (endDate == null) {
              final startRaw =
                  pos['start_date'] ??
                  pos['created_at'] ??
                  pos['subscribed_at'];
              if (startRaw != null) {
                try {
                  endDate = DateTime.parse(
                    startRaw.toString(),
                  ).toLocal().add(Duration(days: lockDays));
                } catch (_) {}
              }
            }
            if (endDate != null) {
              daysRemaining = endDate
                  .difference(DateTime.now())
                  .inDays
                  .clamp(0, 9999);
              unlockDateLabel =
                  "${endDate.month}/${endDate.day}/${endDate.year}";
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 20, top: 20),
            decoration: BoxDecoration(color: Colors.transparent),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                                  horizontal: 5,
                                  vertical: 5,
                                ),

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withOpacity(0.5),
                                  ),

                                  /// FULL BUTTON COLOR EFFECT
                                  gradient: RadialGradient(
                                    center: Alignment.topCenter,
                                    radius: 3.5,
                                    colors: [
                                      Colors.transparent,
                                      color.withOpacity(0.35), // top strong
                                      color.withOpacity(0.70), // middle
                                      color.withOpacity(0.95), // fade
                                      color,
                                    ],
                                    stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                                  ),
                                ),

                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      planType == 'flexible'
                                          ? Icons.bolt
                                          : Icons.lock,
                                      color: planType == 'flexible'
                                          ? Colors.amber
                                          : Colors.amber,
                                      size: 10,
                                    ),

                                    const SizedBox(width: 2),

                                    Text(
                                      planType == 'flexible'
                                          ? "Flexible"
                                          : "${lockDays}d",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
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

                            const SizedBox(height: 8),

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
                        if (canRedeem)
                          GestureDetector(
                            onTap: () => _handleRedeem(pos['id'].toString()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                ),
                                gradient: RadialGradient(
                                  center: Alignment.topCenter,
                                  radius: 3.5,
                                  colors: [
                                    Colors.transparent,
                                    color.withOpacity(0.35),
                                    color.withOpacity(0.70),
                                    color.withOpacity(0.95),
                                    color,
                                  ],
                                  stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                                ),
                              ),
                              child: const Text(
                                "Redeem",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "DMSans",
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              color: Colors.transparent,
                            ),
                            child: Text(
                              "Locked",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: "DMSans",
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (planType != 'flexible' && lockDays > 0) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            unlockDateLabel.isNotEmpty
                                ? "$daysRemaining days remaining : unlocks $unlockDateLabel"
                                : "$lockDays days lock period",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: "DMSans",
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // â”€â”€ History â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
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

          final Color pillBg;
          final Color pillText;
          final Color amtColor;
          final String amtPrefix;
          if (type == 'subscribe') {
            pillBg = Color(0xFFCCFF00).withOpacity(0.3);
            pillText = const Color(0xFFCCFF00);
            amtColor = const Color(0xFFFF5555);
            amtPrefix = '-';
          } else if (type == 'interest') {
            pillBg = Color(0xFF00FF04).withOpacity(0.3);
            pillText = const Color(0xFF00FF04);
            amtColor = const Color(0xFF00FF04);
            amtPrefix = '+';
          } else {
            // redeem
            pillBg = Color(0xFF00E5FF).withOpacity(0.3);
            pillText = const Color(0xFF00E5FF);
            amtColor = const Color(0xFF00FF04);
            amtPrefix = '+';
          }
          final pillLabel = type.isEmpty
              ? 'Unknown'
              : '${type[0].toUpperCase()}${type.substring(1)}';
          final amtStr =
              "$amtPrefix${amount.toStringAsFixed(7).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} $coin";

          return Container(
            margin: const EdgeInsets.only(bottom: 30, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: labels
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Type",
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
                      "Coin",
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
                // Row 2: type pill | coin icon + name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pillLabel,
                        style: TextStyle(
                          color: pillText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _coinIcon(iconUrl, size: 20),
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 3: labels
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Amount",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    Text(
                      "Time",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: "DMSans",
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 4: amount | time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        amtStr,
                        style: TextStyle(
                          color: amtColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: "DMSans",
                          height: 1,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: "DMSans",
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }
}


class EasyEarnModal extends StatefulWidget {
  final String coin;
  final List<EarnProduct> plans;
  final EarnProduct? initialPlan;
  const EasyEarnModal({
    super.key,
    required this.coin,
    required this.plans,
    this.initialPlan,
  });

  @override
  State<EasyEarnModal> createState() => _EasyEarnModalState();
}

class _EasyEarnModalState extends State<EasyEarnModal> {
  late EarnProduct _selectedPlan;
  final _amountCtrl = TextEditingController();
  bool _agreed = false;
  bool _autoSub = false;
  bool _loading = false;
  final _earnCtrl = Get.find<EarnController>();

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

  String _dateStr(int addDays) {
    final d = DateTime.now().add(Duration(days: addDays));
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  void _handleConfirm() async {
    if (_amountNum <= 0 || !_agreed || _uid.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
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
        showToast("Subscribed successfully!");
        await Future.delayed(const Duration(milliseconds: 1500));
        Get.back();
      } else {
        showToast(json['message'] ?? "Failed");
      }
    } catch (_) {
      showToast("Subscription failed");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFlexible = _selectedPlan.lockDays == 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: const Color(0xFF111111),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            // ─── Scrollable content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        _coinIcon(_selectedPlan.coinIcon, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          "${widget.coin} Subscribe",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: "DMSans",
                            height: 24 / 16,
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
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                color: isA
                                    ? Colors.transparent
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isA
                                      ? const Color(0xFFCCFF00)
                                      : Colors.transparent,
                                  width: isA ? 0.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isA
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "DMSans",
                                      height: 24 / 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sub,
                                    style: TextStyle(
                                      color: isA
                                          ? const Color(0xFFCCFF00)
                                          : Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                      fontFamily: "DMSans",
                                      height: 24 / 16,
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

                    // Amount label + auto subscribe toggle
                    Row(
                      children: [
                        const Text(
                          "Amount",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: "DMSans",
                            height: 24 / 16,
                          ),
                        ),
                        if (!isFlexible) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _autoSub = !_autoSub),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _autoSub
                                          ? const Color(0xFFB5F000)
                                          : const Color(0xFF444444),
                                      width: 2,
                                    ),
                                    color: _autoSub
                                        ? const Color(0xFFB5F000)
                                        : Colors.transparent,
                                  ),
                                  child: _autoSub
                                      ? const Icon(Icons.check,
                                          size: 11, color: Colors.black)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Auto Subscribe",
                                  style: TextStyle(
                                    color: _autoSub
                                        ? const Color(0xFFB5F000)
                                        : const Color(0xFF888888),
                                    fontSize: 12,
                                    fontFamily: "DMSans",
                                    height: 24 / 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "DMSans",
                                    height: 24 / 16,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        "${coinFormat(_selectedPlan.minAmount)} Minimum",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "DMSans",
                                      height: 24 / 16,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _amountCtrl.text = coinFormat(
                                      _earnCtrl.balances[widget.coin] ?? 0);
                                  setState(() {});
                                },
                                child: const Text(
                                  "Max",
                                  style: TextStyle(
                                    color: Color(0xFFCCFF00),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "DMSans",
                                    height: 20 / 15,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  widget.coin,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "DMSans",
                                    height: 20 / 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Maximum",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 20 / 15
                                ),
                              ),
                              Text(
                                "Balance",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                  height: 20 / 15
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                coinFormat(_selectedPlan.maxAmount),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: "DMSans",
                                  height: 16 / 12,
                                ),
                              ),
                              Obx(() => Text(
                                    coinFormat(_earnCtrl.balances[widget.coin] ?? 0),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      fontFamily: "DMSans",
                                      fontWeight: FontWeight.w400,
                                      height: 16 / 12,
                                    ),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profit / timeline section
                    if (isFlexible) ...[
                      Text(
                        "Est. Daily Total Profit",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: "DMSans",
                          height: 20 / 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTierTimeline(),
                      const SizedBox(height: 20),
                       Text(
                        "Hourly interest rate, access at any time",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                          height: 20 / 15,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildConnectedTimeline([
                        MapEntry("Subscription Time", _dateStr(0)),
                        MapEntry("Interest Start Time", _dateStr(0)),
                        MapEntry("Interest Payout Time", _dateStr(0)),
                      ]),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Est. Total Profit",
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13),
                          ),
                          const Text(
                            "--",
                            style: TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            "Est. APR",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                 fontSize: 15,
                                 fontWeight: FontWeight.w600,
                                 fontFamily: "DMSans",
                                 height: 20 / 15),
                          ),
                          Text(
                            "${_selectedPlan.apr.toStringAsFixed(2)}%",
                            style: const TextStyle(
                              color: Color(0xFF4ED78E),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: "DMSans",
                              height: 20 / 15
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildConnectedTimeline([
                        MapEntry("Subscription Time", _dateStr(0)),
                        MapEntry("Interest Start Time", _dateStr(1)),
                        MapEntry("Interest Payout Time", _dateStr(1)),
                        MapEntry("Maturity Time",
                            _dateStr(_selectedPlan.lockDays)),
                        MapEntry("Fund Arrival Time",
                            _dateStr(_selectedPlan.lockDays)),
                      ]),
                    ],

                  ],
                ),
              ),
            ),

            // ─── Fixed bottom: Agreement + Button ────────────────────────
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                                  ? const Color(0xFFCCFF00)
                                  : Colors.white,
                              width: 1,
                            ),
                            color: _agreed
                                ? const Color(0xFFB5F000)
                                : Colors.transparent,
                          ),
                          child: _agreed
                              ? const Icon(Icons.check,
                                  size: 12, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 16 / 12,
                                fontFamily: "DMSans",
                                fontWeight: FontWeight.w400,

                              ),
                              children: const [
                                TextSpan(text: "I have read and agree to ",),
                                TextSpan(
                                  text: "Trapix Earn User Agreement",
                                  style: TextStyle(
                                    color: Color(0xFFCCFF00),
                                    fontSize: 12,
                                height: 16 / 12,
                                fontFamily: "DMSans",
                                fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFCCFF00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_loading || _amountNum <= 0 || !_agreed)
                          ? null
                          : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_loading || _amountNum <= 0 || !_agreed)
                                ? const Color(0xFF222222)
                                : const Color(0xFFCCFF00),
                        disabledBackgroundColor: const Color(0xFF222222),
                        overlayColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _loading ? "Processing..." : "Preview Order",
                        style: TextStyle(
                          color: (_loading || _amountNum <= 0 || !_agreed)
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                          height: 24 / 16,
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
  }

  // Connected timeline (dots joined by vertical lines)
  Widget _buildConnectedTimeline(List<MapEntry<String, String>> items) {
    const dotColor = Color(0xFFD9D9D9);
    const lineColor = Color(0x80FFFFFF);
    const textStyle = TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 16 / 12,
      color: Color(0x80FFFFFF),
    );
    return Column(
      children: List.generate(items.length, (i) {
        final isLast = i == items.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 28, color: lineColor),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(items[i].key, style: textStyle),
                    Text(items[i].value, style: textStyle),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // Tier rows for flexible plan (connected timeline style)
  Widget _buildTierTimeline() {
    final flexPlans = widget.plans
        .where((p) => p.lockDays == 0)
        .toList()
      ..sort((a, b) => a.maxAmount.compareTo(b.maxAmount));

    final items = <MapEntry<String, String>>[];
    for (int i = 0; i < flexPlans.length; i++) {
      final prevMax = i > 0 ? flexPlans[i - 1].maxAmount : null;
      final label = prevMax == null
          ? "< ${coinFormat(flexPlans[i].maxAmount)}USDT"
          : "${coinFormat(prevMax)} -${coinFormat(flexPlans[i].maxAmount)}USDT";
      items.add(MapEntry(label, "${flexPlans[i].apr.toStringAsFixed(2)}%"));
    }
    if (items.isEmpty) {
      items.add(MapEntry(
        "< ${coinFormat(_selectedPlan.maxAmount)}USDT",
        "${_selectedPlan.apr.toStringAsFixed(2)}%",
      ));
    }

    return Column(
      children: List.generate(items.length, (i) {
        final isLast = i == items.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD9D9D9),
                    ),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 28, color: const Color(0x80FFFFFF)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(items[i].key,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 16 / 12,
                          color: Color(0x80FFFFFF),
                        )),
                    Text(items[i].value,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 16 / 15,
                          color: Color(0xFF4ED78E),
                        )),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}


// ── Earn Hero — same SVG shape & wave as Spot/Future hero ──────────────────────
const double _earnSvgW2 = 362.0;
const double _earnSvgH2 = 204.0;
const double _earnCardH = 220.0;

class _EarnHeroShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onHistoryTap;
  const _EarnHeroShell({required this.child, this.onHistoryTap});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Container(
      color: Colors.transparent,
      child: SizedBox(
        width: screenW,
        height: _earnCardH,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // SVG-shaped background — same as Spot/Future
            Positioned.fill(
              child: ClipPath(
                clipper: _EarnHeroClipper(cardW: screenW, cardH: _earnCardH),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: CustomPaint(
                    painter: _EarnHeroPainter(
                      cardW: screenW,
                      cardH: _earnCardH,
                      fillColor: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ),
            // Green wave — rotated, same placement as Spot/Future
            Positioned(
              right: 25,
              top: 30,
              width: screenW * 0.40,
              height: _earnCardH * 1.3,
              child: Transform.rotate(
                angle: 1.250,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/images/wallet_green_wave.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Border
            Positioned.fill(
              child: CustomPaint(
                painter: _EarnHeroBorderPainter(cardW: screenW, cardH: _earnCardH),
              ),
            ),
            // Content
            Positioned.fill(child: child),
            // History icon — top right (same as spot/future)
            if (onHistoryTap != null)
              Positioned(
                top: 14,
                right: 16,
                child: GestureDetector(
                  onTap: onHistoryTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                    ),
                    child: const RotatingIcon(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EarnHeroBorderPainter extends CustomPainter {
  const _EarnHeroBorderPainter({required this.cardW, required this.cardH});
  final double cardW, cardH;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = cardW / _earnSvgW2;
    final sy = cardH / _earnSvgH2;
    canvas.drawPath(
      _EarnHeroPainter._buildPath(sx, sy),
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EarnHeroPainter extends CustomPainter {
  const _EarnHeroPainter({
    required this.cardW,
    required this.cardH,
    required this.fillColor,
  });
  final double cardW, cardH;
  final Color fillColor;

  static Path _buildPath(double sx, double sy) => Path()
    ..moveTo(0, 20 * sy)
    ..cubicTo(0, 8.9543 * sy, 8.95431 * sx, 0, 20 * sx, 0)
    ..lineTo(132.716 * sx, 0)
    ..cubicTo(138.02 * sx, 0, 143.107 * sx, 2.10714 * sy, 146.858 * sx, 5.85786 * sy)
    ..lineTo(155.142 * sx, 14.1421 * sy)
    ..cubicTo(158.893 * sx, 17.8929 * sy, 163.98 * sx, 20 * sy, 169.284 * sx, 20 * sy)
    ..lineTo(192.716 * sx, 20 * sy)
    ..cubicTo(198.02 * sx, 20 * sy, 203.107 * sx, 17.8929 * sy, 206.858 * sx, 14.1421 * sy)
    ..lineTo(215.142 * sx, 5.85786 * sy)
    ..cubicTo(218.893 * sx, 2.10713 * sy, 223.98 * sx, 0, 229.284 * sx, 0)
    ..lineTo(342 * sx, 0)
    ..cubicTo(353.046 * sx, 0, 362 * sx, 8.95431 * sy, 362 * sx, 20 * sy)
    ..lineTo(362 * sx, 184 * sy)
    ..cubicTo(362 * sx, 195.046 * sy, 353.046 * sx, 204 * sy, 342 * sx, 204 * sy)
    ..lineTo(20 * sx, 204 * sy)
    ..cubicTo(8.9543 * sx, 204 * sy, 0, 195.046 * sy, 0, 184 * sy)
    ..lineTo(0, 20 * sy)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _buildPath(cardW / _earnSvgW2, cardH / _earnSvgH2),
      Paint()..color = fillColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EarnHeroClipper extends CustomClipper<Path> {
  const _EarnHeroClipper({required this.cardW, required this.cardH});
  final double cardW, cardH;

  @override
  Path getClip(Size size) =>
      _EarnHeroPainter._buildPath(cardW / _earnSvgW2, cardH / _earnSvgH2);

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}


// ── Staking Live Hero ─────────────────────────────────────────────────────────
class _StakingLiveHero extends StatefulWidget {
  const _StakingLiveHero();
  @override
  State<_StakingLiveHero> createState() => _StakingLiveHeroState();
}

class _StakingLiveHeroState extends State<_StakingLiveHero> {
  late McStakingController _c;
  Timer? _ticker;
  Timer? _frameTimer;
  double _liveEarning = 0;
  double _perSec = 0;
  double _dailyTotal = 0;
  double _availableToWithdraw = 0;
  bool _ready = false;
  double _initTotal = 0;
  double _initAvail = 0;
  int _sessionStart = 0;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<McStakingController>()
        ? Get.find<McStakingController>()
        : Get.put(McStakingController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_c.portfolio.value == null || _c.portfolio.value!.portfolio.isEmpty) {
        await _c.fetchPortfolio();
      }
      _initCounter();
      // Start polling live prices for all staked coins
      final symbols = _c.portfolio.value?.portfolio
          .map((e) => e.coinSymbol)
          .toSet()
          .toList() ?? [];
      if (symbols.isNotEmpty) {
        _c.startCoinCarouselPolling(symbols);
        // Recalc every 3s when tickers refresh
        Timer.periodic(const Duration(seconds: 3), (_) {
          if (!mounted) return;
          _recalcFromPortfolio();
        });
      }
    });
  }

  void _initCounter() {
    final portfolio = _c.portfolio.value;
    if (portfolio == null || portfolio.portfolio.isEmpty) return;
    _recalcFromPortfolio();
  }

  // Recalculates base values using live coin prices. Called on init and every 3s.
  void _recalcFromPortfolio() {
    final portfolio = _c.portfolio.value;
    if (portfolio == null || portfolio.portfolio.isEmpty) return;
    double totalPerSec = 0, dailyTotal = 0;
    if (!mounted) return;
    setState(() => _ready = true);

    // Start 60fps vsync frame ticker — recalcs directly from staked_at each frame
    // exactly like web's requestAnimationFrame approach
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final portfolio2 = _c.portfolio.value;
      if (portfolio2 == null) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      double total = 0, avail = 0, perSec = 0, daily = 0;
      for (final item in portfolio2.portfolio) {
        final tickerData = _c.coinTickers[item.coinSymbol];
        final price = (tickerData != null && (tickerData['price'] as double) > 0)
            ? tickerData['price'] as double
            : (item.coinPriceUsdt > 0 ? item.coinPriceUsdt : 1.0);

        final perSecCoin = (item.stakedAmount * (item.dailyRate / 100)) / 86400;
        final perSecUsdt = perSecCoin * price;
        perSec += perSecUsdt;
        daily += perSecUsdt * 86400;

        // All-time: from staked_at
        final stakedMs = DateTime.tryParse(item.stakedAt ?? '')?.millisecondsSinceEpoch ?? nowMs;
        final totalSecs = ((nowMs - stakedMs) / 1000).clamp(0.0, double.infinity);
        total += perSecUsdt * totalSecs;

        // Available: from last_withdrawn_at
        final availStart = item.lastWithdrawnAt ?? item.stakedAt ?? '';
        final availMs = DateTime.tryParse(availStart)?.millisecondsSinceEpoch ?? stakedMs;
        final availSecs = ((nowMs - availMs) / 1000).clamp(0.0, double.infinity);
        avail += perSecUsdt * availSecs;
      }
      _c.liveEarningUsdt.value = total;
      setState(() {
        _liveEarning = total;
        _availableToWithdraw = avail;
        _perSec = perSec;
        _dailyTotal = daily;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _frameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EarnHeroShell(
      onHistoryTap: () => Get.to(() => const McWithdrawHistoryScreen(initialTab: 0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staking',
                  style: TextStyle(
                    color: Color(0xFFCCFF00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                 Text(
                  'Live Earning',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  _ready
                      ? '\$ ${_liveEarning.toStringAsFixed(8)}'
                      : '\$ 0.00000000',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 0),
                Row(
                  children: [
                    Text(
                      'Available to Withdraw: ',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'DMSans'),
                    ),
                    Text(
                      _ready ? _availableToWithdraw.toStringAsFixed(7) : '0.0000000',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'DMSans'),
                    ),
                  ],
                ),
               const SizedBox(height: 0),
                Row(
                  children: [
                    Expanded(child: _stakeStat('Per Second', _ready ? '+${_perSec.toStringAsFixed(8)}' : '--', const Color(0xFF00B052))),
                    Container(width: 1, height: 36, color: Colors.white.withOpacity(0.10), margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(child: _stakeStat('Daily Total', _ready ? _dailyTotal.toStringAsFixed(6) : '--', const Color(0xFF00B052))),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.to(() => McMyStakesScreen()),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFCCFF00), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('My Stakes', style: TextStyle(color: Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'DMSans')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('Calculator', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400, fontFamily: 'DMSans')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stakeStat(String label, String value, [Color valueColor = Colors.white]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
            height: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
