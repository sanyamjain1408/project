import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'dual_investment_controller.dart';

class DualSubscribeModal extends StatefulWidget {
  final DualProduct             product;
  final DualInvestmentController controller;

  const DualSubscribeModal({super.key, required this.product, required this.controller});

  @override
  State<DualSubscribeModal> createState() => _DualSubscribeModalState();
}

class _DualSubscribeModalState extends State<DualSubscribeModal> {
  final _amountController = TextEditingController();
  bool _agreed = false;

  DualProduct get _p => widget.product;
  bool get _isBuyLow => _p.strategy == 'buy_low';
  Color get _stratColor => _isBuyLow ? const Color(0xFF00CCFF) : const Color(0xFFFF9900);
  double get _balance => widget.controller.balances[_p.depositCoin] ?? 0;
  double get _amountNum => double.tryParse(_amountController.text) ?? 0;
  double get _yieldRate => _p.apr * _p.termDays / 365 / 100;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubscribe() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) { Get.snackbar('Error', 'Enter an amount', backgroundColor: Colors.red, colorText: Colors.white); return; }
    if (amount < _p.minAmount) { Get.snackbar('Error', 'Minimum is ${coinFormat(_p.minAmount)} ${_p.depositCoin}', backgroundColor: Colors.red, colorText: Colors.white); return; }
    if (!_agreed) { Get.snackbar('Error', 'Please agree to the terms', backgroundColor: Colors.red, colorText: Colors.white); return; }
    final success = await widget.controller.subscribe(_p.id, amount);
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_p.baseCoin}/${_p.quoteCoin} · ${_isBuyLow ? '📉 Buy Low' : '📈 Sell High'}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Expiry: ${_p.expiryDate} · ${_p.termDays} day${_p.termDays > 1 ? 's' : ''}',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close, color: Color(0xFF6B7280))),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stats Row ──
            Row(
              children: [
                _statBox('Target Price', '\$${_p.targetPrice.toStringAsFixed(0)}', Colors.white),
                const SizedBox(width: 8),
                _statBox('Est. APR', '${_p.apr.toStringAsFixed(2)}%', const Color(0xFF00FF88)),
                const SizedBox(width: 8),
                _statBox('Yield Rate', '${(_yieldRate * 100).toStringAsFixed(4)}%', const Color(0xFFB5F000)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Info Box ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: _stratColor, width: 3)),
              ),
              child: Text(
                _isBuyLow
                    ? '💰 Deposit ${_p.quoteCoin}. If ${_p.baseCoin} hits target → receive ${_p.baseCoin} + interest. Otherwise → keep ${_p.quoteCoin} + interest.'
                    : '💰 Deposit ${_p.baseCoin}. If ${_p.baseCoin} hits target → receive ${_p.quoteCoin} + interest. Otherwise → keep ${_p.baseCoin} + interest.',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.5),
              ),
            ),
            const SizedBox(height: 14),

            // ── Amount Input ──
            const Text('Amount', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2A2A))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '${_p.minAmount} Minimum',
                        hintStyle: const TextStyle(color: Color(0xFF555555)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  GestureDetector(
                    onTap: () { _amountController.text = coinFormat(_balance); setState(() {}); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: const Color(0xFF333333)), borderRadius: BorderRadius.circular(6)),
                      child: Text('Max', style: TextStyle(color: _stratColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Max ${coinFormat(_p.maxAmount)} ${_p.depositCoin}', style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
                Text('Balance ${coinFormat(_balance)}', style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Agreement ──
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _agreed ? _stratColor : const Color(0xFF444444), width: 2),
                      color: _agreed ? _stratColor : Colors.transparent,
                    ),
                    child: _agreed ? Icon(Icons.check, size: 12, color: _isBuyLow ? Colors.black : Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'I have read and agree to Trapix Earn User Agreement',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Subscribe Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_agreed && _amountNum > 0) ? _handleSubscribe : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_agreed && _amountNum > 0) ? _stratColor : const Color(0xFF333333),
                  disabledBackgroundColor: const Color(0xFF333333),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  _isBuyLow ? 'Buy Low' : 'Sell High',
                  style: TextStyle(
                    color: (_agreed && _amountNum > 0) ? (_isBuyLow ? Colors.black : Colors.white) : const Color(0xFF666666),
                    fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2A2A))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}