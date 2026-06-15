import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/currency.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/transaction_history_screen.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';

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

class _BuyCryptoScreenState extends State<BuyCryptoScreen> {
  late bool _isBuy;
  String _amount = '0';
  Currency? _selectedCoin;
  String _balance = '0';

  @override
  void initState() {
    super.initState();
    _isBuy = !widget.startWithSell;
    _loadDefaultCoin();
  }

  void _loadDefaultCoin() {
    APIRepository().getCoinList(currencyType: 1).then((resp) {
      if (resp.success && resp.data != null) {
        final list = List<Currency>.from(
          resp.data!.map((x) => Currency.fromJson(x)),
        );
        final usdt = list.firstWhere(
          (c) => (c.coinType ?? '').toUpperCase() == 'USDT',
          orElse: () => list.isNotEmpty ? list.first : Currency(),
        );
        if (mounted) {
          setState(() => _selectedCoin = usdt);
          _loadBalance(usdt.coinType ?? '');
        }
      }
    });
  }

  void _loadBalance(String coinType) {
    if (coinType.isEmpty) return;
    APIRepository().getWalletNetworks(coinType, TransferType.withdraw).then((resp) {
      if (resp.success && resp.data != null) {
        final networks = CurrencyNetworks.fromJson(resp.data);
        final bal = networks.wallet?.balance ?? 0.0;
        if (mounted) setState(() => _balance = bal.toStringAsFixed(4));
      }
    });
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
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

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _font,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    'Est. Received',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: _font,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: _font,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodCard(
                      icon: 'assets/images/upi.png',
                      title: 'Pay via instant UPI',
                      subtitle: 'Deposit from your registered Bank A/c Only',
                      extraIcons: [
                        'assets/images/ppay.png',
                        'assets/images/gpay.png',
                      ],
                      limit: 'Min. \$ 100 - Max. \$ 1,00,000',
                      fees: '0%',
                      processingTime: 'Within 5 Minutes*',
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodCard(
                      icon: 'assets/images/visa.png',
                      title: 'Pay via Bank Card',
                      limit: 'Min. \$ 100 - Max. \$ 1,00,000',
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Other Method',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: _font,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodCard(
                      icon: 'assets/images/bank.png',
                      title: 'Instant Bank Transfer',
                      limit: 'Min. \$ 100 - Max. \$ 1,00,000',
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodCard(
                      icon: 'assets/images/bank.png',
                      title: 'Fast Bank Transfer - IMPS',
                      limit: 'Min. \$ 100 - Max. \$ 1,00,000',
                      disabled: true,
                      disabledLabel: 'Temporarily Disabled',
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoinSheet() {
    final RxList<Currency> coins = <Currency>[].obs;
    final RxBool loading = true.obs;

    APIRepository().getCoinList(currencyType: 1).then((resp) {
      loading.value = false;
      if (resp.success && resp.data != null) {
        final list = List<Currency>.from(
          resp.data!.map((x) => Currency.fromJson(x)),
        );
        coins.value = list;
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                _isBuy ? 'Asset to Buy' : 'Asset to Sell',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: _font,
                  height: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (loading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFCCFF00)),
                  );
                }
                if (coins.isEmpty) {
                  return Center(
                    child: Text(
                      'No coins found',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: _font,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: coins.length,
                  itemBuilder: (_, i) {
                    final coin = coins[i];
                    final symbol = coin.coinType ?? '';
                    final name = coin.name ?? symbol;
                    final isSelected = _selectedCoin?.coinType == symbol;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCoin = coin;
                          _balance = '0';
                        });
                        _loadBalance(coin.coinType ?? '');
                        Navigator.pop(context);
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            ClipOval(
                              child: showImageNetwork(
                                imagePath: coin.coinIcon,
                                width: 32,
                                height: 32,
                                bgColor: Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    symbol,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: _font,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                      fontFamily: _font,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Color(0xFFCCFF00),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isBuy ? Color(0xFFCCFF00) : Color(0xFFCCFF00);
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
            child: _SpinningTimeIcon(
              onTap: () => Get.to(
                () => const TransactionHistoryScreen(initialTab: 'deposit'),
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
                              Icon(
                                Icons.arrow_drop_down,
                                color: _white.withValues(alpha: 0.5),
                                size: 20,
                              ),
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
                          errorBuilder: (_, e, s) => Icon(
                            Icons.swap_horiz,
                            color: accentColor,
                            size: 22,
                          ),
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
                          color: Color(0xFFCCFF00),
                          fontSize: 12,
                          fontFamily: _font,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFCCFF00),
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
          GestureDetector(
            onTap: _showCoinSheet,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CoinRow(isBuy: _isBuy, selectedCoin: _selectedCoin, balance: _balance),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: _white.withValues(alpha: 0.1), height: 1),
          ),
          // ── Payment row ──────────────────────────────────────────────────
          GestureDetector(
            onTap: _showPaymentSheet,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PaymentRow(isBuy: _isBuy),
            ),
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

  Widget _tab(
    String label,
    bool active,
    Color activeColor,
    VoidCallback onTap,
  ) {
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
  const _CoinRow({required this.isBuy, this.selectedCoin, this.balance = '0'});
  final bool isBuy;
  final Currency? selectedCoin;
  final String balance;

  @override
  Widget build(BuildContext context) {
    final symbol = selectedCoin?.coinType ?? 'USDT';
    final iconUrl = selectedCoin?.coinIcon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ClipOval(
            child: showImageNetwork(
              imagePath: iconUrl,
              width: 30,
              height: 30,
              bgColor: Colors.transparent,
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
              Text(
                symbol,
                style: const TextStyle(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
                  Text(
                    '$balance $symbol',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontFamily: _font,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFFCCFF00), size: 18),
            ],
          ),
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
              child: const Text(
                'U',
                style: TextStyle(
                  color: _bg,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          Icon(Icons.chevron_right, color: Color(0xFFCCFF00), size: 18),
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
                          ? const Icon(
                              Icons.backspace_outlined,
                              color: _white,
                              size: 22,
                            )
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

// ── Payment Method Card ───────────────────────────────────────────────────────
class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.extraIcons = const [],
    this.limit,
    this.fees,
    this.processingTime,
    this.disabled = false,
    this.disabledLabel,
  });
  final String icon;
  final String title;
  final String? subtitle;
  final List<String> extraIcons;
  final String? limit;
  final String? fees;
  final String? processingTime;
  final bool disabled;
  final String? disabledLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Image.asset(
                      icon,
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, s) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontFamily: _font,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: _font,
                  ),
                ),
              ],
              if (extraIcons.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: extraIcons
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Image.asset(
                            p,
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (limit != null || fees != null || processingTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: 1,
                    color: _white.withValues(alpha: 0.1),
                  ),
                ),
              if (limit != null) ...[
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Limit: ',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                      TextSpan(
                        text: limit,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (fees != null) ...[
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fees: ',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                      TextSpan(
                        text: fees,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (processingTime != null) ...[
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Processing Time: ',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                      TextSpan(
                        text: processingTime,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontFamily: _font,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (disabledLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  disabledLabel!,
                  style: const TextStyle(
                    color: Color(0xFFD05858),
                    fontSize: 12,
                    fontFamily: _font,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Spinning Time Icon ────────────────────────────────────────────────────────
class _SpinningTimeIcon extends StatefulWidget {
  const _SpinningTimeIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SpinningTimeIcon> createState() => _SpinningTimeIconState();
}

class _SpinningTimeIconState extends State<_SpinningTimeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: RotationTransition(
        turns: _ctrl,
        child: Image.asset(
          'assets/icons/time.png',
          width: 22,
          height: 22,
          errorBuilder: (_, e, s) =>
              const Icon(Icons.history, color: _white, size: 22),
        ),
      ),
    );
  }
}
