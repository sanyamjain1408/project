import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/activity/activity_screen.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'swap_controller.dart';

const Color _kGreen = Color(0xFFC6F135);
const Color _kCardBg = Color(0xFF1A1A1A);
const Color _kScaffoldBg = Color(0xFF0F0F0F);
const Color _kTextSecondary = Color(0xFF9D9D9D);
const Color _kDivider = Color(0xFF2A2A2A);
const Color _kRed = Color(0xFFFF4444);

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key, this.preWallet, this.prePair});

  final Wallet? preWallet;
  final CoinPair? prePair;

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _controller = Get.put(SwapController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fromEditController.text = "1";
      _controller.fromAmountRx.value = "1";
      _controller.getCoinSwapApp(preWallet: widget.preWallet, pair: widget.prePair);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller.coinList.isEmpty) {
      _controller.getCoinSwapApp(preWallet: widget.preWallet, pair: widget.prePair);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    Get.delete<SwapController>();
    super.dispose();
  }

  void _checkAndConvert() {
    final amount = makeDouble(_controller.fromAmountRx.value);
    if (amount <= 0) {
      showToast("Invalid amount".tr);
      return;
    }
    hideKeyboard();
    final from = _controller.selectedFromCoin.value!;
    final to = _controller.selectedToCoin.value!;
    final subTitle =
        "Swap $amount ${from.symbol} → ${_controller.convertRate.value.toStringAsFixed(5)} ${to.symbol}";
    alertForAction(context,
        title: "Swap".tr,
        subTitle: subTitle,
        buttonTitle: "Convert".tr,
        onOkAction: () => _controller.swapCoinProcess(from.id, to.id, amount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kScaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabs(),
            Expanded(child: _buildBodyObx()),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _iconBtn(Icons.arrow_back_ios_new, () => Get.back(), size: 16),
          const Spacer(),
          Row(
            children: [
              Text("Convert".tr,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(6)),
                child: const Text("0.03 Fees",
                    style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Spacer(),
          _iconBtn(Icons.history, () {
            TemporaryData.activityType = HistoryType.swap;
            Get.to(() => const ActivityScreen());
          }),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {double size = 20}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      );

  // ── Tabs ──────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: _kTextSecondary,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: "Market"), Tab(text: "Limit"), Tab(text: "Staking")],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────
  Widget _buildBodyObx() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _kGreen));
      }
      if (_controller.coinList.isEmpty) {
        return _buildErrorState();
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSwapCards(),
          const SizedBox(height: 20),
          _buildPriceInfo(),
          const SizedBox(height: 20),
          _buildConvertButton(),
        ],
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: _kCardBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: _kTextSecondary, size: 36),
            ),
            const SizedBox(height: 16),
            Text("Connection Failed".tr,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Check your internet connection and try again".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _controller.getCoinSwapApp(
                  preWallet: widget.preWallet, pair: widget.prePair),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(12)),
                child: Text("Retry".tr,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Swap cards ────────────────────────────────────────────────────
  Widget _buildSwapCards() {
    return Obx(() {
      final fCoin = _controller.selectedFromCoin.value;
      final tCoin = _controller.selectedToCoin.value;
      return Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              // PAY card
              _buildCard(
                label: "PAY",
                labelBottom: false,
                amountWidget: TextField(
                  controller: _controller.fromEditController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: TextStyle(
                        color: Color(0xFF4A4A4A), fontSize: 32, fontWeight: FontWeight.w700),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _controller.onFromAmountChanged,
                ),
                usdValue: fCoin != null && fCoin.usdPrice > 0
                    ? Text("\$${_formatPrice(fCoin.usdPrice)}",
                        style: const TextStyle(color: _kTextSecondary, fontSize: 13))
                    : const SizedBox.shrink(),
                balance: fCoin != null && fCoin.availableBalance > 0
                    ? "${_formatNum(fCoin.availableBalance)} ${fCoin.symbol}"
                    : "",
                coin: fCoin,
                coins: _controller.coinList,
                onCoinSelect: (c) {
                  _controller.selectedFromCoin.value = c;
                  _controller.getAndSetCoinRate();
                },
              ),
              const SizedBox(height: 4),
              // RECEIVE card
              _buildCard(
                label: "RECEIVE",
                labelBottom: true,
                amountWidget: Obx(() => Text(
                      _controller.isRateLoading.value
                          ? "..."
                          : (_controller.convertRate.value > 0
                              ? _controller.convertRate.value.toStringAsFixed(5)
                              : "0.00000"),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    )),
                usdValue: tCoin != null && tCoin.usdPrice > 0
                    ? Text("\$${_formatPrice(tCoin.usdPrice)}",
                        style: const TextStyle(color: _kTextSecondary, fontSize: 13))
                    : const SizedBox.shrink(),
                balance: tCoin != null && tCoin.availableBalance > 0
                    ? "${_formatNum(tCoin.availableBalance)} ${tCoin.symbol}"
                    : "",
                coin: tCoin,
                coins: _controller.coinList,
                onCoinSelect: (c) {
                  _controller.selectedToCoin.value = c;
                  _controller.getAndSetCoinRate();
                },
              ),
            ],
          ),
          // Green swap button
          GestureDetector(
            onTap: _controller.swapSelectedCoins,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
              child: const Icon(Icons.swap_vert_rounded, color: Colors.black, size: 28),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCard({
    required String label,
    required bool labelBottom,
    required Widget amountWidget,
    required Widget usdValue,
    required String balance,
    required SwapCoin? coin,
    required List<SwapCoin> coins,
    required void Function(SwapCoin) onCoinSelect,
  }) {
    final labelWidget = Text(label,
        style: const TextStyle(
            color: _kTextSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!labelBottom) ...[labelWidget, const SizedBox(height: 10)],
          Row(
            children: [
              Expanded(child: amountWidget),
              const SizedBox(width: 8),
              _CoinSelector(
                coin: coin,
                coins: coins,
                onSelect: onCoinSelect,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              usdValue,
              if (balance.isNotEmpty)
                Text(balance, style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
            ],
          ),
          if (labelBottom) ...[const SizedBox(height: 8), labelWidget],
        ],
      ),
    );
  }

  // ── Price info ────────────────────────────────────────────────────
  Widget _buildPriceInfo() {
    return Obx(() {
      if (_controller.rate.value <= 0) return const SizedBox.shrink();
      final from = _controller.selectedFromCoin.value;
      final to = _controller.selectedToCoin.value;
      if (from == null || to == null) return const SizedBox.shrink();
      final hasFee = _controller.feeAmount.value > 0;
      final feePct = _controller.feePercentage.value;
      final feeLabel = feePct > 0 ? "Swap fee (${feePct.toStringAsFixed(2)}%)" : "Swap fee";

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _InfoRow(
              label: "Price",
              value: "1 ${from.symbol} = ${_controller.rate.value.toStringAsFixed(5)} ${to.symbol}",
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: "Gross receive",
              value: "${_controller.grossReceive.value.toStringAsFixed(5)} ${to.symbol}",
            ),
            if (hasFee) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: feeLabel,
                value: "-${_controller.feeAmount.value.toStringAsFixed(5)} ${to.symbol}",
                valueColor: _kRed,
              ),
            ],
            const SizedBox(height: 10),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 10),
            _InfoRow(
              label: "You will receive",
              value: "${_controller.convertRate.value.toStringAsFixed(5)} ${to.symbol}",
              labelBold: true,
              valueBold: true,
            ),
          ],
        ),
      );
    });
  }

  // ── Convert button ────────────────────────────────────────────────
  Widget _buildConvertButton() {
    return Obx(() {
      final can = _controller.canSwap;
      return GestureDetector(
        onTap: can ? _checkAndConvert : null,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: can ? const Color(0xFF252525) : const Color(0xFF151515),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: can ? const Color(0xFF3A3A3A) : const Color(0xFF222222)),
          ),
          alignment: Alignment.center,
          child: Text(
            "Convert".tr,
            style: TextStyle(
              color: can ? Colors.white : const Color(0xFF555555),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }

  String _formatNum(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(8);
  }

  String _formatPrice(double p) {
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }
}

// ── Coin Selector button ──────────────────────────────────────────

class _CoinSelector extends StatelessWidget {
  const _CoinSelector({required this.coin, required this.coins, required this.onSelect});

  final SwapCoin? coin;
  final List<SwapCoin> coins;
  final void Function(SwapCoin) onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoinIcon(coin: coin, size: 24),
            const SizedBox(width: 6),
            Text(
              coin?.symbol ?? "Select",
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: _kTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF444444), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text("Select Coin".tr,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const Divider(color: Color(0xFF222222), height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: coins.length,
                itemBuilder: (_, i) {
                  final c = coins[i];
                  final isSelected = c.id == coin?.id;
                  return ListTile(
                    onTap: () {
                      onSelect(c);
                      Navigator.pop(context);
                    },
                    leading: _CoinIcon(coin: c, size: 38),
                    title: Text(c.symbol,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    subtitle: Text(c.name,
                        style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.usdPrice > 0)
                          Text(
                            "\$${_formatPrice(c.usdPrice)}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: _kGreen, size: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }
}

// ── Coin icon widget ──────────────────────────────────────────────

class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.coin, this.size = 32});

  final SwapCoin? coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = coin?.iconUrl;
    final symbol = coin?.symbol ?? "?";
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: showImageNetwork(
          imagePath: url,
          width: size,
          height: size,
          boxFit: BoxFit.cover,
          bgColor: Colors.transparent,
          hideDefaultImage: true,
        ),
      );
    }
    return _fallback(symbol);
  }

  Widget _fallback(String symbol) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(symbol[0],
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.4)),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelBold = false,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool labelBold;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: _kTextSecondary,
                fontSize: 13,
                fontWeight: labelBold ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }
}
