import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../../wallet/swap/swap_screen.dart';
import '../../wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import '../../wallet/wallet_fiat_deposit/wallet_fiat_deposit_screen.dart';
import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import 'spot_trade_controller.dart';

class SpotTradeBuySellView extends StatefulWidget {
  final String? fromPage;

  const SpotTradeBuySellView({super.key, this.fromPage});

  @override
  SpotTradeBuySellViewState createState() => SpotTradeBuySellViewState();
}

class SpotTradeBuySellViewState extends State<SpotTradeBuySellView>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<SpotTradeController>();
  final priceEditController = TextEditingController();
  final amountEditController = TextEditingController();
  final totalEditController = TextEditingController();
  final limitEditController = TextEditingController();

  final takeProfitController = TextEditingController();
  final takeLossController = TextEditingController();
  final RxBool _tpSlEnabled = false.obs;

  TabController? buySellTabController;
  RxInt selectedBuySubTabIndex = 0.obs;
  RxInt selectedSellSubTabIndex = 0.obs;
  bool isLoggedIn = false;

  @override
  void initState() {
    _controller.onBuySaleChange = onBuySellChange;
    isLoggedIn = gUserRx.value.id > 0;
    _controller.selectedBuySellTab.value = (widget.fromPage == FromKey.buy
        ? 0
        : 1);
    buySellTabController = TabController(
      vsync: this,
      length: 2,
      initialIndex: _controller.selectedBuySellTab.value,
    );
    super.initState();
    setSelectedPrice.addListener(() {
      if (setSelectedPrice.value != null && setSelectedPrice.value! > 0) {
        int subIndex = _controller.selectedBuySellTab.value == 0
            ? selectedBuySubTabIndex.value
            : selectedSellSubTabIndex.value;
        if (subIndex == 0 || subIndex == 1) {
          priceEditController.text = setSelectedPrice.value.toString();
        } else if (subIndex == 2) {
          limitEditController.text = setSelectedPrice.value.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    takeProfitController.dispose();
    takeLossController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => BuySellToggleButton(
            options: ['Buy'.tr, 'Sell'.tr],
            selected: _controller.selectedBuySellTab.value,
            onSelect: (index) => onBuySellChange(index),
          ),
        ),
        Obx(() => _buySellTabView(_controller.selectedBuySellTab.value)),
      ],
    );
  }

  void onBuySellChange(int index) {
    _controller.selectedBuySellTab.value = index;
    _clearInputViews();
  }

  Widget _buySellTabView(int tabIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Obx(() {
        int subIndex = tabIndex == 0
            ? selectedBuySubTabIndex.value
            : selectedSellSubTabIndex.value;
        bool isBuy = _controller.selectedBuySellTab.value == 0;
        final total = _controller.selfBalance.value.total;
        final baseCType = total?.baseWallet?.coinType ?? "";
        final tradeCType = total?.tradeWallet?.coinType ?? "";
        final (balance, coinType) = isBuy
            ? (total?.baseWallet?.balance, baseCType)
            : (total?.tradeWallet?.balance, tradeCType);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            vSpacer5(),

            // ── Order type dropdown ────────────────────────────────────
            CustomDropdown(
              items: ["Limit", "Market", "Stop-limit"],
              selectedIndex: subIndex,
              onChange: (index) {
                tabIndex == 0
                    ? selectedBuySubTabIndex.value = index
                    : selectedSellSubTabIndex.value = index;

                _clearInputViews();

                final prices = _controller.dashboardData.value.lastPriceData;
                final price = (prices?.isNotEmpty ?? false) ? prices!.first.price : null;

                if (index == 0 || index == 1) {
                  if (price != null && price > 0) {
                    priceEditController.text = price.toStringAsFixed(2);
                  }
                } else if (index == 2) {
                  if (price != null && price > 0) {
                    limitEditController.text = price.toStringAsFixed(2);
                  }
                }
              },
            ),
            vSpacer5(),

            // ── Limit / Stop Price ─────────────────────────────────────
            TradeTextFieldCalculate(
              controller: priceEditController,
              sTitle: subIndex == 2 ? "Stop".tr : "Limit Price",
              sSubtitle: baseCType,
            ),
            vSpacer5(),

            // ── Limit field (Stop-limit only) ──────────────────────────
            if (subIndex == 2)
              TradeTextFieldCalculate(
                controller: limitEditController,
                sTitle: "Limit".tr,
                sSubtitle: baseCType,
              ),
            if (subIndex == 2) vSpacer5(),
           
            

            // ── Qty ───────────────────────────────────────────────────
            TradeTextFieldCalculate(
              controller: amountEditController,
              onTextChange: _onInputAmount,
              sTitle: "Qty".tr,
              sSubtitle: tradeCType,
            ),
            vSpacer2(),

            // ── Slider ────────────────────────────────────────────────
            _SliderPercentRow(onTap: _tapOnPercentItem),
            vSpacer5(),

            // ── Amount (Total) ─────────────────────────────────────────
            TradeTextFieldCalculate(
              controller: totalEditController,
              isEnable: false,
              sTitle: "Amount".tr,
              sSubtitle: baseCType,
            ),
            vSpacer2(),

            // ── Available balance ──────────────────────────────────────
            isLoggedIn
                ? TradeBalanceView(
                    balance: balance,
                    coinType: coinType,
                    onTap: () {
                      showBottomSheetDynamic(
                        context,
                        TradeBalanceAddView(
                          coinPair: _controller.selectedCoinPair.value,
                          isBuy: _controller.selectedBuySellTab.value == 0,
                        ),
                        title: "Fund Your Account".tr,
                      );
                    },
                  )
                : const TradeLoginButton(),
            vSpacer5(),

            // ── TP/SL section + Button — ek saath fixed structure ──────
            // ✅ KEY: AnimatedAlign + ClipRect = button KABHI nahi hilega
            // ── TP/SL section + Button ──────────────────────────────────────────
            Obx(() {
              final enabled = _tpSlEnabled.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TpSlToggleRow(
                    enabled: enabled,
                    onToggle: (v) => _tpSlEnabled.value = v,
                  ),
                  // Fields always occupy space; only visibility changes
                  Visibility(
                    visible: enabled,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 5),
                        TradeTextFieldCalculate(
                          controller: takeProfitController,
                          sTitle: "Take-Profit Price".tr,
                          sSubtitle: baseCType,
                        ),
                        const SizedBox(height: 5),
                        TradeTextFieldCalculate(
                          controller: takeLossController,
                          sTitle: "Take-Loss Price".tr,
                          sSubtitle: baseCType,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Limit/Market me Limit field nahi hota (45px) — woh gap yahan dete hai
                  if (subIndex != 2) const SizedBox(height: 45),
                  if (isLoggedIn)
                    buttonRoundedMain(
                      text: "${isBuy ? "Buy".tr : "Sell".tr} ",
                      bgColor: isBuy ? gBuyColor : gSellColor,
                      textColor: Colors.white,
                      buttonHeight: 40,
                      borderRadius: 5,
                      onPress: () => _checkInputData(),
                    ),
                ],
              );
            }),
          ],
          ),
        );
      }),
    );
  }

  // ── Input logic ────────────────────────────────────────────────────────────

  void _onInputAmount(String amountStr) {
    var price = 0.0;
    final isBuy = _controller.selectedBuySellTab.value == 0;
    if ((isBuy && selectedBuySubTabIndex.value == 0) ||
        (!isBuy && selectedSellSubTabIndex.value == 0)) {
      price = makeDouble(priceEditController.text.trim());
    } else if ((isBuy && selectedBuySubTabIndex.value == 1) ||
        (!isBuy && selectedSellSubTabIndex.value == 1)) {
      price = makeDouble(priceEditController.text.trim());
      if (price <= 0) return;
    } else if ((isBuy && selectedBuySubTabIndex.value == 2) ||
        (!isBuy && selectedSellSubTabIndex.value == 2)) {
      price = makeDouble(limitEditController.text.trim());
    }
    final amount = Decimal.parse(amountEditController.text.trim());
    totalEditController.text = (amount * Decimal.parse(price.toString()))
        .toString();
  }

  void _tapOnPercentItem(String percentStr) {
    final percent = double.parse(percentStr) / 100;
    final dData = _controller.dashboardData.value;
    final isBuy = _controller.selectedBuySellTab.value == 0;
    var price = 0.0;

    if (isBuy) {
      if (selectedBuySubTabIndex.value == 0 || selectedBuySubTabIndex.value == 1) {
        price = makeDouble(priceEditController.text.trim());
        if (price <= 0 && selectedBuySubTabIndex.value == 1) {
          price = _controller.dashboardData.value.orderData?.buyPrice ?? 0;
        }
      } else if (selectedBuySubTabIndex.value == 2) {
        price = makeDouble(limitEditController.text.trim());
      }
      if (price <= 0) {
        showToast(
          selectedBuySubTabIndex.value == 2
              ? "Please input your limit".tr
              : "Please input your price".tr,
        );
        return;
      }
      final amount =
          (_controller.selfBalance.value.total?.baseWallet?.balance ?? 0) /
          price;
      final feesPercentage =
          ((dData.feesSettings?.makerFees ?? 0) >
                  (dData.feesSettings?.takerFees ?? 0)
              ? dData.feesSettings?.makerFees
              : dData.feesSettings?.takerFees) ??
          0;
      final total = amount * percent * price;
      final fees = (total * feesPercentage) / 100;
      amountEditController.text = coinFormat((total - fees) / price);
      if (selectedBuySubTabIndex.value != 1) {
        totalEditController.text = coinFormat(total - fees);
      }
    } else {
      if (selectedSellSubTabIndex.value == 0 || selectedSellSubTabIndex.value == 1) {
        price = makeDouble(priceEditController.text.trim());
        if (price <= 0 && selectedSellSubTabIndex.value == 1) {
          price = _controller.dashboardData.value.orderData?.sellPrice ?? 0;
        }
      } else if (selectedSellSubTabIndex.value == 2) {
        price = makeDouble(limitEditController.text.trim());
      }
      if (price <= 0) {
        showToast(
          selectedSellSubTabIndex.value == 2
              ? "Please input your limit".tr
              : "Please input your price".tr,
        );
        return;
      }
      final amountPercentage =
          (_controller.selfBalance.value.total?.tradeWallet?.balance ?? 0) *
          percent;
      amountEditController.text = coinFormat(amountPercentage);
      if (selectedSellSubTabIndex.value != 1) {
        totalEditController.text = coinFormat(amountPercentage * price);
      }
    }
  }

  void _clearInputViews() {
    amountEditController.text = "";
    totalEditController.text = "";
    limitEditController.text = "";
    priceEditController.text = "";
    takeProfitController.text = "";
    takeLossController.text = "";
  }

  void _checkInputData() {
    final dData = _controller.dashboardData.value.orderData;
    final isBuy = _controller.selectedBuySellTab.value == 0;
    final amount = makeDouble(amountEditController.text.trim());
    if (amount <= 0) {
      showToast("Please input your amount".tr);
      return;
    }

    if ((isBuy && selectedBuySubTabIndex.value == 0) ||
        (!isBuy && selectedSellSubTabIndex.value == 0)) {
      final price = makeDouble(priceEditController.text.trim());
      if (price <= 0) {
        showToast("Please input your price".tr);
        return;
      }
      if (_controller.tolerance != null) {
        final lowT = _controller.tolerance?.lowTolerance ?? 0;
        if (lowT > 0 && price < lowT) {
          showToast("${"Price is too low, it must be at least".tr} $lowT");
          return;
        }
        final highT = _controller.tolerance?.highTolerance ?? 0;
        if (highT > 0 && price > highT) {
          showToast("${"Price is too high, it must be at most".tr} $highT");
          return;
        }
      }
      hideKeyboard();
      _controller.placeOrderLimit(
        isBuy,
        dData?.baseCoinId ?? 0,
        dData?.tradeCoinId ?? 0,
        price,
        amount,
        () => _clearInputViews(),
      );
    } else if ((isBuy && selectedBuySubTabIndex.value == 1) ||
        (!isBuy && selectedSellSubTabIndex.value == 1)) {
      final enteredPrice = makeDouble(priceEditController.text.trim());
      final price = enteredPrice > 0
          ? enteredPrice
          : (isBuy ? dData?.sellPrice ?? 0 : dData?.buyPrice ?? 0);
      hideKeyboard();
      _controller.placeOrderMarket(
        isBuy,
        dData?.baseCoinId ?? 0,
        dData?.tradeCoinId ?? 0,
        price,
        amount,
        () => _clearInputViews(),
      );
    } else if ((isBuy && selectedBuySubTabIndex.value == 2) ||
        (!isBuy && selectedSellSubTabIndex.value == 2)) {
      final stop = makeDouble(priceEditController.text.trim());
      if (stop <= 0) {
        showToast("Please input your stop".tr);
        return;
      }
      final limit = makeDouble(limitEditController.text.trim());
      if (limit <= 0) {
        showToast("Please input your limit".tr);
        return;
      }
      if (isBuy && stop >= limit) {
        showToast("stop value must be less than limit".tr);
        return;
      }
      if (!isBuy && stop <= limit) {
        showToast("stop value must be greater than limit".tr);
        return;
      }
      hideKeyboard();
      _controller.placeOrderStopMarket(
        isBuy,
        dData?.baseCoinId ?? 0,
        dData?.tradeCoinId ?? 0,
        amount,
        limit,
        stop,
        () => _clearInputViews(),
      );
    }
  }
}

// ── TP/SL Toggle Row Widget ───────────────────────────────────────────────────
class _TpSlToggleRow extends StatelessWidget {
  const _TpSlToggleRow({required this.enabled, required this.onToggle});

  final bool enabled;
  final Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => onToggle(!enabled),
          child: SizedBox(
            width: 12,
            height: 12,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: enabled ? gBuyColor : Colors.transparent,
                  border: Border.all(
                    color: enabled
                        ? gBuyColor
                        : Theme.of(context).primaryColorLight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: enabled
                    ? const Icon(Icons.check, size: 9, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
        hSpacer5(),
        Text(
          'TP/SL',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w400,
            fontSize: 12,
            fontFamily: "DMSans",
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  fontFamily: "DMSans",
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Slider Percent Row ────────────────────────────────────────────────────────
class _SliderPercentRow extends StatefulWidget {
  const _SliderPercentRow({required this.onTap});
  final Function(String) onTap;

  @override
  State<_SliderPercentRow> createState() => _SliderPercentRowState();
}

class _SliderPercentRowState extends State<_SliderPercentRow> {
  double _sliderValue = 0;
  final List<double> points = [0, 25, 50, 75, 100];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white.withOpacity(0.5),
              inactiveTrackColor: Color(0XFF1A1A1A),
              thumbColor: Colors.transparent,
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 100,
              divisions: 4,
              onChanged: (v) {
                setState(() => _sliderValue = v);
                widget.onTap(v.toStringAsFixed(0));
              },
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: points.map((point) {
                  bool isActive = _sliderValue >= point;
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.5)
                          : Color(0XFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TradeBalanceAddView ───────────────────────────────────────────────────────
class TradeBalanceAddView extends StatelessWidget {
  const TradeBalanceAddView({
    super.key,
    required this.coinPair,
    required this.isBuy,
  });

  final CoinPair coinPair;
  final bool isBuy;

  @override
  Widget build(BuildContext context) {
    hideKeyboard();
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttonText(
            "Deposit".tr,
            bgColor: Colors.transparent,
            textColor: context.theme.primaryColor,
            onPress: () async {
              Navigator.pop(context);
              final currencyCode = isBuy
                  ? coinPair.parentCoinName
                  : coinPair.childCoinName;
              final wallet = await getWalletList(currencyCode ?? '');
              if (wallet != null) {
                if (wallet.currencyType == CurrencyType.crypto) {
                  Get.to(() => WalletCryptoDepositScreen(wallet: wallet));
                } else if (wallet.currencyType == CurrencyType.fiat) {
                  Get.to(() => WalletFiatDepositScreen(wallet: wallet));
                }
              } else {
                showToast("Wallet not found".tr);
              }
            },
          ),
          buttonText(
            "Transfer".tr,
            bgColor: Colors.transparent,
            textColor: context.theme.primaryColor,
            onPress: () {
              Navigator.pop(context);
              Get.to(() => SwapScreen(prePair: coinPair));
            },
          ),
        ],
      ),
    );
  }

  Future<Wallet?> getWalletList(String code) async {
    if (gUserRx.value.id == 0) return null;
    showLoadingDialog();
    try {
      final resp = await APIRepository().getWalletList(
        1,
        type: WalletViewType.spot,
        search: code,
      );
      hideLoadingDialog();
      if (resp.success) {
        final wallets = resp.data[APIKeyConstants.wallets];
        if (wallets != null) {
          final listResponse = ListResponse.fromJson(wallets);
          final walletMap = listResponse.data!.firstWhere(
            (x) => x[APIKeyConstants.coinType] == code,
          );
          return Wallet.fromJson(walletMap);
        }
      }
      return null;
    } catch (err) {
      hideLoadingDialog();
      return null;
    }
  }
}

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final Function(int) onChange;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChange,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(0, size.height + 5),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (index) {
                    bool isSelected = index == widget.selectedIndex;

                    return GestureDetector(
                      onTap: () {
                        widget.onChange(index);
                        _toggleDropdown();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00B052) // ✅ GREEN
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.items[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontFamily: "DMSans",
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  widget.items[widget.selectedIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: "DMSans",
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
