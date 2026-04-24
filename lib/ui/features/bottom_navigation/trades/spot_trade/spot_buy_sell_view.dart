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

  // ── NEW: TP/SL controllers ─────────────────────────────────────────────────
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
        if (subIndex == 0) {
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
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            vSpacer5(),

            // ── Order type dropdown ────────────────────────────────────────
            dropDownListIndex(
              ["Limit".tr, "Market".tr, "Stop-limit".tr],
              subIndex,
              "Limit".tr, //  hint text do
              (index) {
                tabIndex == 0
                    ? selectedBuySubTabIndex.value = index
                    : selectedSellSubTabIndex.value = index;
                _clearInputViews();
              },
              height: Dimens.btnHeightMid,
              hMargin: 0,
              bgColor: const Color(0xFF1A1A1A),
              radius: 10,
            ),
            vSpacer5(),

            // ── Limit Price ───────────────────────────────────────────────
            TradeTextFieldCalculate(
              controller: priceEditController,
              isEnable: subIndex != 1,
              text: subIndex == 1 ? "Market".tr : null,
              sTitle: subIndex == 2 ? "Stop".tr : "Limit Price".tr,
              sSubtitle: baseCType,
            ),
            vSpacer10(),

            // ── Stop field (Stop-limit only) ───────────────────────────────
            if (subIndex == 2)
              TradeTextFieldCalculate(
                controller: limitEditController,
                sTitle: "Limit".tr,
                sSubtitle: baseCType,
              ),
            if (subIndex == 2) vSpacer10(),

            // ── Qty ────────────────────────────────────────────────────────
            TradeTextFieldCalculate(
              controller: amountEditController,
              onTextChange: _onInputAmount,
              sTitle: "Qty".tr,
              sSubtitle: tradeCType,
            ),
            vSpacer10(),

            // ── Slider ─────────────────────────────────────────────────────
            _SliderPercentRow(onTap: _tapOnPercentItem),
            vSpacer5(),

            // ── Amount (Total) ─────────────────────────────────────────────
            TradeTextFieldCalculate(
              controller: totalEditController,
              isEnable: false,
              sTitle: "Amount".tr,
              sSubtitle: baseCType,
            ),
            vSpacer10(),

            // ── Available balance ──────────────────────────────────────────
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
            vSpacer10(),

            // ── TP/SL Toggle ────────────────────────────────────────────────
            Obx(
              () => _TpSlToggleRow(
                enabled: _tpSlEnabled.value,
                onToggle: (v) => _tpSlEnabled.value = v,
              ),
            ),
            vSpacer5(),

            // ── Take-Profit & Take-Loss fields ─────────────────────────────
            Obx(() {
              if (!_tpSlEnabled.value) return const SizedBox.shrink();
              return Column(
                children: [
                  TradeTextFieldCalculate(
                    controller: takeProfitController,
                    sTitle: "Take-Profit Price".tr,
                    sSubtitle: baseCType,
                  ),
                  vSpacer10(),
                  TradeTextFieldCalculate(
                    controller: takeLossController,
                    sTitle: "Take-Loss Price".tr,
                    sSubtitle: baseCType,
                  ),
                  vSpacer10(),
                ],
              );
            }),

            // ── Buy / Sell button ──────────────────────────────────────────
            if (isLoggedIn)
              buttonRoundedMain(
                text: "${isBuy ? "Buy".tr : "Sell".tr} $tradeCType",
                bgColor: isBuy ? gBuyColor : gSellColor,
                textColor: Colors.white,
                buttonHeight: Dimens.btnHeightMid,
                borderRadius: Dimens.radiusCornerLarge,
                onPress: () => _checkInputData(),
              ),
            vSpacer10(),
          ],
        );
      }),
    );
  }

  // ── Input logic (unchanged from original) ─────────────────────────────────

  void _onInputAmount(String amountStr) {
    var price = 0.0;
    final isBuy = _controller.selectedBuySellTab.value == 0;
    if ((isBuy && selectedBuySubTabIndex.value == 0) ||
        (!isBuy && selectedSellSubTabIndex.value == 0)) {
      price = makeDouble(priceEditController.text.trim());
    } else if ((isBuy && selectedBuySubTabIndex.value == 1) ||
        (!isBuy && selectedSellSubTabIndex.value == 1)) {
      return;
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
      if (selectedBuySubTabIndex.value == 0) {
        price = makeDouble(priceEditController.text.trim());
      } else if (selectedBuySubTabIndex.value == 1) {
        price = _controller.dashboardData.value.orderData?.buyPrice ?? 0;
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
      if (selectedSellSubTabIndex.value == 0) {
        price = makeDouble(priceEditController.text.trim());
      } else if (selectedSellSubTabIndex.value == 1) {
        price = _controller.dashboardData.value.orderData?.sellPrice ?? 0;
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
      final price = isBuy ? dData?.sellPrice ?? 0 : dData?.buyPrice ?? 0;
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

// ── TP/SL Toggle Row Widget ────────────────────────────────────────────────────
class _TpSlToggleRow extends StatelessWidget {
  const _TpSlToggleRow({required this.enabled, required this.onToggle});

  final bool enabled;
  final Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Green dot indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: enabled ? gBuyColor : Theme.of(context).primaryColorLight,
            shape: BoxShape.circle,
          ),
        ),
        hSpacer5(),
        TextRobotoAutoNormal(
          'TP/SL',
          fontSize: Dimens.fontSizeSmall,
          color: Theme.of(context).primaryColor,
        ),
        hSpacer5(),
        // "Last" label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextRobotoAutoNormal(
                'Last',
                fontSize: Dimens.fontSizeMin,
                color: Theme.of(context).primaryColorLight,
              ),
              const Icon(Icons.arrow_drop_down, size: 14),
            ],
          ),
        ),
        const Spacer(),
        // Toggle switch
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: gBuyColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

// ── Slider Percent Row (replaces old TradePercentView for slider style) ────────
class _SliderPercentRow extends StatefulWidget {
  const _SliderPercentRow({required this.onTap});
  final Function(String) onTap;

  @override
  State<_SliderPercentRow> createState() => _SliderPercentRowState();
}

class _SliderPercentRowState extends State<_SliderPercentRow> {
  double _sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Color(0xFF00B052),
            inactiveTrackColor: Color(0xFF00B052).withOpacity(0.2),
            thumbColor: Colors.white,
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
        // Percent labels row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0%', '25%', '50%', '75%', '100%'].map((label) {
              return Text(
                label,
                style: TextStyle(
                  fontSize: Dimens.fontSizeMin,
                  color: Theme.of(context).primaryColorLight,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TradeBalanceAddView  (unchanged — kept here so imports stay clean)
// ═════════════════════════════════════════════════════════════════════════════
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
