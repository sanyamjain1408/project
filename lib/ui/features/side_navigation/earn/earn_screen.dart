import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';
import 'earn_subscribe_modal.dart';
import 'dual_investment_screen.dart'; // ✅ Your existing file

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  final _controller = Get.put(EarnController());

  int _selectedTab = 0;
  final List<String> _tabs = ["Overview", "Easy Earn", "Dual Investment"];

  final List<Map<String, String>> _faqs = [
    {'q': 'What is Trapix Earn?', 'a': 'Trapix Earn lets you earn passive income on your crypto holdings through Flexible plans (redeem anytime) and Fixed/Locked plans (earn higher APR for a fixed period).'},
    {'q': 'How is the yield generated?', 'a': 'Yield is generated from trading fees, lending activity, and platform operations. The APR shown is an estimate based on current market conditions.'},
    {'q': 'Is the yield fixed?', 'a': 'Flexible plan yields may vary based on market conditions. Locked plan yields are fixed at the time of subscription for the entire lock period.'},
    {'q': 'When does the interest start to accrue?', 'a': 'Interest starts accruing from the next day after your subscription is confirmed. It is calculated daily and added to your accrued interest balance.'},
    {'q': 'When can I redeem my funds?', 'a': 'Flexible plans can be redeemed at any time. Locked plans can only be redeemed after the lock period expires.'},
  ];

  int? _openFaq;

  final List<Color> _recColors = [
    const Color(0xFFFF6F00),
    const Color(0xFF00C9FF),
    const Color(0xFF6C5CE7),
    const Color(0xFF00B894),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchProducts();
      if (gUserRx.value.id > 0) {
        _controller.fetchPositions();
        _controller.fetchBalances();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Trapix Earn",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Grow steadily. Let your wealth endure.",
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Main Tabs (Always visible) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF111318),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFB5F000) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : const Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Body Content ──
            Expanded(
              child: _selectedTab == 2
                  ? const DualInvestmentScreen() // ✅ Embedded inside main tabs
                  : _buildOverviewContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview / Easy Earn Content ──
  Widget _buildOverviewContent() {
    return Obx(() {
      final products = _controller.products;
      final positions = _controller.positions;
      final isLoggedIn = gUserRx.value.id > 0;

      final totalAssets = positions.fold(0.0, (s, p) => s + p.amount);
      final totalInterest = positions.fold(0.0, (s, p) => s + p.accruedInterest);

      final recommended = [...products]
        ..sort((a, b) => b.apr.compareTo(a.apr));
      final topRec = recommended.take(4).toList();

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // ── Header Section (Buttons Left + Stats Right) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderButton(
                      icon: Icons.account_balance_wallet_outlined,
                      label: "View My Earnings",
                      onTap: () {
                        if (!isLoggedIn) {
                          Get.to(() => const _SignInPlaceholder());
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildHeaderButton(
                      icon: Icons.calculate_outlined,
                      label: "Calculator",
                      onTap: () => _showCalculatorDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111318),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E2128)),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow("Total Assets (USDT)", isLoggedIn ? coinFormat(totalAssets) : '--', const Color(0xFFFFFFFF), 22),
                      const SizedBox(height: 14),
                      Container(height: 1, color: const Color(0xFF1E2128)),
                      const SizedBox(height: 14),
                      _buildStatRow("Total Interest (USDT)", isLoggedIn ? coinFormat(totalInterest) : '--', const Color(0xFFB5F000), 16),
                      const SizedBox(height: 12),
                      _buildStatRow("Active Positions", isLoggedIn ? positions.length.toString() : '--', const Color(0xFFB5F000), 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Recommended ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recommended',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),

          if (_controller.isLoadingProducts.value)
            const Center(child: CircularProgressIndicator(color: Color(0xFFB5F000)))
          else if (topRec.isEmpty)
            const Center(child: Text("No products available", style: TextStyle(color: Color(0xFF6B7280))))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              itemCount: topRec.length,
              itemBuilder: (context, index) {
                final p = topRec[index];
                final color = _recColors[index % _recColors.length];
                return _buildRecommendedCard(p, color);
              },
            ),

          const SizedBox(height: 28),

          // ── Products Table ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Products',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Coin', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('APR', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Period', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E2128)),

          ...() {
            final coins = products.map((p) => p.coin).toSet().toList();
            return coins.map((coin) {
              final coinProducts = products.where((p) => p.coin == coin).toList()
                ..sort((a, b) => a.lockDays.compareTo(b.lockDays));
              final aprs = coinProducts.map((p) => p.apr).toList();
              final minApr = aprs.reduce((a, b) => a < b ? a : b);
              final maxApr = aprs.reduce((a, b) => a > b ? a : b);
              final hasFlexible = coinProducts.any((p) => p.lockDays == 0);
              final hasFixed = coinProducts.any((p) => p.lockDays > 0);
              final period = hasFlexible && hasFixed ? 'Flex/Fixed' : hasFlexible ? 'Flexible' : 'Fixed';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E2128)),
                                child: coinProducts.first.coinIcon != null
                                    ? ClipOval(child: Image.network(coinProducts.first.coinIcon!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 18)))
                                    : const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(coin, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            minApr == maxApr ? '${minApr.toStringAsFixed(2)}%' : '${minApr.toStringAsFixed(2)}%~${maxApr.toStringAsFixed(2)}%',
                            style: const TextStyle(color: Color(0xFFB5F000), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => EarnSubscribeModal(product: coinProducts.first),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB5F000),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(period, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFF111318)),
                ],
              );
            }).toList();
          }(),

          const SizedBox(height: 28),

          // ── FAQs ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111318),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Frequently asked questions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ..._faqs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final faq = entry.value;
                  final isOpen = _openFaq == i;
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _openFaq = isOpen ? null : i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(child: Text(faq['q']!, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, fontWeight: FontWeight.w500))),
                              Text(isOpen ? '−' : '+', style: const TextStyle(color: Color(0xFF555555), fontSize: 22)),
                            ],
                          ),
                        ),
                      ),
                      if (isOpen)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(faq['a']!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.6)),
                        ),
                      const Divider(height: 1, color: Color(0xFF1E2128)),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      );
    });
  }

  // ── Header Button ──
  Widget _buildHeaderButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2128)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFB5F000), size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat Row ──
  Widget _buildStatRow(String label, String value, Color valueColor, double valueSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: valueSize, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── Recommended Card ──
  Widget _buildRecommendedCard(dynamic p, Color color) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EarnSubscribeModal(product: p),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              const Color(0xFF111318),
            ],
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                  child: p.coinIcon != null
                      ? ClipOval(child: Image.network(p.coinIcon!, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.monetization_on, color: color, size: 18)))
                      : Icon(Icons.monetization_on, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.coin, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      p.lockDays == 0 ? 'Easy Earn | Flexible' : 'Easy Earn | Fixed',
                      style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${p.apr.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'APR',
                      style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (p.lockDays > 0)
                  Text(
                    '${p.lockDays} Days',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Calculator Dialog ──
  void _showCalculatorDialog(BuildContext context) {
    final amountController = TextEditingController();
    double calculated = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111318),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Earn Calculator", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter amount (USDT)",
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFF1E2128),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFB5F000)),
                  ),
                  onChanged: (val) {
                    final amt = double.tryParse(val) ?? 0;
                    final apr = _controller.products.isNotEmpty ? _controller.products.first.apr : 0;
                    calculated = (amt * apr) / (100 * 365);
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2128),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Estimated Daily Earning", style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      Text(
                        "${calculated.toStringAsFixed(4)} USDT",
                        style: const TextStyle(color: Color(0xFFB5F000), fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close", style: TextStyle(color: Color(0xFF6B7280))),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sign In Placeholder ──
class _SignInPlaceholder extends StatelessWidget {
  const _SignInPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFFB5F000), size: 50),
            const SizedBox(height: 16),
            const Text("Please Sign In", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text("You need to be logged in to view earnings.", style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5F000),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Go Back", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}