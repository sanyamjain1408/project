import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/currency.dart';
import '../../../../../data/models/wallet.dart';
import '../../../../../helper/app_helper.dart';
import '../../../../../utils/alert_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../utils/image_util.dart';
import '../../../../../utils/number_util.dart';
import '../../../../../utils/qr_scanner.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_field_util.dart';
import '../../../../../utils/text_util.dart';
import '../../../side_navigation/activity/activity_screen.dart';
import '../../../side_navigation/faq/faq_page.dart';
import '../wallet_widgets.dart';
import 'wallet_crypto_withdraw_controller.dart';

// ── CONSTANTS ─────────────────────────────────────────────────────────────────
const _dmSans = 'DMSans';
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8A);

const _popularSymbols = ['ETH', 'BTC', 'BAS', 'USDT', 'SHIB', 'XRP'];

// ── SCREEN 1: COIN SELECTION ──────────────────────────────────────────────────
class WalletCryptoWithdrawScreen extends StatefulWidget {
  const WalletCryptoWithdrawScreen({super.key, this.wallet});
  final Wallet? wallet;

  @override
  State<WalletCryptoWithdrawScreen> createState() =>
      _WalletCryptoWithdrawScreenState();
}

class _WalletCryptoWithdrawScreenState
    extends State<WalletCryptoWithdrawScreen>
    with SingleTickerProviderStateMixin {
  final _controller = Get.put(WalletCryptoWithdrawController());
  late final AnimationController _spinCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String _query = '';
  String? _selectedChip;

  @override
  void initState() {
    super.initState();
    _controller.initController();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.getWithdrawCoinList(preWallet: widget.wallet);
      if (widget.wallet?.coinType != null &&
          _controller.selectedCurrency.value.coinType != null &&
          mounted) {
        Get.to(() => const WalletCryptoWithdrawDetailScreen());
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<Currency> get _filtered {
    var list = _controller.currencyList.toList();
    if (_selectedChip != null) {
      list = list.where((c) => c.coinType == _selectedChip).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
            (c) =>
                (c.coinType?.toLowerCase().contains(_query) ?? false) ||
                (c.name?.toLowerCase().contains(_query) ?? false),
          )
          .toList();
    }
    return list;
  }

  Map<String, List<Currency>> get _grouped {
    final map = <String, List<Currency>>{};
    for (final c in _filtered) {
      final k =
          (c.coinType?.isNotEmpty == true) ? c.coinType![0].toUpperCase() : '#';
      final key = RegExp(r'[0-9]').hasMatch(k) ? '0-9' : k;
      map.putIfAbsent(key, () => []).add(c);
    }
    return map;
  }

  List<dynamic> get _flatList {
    final grouped = _grouped;
    final keys = grouped.keys.toList()..sort();
    final flat = <dynamic>[];
    for (final k in keys) {
      flat.add(k);
      flat.addAll(grouped[k]!);
    }
    return flat;
  }

  void _scrollToLetter(String letter) {
    final flat = _flatList;
    final idx = flat.indexWhere((e) => e is String && e == letter);
    if (idx < 0) return;
    double offset = 0;
    for (int i = 0; i < idx; i++) {
      offset += flat[i] is String ? 32.0 : 60.0;
    }
    _scrollCtrl.animateTo(
      offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 48,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.arrow_back, color: _white, size: 22),
            ),
          ),
          title: const Text(
            'Withdraw Crypto',
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
              height: 24 / 16,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () {
                  TemporaryData.activityType = HistoryType.withdraw;
                  Get.to(() => const ActivityScreen());
                },
                child: RotationTransition(
                  turns: _spinCtrl,
                  child: Image.asset(
                    'assets/icons/time.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.history, color: _white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── SEARCH ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _searchCtrl,
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: _white,
                  fontFamily: _dmSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha:0.5),
                    fontFamily: _dmSans,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search_outlined,
                    color: Colors.white.withValues(alpha:0.5),
                    size: 30,
                  ),
                  filled: true,
                  fillColor: _card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── POPULAR CHIPS ─────────────────────────────────────────────────
            Obx(() {
              final popular = _controller.currencyList
                  .where((c) => _popularSymbols.contains(c.coinType))
                  .toList();
              if (popular.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: popular.map((coin) {
                    final sel = _selectedChip == coin.coinType;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _selectedChip = sel ? null : coin.coinType,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (coin.coinIcon != null)
                              showImageNetwork(
                                imagePath: coin.coinIcon,
                                height: 20,
                                width: 20,
                                bgColor: Colors.transparent,
                              ),
                            if (coin.coinIcon != null)
                              const SizedBox(width: 5),
                            Text(
                              coin.coinType ?? '',
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withValues(alpha:0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: _dmSans,
                                height: 24 / 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),

            const SizedBox(height: 6),

            // ── COIN LIST ─────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                final flat = _flatList;
                if (_controller.isLoading.value && flat.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _green),
                  );
                }
                if (flat.isEmpty) {
                  return const Center(
                    child: Text(
                      'No coins found',
                      style: TextStyle(color: _grey, fontFamily: _dmSans),
                    ),
                  );
                }
                final grouped = _grouped;
                final keys = grouped.keys.toList()..sort();
                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: flat.length,
                      itemBuilder: (_, idx) {
                        final item = flat[idx];
                        if (item is String) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: _white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: _dmSans,
                                height: 24 / 16,
                              ),
                            ),
                          );
                        }
                        final coin = item as Currency;
                        return _WithdrawCoinItem(
                          coin: coin,
                          onTap: () {
                            _controller.selectedCurrency.value = coin;
                            _controller.isEvm
                                ? _controller.getWalletNetworks()
                                : _controller.getWalletWithdrawal();
                            Get.to(
                              () => const WalletCryptoWithdrawDetailScreen(),
                            );
                          },
                        );
                      },
                    ),

                    // ── A-Z INDEX ───────────────────────────────────────────
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: keys
                                .map(
                                  (k) => GestureDetector(
                                    onTap: () => _scrollToLetter(k),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1.5,
                                      ),
                                      child: Text(
                                        k,
                                        style: const TextStyle(
                                          color: _grey,
                                          fontSize: 10,
                                          fontFamily: _dmSans,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawCoinItem extends StatelessWidget {
  const _WithdrawCoinItem({required this.coin, required this.onTap});
  final Currency coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: _green.withValues(alpha:0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            showImageNetwork(
              imagePath: coin.coinIcon,
              height: 30,
              width: 30,
              bgColor: Colors.transparent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.coinType ?? '',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                      height: 24 / 16,
                    ),
                  ),
                  Text(
                    coin.name ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.5),
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SCREEN 2: WITHDRAW DETAIL ─────────────────────────────────────────────────
class WalletCryptoWithdrawDetailScreen extends StatefulWidget {
  const WalletCryptoWithdrawDetailScreen({super.key});

  @override
  State<WalletCryptoWithdrawDetailScreen> createState() =>
      _WalletCryptoWithdrawDetailScreenState();
}

class _WalletCryptoWithdrawDetailScreenState
    extends State<WalletCryptoWithdrawDetailScreen>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<WalletCryptoWithdrawController>();
  final _addressEditController = TextEditingController();
  final _amountEditController = TextEditingController();
  final _memoEditController = TextEditingController();
  late final AnimationController _spinCtrl;
  final RxDouble _enteredAmount = 0.0.obs;
  bool isWithdraw2FActive = false;
  Timer? _feeTimer;

  @override
  void initState() {
    super.initState();
    isWithdraw2FActive = getSettingsLocal()?.twoFactorWithdraw == "1";
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getHistoryListData();
      _controller.getFAQList();
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _addressEditController.dispose();
    _amountEditController.dispose();
    _memoEditController.dispose();
    _feeTimer?.cancel();
    super.dispose();
  }

  void _openNetworkSheet() {
    final nets = _controller.networkList.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WithdrawNetworkSelectSheet(
        networks: nets,
        selected: _controller.selectedNetwork.value,
        onSelect: (net) {
          _controller.selectedNetwork.value = net;
          Get.back();
        },
      ),
    );
  }

  void _onAmountChanged(String text) {
    _enteredAmount.value =
        double.tryParse(_amountEditController.text.trim()) ?? 0.0;
    if (_feeTimer?.isActive ?? false) _feeTimer?.cancel();
    _feeTimer = Timer(
      const Duration(seconds: 1),
      () => _getPreWithdrawDate(),
    );
  }

  void _onAddressChanged(String text) {
    if (_feeTimer?.isActive ?? false) _feeTimer?.cancel();
    _feeTimer = Timer(
      const Duration(seconds: 1),
      () => _getPreWithdrawDate(),
    );
  }

  void _getPreWithdrawDate() {
    final address = _addressEditController.text.trim();
    final amount = makeDecimal(_amountEditController.text.trim());
    if (address.isEmpty || amount <= Decimal.zero) {
      _controller.preWithdrawal.value = PreWithdraw();
      return;
    }
    _controller.preWithdrawProcess(address, amount);
  }

  void _checkInputData() {
    final withdraw = WithdrawalCreate();
    if (!_controller.selectedNetwork.value.networkType.isValid &&
        (_controller.selectedNetwork.value.id ?? 0) <= 0) {
      showToast("select network".tr);
      return;
    }
    withdraw.coinId = _controller.selectedCurrency.value.id;
    withdraw.coinType = _controller.selectedCurrency.value.coinType;
    withdraw.networkType = _controller.selectedNetwork.value.networkType;
    withdraw.networkId = _controller.selectedNetwork.value.id;
    final address = _addressEditController.text.trim();
    if (address.isEmpty) {
      showToast("Address can not be empty".tr);
      return;
    }
    withdraw.address = address;
    final amount = makeDecimal(_amountEditController.text.trim());
    if (amount <= Decimal.zero) {
      showToast("amount_must_greater_than_0".tr);
      return;
    }
    final minAmount = _controller.preWithdrawal.value.min ?? Decimal.zero;
    if (amount < minAmount) {
      showToast("Amount_less_then".trParams({"amount": minAmount.toString()}));
      return;
    }
    final maxAmount = _controller.preWithdrawal.value.max ?? Decimal.zero;
    if (amount > maxAmount) {
      showToast(
        "Amount_greater_then".trParams({"amount": maxAmount.toString()}),
      );
      return;
    }
    withdraw.amount = amount;
    final total = amount + makeDecimal(_controller.preWithdrawal.value.fees);
    if (total > _controller.walletBalance.value) {
      showToast("Insufficient balance".tr);
      return;
    }
    if (isWithdraw2FActive && !gUserRx.value.google2FaSecret.isValid) {
      showToast("Please setup your google 2FA".tr);
      return;
    }
    hideKeyboard();
    showModalSheetFullScreen(
      context,
      WithdrawConfirmView(
        withdrawal: withdraw,
        is2FActive: isWithdraw2FActive,
        onWithdrawal: (withdrawal) {
          hideKeyboard();
          Get.back();
          withdrawal.memo = _memoEditController.text.trim();
          _controller.withdrawProcess(withdrawal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.arrow_back, color: _white, size: 22),
          ),
        ),
        title: const Text(
          'Withdraw',
          style: TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: _dmSans,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                TemporaryData.activityType = HistoryType.withdraw;
                Get.to(() => const ActivityScreen());
              },
              child: RotationTransition(
                turns: _spinCtrl,
                child: Image.asset(
                  'assets/icons/time.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stack) =>
                      const Icon(Icons.history, color: _white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 10),

            // ── WITHDRAW COIN ─────────────────────────────────────────────
            // const Text(
            //   'Withdraw Coin',
            //   style: TextStyle(
            //     color: _white,
            //     fontSize: 16,
            //     fontWeight: FontWeight.w700,
            //     fontFamily: _dmSans,
            //     height: 24 / 16,
            //   ),
            // ),
            // const SizedBox(height: 10),
            // Obx(() {
            //   final cur = _controller.selectedCurrency.value;
            //   return GestureDetector(
            //     onTap: () => Get.back(),
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 14,
            //         vertical: 12,
            //       ),
            //       decoration: BoxDecoration(
            //         color: _card,
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //       child: Row(
            //         children: [
            //           if (cur.coinIcon != null)
            //             showImageNetwork(
            //               imagePath: cur.coinIcon,
            //               height: 30,
            //               width: 30,
            //               bgColor: Colors.transparent,
            //             ),
            //           if (cur.coinIcon != null) const SizedBox(width: 10),
            //           Expanded(
            //             child: Text(
            //               cur.coinType ?? '',
            //               style: TextStyle(
            //                 color: Colors.white.withValues(alpha:0.5),
            //                 fontSize: 16,
            //                 fontWeight: FontWeight.w400,
            //                 fontFamily: _dmSans,
            //                 height: 24 / 16,
            //               ),
            //             ),
            //           ),
            //           const Icon(
            //             Icons.keyboard_arrow_down,
            //             color: _green,
            //             size: 22,
            //           ),
            //         ],
            //       ),
            //     ),
            //   );
            // }),

            const SizedBox(height: 20),

            // ── ADDRESS ───────────────────────────────────────────────────
            const Text(
              'Address',
              style: TextStyle(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
                height: 16/12,
                
              ),
            ),
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _addressEditController,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: _dmSans,
                    fontSize: 16,
                    height: 24/16,
                    fontWeight: FontWeight.w400,
                  ),
                onChanged: _onAddressChanged,
                decoration: InputDecoration(
                  hintText: 'Long press to paste',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: _dmSans,
                    fontSize: 16,
                    height: 24/16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  suffixIcon: InkWell(
                    onTap: () => Get.to(
                      () => QRScannerPage(
                        onData: (text) => _addressEditController.text = text,
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.qr_code_scanner, color: _grey, size: 22),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── NETWORK ───────────────────────────────────────────────────
            Obx(() {
              final nets = _controller.networkList;
              final selNet = _controller.selectedNetwork.value;
              final loading = _controller.isLoading.value;

              final hasFixed =
                  nets.isEmpty &&
                  (selNet.networkType.isValid ||
                      selNet.networkName.isValid ||
                      (selNet.id ?? 0) > 0);
              final showNetwork = nets.isNotEmpty || hasFixed || loading;

              if (!showNetwork) return const SizedBox.shrink();

              final netDisplay = selNet.networkType ?? selNet.networkName ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Network',
                    style: TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                      height:16/12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: (hasFixed || loading) ? null : _openNetworkSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: loading && netDisplay.isEmpty
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: _green,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    netDisplay.isNotEmpty
                                        ? netDisplay
                                        : (nets.isNotEmpty ? 'Select' : ''),
                                    style: TextStyle(
                                      color: netDisplay.isNotEmpty
                                          ? _white
                                          : Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: _dmSans,
                                      height: 24 / 16,
                                    ),
                                  ),
                                ),
                                if (!hasFixed)
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _green,
                                    size: 22,
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),

            // ── WITHDRAWAL AMOUNT ─────────────────────────────────────────
            const Text(
              'Withdrawal Amount',
              style: TextStyle(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
                height: 16/12,
              ),
            ),
            const SizedBox(height: 5),
            Obx(() {
              final coinType =
                  _controller.selectedCurrency.value.coinType ?? '';
              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountEditController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: _white,
                          fontFamily: _dmSans,
                          fontSize: 14,
                        ),
                        onChanged: _onAmountChanged,
                        decoration: InputDecoration(
                          hintText: 'Minimum 0',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: _dmSans,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 24/16
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            coinType,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: _dmSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 24/16
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              final bal = _controller.walletBalance.value
                                  .toStringAsFixed(8);
                              _amountEditController.text = bal;
                              _enteredAmount.value = _controller
                                  .walletBalance.value
                                  .toDouble();
                              _onAmountChanged(bal);
                            },
                            child: const Text(
                              'Max',
                              style: TextStyle(
                              color: _green,
                              fontFamily: _dmSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 24/16
                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),

            // ── AVAILABLE / RECEIVE / FEE ─────────────────────────────────
            Obx(() {
              final coinType =
                  _controller.selectedCurrency.value.coinType ?? '';
              final balance = _controller.walletBalance.value;
              final preWith = _controller.preWithdrawal.value;
              final fees = preWith.fees ?? 0.0;
              final entered = _enteredAmount.value;
              final receive = entered > fees ? entered - fees : 0.0;

              return Column(
                children: [
                  _infoRow(
                    'Available',
                    '${balance.toDouble().toStringAsFixed(2)} $coinType',
                  ),
                  const SizedBox(height: 8),
                  _amountinfoRow(
                    'Receive Amount',
                    '${receive.toStringAsFixed(2)} $coinType',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Network Fee',
                    '${fees.toStringAsFixed(2)} $coinType',
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // ── HOLD TO EARN ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x3377D215),
                    Color(0x33DEFF9E),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hold to Earn',
                          style: TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: _dmSans,
                            height: 24 / 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No lock-up. Trade anytime with daily earnings credited automatically.',
                          style: TextStyle(
                            color: _white,
                            fontSize: 12,
                            fontFamily: _dmSans,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF53F8A0), Color(0xFF00E5AB)],
                      ),
                    ),
                    child: const Text(
                      'APR up to 3.2%',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── RECENT WITHDRAW ───────────────────────────────────────────
            const Text(
              'Recent Withdraw',
              style: TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final list = _controller.historyList;
              if (list.isEmpty) return showEmptyView(height: 60);
              return Column(
                children: List.generate(
                  list.length,
                  (i) => WalletRecentTransactionItemView(
                    history: list[i],
                    type: HistoryType.withdraw,
                  ),
                ),
              );
            }),

            // ── FAQ ───────────────────────────────────────────────────────
            Obx(() => FAQRelatedView(_controller.faqList.toList())),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w400,
            height: 16/12
          ),
        ),
        Text(
          value,
          style:  TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w400,
            height: 16/12
          ),
        ),
      ],
    );
  }


  Widget _amountinfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w400,
            height: 16/12
          ),
        ),
        Text(
          value,
          style:  TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: _dmSans,
            fontWeight: FontWeight.w400,
            height: 20/16
          ),
        ),
      ],
    );
  }


  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: const Color(0xFF111111),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _checkInputData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Withdraw',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: _dmSans,
              height: 24/16
            ),
          ),
        ),
      ),
    );
  }
}

// ── NETWORK SELECT BOTTOM SHEET ───────────────────────────────────────────────
class _WithdrawNetworkSelectSheet extends StatelessWidget {
  const _WithdrawNetworkSelectSheet({
    required this.networks,
    required this.selected,
    required this.onSelect,
  });

  final List<Network> networks;
  final Network selected;
  final void Function(Network) onSelect;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
            child: Row(
              children: [
                const Text(
                  'Select Network',
                  style: TextStyle(
                    color: _white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: _white, size: 22),
                ),
              ],
            ),
          ),

          // Warning banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1E00),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFA500),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: Color(0xFFFFD080),
                          fontSize: 12,
                          fontFamily: _dmSans,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Make sure you select the withdrawal network that '
                                'corresponds to the receiving platform. Failure '
                                'to do so may result in the loss of your funds. ',
                          ),
                          TextSpan(
                            text: 'Learn How to Select Network',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Network list
          Expanded(
            child: networks.isEmpty
                ? const Center(
                    child: Text(
                      'No networks available',
                      style: TextStyle(color: _grey, fontFamily: _dmSans),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: networks.length,
                    itemBuilder: (_, i) {
                      final net = networks[i];
                      final isSelected =
                          (net.networkType != null &&
                              net.networkType == selected.networkType) ||
                          (net.id != null && net.id == selected.id);

                      return GestureDetector(
                        onTap: () => onSelect(net),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _green.withValues(alpha:0.08)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _green : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            net.networkType ??
                                                net.networkName ??
                                                '',
                                            style: TextStyle(
                                              color:
                                                  isSelected ? _green : _white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: _dmSans,
                                            ),
                                          ),
                                          if ((net.networkName?.isNotEmpty ??
                                                  false) &&
                                              (net.networkType?.isNotEmpty ??
                                                  false)) ...[
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                net.networkName ?? '',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? _green.withValues(alpha:0.7)
                                                      : _grey,
                                                  fontSize: 14,
                                                  fontFamily: _dmSans,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Arrival Time = 3 minutes',
                                        style: TextStyle(
                                          color: _grey,
                                          fontSize: 13,
                                          fontFamily: _dmSans,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Min Withdrawal: 1',
                                        style: TextStyle(
                                          color: _grey,
                                          fontSize: 13,
                                          fontFamily: _dmSans,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: _green,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── CONFIRM WITHDRAW ──────────────────────────────────────────────────────────
class WithdrawConfirmView extends StatelessWidget {
  const WithdrawConfirmView({
    super.key,
    required this.withdrawal,
    required this.onWithdrawal,
    required this.is2FActive,
  });

  final WithdrawalCreate withdrawal;
  final Function(WithdrawalCreate) onWithdrawal;
  final bool is2FActive;

  @override
  Widget build(BuildContext context) {
    final subTitle =
        "${"You will withdrawal".tr} ${withdrawal.amount} ${withdrawal.coinType} ${"to this address".tr} ${withdrawal.address}";
    final codeEditController = TextEditingController();
    return Column(
      children: [
        vSpacer10(),
        TextRobotoAutoBold(
          "Withdrawal Currency".tr,
          fontSize: Dimens.fontSizeLarge,
        ),
        vSpacer10(),
        TextRobotoAutoBold(subTitle, maxLines: 3),
        vSpacer10(),
        if (is2FActive)
          textFieldWithSuffixIcon(
            controller: codeEditController,
            hint: "Input 2FA code".tr,
            labelText: "2FA code".tr,
          ),
        vSpacer15(),
        buttonRoundedMain(
          text: "Withdraw".tr,
          onPress: () {
            final code = codeEditController.text.trim();
            if (is2FActive && code.length < DefaultValue.codeLength) {
              showToast(
                "Code length must be".trParams(
                  {"count": DefaultValue.codeLength.toString()},
                ),
              );
              return;
            }
            withdrawal.verifyCode = code;
            onWithdrawal(withdrawal);
          },
        ),
        vSpacer10(),
      ],
    );
  }
}
