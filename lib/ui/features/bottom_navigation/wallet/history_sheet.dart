import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/future_trade/future_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/future_trade/future_widgets.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/spot_trade/spot_trade_controller.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/spot_trade/spot_trade_history_views.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transaction_history_screen.dart';

class HistorySheet extends StatefulWidget {
  const HistorySheet({super.key});

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  int _tab = 0;

  static const _bg = Color(0xFF111111);
  static const _font = 'DM Sans';
  static const _tabs = ['Crypto Asset', 'Spot', 'Future'];

  List<_SheetItem> get _items {
    if (_tab == 0) return [
      _SheetItem('assets/icons/hist-deposit.png',  'Deposit History',    () { Get.back(); Get.to(() => const TransactionHistoryScreen(initialTab: 'deposit')); }),
      _SheetItem('assets/icons/hist-withdraw.png', 'Withdraw History',   () { Get.back(); Get.to(() => const TransactionHistoryScreen(initialTab: 'withdraw')); }),
      _SheetItem('assets/icons/hist-transfer.png', 'Transfer History',   () { Get.back(); Get.to(() => const TransactionHistoryScreen(initialTab: 'transfer')); }),
      _SheetItem('assets/icons/hist-swap.png',     'Swap History',       () { Get.back(); Get.to(() => const TransactionHistoryScreen(initialTab: 'swap')); }),
    ];
    if (_tab == 1) return [
      _SheetItem('assets/icons/open_order.png',          'Open Orders',         () { Get.back(); _goSpot(0); }),
      _SheetItem('assets/icons/order_history.png',       'Order History',       () { Get.back(); _goSpot(1); }),
      _SheetItem('assets/icons/transaction_history.png', 'Transaction History', () { Get.back(); _goSpot(2); }),
      _SheetItem('assets/icons/stop_limit.png',          'Stop Limit History',  () { Get.back(); _goSpot(3); }),
    ];
    return [
      _SheetItem('assets/icons/open_order.png',       'Open Orders',        () { Get.back(); _goFuture(0); }),
      _SheetItem('assets/icons/order_history.png',    'Order History',      () { Get.back(); _goFuture(1); }),
      _SheetItem('assets/icons/stop_limit.png',       'Stop Limit History', () { Get.back(); _goFuture(2); }),
      _SheetItem('assets/icons/position_history.png', 'Position History',   () { Get.back(); _goFuture(3); }),
    ];
  }

  void _goSpot(int index) {
    final ctrl = Get.isRegistered<SpotTradeController>()
        ? Get.find<SpotTradeController>()
        : Get.put(SpotTradeController());
    Get.to(() => SpotTradeHistoryFullScreen(controller: ctrl, initialIndex: index));
  }

  void _goFuture(int index) {
    final ctrl = Get.isRegistered<NewFutureController>()
        ? Get.find<NewFutureController>()
        : Get.put(NewFutureController());
    Get.to(() => FutureHistoryFullScreen(ctrl: ctrl, pair: null, pp: 2, initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('History', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.50)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = _tab == i;
                return GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 24 : 0),
                    child: Text(
                      _tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white.withOpacity(0.50),
                        fontSize: 16,
                        fontFamily: _font,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          ...items.map((item) => GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Image.asset(item.icon, width: 20, height: 20),
                  const SizedBox(width: 20),
                  Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.25)),
                ],
              ),
            ),
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

void showHistorySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF111111),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    isScrollControlled: true,
    builder: (_) => const HistorySheet(),
  );
}

class _SheetItem {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _SheetItem(this.icon, this.label, this.onTap);
}
