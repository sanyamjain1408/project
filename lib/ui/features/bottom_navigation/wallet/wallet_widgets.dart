import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/activity/activity_screen.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../helper/app_checker.dart';
import 'swap/swap_screen.dart';
import 'wallet_controller.dart';
import 'wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';
import 'wallet_fiat_deposit/wallet_fiat_deposit_screen.dart';
import 'wallet_fiat_withdrawal/wallet_fiat_withdrawal_screen.dart';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _dmSans = 'DMSans';

class WalletNameView extends StatelessWidget {
  const WalletNameView({
    super.key,
    required this.wallet,
    this.isExpanded = false,
    this.hideImage,
  });

  final Wallet wallet;
  final bool isExpanded;
  final bool? hideImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hideImage != true)
          showImageNetwork(
            imagePath: wallet.coinIcon,
            width: 30,
            height: 30,
            bgColor: Colors.transparent,
          ),
        if (hideImage != true) hSpacer10(),
        isExpanded ? Expanded(child: _nameView(context)) : _nameView(context),
      ],
    );
  }

  Column _nameView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          wallet.coinType ?? "",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
            fontStyle: FontStyle.normal,
            height: 1.33,
          ),
        ),
        Text(
          wallet.childfullname ?? "",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: _dmSans,
            fontStyle: FontStyle.normal,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}

class CommonWalletItemView extends StatelessWidget {
  const CommonWalletItemView({
    super.key,
    required this.wallet,
    required this.fromType,
    required this.isHide,
  });

  final Wallet wallet;
  final int fromType;
  final bool isHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Row(
        children: [
          Expanded(child: WalletNameView(wallet: wallet, isExpanded: true)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isHide
                    ? const TextRobotoAutoBold(
                        "******",
                        fontSize: Dimens.fontSizeMid,
                        textAlign: TextAlign.end,
                      )
                    : TextRobotoAutoBold(coinFormat(wallet.balance)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    buttonOnlyIcon(
                      iconData: Icons.send_outlined,
                      size: Dimens.iconSizeMin,
                      visualDensity: minimumVisualDensity,
                      iconColor: context.theme.primaryColor,
                      onPress: () => _showTransferView(context, true),
                    ),
                    buttonOnlyIcon(
                      iconData: Icons.wallet_outlined,
                      size: Dimens.iconSizeMin,
                      visualDensity: minimumVisualDensity,
                      iconColor: context.theme.primaryColor,
                      onPress: () => _showTransferView(context, false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransferView(BuildContext context, bool isSend) {
    hideKeyboard();
    showModalSheetFullScreen(
      context,
      WalletTransferView(
        isSend: isSend,
        fromType: fromType,
        coinType: wallet.coinType ?? '',
        onSubmit: (amount) {
          Get.find<WalletController>().transferWalletAmount(
            wallet,
            fromType,
            amount,
            isSend,
          );
        },
      ),
    );
  }
}

class WalletTransferView extends StatelessWidget {
  const WalletTransferView({
    super.key,
    required this.isSend,
    required this.fromType,
    required this.coinType,
    required this.onSubmit,
  });

  final bool isSend;
  final int fromType;
  final String coinType;
  final Function(double) onSubmit;

  @override
  Widget build(BuildContext context) {
    final title = isSend ? "Send Balance".tr : "Receive Balance".tr;
    final name = fromType == WalletViewType.p2p ? "P2P" : "Future";
    final subtitle = isSend
        ? "sent_coin_to_spot_wallet".trParams({"coin": coinType, "name": name})
        : "receive_coin_from_spot_wallet".trParams({
            "coin": coinType,
            "name": name,
          });
    final amountEditController = TextEditingController();
    RxString error = "".obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        vSpacer15(),
        TextRobotoAutoBold(title),
        vSpacer5(),
        TextRobotoAutoNormal(subtitle, maxLines: 2),
        vSpacer20(),
        textFieldWithSuffixIcon(
          controller: amountEditController,
          labelText: "Amount".tr,
          hint: "Your amount".tr,
          type: const TextInputType.numberWithOptions(decimal: true),
          onTextChange: (text) => error.value = "",
        ),
        Obx(
          () => error.value.isValid
              ? TextRobotoAutoNormal(
                  error.value,
                  color: Colors.red,
                  textAlign: TextAlign.center,
                )
              : vSpacer0(),
        ),
        vSpacer20(),
        buttonRoundedMain(
          text: "Exchange".tr,
          onPress: () {
            final amount = makeDouble(amountEditController.text.trim());
            if (amount <= 0) {
              error.value = "amount_must_greater_than_0".tr;
              return;
            }
            hideKeyboard();
            onSubmit(amount);
          },
        ),
        vSpacer15(),
      ],
    );
  }
}

String _formatBalance(double? value) {
  if (value == null || value == 0) return "0.00";
  final intDigits = value.truncate().abs().toString().length;
  final decimals = intDigits <= 2 ? 4 : 2;
  return value.toStringAsFixed(decimals);
}

class SpotWalletItemView extends StatelessWidget {
  const SpotWalletItemView({
    super.key,
    required this.wallet,
    this.onTap,
    required this.isHide,
  });

  final Wallet wallet;
  final VoidCallback? onTap;
  final bool isHide;

  @override
  Widget build(BuildContext context) {
    String currencyName = getSettingsLocal()?.currency ?? DefaultValue.currency;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap:
            onTap ??
            () {
              hideKeyboard();
              showBottomSheetDynamic(
                context,
                SpotWalletDetailsView(wallet: wallet),
                title: "Wallet Details".tr,
              );
            },
        child: Row(
          children: [
            Expanded(child: WalletNameView(wallet: wallet, isExpanded: true)),
            Expanded(
              child: isHide
                  ? const TextRobotoAutoBold(
                      "******",
                      fontSize: Dimens.fontSizeMid,
                      textAlign: TextAlign.end,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatBalance(wallet.availableBalance),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: _dmSans,
                            fontStyle: FontStyle.normal,
                            height: 1.33,
                          ),
                        ),
                        Text(
                          currencyFormat(
                            wallet.availableBalanceUsd,
                            name: currencyName,
                          ),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: _dmSans,
                            fontStyle: FontStyle.normal,
                            height: 1.33,
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

class SpotWalletDetailsView extends StatelessWidget {
  SpotWalletDetailsView({super.key, required this.wallet});

  final Wallet wallet;

  final _controller = Get.find<WalletController>();

  @override
  Widget build(BuildContext context) {
    final pairList = _controller.getCoinPairList(wallet.coinType ?? "");
    final isSwapActive = getSettingsLocal()?.swapStatus == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          vSpacer10(),
          WalletNameView(wallet: wallet),
          vSpacer20(),
          WalletBalanceView(
            title: 'Total Balance'.tr,
            coin: wallet.total,
            currency: wallet.totalBalanceUsd,
          ),
          dividerHorizontal(),
          WalletBalanceView(
            title: 'On Order'.tr,
            coin: wallet.onOrder,
            currency: wallet.onOrderUsd,
          ),
          dividerHorizontal(),
          WalletBalanceView(
            title: 'Available Balance'.tr,
            coin: wallet.availableBalance,
            currency: wallet.availableBalanceUsd,
          ),
          dividerHorizontal(),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (wallet.isDeposit == 1)
                _btnWalletDetails(
                  "Deposit".tr,
                  true,
                  onTap: () {
                    if (wallet.currencyType == CurrencyType.crypto) {
                      Get.to(() => WalletCryptoDepositScreen(wallet: wallet));
                    } else if (wallet.currencyType == CurrencyType.fiat) {
                      Get.to(() => WalletFiatDepositScreen(wallet: wallet));
                    }
                  },
                ),
              if (wallet.isWithdrawal == 1)
                _btnWalletDetails(
                  "Withdraw".tr,
                  false,
                  onTap: () {
                    if (wallet.currencyType == CurrencyType.crypto) {
                      Get.to(() => WalletCryptoWithdrawScreen(wallet: wallet));
                    } else if (wallet.currencyType == CurrencyType.fiat) {
                      Get.to(() => WalletFiatWithdrawalScreen(wallet: wallet));
                    }
                  },
                ),
              if (wallet.tradeStatus == 1 && pairList.isNotEmpty)
                PopupMenuView(
                  pairList,
                  child: _btnWalletDetails("Trade".tr, false),
                  onSelected: (selected) {
                    Get.back();
                    final pair = _controller.coinPairs.firstWhere(
                      (element) => element.coinPairName == selected,
                    );
                    getDashboardController().selectedCoinPair.value = pair;
                    getRootController().changeBottomNavIndex(
                      AppBottomNavKey.trade,
                    );
                  },
                ),
              if (isSwapActive)
                _btnWalletDetails(
                  "Swap".tr,
                  false,
                  onTap: () {
                    Get.to(() => SwapScreen(preWallet: wallet));
                  },
                ),
            ],
          ),
          vSpacer10(),
        ],
      ),
    );
  }

  Widget _btnWalletDetails(
    String title,
    bool isDeposit, {
    VoidCallback? onTap,
  }) {
    final color = isDeposit ? null : Get.theme.dialogTheme.backgroundColor;
    return buttonText(
      title,
      bgColor: color,
      fontSize: Dimens.fontSizeMidExtra,
      visualDensity: VisualDensity.compact,
      onPress: onTap == null
          ? null
          : () {
              Get.back();
              onTap();
            },
    );
  }
}

class WalletBalanceView extends StatelessWidget {
  const WalletBalanceView({
    super.key,
    required this.title,
    this.coin,
    this.currency,
  });

  final String title;
  final double? coin;
  final double? currency;

  @override
  Widget build(BuildContext context) {
    String currencyName = getSettingsLocal()?.currency ?? DefaultValue.currency;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: TextRobotoAutoBold(
            title,
            maxLines: 1,
            color: context.theme.primaryColorLight,
          ),
        ),
        Expanded(
          flex: 3,
          child: gIsBalanceHide.value
              ? const TextRobotoAutoBold(
                  "******",
                  fontSize: Dimens.fontSizeMid,
                  textAlign: TextAlign.end,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextRobotoAutoBold(coinFormat(coin)),
                    TextRobotoAutoNormal(
                      currencyFormat(currency, name: currencyName),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class TotalBalanceView extends StatelessWidget {
  const TotalBalanceView(
    this.isHide,
    this.totalBalance, {
    super.key,
    this.onHide,
    this.title,
    this.totalUsd,
    this.onHistoryTap,
    this.coins,
    this.selectedCoin,
    this.onSelectCoin,
  });

  final bool isHide;
  final double? totalBalance;
  final double? totalUsd;
  final Function(bool)? onHide;
  final VoidCallback? onHistoryTap;
  final String? title;
  final List<String>? coins;
  final String? selectedCoin;
  final Function(String)? onSelectCoin;

  @override
  Widget build(BuildContext context) {
    String currencyName = gUserRx.value.currency ?? DefaultValue.currency;

    final iconData = isHide
        ? Icons.visibility_off_rounded
        : Icons.visibility_outlined;

    final titleL = title ?? 'Total Balance'.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 TOP CONTENT (same as before)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TextRobotoAutoNormal(titleL),
                          buttonOnlyIcon(
                            iconData: iconData,
                            size: 15,
                            iconColor: Colors.white.withOpacity(0.5),
                            visualDensity: minimumVisualDensity,
                            onPress: () {
                              GetStorage().write(
                                PreferenceKey.isBalanceHide,
                                !isHide,
                              );
                              gIsBalanceHide.value = !isHide;
                              if (onHide != null) onHide!(!isHide);
                            },
                          ),
                        ],
                      ),

                      GestureDetector(
                        onTap: () => Get.to(() => const ActivityScreen()),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: RotatingIcon(), //  bas yaha replace karo
                        ),
                      ),
                    ],
                  ),

                  isHide
                      ? TextRobotoAutoNormal("Balance_hidden".tr)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic, //  important
                          children: [
                            Text(
                              '\$${double.parse(coinFormat(totalBalance)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSans',
                                color: Colors.white,
                              ),
                            ),
                            hSpacer5(),
                            if (coins.isValid || selectedCoin.isValid)
                              PopupMenuView(
                                coins ?? [],
                                child: _coinNameView(
                                  selectedCoin,
                                  coins.isValid,
                                ),
                                onSelected: (selected) => onSelectCoin == null
                                    ? null
                                    : onSelectCoin!(selected),
                              ),
                          ],
                        ),

                  if (!isHide) vSpacer2(),

                  if (!isHide)
                    Text(
                      "≈ \$${currencyFormat(totalUsd)} ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DMSans',
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),

                  const SizedBox(height: 5),

                  if (!isHide)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Today ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const TextSpan(
                            text: "+\$8.84(0.71%)",
                            style: TextStyle(
                              color: Color(0xFFCCFF00),
                              fontSize: 12,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // 🔥 spacing before bottom button

        // 🔻 BOTTOM RIGHT BUTTON
        if (onHistoryTap != null)
          Align(
            alignment: Alignment.bottomRight,
            child: buttonOnlyIcon(
              iconData: Icons.history,
              visualDensity: minimumVisualDensity,
              onPress: onHistoryTap,
            ),
          ),
      ],
    );
  }

  Row _coinNameView(String? coinType, bool showIcon) {
    return Row(
      children: [
        Text(
          coinType ?? "",
          style: TextStyle(
            fontSize: 15, // Dimens.fontSizeMidExtra ki jagah apna size
            fontWeight: FontWeight.w300,
            fontFamily: 'DMSans',
            height: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        if (showIcon)
          Icon(
            Icons.expand_more,
            size: 16, // Dimens.iconSizeMin ki jagah fixed ya custom
            color: Colors.white, // ya Get.theme.primaryColor bhi rakh sakte ho
          ),
      ],
    );
  }
}

class WalletTopButtonsView extends StatelessWidget {
  const WalletTopButtonsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final btnWidth = (constraints.maxWidth - 20) / 3;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _WalletActionButton(
              label: "Add Funds".tr,
              iconPath: null, //  NO ICON
              isMain: true,
              width: btnWidth,
              onTap: () => _showAddFundsSheet(context),
            ),
            _WalletActionButton(
              label: "Withdraw".tr,
              iconPath: "assets/images/withdraw.png", // asset icon
              isMain: false,
              width: btnWidth,
              onTap: () => _showWithdrawSheet(context),
            ),
            if (getSettingsLocal()?.swapStatus == 1)
              _WalletActionButton(
                label: "Transfer".tr,
                iconPath: "assets/images/transfer.png", // asset icon
                isMain: false,
                width: btnWidth,
                onTap: () => Get.to(() => const SwapScreen()),
              )
            else
              SizedBox(width: btnWidth),
          ],
        );
      },
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  const _WalletActionButton({
    required this.label,
    required this.width,
    required this.onTap,
    this.iconPath,
    required this.isMain,
  });

  final String label;
  final String? iconPath; // ✅ asset icon
  final bool isMain;
  final double width;
  final VoidCallback onTap;

  static const _green = Color(0xFFB5F000);

  @override
  Widget build(BuildContext context) {
    final bgColor = isMain ? _green : _secondary;
    final textColor = isMain ? Colors.black : Colors.white;

    return SizedBox(
      width: width,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 🔹 radius control
          ),
          padding: const EdgeInsets.symmetric(horizontal: 7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ ICON (only if exists)
            if (iconPath != null) ...[
              Image.asset(
                iconPath!,
                height: 18,
                width: 18,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 2),
            ],

            SizedBox(width: 5),

            // ✅ TEXT (fully customizable)
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13, // change kar sakta hai
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddFundsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AddFundsSheet(),
  );
}

class _AddFundsSheet extends StatelessWidget {
  const _AddFundsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
           
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                const Text(
                  "Select Deposit Method",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                    height: 24/16
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          _item(
            icon: 'assets/images/deposit.png',
            title: 'Deposit Crypto',
            subtitle: 'Deposit Crypto from other exchanges/wallet to Trapix Exchange.',
            onTap: () {
              Get.back();
              Get.to(() => WalletCryptoDepositScreen());
            },
          ),
          _item(
            icon: 'assets/icons/deposit.png',
            title: 'Deposit Fiat',
            subtitle: 'Deposit INR to buy with wallet balance or spot.',
            onTap: () {},
          ),
          _item(
            icon: 'assets/icons/passport.png',
            title: 'Buy crypto',
            subtitle: 'Buy instantly using Visa, Mastercard and More.',
            onTap: () {},
          ),
          _item(
            icon: 'assets/icons/p2p.png',
            title: 'P2P Trading',
            subtitle: 'Buy directly from user. Competitive Pricing. Local Payment.',
            onTap: () {},
          ),
          _item(
            icon: 'assets/images/icon.png',
            title: 'Receive Via Trapix User',
            subtitle: 'Receive crypto from other Trapix user',
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _item({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Image.asset(icon, width: 20, height: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                      height: 24/16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                      height: 12/10
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

void _showWithdrawSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _WithdrawSheet(),
  );
}

class _WithdrawSheet extends StatelessWidget {
  const _WithdrawSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                const Text(
                  "Select Withdraw Method",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSans',
                    height: 24 / 16,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          _item(
            icon: 'assets/images/deposit.png',
            title: 'Withdraw Crypto',
            subtitle: 'Withdraw Crypto to other exchanges/wallet from Trapix Exchange.',
            onTap: () {
              Get.back();
              Get.to(() => WalletCryptoWithdrawScreen());
            },
          ),
          _item(
            icon: 'assets/icons/deposit.png',
            title: 'Withdraw Fiat',
            subtitle: 'Withdraw INR from wallet balance or spot.',
            onTap: () {},
          ),
          _item(
            icon: 'assets/icons/passport.png',
            title: 'Sell crypto',
            subtitle: 'Sell instantly using Visa, Mastercard and More.',
            onTap: () {},
          ),
          _item(
            icon: 'assets/icons/p2p.png',
            title: 'P2P Trading',
            subtitle: 'Sell directly to user. Competitive Pricing. Local Payment.',
            onTap: () {},
          ),
          _item(
            icon: 'assets/images/icon.png',
            title: 'Receive Via Trapix User',
            subtitle: 'Receive crypto from other Trapix user',
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _item({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Image.asset(icon, width: 20, height: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'DMSans',
                      height: 12 / 10,
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

class WalletRecentTransactionItemView extends StatelessWidget {
  const WalletRecentTransactionItemView({
    super.key,
    required this.history,
    required this.type,
  });

  final History history;
  final String type;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStatusData(history.status ?? 0);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.paddingMid,
        horizontal: Dimens.paddingMid,
      ),
      child: Column(
        children: [
          TwoTextSpaceFixed(
            history.coinType ?? "",
            statusData.first,
            subColor: statusData.last,
            color: context.theme.primaryColor,
          ),
          TwoTextSpaceFixed('Amount'.tr, coinFormat(history.amount)),
          TwoTextSpaceFixed('Fees'.tr, coinFormat(history.fees)),
          TwoTextSpaceFixed(
            'Address'.tr,
            history.address ?? "",
            color: context.theme.primaryColorLight,
          ),
          TwoTextSpaceFixed(
            'Created At'.tr,
            formatDate(history.createdAt, format: dateTimeFormatDdMMMYyyyHhMm),
          ),
          dividerHorizontal(),
        ],
      ),
    );
  }
}

class WalletBalanceViewWithBg extends StatelessWidget {
  const WalletBalanceViewWithBg({super.key, this.balance});

  final double? balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingMid),
      decoration: boxDecorationRoundCorner(
        color: context.theme.dialogTheme.backgroundColor,
      ),
      child: Row(
        children: [
          TextRobotoAutoBold("Balance".tr),
          hSpacer10(),
          Expanded(
            child: TextRobotoAutoBold(
              coinFormat(balance),
              textAlign: TextAlign.end,
              fontSize: Dimens.fontSizeLarge,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ROTATING ICON ─────────────────────────────────────────────────────────────
class RotatingIcon extends StatefulWidget {
  const RotatingIcon({super.key});

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.1416 / 2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -3.1416 / 2, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    _controller!.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animation == null) {
      return Image.asset('assets/icons/time.png', width: 18, height: 18);
    }
    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        return Transform.rotate(angle: _animation!.value, child: child);
      },
      child: Image.asset('assets/icons/time.png', width: 18, height: 18),
    );
  }
}
