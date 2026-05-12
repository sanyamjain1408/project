import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'dual_investment_controller.dart';

// ─── coin icon helper ─────────────────────────────────────────────────────────
Widget _coinIcon(String? url, {double size = 28}) {
  if (url != null && url.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(size),
      ),
    );
  }
  return _fallback(size);
}

Widget _fallback(double size) => Container(
  width: size,
  height: size,
  decoration: const BoxDecoration(
    shape: BoxShape.circle,
    color: Color(0xFF26A17B),
  ),
  child: const Icon(Icons.monetization_on, color: Colors.white, size: 14),
);

// ─── DualSubscribeModal ───────────────────────────────────────────────────────
class DualSubscribeModal extends StatefulWidget {
  final DualProduct product;
  final DualInvestmentController controller;

  const DualSubscribeModal({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<DualSubscribeModal> createState() => _DualSubscribeModalState();
}

class _DualSubscribeModalState extends State<DualSubscribeModal> {
  final _amountCtrl = TextEditingController();
  bool _agreed = false;

  // active tab: 0 = Buy Low, 1 = Sell High  (driven by product.strategy)
  late int _activeStrategy; // 0 = buy_low, 1 = sell_high

  DualProduct get _p => widget.product;
  bool get _isBuyLow => _activeStrategy == 0;
  Color get _stratColor =>
      _isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900);
  double get _balance => widget.controller.balances[_p.depositCoin] ?? 0;
  double get _amountNum => double.tryParse(_amountCtrl.text) ?? 0;
  double get _yieldRate => _p.apr * _p.termDays / 365 / 100;

  @override
  void initState() {
    super.initState();
    _activeStrategy = _p.strategy == 'buy_low' ? 0 : 1;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _handleSubscribe() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar(
        'Error',
        'Enter an amount',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (amount < _p.minAmount) {
      Get.snackbar(
        'Error',
        'Minimum is ${coinFormat(_p.minAmount)} ${_p.depositCoin}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (!_agreed) {
      Get.snackbar(
        'Error',
        'Please agree to the terms',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final success = await widget.controller.subscribe(_p.id, amount);
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF111111)),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── App-bar style header: "← USDT Subscribe  [tag]" ──────────
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        _coinIcon(widget.product.coinIcon, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          "${_p.depositCoin} Suscribe",
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
                  ),
                  const SizedBox(width: 5),
                 Text(
                      _isBuyLow ? "Buy Low" : "Sell High",
                      style: TextStyle(
                        color: _stratColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: "DMSans",
                        height: 24 / 12,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20,),
            

            // ── Stats row: Target Price / EST. APR / Yield Rate ───────────
            Row(
              children: [
                _statBox(
                  "Target Price",
                  "\$${_p.targetPrice.toStringAsFixed(4)}",
                  Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 10),
                _statBox(
                  "EST. APR",
                  "${_p.apr.toStringAsFixed(2)}%",
                  Color(0xFF00B052),
                ),
                const SizedBox(width: 10),
                _statBox(
                  "Yield Rate",
                  "${(_yieldRate * 100).toStringAsFixed(4)}%",
                  const Color(0xFFCCFF00),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Info box ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("💡 ", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                  Expanded(
                    child: Text(
                      _isBuyLow
                          ? "Deposit ${_p.quoteCoin} (USDT). If ${_p.baseCoin} price hits target → receive ${_p.baseCoin} + interest. Otherwise → you keep ${_p.quoteCoin} interest."
                          : "Deposit ${_p.depositCoin} (USDT). If ${_p.baseCoin} price hits target → receive ${_p.baseCoin} + interest. Otherwise → you keep ${_p.depositCoin} interest.",
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontFamily: "DMSans",
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Amount label ──────────────────────────────────────────────
            const Text(
              "Amount",
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                 fontFamily: "DMSans",
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: 10),

            // ── Amount input ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                         fontSize: 16,
                         fontWeight: FontWeight.w700,
                         fontFamily: "DMSans",
                         height: 24 / 16,
                         ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "${coinFormat(_p.minAmount)} Minimum",
                        hintStyle:  TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _amountCtrl.text = coinFormat(_balance);
                      setState(() {});
                    },
                    child: Text(
                        "Max",
                        style: TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 15,
                           fontFamily: "DMSans",
                          fontWeight: FontWeight.w600,
                          height: 20 / 15,
                        ),
                      ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10,right: 20),
                    child: Text(
                      _p.depositCoin,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                         fontFamily: "DMSans",
                         height: 20 / 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Maximum",
                  style:  TextStyle(
                    color: Colors.white.withOpacity(0.5),
                     fontFamily: "DMSans",
                     height: 20 / 15,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  "Balance",
                  style:  TextStyle(
                    color: Colors.white.withOpacity(0.5),
                     fontFamily: "DMSans",
                     height: 20 / 15,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${coinFormat(_p.maxAmount)} ${_p.depositCoin}",
                  style:  TextStyle(
                    color: Colors.white.withOpacity(0.5),
                     fontFamily: "DMSans",
                     height: 26 / 12,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  "${coinFormat(_balance)}",
                  style:  TextStyle(
                    color: Colors.white.withOpacity(0.5),
                     fontFamily: "DMSans",
                     height: 26 / 12,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ── Agreement ──────────────────────────────────────────────────
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
                        color: _agreed ? _stratColor : Colors.white,
                        width: 2,
                      ),
                      color: _agreed ? _stratColor : Colors.transparent,
                    ),
                    child: _agreed
                        ? Icon(
                            Icons.check,
                            size: 12,
                            color: _isBuyLow ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 16/12,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          const TextSpan(text: "I have read and agree to "),
                          TextSpan(
                            text: "Trapix Earn User Agreement",
                            style: TextStyle(color: Color(0XFFCCFF00),
                             fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                              height: 16/12,
                              fontSize: 12
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

            // ── Buy Low / Sell High action buttons ────────────────────────
            // (Image 8: Buy Low highlighted cyan, Sell High outline)
            // (Image 9: Sell High highlighted orange, Buy Low outline)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _activeStrategy = 0;
                    }),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isBuyLow
                            ? const Color(0xFF00E5FF)
                            : Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isBuyLow
                              ? Colors.transparent
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Buy Low",
                          style: TextStyle(
                            color: _isBuyLow
                                ?  const Color(0xFF111111)
                                : Colors.white,
                            fontSize: 16,
                             fontFamily: "DMSans",
                             height: 24 / 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeStrategy = 1;
                      });
                      // If they hit "Sell High" and agreed+amount filled → subscribe
                      if (_agreed && _amountNum > 0 && !_isBuyLow)
                        _handleSubscribe();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: !_isBuyLow
                            ? const Color(0xFFFF9900)
                            : Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_isBuyLow
                              ? Colors.transparent
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Sell High",
                          style: TextStyle(
                            color: !_isBuyLow
                                ? const Color(0xFF111111)
                                : Colors.white,
                            fontSize: 16,
                            fontFamily: "DMSans",
                            height: 24 / 16,
                            fontWeight: FontWeight.w400,
                          ),
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
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                 fontSize: 12,
                 fontWeight: FontWeight.w400,
                 fontFamily: "DMSans",
                 height: 24 / 12,
                 ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 24 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
