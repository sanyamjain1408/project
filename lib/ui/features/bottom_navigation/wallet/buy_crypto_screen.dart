import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transaction_history_screen.dart';

const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _white = Colors.white;
const _green = Color(0xFF00B052);
const _red = Color(0xFFD63B3B);
const _font = 'DMSans';

class BuyCryptoScreen extends StatefulWidget {
  const BuyCryptoScreen({super.key, this.startWithSell = false});
  final bool startWithSell;

  @override
  State<BuyCryptoScreen> createState() => _BuyCryptoScreenState();
}

class _BuyCryptoScreenState extends State<BuyCryptoScreen>
    with SingleTickerProviderStateMixin {
  late bool _isBuy;
  String _amount = '0';
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _isBuy = !widget.startWithSell;
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        _amount = _amount == '0' ? key : _amount + key;
      }
    });
  }

  // Format number with Indian commas (e.g. 1,00,000)
  String _formatAmount(String raw) {
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    if (intPart.length <= 3) return raw;
    final result = StringBuffer();
    final extra = (intPart.length - 3) % 2;
    int i = 0;
    if (extra > 0) {
      result.write(intPart.substring(0, extra));
      result.write(',');
      i = extra;
    }
    while (i < intPart.length - 3) {
      result.write(intPart.substring(i, i + 2));
      result.write(',');
      i += 2;
    }
    result.write(intPart.substring(i));
    return result.toString() + decPart;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isBuy ? Color(0xFFCCFF00) : _red;
    final convertLabel = _isBuy ? 'USDT' : 'INR';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        leadingWidth: 48,
        title: Text(
          _isBuy ? 'Buy Crypto' : 'Sell Crypto',
          style: const TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _font,
            height: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Get.to(() => const TransactionHistoryScreen(initialTab: 'deposit')),
              child: RotationTransition(
                turns: _spinCtrl,
                child: Image.asset(
                  'assets/icons/time.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, e, s) =>
                      const Icon(Icons.history, color: _white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _BuySellToggle(
                  isBuy: _isBuy,
                  onChanged: (v) => setState(() {
                    _isBuy = v;
                    _amount = '0';
                  }),
                ),
                const SizedBox(height: 24),
                // ── Amount ────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatAmount(_amount),
                                style: const TextStyle(
                                  color: _white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: _font,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'INR',
                                style: TextStyle(
                                  color: _white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                  fontFamily: _font,
                                  height: 1.5,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: _white.withValues(alpha: 0.5), size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      
                      children: [
                        Image.asset(
                          'assets/images/uu.png',
                          width: 18,
                          height: 18,
                          color: accentColor,
                          errorBuilder: (_, e, s) =>
                              Icon(Icons.swap_horiz, color: accentColor, size: 22),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          convertLabel,
                          style: TextStyle(
                            color: _white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontFamily: _font,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Limit ────────────────────────────────────────────────
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Limit 10 - 5,000 USDT\n',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                      TextSpan(
                        text: 'Need higher limits?',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _font,
                          decoration: TextDecoration.underline,
                          decorationColor: _white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Push coin/payment/button to bottom ───────────────────────────
          const Spacer(),

          // ── Coin row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CoinRow(isBuy: _isBuy),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: _white.withValues(alpha: 0.1), height: 1),
          ),
          // ── Payment row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PaymentRow(isBuy: _isBuy),
          ),

          // ── Preview Order button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Preview Order',
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontFamily: _font,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          // ── Numpad ───────────────────────────────────────────────────────
          _Numpad(onKey: _onKey),
        ],
      ),
    );
  }
}

// ── Buy/Sell Toggle ───────────────────────────────────────────────────────────
class _BuySellToggle extends StatelessWidget {
  const _BuySellToggle({required this.isBuy, required this.onChanged});
  final bool isBuy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 30,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _tab('Buy', isBuy, _green, () => onChanged(true)),
          _tab('Sell', !isBuy, _red, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, Color activeColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: _white,
              fontSize: 15,
              fontFamily: _font,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Coin Row ──────────────────────────────────────────────────────────────────
class _CoinRow extends StatelessWidget {
  const _CoinRow({required this.isBuy});
  final bool isBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Image.asset(
            'assets/images/usdt.png',
            width: 30,
            height: 30,
            errorBuilder: (_, e, s) => Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF50AF95),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('T',
                  style: TextStyle(
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBuy ? 'Buy' : 'Sell',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: _font,
                ),
              ),
              const Text(
                'USDT',
                style: TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontFamily: _font,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!isBuy)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Available',
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: _font,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      '0 USDT',
                      style: TextStyle(
                        color: _white,
                        fontSize: 16,
                        fontFamily: _font,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: _white.withValues(alpha: 0.5), size: 18),
                  ],
                ),
              ],
            )
          else
            Icon(Icons.chevron_right,
                color: Color(0xFFCCFF00), size: 18),
        ],
      ),
    );
  }
}

// ── Payment/Receiving Method Row ──────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.isBuy});
  final bool isBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Image.asset(
            isBuy ? 'assets/images/upi.png' : 'assets/icons/deposit.png',
            width: 30,
            height: 30,
            errorBuilder: (_, e, s) => Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: _white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('U',
                  style: TextStyle(
                      color: _bg,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBuy ? 'Payment Method' : 'Receiving Method',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: _font,
                ),
              ),
              Text(
                isBuy ? 'UPI' : 'Select Payment Method',
                style: TextStyle(
                  color: isBuy ? _white : _white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontFamily: _font,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right,
              color: Color(0xFFCCFF00), size: 18),
        ],
      ),
    );
  }
}

// ── Numpad ────────────────────────────────────────────────────────────────────
class _Numpad extends StatelessWidget {
  const _Numpad({required this.onKey});
  final ValueChanged<String> onKey;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: _keys.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => onKey(key),
                  child: SizedBox(
                    height: 68,
                    child: Center(
                      child: key == '⌫'
                          ? const Icon(Icons.backspace_outlined,
                              color: _white, size: 22)
                          : Text(
                              key,
                              style: const TextStyle(
                                color: _white,
                                fontSize: 20,
                                fontFamily: _font,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
