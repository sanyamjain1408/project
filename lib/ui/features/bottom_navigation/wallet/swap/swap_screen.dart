import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/activity/activity_screen.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_widgets.dart';
import 'swap_controller.dart';

// ── Design tokens ──────────────────────────────────────────────────
const Color _kGreen = Color(0xFFCCFF00);
const Color _kCardBg = Color(0xFF1A1A1A);
const Color _kScaffoldBg = Color(0xFF0F0F0F);
const Color _kTextSec = Color(0xFF9D9D9D);
const Color _kDivider = Color(0xFF2A2A2A);
const Color _kRed = Color(0xFFFF4444);
const String _dmSans = 'DMSans';

// ─────────────────────────────────────────────────────────────────
// PAY card SVG — flat corners on top, notch cut at BOTTOM centre
// border sirf top+sides pe hai, bottom (notch wali side) pe nahi
// ─────────────────────────────────────────────────────────────────
const String _kSvgPay = '''
<svg xmlns="http://www.w3.org/2000/svg" width="362" height="160" viewBox="0 0 362 160" fill="none">
  <!-- fill shape -->
  <path d="M0 10C0 4.47715 4.47715 0 10 0H352C357.523 0 362 4.47715 362 10V150C362 155.523 357.523 160 352 160H229.353C227.177 160 225.061 159.29 223.325 157.979L193.057 135.109C185.923 129.719 176.077 129.719 168.943 135.109L138.675 157.979C136.939 159.29 134.823 160 132.647 160H10C4.47715 160 0 155.523 0 150V10Z"
    fill="#1A1A1A"/>
  <!-- border — only top + left + right, NOT the notch bottom edge -->
  <path d="M1 10C1 5.02944 5.02944 1 10 1H352C356.971 1 361 5.02944 361 10V150C361 154.971 356.971 159 352 159H229.353C226.959 159 224.629 158.222 222.72 156.776L192.452 133.906C184.876 128.181 174.124 128.181 166.548 133.906L136.28 156.776C134.371 158.222 132.041 159 129.647 159H10C5.02944 159 1 154.971 1 150V10Z"
    stroke="white" stroke-opacity="0.10" stroke-width="1"
    fill="none"
    stroke-dasharray=""
    clip-path="inset(0 0 28px 0)"/>
</svg>
''';

// ─────────────────────────────────────────────────────────────────
// RECEIVE card SVG — notch cut at TOP centre, flat corners on bottom
// border sirf bottom+sides pe hai, top (notch wali side) pe nahi
// ─────────────────────────────────────────────────────────────────
const String _kSvgReceive = '''
<svg xmlns="http://www.w3.org/2000/svg" width="362" height="160" viewBox="0 0 362 160" fill="none">
  <!-- fill shape -->
  <path d="M0 10C0 4.47715 4.47715 0 10 0H132.647C134.823 0 136.939 0.709661 138.675 2.02133L168.943 24.8905C176.077 30.2807 185.923 30.2807 193.057 24.8905L223.325 2.02133C225.061 0.70966 227.177 0 229.353 0H352C357.523 0 362 4.47715 362 10V150C362 155.523 357.523 160 352 160H10C4.47715 160 0 155.523 0 150V10Z"
    fill="#1A1A1A"/>
  <!-- border — only bottom + left + right, NOT the notch top edge -->
  <path d="M1 10C1 5.02944 5.02944 1 10 1H132.647C135.041 1 137.371 1.778 139.28 3.224L169.548 26.094C177.124 31.819 187.876 31.819 195.452 26.094L225.72 3.224C227.629 1.778 229.959 1 232.353 1H352C356.971 1 361 5.02944 361 10V150C361 154.971 356.971 159 352 159H10C5.02944 159 1 154.971 1 150V10Z"
    stroke="white" stroke-opacity="0.10" stroke-width="1"
    fill="none"
    clip-path="inset(28px 0 0 0)"/>
</svg>
''';

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
  final _showDetails = false.obs;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fromEditController.text = "1";
      _controller.fromAmountRx.value = "1";
      _controller.getCoinSwapApp(
        preWallet: widget.preWallet,
        pair: widget.prePair,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller.coinList.isEmpty) {
      _controller.getCoinSwapApp(
        preWallet: widget.preWallet,
        pair: widget.prePair,
      );
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
    alertForAction(
      context,
      title: "Swap".tr,
      subTitle:
          "Swap $amount ${from.symbol} → "
          "${_controller.convertRate.value.toStringAsFixed(5)} ${to.symbol}",
      buttonTitle: "Convert".tr,
      onOkAction: () => _controller.swapCoinProcess(from.id, to.id, amount),
    );
  }

  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabs(),
            Expanded(child: _buildBody()),
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
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Text(
                "Convert",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: _dmSans,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF53F8A0), Color(0xFF00E5AB)],
                  ),
                ),
                child: const Text(
                  "0.03 Fees",
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 12,
                    height: 16/12,
                    fontWeight: FontWeight.w400,
                    fontFamily: _dmSans,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              TemporaryData.activityType = HistoryType.swap;
              Get.to(() => const ActivityScreen());
            },
            child: Container(
              width: 20,
              height: 20,
              child: const RotatingIcon(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: _dmSans,
          height: 24/16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: _dmSans,
          height: 24/16,
        ),
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Market"),
          Tab(text: "Limit"),
          Tab(text: "Staking"),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _kGreen));
      }
      if (_controller.coinList.isEmpty) return _buildErrorState();

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          children: [
            // ── Two SVG cards ──
            _buildSwapCards(),

            // ── Price details — sirf Convert click ke baad ──
            Obx(() {
              if (!_showDetails.value) return const SizedBox(height: 16);
              return Column(
                children: [const SizedBox(height: 16), _buildPriceInfo()],
              );
            }),

            // ── Rate line: 1 BTC = X ETH ──
            Obx(() {
              final from = _controller.selectedFromCoin.value;
              final to = _controller.selectedToCoin.value;
              final rate = _controller.rate.value;
              final rateStr = rate > 0
                  ? '1 ${from?.symbol ?? ''} = ${rate.toStringAsFixed(5)} ${to?.symbol ?? ''}'
                  : '1 ${from?.symbol ?? ''} = - ${to?.symbol ?? ''}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    rateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ),
              );
            }),

            // ── Convert / Confirm button ──
            _buildConvertButton(),
          ],
        ),
      );
    });
  }

  // ── Error state ────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _kCardBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: _kTextSec,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Connection Failed".tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check your internet connection and try again".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kTextSec,
                fontSize: 13,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _controller.getCoinSwapApp(
                preWallet: widget.preWallet,
                pair: widget.prePair,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Retry".tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TWO SVG CARDS  +  green swap button in centre
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSwapCards() {
    return Obx(() {
      final fCoin = _controller.selectedFromCoin.value;
      final tCoin = _controller.selectedToCoin.value;

      // Card height matches SVG viewBox height
      const double cardH = 160.0;
      // Vertical gap between the two cards (swap button fills this)
      const double gap = 10.0;
      const double totalH = cardH * 2 + gap;

      return SizedBox(
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── PAY card (top) ─────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: cardH,
                child: Stack(
                  children: [
                    // SVG background
                    Positioned.fill(
                      child: SvgPicture.string(_kSvgPay, fit: BoxFit.fill),
                    ),

                    // Content — bottom padding leaves room for notch
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label
                           Text(
                            "PAY",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                              height: 20/15,
                              fontWeight: FontWeight.w400,
                              fontFamily: _dmSans,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Amount row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Input
                              Expanded(
                                child: TextField(
                                  controller: _controller.fromEditController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style:  TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: _dmSans,
                                    height: 40/34,
                                  ),
                                  decoration:  InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "0",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: _controller.onFromAmountChanged,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Coin pill + balance below
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _CoinSelector(
                                    coin: fCoin,
                                    coins: _controller.coinList,
                                    onSelect: (c) {
                                      _controller.selectedFromCoin.value = c;
                                      _controller.getAndSetCoinRate();
                                    },
                                  ),
                                  if (fCoin != null &&
                                      fCoin.availableBalance > 0) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      "${_fmtNum(fCoin.availableBalance)} ${fCoin.symbol}",
                                      style:  TextStyle(
                                        color:Colors.white.withOpacity(0.5) ,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: _dmSans,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // USD price
                          Text(
                            "\$${_fmtPrice(fCoin?.usdPrice ?? 0)}",
                            style:  TextStyle(
                              color: Colors.white.withOpacity(0.5) ,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 20/15,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── RECEIVE card (bottom) ───────────────────────────────
            Positioned(
              top: cardH + gap,
              left: 0,
              right: 0,
              child: SizedBox(
                height: cardH,
                child: Stack(
                  children: [
                    // SVG background
                    Positioned.fill(
                      child: SvgPicture.string(_kSvgReceive, fit: BoxFit.fill),
                    ),

                    // Content — top padding leaves room for notch
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 34, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label
                           Text(
                            "RECEIVE",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                              height: 20/15,
                              fontWeight: FontWeight.w400,
                              fontFamily: _dmSans,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Amount row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Read-only receive amount
                              Expanded(
                                child: Obx(
                                  () => Text(
                                    _controller.isRateLoading.value
                                        ? "..."
                                        : _fmtReceive(
                                            _controller.convertRate.value,
                                          ),
                                    style:  TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      height: 40/34,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: _dmSans,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Coin pill + balance below
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _CoinSelector(
                                    coin: tCoin,
                                    coins: _controller.coinList,
                                    onSelect: (c) {
                                      _controller.selectedToCoin.value = c;
                                      _controller.getAndSetCoinRate();
                                    },
                                  ),
                                  if (tCoin != null &&
                                      tCoin.availableBalance > 0) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      "${_fmtNum(tCoin.availableBalance)} ${tCoin.symbol}",
                                      style:  TextStyle(
                                        color: Colors.white.withOpacity(0.5) ,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 16/12,
                                        fontFamily: _dmSans,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // USD price
                          Text(
                            "\$${_fmtPrice(tCoin?.usdPrice ?? 0)}",
                            style:  TextStyle(
                              color: Colors.white.withOpacity(0.5) ,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 20/15,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── GREEN SWAP BUTTON — centred on the seam ────────────
            Positioned(
              // seam = cardH + gap/2 ; button half = 29
              top: cardH + gap / 2 - 25,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _controller.swapSelectedCoins,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFCCFF00),
                      border: Border.all(color: const Color(0xFF000000), width: 1.5),
                     
                    ),
                    child:  Icon(
                      Icons.swap_calls_sharp,
                      color: Color(0xFF000000).withOpacity(0.8),
                      weight: 1.5,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Price info panel ──────────────────────────────────────────────
  Widget _buildPriceInfo() {
    return Obx(() {
      if (_controller.rate.value <= 0) return const SizedBox.shrink();
      final from = _controller.selectedFromCoin.value;
      final to = _controller.selectedToCoin.value;
      if (from == null || to == null) return const SizedBox.shrink();

      final hasFee = _controller.feeAmount.value > 0;
      final feePct = _controller.feePercentage.value;
      final feeLabel = feePct > 0
          ? "Swap fee (${feePct.toStringAsFixed(1)}%)"
          : "Swap fee";

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color:  Colors.transparent,
        ),
        child: Column(
          children: [
            _InfoRow(
              label: "Price",
              value:
                  "1 ${from.symbol} = ${_controller.rate.value.toStringAsFixed(5)} ${to.symbol}",
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: "Gross receive",
              value:
                  "${_controller.grossReceive.value.toStringAsFixed(5)} ${to.symbol}",
            ),
            if (hasFee) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: feeLabel,
                value:
                    "-${_controller.feeAmount.value.toStringAsFixed(5)} ${to.symbol}",
                valueColor: const Color(0xFFD05858),
              ),
            ],
            const SizedBox(height: 10),
             Divider(color: Colors.white.withOpacity(0.5), height: 1),
            const SizedBox(height: 10),
            _InfoRow(
              label: "You will receive",
              value:
                  "${_controller.convertRate.value.toStringAsFixed(5)} ${to.symbol}",
              labelBold: true,
              valueBold: true,
            ),
          ],
        ),
      );
    });
  }

  // ── Convert / Confirm button ──────────────────────────────────────
  // First tap  → show price details
  // Second tap → show confirm dialog
  Widget _buildConvertButton() {
    return Obx(() {
      final can = _controller.canSwap;

      return GestureDetector(
        onTap: () {
          if (!can) return;
          if (!_showDetails.value) {
            // First click: reveal price details
            _showDetails.value = true;
          } else {
            // Second click: proceed to convert
            _checkAndConvert();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: can ? const Color(0xFF1A1A1A) : const Color(0xFF151515),
            border: Border.all(
              color: Colors.transparent
            ),
           
          ),
          alignment: Alignment.center,
          child: Text(
            _showDetails.value ? "Confirm Convert" : "Convert",
            style: TextStyle(
              color: can ? Colors.white : const Color(0xFF555555),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: _dmSans,
            ),
          ),
        ),
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String _fmtReceive(double v) {
    if (v == 0) return "0";
    if (v >= 100000) return v.toStringAsFixed(0);
    if (v >= 10000) return v.toStringAsFixed(2);
    if (v >= 100) return v.toStringAsFixed(3);
    return v.toStringAsFixed(5);
  }

  String _fmtNum(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(8);
  }

  String _fmtPrice(double p) {
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }
}

// ─────────────────────────────────────────────────────────────────
// Coin selector pill  —  icon + symbol + chevron
// ─────────────────────────────────────────────────────────────────
class _CoinSelector extends StatelessWidget {
  const _CoinSelector({
    required this.coin,
    required this.coins,
    required this.onSelect,
  });

  final SwapCoin? coin;
  final List<SwapCoin> coins;
  final void Function(SwapCoin) onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color:  Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoinIcon(coin: coin, size: 30),
            const SizedBox(width: 5),
            Text(
              coin?.symbol ?? "Select",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 28/20,
                fontFamily: _dmSans,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (_, sc) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                "Select Coin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 24/16,
                  fontWeight: FontWeight.w700,
                  fontFamily: _dmSans,
                ),
              ),
            ),
             Divider(color: Colors.white.withOpacity(0.5), height: 1),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: coins.length,
                itemBuilder: (_, i) => _CoinPickerTile(
                  coin: coins[i],
                  isSelected: coins[i].id == coin?.id,
                  onTap: () {
                    onSelect(coins[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom-sheet picker tile
// ─────────────────────────────────────────────────────────────────
class _CoinPickerTile extends StatelessWidget {
  const _CoinPickerTile({
    required this.coin,
    required this.isSelected,
    required this.onTap,
  });

  final SwapCoin coin;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF2A2A2A),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : Colors.transparent,
         
        ),
        child: Row(
          children: [
            _CoinIcon(coin: coin, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 24/16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    coin.name,
                    style:  TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      height: 16/12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (coin.usdPrice > 0)
                  Text(
                    "\$${_fmtP(coin.usdPrice)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 24/16,
                      fontWeight: FontWeight.w700,
                      fontFamily: _dmSans,
                    ),
                  ),
                if (coin.availableBalance > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    "${_fmtN(coin.availableBalance)} ${coin.symbol}",
                    style:  TextStyle(
                      color: Colors.white.withOpacity(0.5) ,
                      fontSize: 12,
                      height: 16/12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dmSans,
                    ),
                  ),
                ],
                // if (isSelected) ...[
                //   const SizedBox(height: 4),
                //   const Icon(
                //     Icons.check_circle,
                //     color: Color(0xFFCCFF00),
                //     size: 16,
                //   ),
                // ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtP(double p) {
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }

  String _fmtN(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(8);
  }
}

// ─────────────────────────────────────────────────────────────────
// Coin icon — network image with coloured fallback circle
// ─────────────────────────────────────────────────────────────────
class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.coin, this.size = 32});

  final SwapCoin? coin;
  final double size;

  static const _palette = [
    Color(0xFFF7931A),
    Color(0xFF627EEA),
    Color(0xFF26A17B),
    Color(0xFF2775CA),
    Color(0xFF00D4AA),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
    Color(0xFF1DA462),
    Color(0xFF00B8D9),
  ];

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
    final color = _palette[symbol.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        symbol.isNotEmpty ? symbol[0] : "?",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFamily: _dmSans,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Info row  (Price / Gross receive / Fee / You will receive)
// ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelBold = false,
    this.valueBold = false,
  });

  final String label, value;
  final Color? valueColor;
  final bool labelBold, valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 16/12,
            fontFamily: _dmSans,
            fontWeight: labelBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 12,
            height: 16/12,
            fontFamily: _dmSans,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
