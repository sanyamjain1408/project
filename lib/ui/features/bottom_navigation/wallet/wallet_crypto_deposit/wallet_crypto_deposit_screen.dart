import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/currency.dart';
import '../../../../../data/models/wallet.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/decorations.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/image_util.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../utils/extensions.dart';
import '../../../side_navigation/activity/activity_screen.dart';
import '../../../side_navigation/faq/faq_page.dart';
import '../check_deposit/check_deposit_page.dart';
import '../wallet_widgets.dart';
import 'wallet_crypto_deposit_controller.dart';

// ── CONSTANTS ─────────────────────────────────────────────────────────────────
const _dmSans = 'DMSans';
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8A);

// Popular coins shown as chips at the top
const _popularSymbols = ['ETH', 'BTC', 'BAS', 'USDT', 'SHIB', 'XRP'];

// ── SCREEN 1: COIN SELECTION ──────────────────────────────────────────────────
class WalletCryptoDepositScreen extends StatefulWidget {
  const WalletCryptoDepositScreen({super.key, this.wallet});
  final Wallet? wallet;

  @override
  State<WalletCryptoDepositScreen> createState() =>
      _WalletCryptoDepositScreenState();
}

class _WalletCryptoDepositScreenState extends State<WalletCryptoDepositScreen>
    with SingleTickerProviderStateMixin {
  final _controller = Get.put(WalletCryptoDepositController());
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
      await _controller.getDepositCoinList(preCode: widget.wallet?.coinType);
      if (widget.wallet?.coinType != null &&
          _controller.selectedCurrency.value.coinType != null &&
          mounted) {
        Get.to(() => const WalletCryptoDepositDetailScreen());
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
    if (_selectedChip != null)
      list = list.where((c) => c.coinType == _selectedChip).toList();
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
      final k = (c.coinType?.isNotEmpty == true)
          ? c.coinType![0].toUpperCase()
          : '#';
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
      onTap: () {
        FocusScope.of(context).unfocus(); //  keyboard + cursor band
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 48,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.arrow_back, color: _white, size: 22),
            ),
          ),
          title: const Text(
            'Deposit Crypto',
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
          ],
        ),
        body: Column(
          children: [
            // ── SEARCH ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              margin: EdgeInsets.symmetric(horizontal: 10),
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
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: _dmSans,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search_outlined,
                    color: Colors.white.withOpacity(0.5),
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

            SizedBox(height: 10),

            // ── POPULAR CHIPS ─────────────────────────────────────────────────
            Obx(() {
              final popular = _controller.currencyList
                  .where((c) => _popularSymbols.contains(c.coinType))
                  .toList();

              if (popular.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10, // horizontal gap
                  runSpacing: 10, // vertical gap
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
                          color: sel ? _card : _card,
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
                            if (coin.coinIcon != null) const SizedBox(width: 5),
                            Text(
                              coin.coinType ?? '',
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
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
                  return Center(
                    child: Text(
                      'No coins found',
                      style: const TextStyle(color: _grey, fontFamily: _dmSans),
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
                        return _CoinItem(
                          coin: coin,
                          onTap: () {
                            _controller.selectedCurrency.value = coin;
                            _controller.isEvm
                                ? _controller.getWalletNetworks()
                                : _controller.getWalletDeposit();
                            Get.to(
                              () => const WalletCryptoDepositDetailScreen(),
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

class _CoinItem extends StatelessWidget {
  const _CoinItem({required this.coin, required this.onTap});
  final Currency coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecommended = coin.coinType == 'BTC';
    return InkWell(
      onTap: onTap,
      splashColor: _green.withOpacity(0.05),
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
                      height: 24/16
                    ),
                  ),
                  Text(
                    coin.name ?? '',
                    style:  TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 16/12,
                    ),
                  ),
                ],
              ),
            ),
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: _dmSans,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── SCREEN 2: DEPOSIT DETAIL ──────────────────────────────────────────────────
class WalletCryptoDepositDetailScreen extends StatefulWidget {
  const WalletCryptoDepositDetailScreen({super.key});

  @override
  State<WalletCryptoDepositDetailScreen> createState() =>
      _WalletCryptoDepositDetailScreenState();
}

class _WalletCryptoDepositDetailScreenState
    extends State<WalletCryptoDepositDetailScreen>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<WalletCryptoDepositController>();
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  // ✅ Network select sheet kholta hai — pehle wale dropdown jaisa list
  void _openNetworkSheet() {
    final nets = _controller.networkList.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NetworkSelectSheet(
        networks: nets,
        selected: _controller.selectedNetwork.value,
        onSelect: (net) {
          // ✅ Network select karo
          _controller.selectedNetwork.value = net;
          // ✅ Address fetch karo
          _controller.isEvm
              ? _controller.getWalletDepositAddress()
              : _controller.getWalletNetworkAddress();
          // ✅ Sheet band karo
          Get.back();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
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
          'Deposit',
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
                TemporaryData.activityType = HistoryType.deposit;
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // ── DEPOSIT COIN ─────────────────────────────────────────────────
          const Text(
            'Deposit Coin',
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final cur = _controller.selectedCurrency.value;
            return GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (cur.coinIcon != null)
                      showImageNetwork(
                        imagePath: cur.coinIcon,
                        height: 30,
                        width: 30,
                        bgColor: Colors.transparent,
                      ),
                    if (cur.coinIcon != null) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cur.coinType ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 24 / 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: _green,
                      size: 22,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── NETWORK + WARNING + QR ────────────────────────────────────────
          Obx(() {
            final loading = _controller.isLoading.value;
            final nets = _controller.networkList;
            final selNet = _controller.selectedNetwork.value;
            final depAddr = _controller.depositAddress.value;

            final hasFixed =
                nets.isEmpty &&
                (selNet.networkType.isValid ||
                    selNet.networkName.isValid ||
                    (selNet.id ?? 0) > 0);
            final showNetwork = nets.isNotEmpty || hasFixed || loading;

            final showQR =
                selNet.networkType.isValid ||
                (selNet.id ?? 0) > 0 ||
                depAddr.address.isValid;

            if (!showNetwork && !showQR) return const SizedBox.shrink();

            final netDisplay = selNet.networkType ?? selNet.networkName ?? '';
            final netSub =
                (selNet.networkType.isValid && selNet.networkName.isValid)
                ? selNet.networkName
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── NETWORK SELECTOR ────────────────────────────────────
                if (showNetwork) ...[
                  const Text(
                    'Network',
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    // ✅ hasFixed hoga to tap kaam nahi karega
                    // Multiple networks hain to sheet khulegi
                    onTap: (hasFixed || loading) ? null : _openNetworkSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        netDisplay.isNotEmpty
                                            ? netDisplay
                                            : (nets.isNotEmpty
                                                  ? 'Select Network'
                                                  : ''),
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
                                      if (netSub != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          netSub,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 12,
                                            fontFamily: _dmSans,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // ✅ Arrow down — tap karne se sheet khulegi
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

                // ── WARNING + QR ─────────────────────────────────────────
                if (showQR) ...[
                  CryptoDepositAddressView(
                    depositAddress: depAddr,
                    isLoading: _controller.isLoading.value,
                    networkLabel:
                        selNet.networkType ?? selNet.networkName ?? '',
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            );
          }),

          Obx(
            () => _controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _green,
                      strokeWidth: 2,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── HAVING TROUBLE ───────────────────────────────────────────────
          const CheckDepositButtonView(),
          const SizedBox(height: 16),

          // ── HOLD TO EARN ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            margin: EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x3377D215), // rgba(119, 210, 21, 0.2)
                  Color(0x33DEFF9E), // rgba(222, 255, 158, 0.2)
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
                      colors: [
                        Color(0xFF53F8A0), // #53F8A0
                        Color(0xFF00E5AB), // #00E5AB
                      ],
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

          // ── RECENT DEPOSITS ──────────────────────────────────────────────
          const Text(
            'Recent Deposit',
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
              height: 24/15
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
                  type: HistoryType.deposit,
                ),
              ),
            );
          }),

          // ── FAQ ──────────────────────────────────────────────────────────
          Obx(() => FAQRelatedView(_controller.faqList.toList())),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── NETWORK SELECT BOTTOM SHEET ───────────────────────────────────────────────
// ✅ Pehle wale dropdown jaisa list — tap karne se select hoga
class _NetworkSelectSheet extends StatelessWidget {
  const _NetworkSelectSheet({
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
          // ── HANDLE BAR ───────────────────────────────────────────────────
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

          // ── TITLE ROW ────────────────────────────────────────────────────
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

          // ── WARNING BANNER ────────────────────────────────────────────────
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
                                'Make sure you select the deposit network that '
                                'corresponds to the withdrawal platform. Failure '
                                'to do so may result in the loss of your funds. ',
                          ),
                          TextSpan(
                            text: 'Learn How to Select Deposit Network',
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

          // ── NETWORK LIST ──────────────────────────────────────────────────
          // ✅ Pehle wale dropdown jaisi list — tap karne se select hoga
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

                      // ✅ Check: yeh network currently selected hai?
                      final isSelected =
                          (net.networkType != null &&
                              net.networkType == selected.networkType) ||
                          (net.id != null && net.id == selected.id);

                      return GestureDetector(
                        // ✅ Tap karo — select karo, sheet band karo
                        onTap: () => onSelect(net),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            // ✅ Selected = green border + green bg
                            color: isSelected
                                ? _green.withOpacity(0.08)
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
                                      // ── Network type + name ──────────
                                      Row(
                                        children: [
                                          Text(
                                            net.networkType ??
                                                net.networkName ??
                                                '',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? _green
                                                  : _white,
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
                                                      ? _green.withOpacity(0.7)
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
                                        'Min Deposit: 1',
                                        style: TextStyle(
                                          color: _grey,
                                          fontSize: 13,
                                          fontFamily: _dmSans,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ✅ Selected checkmark icon
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

// ── CHECK DEPOSIT BUTTON ──────────────────────────────────────────────────────
class CheckDepositButtonView extends StatelessWidget {
  const CheckDepositButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              /// 📝 LEFT TEXT
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Having trouble with your deposit".tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "DMSans",
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 20 / 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "You can manually check the status of your transaction?"
                          .tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: "DMSans",
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              /// 🔘 BUTTON
              Expanded(
                flex: 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Get.to(() => CheckDepositPage()),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green, width: 0.5),
                      ),
                      child: Text(
                        "Check".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "DMSans",
                          fontWeight: FontWeight.w400,
                          height: 20 / 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DEPOSIT ADDRESS + QR ──────────────────────────────────────────────────────

class CryptoDepositAddressView extends StatelessWidget {
  const CryptoDepositAddressView({
    super.key,
    required this.depositAddress,
    required this.isLoading,
    this.networkLabel = '',
  });

  final WalletAddress depositAddress;
  final bool isLoading;
  final String networkLabel;

  @override
  Widget build(BuildContext context) {
    final address = depositAddress.address ?? '';
    if (!address.isValid) {
      return !isLoading
          ? Padding(
              padding: const EdgeInsets.all(Dimens.paddingMid),
              child: TextRobotoAutoBold("No Address Found".tr),
            )
          : const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Warning banner
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_outlined,
                      color: Color(0xFFC25400),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please ensure that you're using only the "
                        "$networkLabel "
                        "chain for sending tokens. Substrate or bridge "
                        "transfers will result in loss of funds.",
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: qrView(address),
          ),
          const SizedBox(height: 20),

          // Address text
          Text(
            address,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: _dmSans,
              height: 20 / 15,
            ),
          ),
          const SizedBox(height: 20),

          // Share + Copy buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => shareText(address),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF202020),
                    side: const BorderSide(color: Colors.transparent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 20 / 15,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    showToast('Address copied');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _green, width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 20 / 15,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (depositAddress.rentedTill != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextRobotoAutoNormal(
                "${"Exp AT".tr} ${formatDate(depositAddress.rentedTill, format: dateTimeFormatDdMMMMYyyyHhMm)}",
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
