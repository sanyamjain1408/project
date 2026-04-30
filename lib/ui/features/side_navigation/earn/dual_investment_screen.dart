import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'dual_investment_controller.dart';
import 'dual_subscribe_modal.dart';

class DualInvestmentScreen extends StatefulWidget {
  const DualInvestmentScreen({super.key});

  @override
  State<DualInvestmentScreen> createState() => _DualInvestmentScreenState();
}

class _DualInvestmentScreenState extends State<DualInvestmentScreen> {
  late DualInvestmentController _controller;
  final RxInt _mainTab = 0.obs; // 0=market, 1=subscriptions

  @override
  void initState() {
    super.initState();
    _controller = Get.put(DualInvestmentController());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(child: Obx(() => _mainTab.value == 0 ? _buildMarketTab() : _buildSubscriptionsTab())),
      ],
    );
  }

  Widget _buildTabBar() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E2128)))),
      child: Row(
        children: [
          _tabBtn('Market', 0),
          _tabBtn('My Subscriptions', 1),
        ],
      ),
    ));
  }

  Widget _tabBtn(String label, int index) {
    final isActive = _mainTab.value == index;
    return GestureDetector(
      onTap: () {
        _mainTab.value = index;
        if (index == 1) _controller.fetchSubscriptions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFB5F000) : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: isActive ? const Color(0xFFB5F000) : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMarketTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Step 1: Select Coin ──
        _stepLabel('1', 'Select Coin'),
        const SizedBox(height: 12),
        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _controller.pairs.map((pair) {
              final isSelected = _controller.selectedPair.value?.baseCoin == pair.baseCoin;
              return GestureDetector(
                onTap: () => _controller.setSelectedPair(pair),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111318),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? const Color(0xFFB5F000) : const Color(0xFF1E2128)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFB5F000), size: 28),
                      const SizedBox(height: 6),
                      Text(pair.baseCoin, style: TextStyle(color: isSelected ? const Color(0xFFB5F000) : Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        )),

        const SizedBox(height: 24),

        // ── Step 2: Start ──
        _stepLabel('2', 'Start'),
        const SizedBox(height: 12),

        // Strategy Toggle
        Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFF111318), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _strategyBtn('buy_low',   '📉 Buy Low'),
              _strategyBtn('sell_high', '📈 Sell High'),
            ],
          ),
        )),

        const SizedBox(height: 12),

        // Term Filter
        Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _termBtn(null, 'All'),
              _termBtn(1,    '1 Day'),
              _termBtn(3,    '3 Days'),
              _termBtn(7,    '7 Days'),
            ],
          ),
        )),

        const SizedBox(height: 16),

        // Products Table
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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text('Target Price', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11))),
                      Expanded(flex: 1, child: Text('APR',          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11))),
                      Expanded(flex: 2, child: Text('Expiry',       style: TextStyle(color: Color(0xFF6B7280), fontSize: 11))),
                      Expanded(flex: 1, child: Text('Action',       style: TextStyle(color: Color(0xFF6B7280), fontSize: 11))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF1E2128)),

                ..._controller.products.map((p) {
                  final isBuyLow   = p.strategy == 'buy_low';
                  final stratColor = isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900);
                  final yieldRate  = p.apr * p.termDays / 365 / 100;
                  final isLoggedIn = gUserRx.value.id > 0;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.targetPrice.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(color: stratColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                    child: Text('${(yieldRate * 100).toStringAsFixed(2)}% ${isBuyLow ? '↓' : '↑'}', style: TextStyle(color: stratColor, fontSize: 9, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${p.apr.toStringAsFixed(2)}%', style: const TextStyle(color: Color(0xFF00B052), fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('${p.expiryDate}\n${p.termDays}d', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10), maxLines: 2),
                            ),
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: isLoggedIn ? () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => DualSubscribeModal(product: p, controller: _controller),
                                ) : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: isLoggedIn ? LinearGradient(colors: isBuyLow ? [const Color(0xFF00E5FF), const Color(0xFF00BFFF)] : [const Color(0xFFFF6F00), const Color(0xFFFF8C00)]) : null,
                                    color: isLoggedIn ? null : const Color(0xFF222222),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    isLoggedIn ? 'Subscribe' : 'Login',
                                    style: TextStyle(color: isLoggedIn ? Colors.black : const Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFF111318)),
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
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Color(0xFF6B7280), size: 48),
              SizedBox(height: 12),
              Text('No subscriptions yet', style: TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.subscriptions.length,
        itemBuilder: (context, index) {
          final sub        = _controller.subscriptions[index];
          final isActive   = sub.status == 'active';
          final isSettled  = sub.status == 'settled';
          final isBuyLow   = sub.strategy == 'buy_low';
          final stratColor = isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900);

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
                Row(
                  children: [
                    Text('${sub.baseCoin}-${sub.quoteCoin}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: stratColor, borderRadius: BorderRadius.circular(10)),
                      child: Text(isBuyLow ? 'Buy Low' : 'Sell High', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFB5F000) : const Color(0xFF666666),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(sub.status[0].toUpperCase() + sub.status.substring(1), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    if (isActive) Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Settles on', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
                        Text(sub.expiryDate, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (isSettled && sub.payoutAmount != null) Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Settlement', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
                        Text('+${coinFormat(sub.payoutAmount!)} ${sub.payoutCoin}', style: const TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _subInfo('Target', '\$${sub.targetPrice.toStringAsFixed(0)}'),
                    _subInfo('Deposited', '${coinFormat(sub.amount)} ${sub.depositCoin}'),
                    _subInfo('APR', '${sub.apr.toStringAsFixed(2)}%', color: const Color(0xFF00FF88)),
                    _subInfo('Yield', '${(sub.yieldRate * 100).toStringAsFixed(4)}%', color: const Color(0xFFB5F000)),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _subInfo(String label, String value, {Color? color}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: Color(0xFF6B7280))),
          TextSpan(text: value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _stepLabel(String num, String label) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB5F000)),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _strategyBtn(String val, String label) {
    final isActive = _controller.strategy.value == val;
    final isBuyLow = val == 'buy_low';
    return GestureDetector(
      onTap: () => _controller.setStrategy(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? (isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _termBtn(int? val, String label) {
    final isActive = _controller.termFilter.value == val;
    return GestureDetector(
      onTap: () => _controller.setTermFilter(val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB5F000) : const Color(0xFF111318),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : const Color(0xFF1E2128)),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}