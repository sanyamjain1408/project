import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'earn_controller.dart';

class EarnSubscribeModal extends StatefulWidget {
  final EarnProduct product;

  const EarnSubscribeModal({super.key, required this.product});

  @override
  State<EarnSubscribeModal> createState() => _EarnSubscribeModalState();
}

class _EarnSubscribeModalState extends State<EarnSubscribeModal> {
  final _controller = Get.find<EarnController>();
  final _amountController = TextEditingController();
  bool _agreed = false;
  bool _autoReinvest = false;

  double get _balance => _controller.balances[widget.product.coin] ?? 0;
  double get _amountNum => double.tryParse(_amountController.text) ?? 0;
  double get _dailyProfit => _amountNum > 0 ? (_amountNum * widget.product.apr) / 100 / 365 : 0;
  double get _totalProfit => widget.product.lockDays > 0 ? _dailyProfit * widget.product.lockDays : 0;
  bool get _isFixed => widget.product.lockDays > 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubscribe() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar('Error', 'Please enter an amount', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (amount < widget.product.minAmount) {
      Get.snackbar('Error', 'Minimum amount is ${coinFormat(widget.product.minAmount)} ${widget.product.coin}',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (amount > widget.product.maxAmount) {
      Get.snackbar('Error', 'Maximum amount is ${coinFormat(widget.product.maxAmount)} ${widget.product.coin}',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (!_agreed) {
      Get.snackbar('Error', 'Please agree to the terms', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final success = await _controller.subscribe(
      productId: widget.product.id,
      amount: amount,
      autoReinvest: _isFixed ? _autoReinvest : false,
    );
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final planLabel = widget.product.lockDays == 0 ? 'Flexible' : '${widget.product.lockDays} Days Fixed';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
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
                      const Text('EASY EARN', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(widget.product.coin, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Plan Badge ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB5F000).withOpacity(0.5)),
              ),
              child: Text(planLabel, style: const TextStyle(color: Color(0xFFB5F000), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // ── Amount Input ──
            const Text('Amount', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2128)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Min ${coinFormat(widget.product.minAmount)}',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _amountController.text = _balance.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFB5F000).withOpacity(0.3)),
                      ),
                      child: const Text('MAX', style: TextStyle(color: Color(0xFFB5F000), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(widget.product.coin, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Max ${coinFormat(widget.product.maxAmount)} ${widget.product.coin}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                Text('Available ${coinFormat(_balance)}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Profit Box ──
            Row(
              children: [
                _profitBox('APR', '${widget.product.apr.toStringAsFixed(2)}%'),
                const SizedBox(width: 8),
                _profitBox('Daily Est.', '+${_formatProfit(_dailyProfit)} ${widget.product.coin}'),
                const SizedBox(width: 8),
                _isFixed
                    ? _profitBox('Total Est.', '+${_formatProfit(_totalProfit)} ${widget.product.coin}')
                    : _profitBox('Redeem', 'Any time'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Auto Re-invest Toggle (Fixed plans only) ──
            if (_isFixed)
              GestureDetector(
                onTap: () => setState(() => _autoReinvest = !_autoReinvest),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _autoReinvest ? const Color(0xFFB5F000).withOpacity(0.6) : const Color(0xFF1E2128),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔄 Auto Re-invest',
                              style: TextStyle(
                                color: _autoReinvest ? const Color(0xFFB5F000) : const Color(0xFFB0B8C1),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'When this ${widget.product.lockDays}-day plan completes, principal + interest automatically restarts the same plan',
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Toggle Switch
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _autoReinvest ? const Color(0xFFB5F000) : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              top: 3,
                              left: _autoReinvest ? 23 : 3,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _autoReinvest ? Colors.black : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isFixed) const SizedBox(height: 16),

            // ── Agreement ──
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _agreed ? const Color(0xFFB5F000) : const Color(0xFF333333), width: 2),
                      color: _agreed ? const Color(0xFFB5F000) : Colors.transparent,
                    ),
                    child: _agreed ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Trapix Earn User Agreement.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Subscribe Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_agreed && _amountNum > 0) ? _handleSubscribe : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5F000),
                  disabledBackgroundColor: const Color(0xFF222222),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Subscribe',
                  style: TextStyle(
                    color: (_agreed && _amountNum > 0) ? Colors.black : const Color(0xFF555555),
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

  Widget _profitBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2128)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  String _formatProfit(double val) {
    if (val <= 0) return '0.00';
    return val.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}