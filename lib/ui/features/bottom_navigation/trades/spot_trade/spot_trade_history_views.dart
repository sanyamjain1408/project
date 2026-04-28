import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/swap/swap_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'spot_trade_controller.dart';

const _cardBg = Color(0xFF161A1E);
const _labelClr = Color(0xFF848E9C);
const _valueClr = Color(0xFFEAECEF);
const _borderClr = Color(0xFF252930);

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN VIEW  — "Open order | Assets" + clock icon
// ══════════════════════════════════════════════════════════════════════════════
class SpotTradeHistoryView extends StatefulWidget {
  const SpotTradeHistoryView({super.key});
  @override
  SpotTradeHistoryViewState createState() => SpotTradeHistoryViewState();
}

class SpotTradeHistoryViewState extends State<SpotTradeHistoryView> {
  final _controller = Get.find<SpotTradeController>();
  final RxInt _mainTab = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tab row ───────────────────────────────────────────────────────────
        Row(
          children: [
            Obx(
              () => _TabChip(
                label: "Open order".tr,
                selected: _mainTab.value == 0,
                onTap: () => _mainTab.value = 0,
              ),
            ),
            const SizedBox(width: 4),
            Obx(
              () => _TabChip(
                label: "Assets".tr,
                selected: _mainTab.value == 1,
                onTap: () => _mainTab.value = 1,
              ),
            ),
            const Spacer(),
            // Clock icon → history bottom sheet
            GestureDetector(
              onTap: () => _openHistorySheet(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _borderClr),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: _labelClr,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.5, color: _borderClr),
        const SizedBox(height: 8),

        // ── Body ──────────────────────────────────────────────────────────────
        Obx(
          () => gUserRx.value.id == 0
              ? Padding(
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  child: RichText(
                    text: TextSpan(
                      text: "${"Want to trade".tr} ",
                      style: const TextStyle(color: _labelClr, fontSize: 13),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Get.to(() => const SignInPage()),
                            child: Text(
                              "Login".tr,
                              style: TextStyle(
                                color: gBuyColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Obx(
                  () => _mainTab.value == 0 ? _openOrdersList() : _assetsView(),
                ),
        ),
      ],
    );
  }

  Widget _openOrdersList() {
    return Obx(() {
      final list = _controller.allMyHistories.value.orders ?? [];
      return list.isEmpty
          ? handleEmptyViewWithLoading(_controller.isHistoryLoading.value)
          : Column(
              children: list
                  .map(
                    (t) => SpotTradeHistoryItemView(
                      trade: t,
                      fromKey: FromKey.buySell,
                      onCancel: (trade) => _controller.cancelOpenOrderApp(
                        trade.type ?? '',
                        trade.id ?? 0,
                      ),
                      orderData: _controller.dashboardData.value.orderData,
                    ),
                  )
                  .toList(),
            );
    });
  }

  Widget _assetsView() {
    return Obx(() {
      final total = _controller.selfBalance.value.total;
      final baseW = total?.baseWallet;
      final tradeW = total?.tradeWallet;
      final coinPair = _controller.selectedCoinPair.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Current Assets",
            style: TextStyle(color: _labelClr, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (baseW != null)
            _AssetCoinCard(
              coinType: baseW.coinType ?? "",
              total: coinFormat(baseW.balance, fixed: tradeDecimal),
              available: coinFormat(baseW.balance, fixed: tradeDecimal),
              coinPair: coinPair,
              controller: _controller,
            ),
          const SizedBox(height: 10),
          if (tradeW != null)
            _AssetCoinCard(
              coinType: tradeW.coinType ?? "",
              total: coinFormat(tradeW.balance, fixed: tradeDecimal),
              available: coinFormat(tradeW.balance, fixed: tradeDecimal),
              coinPair: coinPair,
              controller: _controller,
            ),
        ],
      );
    });
  }

  void _openHistorySheet(BuildContext context) {
    Get.to(() => SpotTradeHistoryFullScreen(controller: _controller));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ASSET COIN CARD
// ══════════════════════════════════════════════════════════════════════════════
class _AssetCoinCard extends StatelessWidget {
  const _AssetCoinCard({
    required this.coinType,
    required this.total,
    required this.available,
    required this.coinPair,
    required this.controller,
  });

  final String coinType;
  final String total;
  final String available;
  final dynamic coinPair;
  final SpotTradeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderClr, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: gBuyColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    coinType.isNotEmpty ? coinType[0] : "?",
                    style: TextStyle(
                      color: gBuyColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                coinType,
                style: const TextStyle(
                  color: _valueClr,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: _labelClr, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                "Total",
                style: TextStyle(color: _labelClr, fontSize: 12),
              ),
              const Spacer(),
              Text(
                total,
                style: const TextStyle(
                  color: _valueClr,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                "Available",
                style: TextStyle(color: _labelClr, fontSize: 12),
              ),
              const Spacer(),
              Text(
                available,
                style: const TextStyle(
                  color: _valueClr,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(label: "Buy/Sell", onTap: () => Get.back()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: "Add Funds",
                  onTap: () {
                    final total = controller.selfBalance.value.total;
                    final wallet =
                        coinType == (total?.baseWallet?.coinType ?? "")
                        ? total?.baseWallet
                        : total?.tradeWallet;
                    if (wallet != null) {
                      Get.to(
                        () => WalletCryptoDepositScreen(
                          wallet: wallet.createWallet(),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: "⇄ Swap",
                  onTap: () => Get.to(() => SwapScreen(prePair: coinPair)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2329),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _borderClr),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _valueClr,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Theme.of(context).focusColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Theme.of(context).primaryColor : _labelClr,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HISTORY FULL SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class SpotTradeHistoryFullScreen extends StatefulWidget {
  const SpotTradeHistoryFullScreen({super.key, required this.controller});
  final SpotTradeController controller;

  @override
  State<SpotTradeHistoryFullScreen> createState() =>
      _SpotTradeHistoryFullScreenState();
}

class _SpotTradeHistoryFullScreenState extends State<SpotTradeHistoryFullScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final RxInt _buySell = 0.obs;

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Open Order, Order History, Trade History, Stop Limit Orders
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _valueClr),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "My Trades",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: "DMSans",
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: "DMSans",
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: "DMSans",
              height: 1.5,
            ),
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              Tab(text: "Open Order".tr),
              Tab(text: "Order History".tr),
              Tab(text: "Trade History".tr),
              Tab(text: "Stop Limit Orders".tr),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Tab 0: Open Order — Upcoming placeholder ──────────────
          const _UpcomingOpenOrderWidget(),

          // ── Tab 1: Order History (Separate Widget) ────────────────────
          _OrderHistoryView(controller: widget.controller),

          // ── Tab 2: Trade History ───────────────────────────────────────
          Obx(() {
            final list =
                widget.controller.allMyHistories.value.transactions ?? [];
            return list.isEmpty
                ? handleEmptyViewWithLoading(
                    widget.controller.isHistoryLoading.value,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => SpotTradeHistoryItemView(
                      trade: list[i],
                      fromKey: FromKey.trade,
                      onCancel: (_) {},
                      orderData: widget.controller.dashboardData.value.orderData,
                    ),
                  );
          }),

          // ── Tab 3: Stop Limit Orders — Upcoming placeholder ───────────
          const _UpcomingStopLimitWidget(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET 1: ORDER HISTORY VIEW
// ══════════════════════════════════════════════════════════════════════════════
class _OrderHistoryView extends StatelessWidget {
  const _OrderHistoryView({required this.controller});
  final SpotTradeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Logic: Buy + Sell merged
      final buys = controller.allMyHistories.value.buyOrders ?? [];
      final sells = controller.allMyHistories.value.sellOrders ?? [];
      final list = [...buys, ...sells];

      // Sort logic
      list.sort((a, b) {
        final aDate = (a as dynamic).createdAt;
        final bDate = (b as dynamic).createdAt;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      if (list.isEmpty) {
        return handleEmptyViewWithLoading(controller.isHistoryLoading.value);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (_, i) => SpotTradeHistoryItemView(
          trade: list[i],
          fromKey: list[i].type == FromKey.buy ? FromKey.buy : FromKey.sell,
          onCancel: (_) {}, // History mein cancel nahi hota usually
          orderData: controller.dashboardData.value.orderData,
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET 2: UPCOMING OPEN ORDER PLACEHOLDER
// ══════════════════════════════════════════════════════════════════════════════
class _UpcomingOpenOrderWidget extends StatelessWidget {
  const _UpcomingOpenOrderWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: _borderClr),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: _labelClr,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Upcoming",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: "DMSans",
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Open Orders feature is coming soon",
            style: TextStyle(color: _labelClr, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGET 3: UPCOMING STOP LIMIT PLACEHOLDER
// ══════════════════════════════════════════════════════════════════════════════
class _UpcomingStopLimitWidget extends StatelessWidget {
  const _UpcomingStopLimitWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: _borderClr),
            ),
            child: const Icon(
              Icons.price_change_rounded,
              color: _labelClr,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Upcoming Stop Limit",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: "DMSans",
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Stop Limit Orders feature is coming soon",
            style: TextStyle(color: _labelClr, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  COMMON ORDER CARD (USED EVERYWHERE)
// ══════════════════════════════════════════════════════════════════════════════
class SpotTradeHistoryItemView extends StatelessWidget {
  const SpotTradeHistoryItemView({
    super.key,
    required this.trade,
    required this.orderData,
    required this.fromKey,
    required this.onCancel,
  });
  final Trade trade;
  final OrderData? orderData;
  final String fromKey;
  final Function(Trade) onCancel;

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == FromKey.buy;
    final color = isBuy ? gBuyColor : gSellColor;
    final tradeCoin = orderData?.tradeCoin ?? "";
    final baseCoin = orderData?.baseCoin ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderClr, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(
                  "$tradeCoin/$baseCoin",
                  style: const TextStyle(
                    color: _valueClr,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    "${(trade.type ?? '').toUpperCase()} Limit",
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(
                        trade.createdAt,
                        format: dateTimeFormatYyyyMMDdHhMm,
                      ) ??
                      "",
                  style: const TextStyle(color: _labelClr, fontSize: 10),
                ),
                if (fromKey == FromKey.buySell) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onCancel(trade),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: _borderClr),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                _row("Amount ($tradeCoin)", coinFormat(trade.amount)),
                _row("Fee ($baseCoin)", coinFormat(trade.fees)),
                _row("Price ($baseCoin)", coinFormat(trade.price)),
                if (fromKey != FromKey.buy)
                  _row("Processed ($tradeCoin)", coinFormat(trade.processed)),
                if (fromKey != FromKey.trade)
                  _row("Total ($baseCoin)", coinFormat(trade.total)),
                if (fromKey == FromKey.trade)
                  _row("TX ID", trade.transactionId ?? "—"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(l, style: const TextStyle(color: _labelClr, fontSize: 12)),
        const Spacer(),
        Text(v, style: const TextStyle(color: _valueClr, fontSize: 12)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  STOP-LIMIT CARD
// ══════════════════════════════════════════════════════════════════════════════
class SpotTradeHistoryStopLimitItemView extends StatelessWidget {
  const SpotTradeHistoryStopLimitItemView({
    super.key,
    required this.trade,
    required this.orderData,
    required this.onCancel,
  });
  final StopLimitOrder trade;
  final OrderData? orderData;
  final Function(StopLimitOrder) onCancel;

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == FromKey.buy;
    final color = isBuy ? gBuyColor : gSellColor;
    final tradeCoin = orderData?.tradeCoin ?? "";
    final baseCoin = orderData?.baseCoin ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderClr, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Text(
                  "$tradeCoin/$baseCoin",
                  style: const TextStyle(
                    color: _valueClr,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    "${(trade.type ?? '').toUpperCase()} Stop Limit",
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onCancel(trade),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: _borderClr),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                _row("Amount ($tradeCoin)", coinFormat(trade.amount)),
                _row("Fee ($baseCoin)", coinFormat(trade.fees)),
                _row("Price ($baseCoin)", coinFormat(trade.price)),
                _row("Stop ($baseCoin)", coinFormat(trade.stop)),
                _row("Total ($baseCoin)", coinFormat(trade.total)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(l, style: const TextStyle(color: _labelClr, fontSize: 12)),
        const Spacer(),
        Text(v, style: const TextStyle(color: _valueClr, fontSize: 12)),
      ],
    ),
  );
}