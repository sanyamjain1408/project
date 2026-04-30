import 'dart:convert';

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
import 'package:flutter/services.dart';

const _cardBg = Color(0xFF161A1E);
const _labelClr = Color(0xFF848E9C);
const _valueClr = Color(0xFFEAECEF);
const _borderClr = Color(0xFF252930);

// ── Shared horizontal padding for ALL content rows ────────────────────────────
// Tab row, list items, asset cards — sabki left/right padding same hogi
const double _kHPad = 10.0;

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN VIEW
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kHPad),
          child: Row(
            children: [
              Obx(
                () => _TabChip(
                  label: "Open order".tr,
                  selected: _mainTab.value == 0,
                  onTap: () => _mainTab.value = 0,
                ),
              ),
              const SizedBox(width: 20),
              Obx(
                () => _TabChip(
                  label: "Assets".tr,
                  selected: _mainTab.value == 1,
                  onTap: () => _mainTab.value = 1,
                ),
              ),
              const Spacer(),
              // ✅ History icon — same vertical centre as delete icon in list
              GestureDetector(
                onTap: () => _openHistorySheet(context),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Image.asset(
                    "assets/icons/history.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),

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
                  () => _mainTab.value == 0
                      ? _openOrdersList()
                      : _assetsView(),
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
                    (t) => _OpenOrderCard(
                      trade: t,
                      orderData: _controller.dashboardData.value.orderData,
                      onDelete: () => _controller.cancelOpenOrderApp(
                        t.type ?? '',
                        t.id ?? 0,
                      ),
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

      String? iconFor(String? coinType) {
        if (coinType == null || coinType.isEmpty) return null;
        final upper = coinType.toUpperCase();
        if ((coinPair.childCoinName ?? '').toUpperCase() == upper)
          return coinPair.icon;
        if ((coinPair.parentCoinName ?? '').toUpperCase() == upper &&
            coinPair.parentIcon != null)
          return coinPair.parentIcon;
        for (final p in _controller.coinPairs) {
          if ((p.childCoinName ?? '').toUpperCase() == upper) return p.icon;
        }
        for (final p in _controller.coinPairs) {
          if ((p.parentCoinName ?? '').toUpperCase() == upper &&
              p.parentIcon != null)
            return p.parentIcon;
        }
        return _controller.coinIconMap[upper];
      }

      final tradePrice = tradeW?.lastPrice ?? 0.0;
      final basePrice =
          (baseW?.lastPrice ?? 0.0) > 0 ? (baseW?.lastPrice ?? 0.0) : 1.0;
      final tradeUsd = tradePrice > 0
          ? "\$${coinFormat((tradeW?.balance ?? 0) * tradePrice, fixed: 2)}"
          : null;
      final baseUsd =
          "\$${coinFormat((baseW?.balance ?? 0) * basePrice, fixed: 2)}";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "Current Assets" label — same left edge as tab chips ──────────
          Padding(
            padding: const EdgeInsets.only(left: _kHPad),
            child: const Text(
              "Current Assets",
              style: TextStyle(
                color: Color(0xFFC5C5C5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),

          if (baseW != null)
            _AssetCoinCard(
              coinType: baseW.coinType ?? "",
              coinIcon: iconFor(baseW.coinType),
              total: coinFormat(baseW.balance, fixed: tradeDecimal),
              available: coinFormat(baseW.balance, fixed: tradeDecimal),
              usdValue: baseUsd,
              coinPair: coinPair,
              controller: _controller,
            ),
          if (tradeW != null)
            _AssetCoinCard(
              coinType: tradeW.coinType ?? "",
              coinIcon: iconFor(tradeW.coinType),
              total: coinFormat(tradeW.balance, fixed: tradeDecimal),
              available: coinFormat(tradeW.balance, fixed: tradeDecimal),
              usdValue: tradeUsd,
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
    this.coinIcon,
    this.usdValue,
  });

  final String coinType;
  final String total;
  final String available;
  final dynamic coinPair;
  final SpotTradeController controller;
  final String? coinIcon;
  final String? usdValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // ✅ Same horizontal padding as tab row & list items
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Coin icon circle
                ClipOval(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: coinIcon != null && coinIcon!.isNotEmpty
                        ? Image.network(
                            coinIcon!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => _coinLetter(),
                          )
                        : _coinLetter(),
                  ),
                ),
                const SizedBox(width: 10),
                // Coin name
                Text(
                  coinType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                    height: 1.5,
                  ),
                ),
                const Spacer(),
               
                 Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.3),
                    size: 30,
                    
                  ),
                
              ],
            ),
          ),

          // ── Field rows ────────────────────────────────────────────────────
          _totalRow("Total", total, usdValue),
          _row("Available", available),
          const SizedBox(height: 8),

          // ── Action buttons ────────────────────────────────────────────────
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
                    final bal = controller.selfBalance.value.total;
                    final wallet =
                        coinType == (bal?.baseWallet?.coinType ?? "")
                        ? bal?.baseWallet
                        : bal?.tradeWallet;
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
          const SizedBox(height: 10),
          Divider(
            height: 0,
            thickness: 0.5,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC5C5C5),
              fontSize: 12,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w700,
              height: 1.066,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, String? usd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total",
            style: TextStyle(
              color: Color(0xFFC5C5C5),
              fontSize: 12,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w700,
                  height: 1.066,
                ),
              ),
              if (usd != null)
                Text(
                  usd,
                  style: const TextStyle(
                    color: Color(0xFFC5C5C5),
                    fontSize: 12,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coinLetter() {
    return Container(
      width: 20,
      height: 20,
      color: gBuyColor.withOpacity(0.2),
      child: Center(
        child: Text(
          coinType.isNotEmpty ? coinType[0] : "?",
          style: TextStyle(
            color: gBuyColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ACTION BUTTON
// ══════════════════════════════════════════════════════════════════════════════
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
          color: const Color(0xFF211B15),
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

// ══════════════════════════════════════════════════════════════════════════════
//  TAB CHIP
// ══════════════════════════════════════════════════════════════════════════════
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontFamily: "DMSans",
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

class _SpotTradeHistoryFullScreenState
    extends State<SpotTradeHistoryFullScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
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
            indicator: const BoxDecoration(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
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
          _OpenOrderFullView(controller: widget.controller),
          _OrderHistoryView(controller: widget.controller),
          _TradeHistoryView(controller: widget.controller),
          const _UpcomingStopLimitWidget(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 0: OPEN ORDER FULL VIEW
// ══════════════════════════════════════════════════════════════════════════════
class _OpenOrderFullView extends StatefulWidget {
  const _OpenOrderFullView({required this.controller});
  final SpotTradeController controller;

  @override
  State<_OpenOrderFullView> createState() => _OpenOrderFullViewState();
}

class _OpenOrderFullViewState extends State<_OpenOrderFullView> {
  List<Trade> _allList = [];
  List<Trade> _filteredList = [];
  bool _isFilterActive = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _allList =
          (widget.controller.allMyHistories.value.orders ?? []).cast<Trade>();

      if (_allList.isEmpty) {
        return handleEmptyViewWithLoading(
            widget.controller.isHistoryLoading.value);
      }

      final displayList = _isFilterActive ? _filteredList : _allList;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: _OpenOrderFilterBar(
              trades: _allList,
              currentBaseCoin:
                  widget.controller.dashboardData.value.orderData?.baseCoin ??
                      "",
              onFiltered: (filtered) {
                setState(() {
                  _filteredList = filtered;
                  _isFilterActive = true;
                });
              },
              onReset: () {
                setState(() {
                  _filteredList = [];
                  _isFilterActive = false;
                });
              },
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Text(
                      "No records found",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontFamily: "DMSans",
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) => _OpenOrderCard(
                      trade: displayList[i],
                      orderData:
                          widget.controller.dashboardData.value.orderData,
                      onDelete: () => widget.controller.cancelOpenOrderApp(
                        displayList[i].type ?? '',
                        displayList[i].id ?? 0,
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 1: ORDER HISTORY VIEW
// ══════════════════════════════════════════════════════════════════════════════
class _OrderHistoryView extends StatefulWidget {
  const _OrderHistoryView({required this.controller});
  final SpotTradeController controller;

  @override
  State<_OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<_OrderHistoryView> {
  List<Trade> _allList = [];
  List<Trade> _filteredList = [];
  bool _isFilterActive = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final buys = widget.controller.allMyHistories.value.buyOrders ?? [];
      final sells = widget.controller.allMyHistories.value.sellOrders ?? [];

      _allList = [...buys, ...sells].cast<Trade>();
      _allList.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      if (_allList.isEmpty) {
        return handleEmptyViewWithLoading(
            widget.controller.isHistoryLoading.value);
      }

      final displayList = _isFilterActive ? _filteredList : _allList;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: _OrderHistoryFilterBar(
              trades: _allList,
              currentBaseCoin:
                  widget.controller.dashboardData.value.orderData?.baseCoin ??
                      "",
              onFiltered: (filtered) {
                setState(() {
                  _filteredList = filtered;
                  _isFilterActive = true;
                });
              },
              onReset: () {
                setState(() {
                  _filteredList = [];
                  _isFilterActive = false;
                });
              },
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Text(
                      "No records found",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontFamily: "DMSans",
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) => SpotOrderHistoryItemView(
                      trade: displayList[i],
                      fromKey:
                          (displayList[i].type ?? "").toLowerCase() == "buy"
                              ? FromKey.buy
                              : FromKey.sell,
                      onCancel: (_) {},
                      orderData:
                          widget.controller.dashboardData.value.orderData,
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 2: TRADE HISTORY VIEW
// ══════════════════════════════════════════════════════════════════════════════
class _TradeHistoryView extends StatefulWidget {
  const _TradeHistoryView({required this.controller});
  final SpotTradeController controller;

  @override
  State<_TradeHistoryView> createState() => _TradeHistoryViewState();
}

class _TradeHistoryViewState extends State<_TradeHistoryView> {
  List<Trade> _allList = [];
  List<Trade> _filteredList = [];
  bool _isFilterActive = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _allList =
          (widget.controller.allMyHistories.value.transactions ?? [])
              .cast<Trade>();

      if (_allList.isEmpty) {
        return handleEmptyViewWithLoading(
            widget.controller.isHistoryLoading.value);
      }

      final displayList = _isFilterActive ? _filteredList : _allList;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: _TradeHistoryFilterBar(
              trades: _allList,
              currentBaseCoin:
                  widget.controller.dashboardData.value.orderData?.baseCoin ??
                      "",
              onFiltered: (filtered) {
                setState(() {
                  _filteredList = filtered;
                  _isFilterActive = true;
                });
              },
              onReset: () {
                setState(() {
                  _filteredList = [];
                  _isFilterActive = false;
                });
              },
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Text(
                      "No records found",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontFamily: "DMSans",
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) => SpotTraderHistoryItemView(
                      trade: displayList[i],
                      fromKey: FromKey.trade,
                      onCancel: (_) {},
                      orderData:
                          widget.controller.dashboardData.value.orderData,
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OPEN ORDER FILTER BAR
// ══════════════════════════════════════════════════════════════════════════════
class _OpenOrderFilterBar extends StatefulWidget {
  const _OpenOrderFilterBar({
    required this.trades,
    required this.currentBaseCoin,
    required this.onFiltered,
    required this.onReset,
  });

  final List<Trade> trades;
  final String currentBaseCoin;
  final Function(List<Trade>) onFiltered;
  final VoidCallback onReset;

  @override
  State<_OpenOrderFilterBar> createState() => _OpenOrderFilterBarState();
}

class _OpenOrderFilterBarState extends State<_OpenOrderFilterBar> {
  String? selectedPair;
  String? selectedType;

  void _applyFilters() {
    if (selectedPair == null && selectedType == null) {
      widget.onReset();
      return;
    }
    List<Trade> result = List.from(widget.trades);
    if (selectedPair != null) {
      result = result
          .where((t) =>
              (t.baseCoin ?? widget.currentBaseCoin).toUpperCase() ==
              selectedPair!.toUpperCase())
          .toList();
    }
    if (selectedType != null) {
      result = result
          .where((t) => selectedType == "Buy"
              ? (t.type ?? "").toLowerCase() == "buy"
              : (t.type ?? "").toLowerCase() == "sell")
          .toList();
    }
    widget.onFiltered(result);
  }

  void _showFilterDrawer({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterDrawer(
        title: title,
        options: options,
        selected: selected,
        onSelect: (val) {
          Navigator.pop(context);
          setState(() => onSelect(val));
          WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipBtn(
          label: "Pair",
          selected: selectedPair,
          onTap: () => _showFilterDrawer(
            title: "Select Pair",
            options: const ["USDT", "USDC", "BTC"],
            selected: selectedPair,
            onSelect: (v) => selectedPair = v,
          ),
        ),
        const SizedBox(width: 8),
        _FilterChipBtn(
          label: "Order Type",
          selected: selectedType,
          onTap: () => _showFilterDrawer(
            title: "Select Order Type",
            options: ["Buy", "Sell"],
            selected: selectedType,
            onSelect: (v) => selectedType = v,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ORDER HISTORY FILTER BAR
// ══════════════════════════════════════════════════════════════════════════════
class _OrderHistoryFilterBar extends StatefulWidget {
  const _OrderHistoryFilterBar({
    required this.trades,
    required this.currentBaseCoin,
    required this.onFiltered,
    required this.onReset,
  });

  final List<Trade> trades;
  final String currentBaseCoin;
  final Function(List<Trade>) onFiltered;
  final VoidCallback onReset;

  @override
  State<_OrderHistoryFilterBar> createState() => _OrderHistoryFilterBarState();
}

class _OrderHistoryFilterBarState extends State<_OrderHistoryFilterBar> {
  String? selectedPair;
  String? selectedType;
  String? selectedStatus;

  void _applyFilters() {
    if (selectedPair == null &&
        selectedType == null &&
        selectedStatus == null) {
      widget.onReset();
      return;
    }
    List<Trade> result = List.from(widget.trades);
    if (selectedPair != null) {
      result = result
          .where((t) =>
              (t.baseCoin ?? widget.currentBaseCoin).toUpperCase() ==
              selectedPair!.toUpperCase())
          .toList();
    }
    if (selectedType != null) {
      result = result
          .where((t) => selectedType == "Buy"
              ? (t.type ?? "").toLowerCase() == "buy"
              : (t.type ?? "").toLowerCase() == "sell")
          .toList();
    }
    if (selectedStatus != null) {
      result = result
          .where((t) =>
              selectedStatus == "Success" ? t.status == 1 : t.status != 1)
          .toList();
    }
    widget.onFiltered(result);
  }

  void _showFilterDrawer({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterDrawer(
        title: title,
        options: options,
        selected: selected,
        onSelect: (val) {
          Navigator.pop(context);
          setState(() => onSelect(val));
          WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipBtn(
          label: "Pair",
          selected: selectedPair,
          onTap: () => _showFilterDrawer(
            title: "Select Pair",
            options: ["USDT", "USDC", "BTC"],
            selected: selectedPair,
            onSelect: (v) => selectedPair = v,
          ),
        ),
        const SizedBox(width: 8),
        _FilterChipBtn(
          label: "Order Type",
          selected: selectedType,
          onTap: () => _showFilterDrawer(
            title: "Select Order Type",
            options: ["Buy", "Sell"],
            selected: selectedType,
            onSelect: (v) => selectedType = v,
          ),
        ),
        const SizedBox(width: 8),
        _FilterChipBtn(
          label: "Status",
          selected: selectedStatus,
          onTap: () => _showFilterDrawer(
            title: "Select Status",
            options: ["Success", "Pending"],
            selected: selectedStatus,
            onSelect: (v) => selectedStatus = v,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TRADE HISTORY FILTER BAR
// ══════════════════════════════════════════════════════════════════════════════
class _TradeHistoryFilterBar extends StatefulWidget {
  const _TradeHistoryFilterBar({
    required this.trades,
    required this.currentBaseCoin,
    required this.onFiltered,
    required this.onReset,
  });

  final List<Trade> trades;
  final String currentBaseCoin;
  final Function(List<Trade>) onFiltered;
  final VoidCallback onReset;

  @override
  State<_TradeHistoryFilterBar> createState() => _TradeHistoryFilterBarState();
}

class _TradeHistoryFilterBarState extends State<_TradeHistoryFilterBar> {
  String? selectedPair;
  String? selectedType;

  void _applyFilters() {
    if (selectedPair == null && selectedType == null) {
      widget.onReset();
      return;
    }
    List<Trade> result = List.from(widget.trades);
    if (selectedPair != null) {
      result = result
          .where((t) =>
              (t.baseCoin ?? widget.currentBaseCoin).toUpperCase() ==
              selectedPair!.toUpperCase())
          .toList();
    }
    if (selectedType != null) {
      result = result.where((t) {
        final typeRaw =
            ((t.type ?? t.priceOrderType)?.toLowerCase().trim()) ?? "";
        return selectedType == "Buy" ? typeRaw == "buy" : typeRaw == "sell";
      }).toList();
    }
    widget.onFiltered(result);
  }

  void _showFilterDrawer({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterDrawer(
        title: title,
        options: options,
        selected: selected,
        onSelect: (val) {
          Navigator.pop(context);
          setState(() => onSelect(val));
          WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipBtn(
          label: "Pair",
          selected: selectedPair,
          onTap: () => _showFilterDrawer(
            title: "Select Pair",
            options: const ["USDT", "USDC", "BTC"],
            selected: selectedPair,
            onSelect: (v) => selectedPair = v,
          ),
        ),
        const SizedBox(width: 8),
        _FilterChipBtn(
          label: "Order Type",
          selected: selectedType,
          onTap: () => _showFilterDrawer(
            title: "Select Order Type",
            options: ["Buy", "Sell"],
            selected: selectedType,
            onSelect: (v) => selectedType = v,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FILTER CHIP BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = selected != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ?? label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFD4F000)
                    : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive
                  ? const Color(0xFFD4F000)
                  : Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FILTER DRAWER
// ══════════════════════════════════════════════════════════════════════════════
class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _DrawerOption(
            label: "All",
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...options.map(
            (opt) => _DrawerOption(
              label: opt,
              isSelected: selected == opt,
              onTap: () => onSelect(opt),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DRAWER OPTION
// ══════════════════════════════════════════════════════════════════════════════
class _DrawerOption extends StatelessWidget {
  const _DrawerOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFD4F000)
                    : Colors.white.withOpacity(0.85),
                fontSize: 15,
                fontFamily: "DMSans",
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_rounded, color: Color(0xFFD4F000), size: 18),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OPEN ORDER CARD
// ══════════════════════════════════════════════════════════════════════════════
class _OpenOrderCard extends StatelessWidget {
  const _OpenOrderCard({
    required this.trade,
    required this.orderData,
    required this.onDelete,
  });

  final Trade trade;
  final OrderData? orderData;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBuy = (trade.type ?? "").toLowerCase() == "buy";
    final color = isBuy ? gBuyColor : gSellColor;
    final tradeCoin = trade.tradeCoin ?? orderData?.tradeCoin ?? "";
    final baseCoin = trade.baseCoin ?? orderData?.baseCoin ?? "";
    final rawType = trade.priceOrderType ?? "Limit";
    final orderTypeCap = rawType.isNotEmpty
        ? rawType[0].toUpperCase() + rawType.substring(1).toLowerCase()
        : "Limit";
    final typeLabel = "${isBuy ? "Buy" : "Sell"} $orderTypeCap";

    return Padding(
      // ✅ Same horizontal padding as tab row
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ROW 1: Coin pair + delete icon ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
            child: Row(
              children: [
                Text(
                  "$tradeCoin/$baseCoin",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // ✅ Delete icon — same size as history icon (20×20)
                GestureDetector(
                  onTap: onDelete,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      "assets/icons/delete.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── ROW 2: Type label + date ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: Row(
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.066,
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(trade.createdAt,
                      format: dateTimeFormatYyyyMMDdHhMm),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          // ── Field rows ────────────────────────────────────────────────────
          _row("Amount ($tradeCoin)", coinFormat(trade.amount)),
          _row("Fee ($baseCoin)", coinFormat(trade.fees)),
          _row("Price ($baseCoin)", coinFormat(trade.price)),
          _row("Processed ($tradeCoin)", coinFormat(trade.processed)),
          _row("Total ($baseCoin)", coinFormat(trade.total)),
          const SizedBox(height: 10),
          Divider(
              height: 0,
              thickness: 0.5,
              color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                )),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                  height: 1.066,
                )),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  UPCOMING STOP LIMIT
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
            child:
                const Icon(Icons.price_change_rounded, color: _labelClr, size: 40),
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
//  SPOT ORDER HISTORY CARD
// ══════════════════════════════════════════════════════════════════════════════
class SpotOrderHistoryItemView extends StatelessWidget {
  const SpotOrderHistoryItemView({
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
    final isBuy = (trade.type ?? "").toLowerCase() == "buy";
    final color = isBuy ? gBuyColor : gSellColor;
    final tradeCoin = orderData?.tradeCoin ?? "";
    final baseCoin = orderData?.baseCoin ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
            child: Row(
              children: [
                Text(
                  "$tradeCoin/$baseCoin",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(trade.createdAt,
                          format: dateTimeFormatYyyyMMDdHhMm) ??
                      "",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              isBuy ? "Buy" : "Sell",
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 1.066,
              ),
            ),
          ),
          _row("Amount ($tradeCoin)", coinFormat(trade.amount)),
          _row("Price ($baseCoin)", coinFormat(trade.price)),
           _row("Fee ($baseCoin)", coinFormat(trade.fees)),
          if (fromKey != FromKey.trade)
            _row("Total ($baseCoin)", coinFormat(trade.total)),
          if (fromKey == FromKey.trade)
            _row("TX ID", _trimTxId(trade.transactionId?.toString())),
          _statusRow(trade.status),
          const SizedBox(height: 10),
          Divider(
              height: 0,
              thickness: 0.5,
              color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  String _trimTxId(String? id) {
    if (id == null || id.isEmpty) return "—";
    if (id.length <= 8) return id;
    return "${id.substring(0, 4)}....${id.substring(id.length - 4)}";
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                )),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                  height: 1.066,
                )),
          ],
        ),
      );

  Widget _statusRow(int? status) {
    final bool isSuccess = status == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text("Status",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400,
                height: 1.33,
              )),
          const Spacer(),
          Text(
            isSuccess ? "Success" : "Pending",
            style: TextStyle(
              color: isSuccess
                  ? const Color(0xFF00B052)
                  : const Color(0xFFD4F000),
              fontSize: 15,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w400,
              height: 1.066,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SPOT TRADE HISTORY CARD
// ══════════════════════════════════════════════════════════════════════════════
class SpotTraderHistoryItemView extends StatelessWidget {
  const SpotTraderHistoryItemView({
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
    final isBuy =
        ((trade.type ?? trade.priceOrderType) ?? "").toLowerCase() == "buy";
    final tradeCoin = orderData?.tradeCoin ?? "";
    final baseCoin = orderData?.baseCoin ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
            child: Row(
              children: [
                Text(
                  "$tradeCoin/$baseCoin",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(trade.createdAt,
                          format: dateTimeFormatYyyyMMDdHhMm) ??
                      "",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              isBuy ? "Buy" : "Sell",
              style: TextStyle(
                color: isBuy ? gBuyColor : gSellColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 1.066,
              ),
            ),
          ),
          // Order No. with copy
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Text("Order No.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    )),
                const Spacer(),
                Text(
                  trimTransactionId(trade.transactionId?.toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 1.066,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text: trade.transactionId?.toString() ?? ""));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Order No. copied"),
                        duration: const Duration(seconds: 1),
                        backgroundColor: const Color(0xFF1A1A1A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  child: Image.asset("assets/icons/copy.png",
                      width: 14, height: 14),
                ),
              ],
            ),
          ),
          _row("Price ($baseCoin)", coinFormat(trade.price)),
          _row("Amount ($tradeCoin)", coinFormat(trade.amount)),
          _row("Fee ($baseCoin)", coinFormat(trade.fees)),
          _row("Total ($baseCoin)", coinFormat(trade.total)),
          const SizedBox(height: 10),
          Divider(
              height: 0,
              thickness: 0.5,
              color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                )),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                  height: 1.066,
                )),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  HELPER
// ══════════════════════════════════════════════════════════════════════════════
String trimTransactionId(String? id) {
  if (id == null || id.length <= 8) return id ?? "—";
  return "${id.substring(0, 4)}....${id.substring(id.length - 4)}";
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
                Text("$tradeCoin/$baseCoin",
                    style: const TextStyle(
                        color: _valueClr,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Text(
                    "${(trade.type ?? '').toUpperCase()} Stop Limit",
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onCancel(trade),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 16),
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