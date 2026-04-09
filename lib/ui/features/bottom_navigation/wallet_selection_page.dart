import 'dart:async';

import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import 'wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';
import 'wallet/wallet_fiat_deposit/wallet_fiat_deposit_screen.dart';
import 'wallet/wallet_fiat_withdrawal/wallet_fiat_withdrawal_screen.dart';
import 'wallet/wallet_widgets.dart';

class WalletSelectionPage extends StatefulWidget {
  const WalletSelectionPage({super.key, required this.fromKey, this.walletList, this.onSelect});

  final String fromKey;
  final List<Wallet>? walletList;
  final Function(Wallet)? onSelect;

  @override
  State<WalletSelectionPage> createState() => _WalletSelectionPageState();
}

class _WalletSelectionPageState extends State<WalletSelectionPage> {
  Timer? _searchTimer;
  RxBool isLoadingWallets = false.obs;
  ListResponse listResponse = ListResponse();
  RxList<Wallet> walletList = <Wallet>[].obs;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.fromKey == FromKey.swap && widget.walletList != null) {
        walletList.value = widget.walletList!;
      } else {
        getWalletList(widget.fromKey, isLoadMore: false);
      }
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          textFieldSearch(controller: searchController, height: Dimens.btnHeightMid, onTextChange: onTextChanged),
          Obx(() {
            return walletList.isEmpty
                ? handleEmptyViewWithLoading(isLoadingWallets.value, message: "Your wallets will listed here".tr, height: Dimens.mainContendGapTop)
                : Expanded(
                    child: ListView.builder(
                      itemCount: walletList.length,
                      itemBuilder: (context, index) {
                        if (listResponse.nextPageUrl.isValid && index == (walletList.length - 1)) {
                          WidgetsBinding.instance.addPostFrameCallback((timeStamp) => getWalletList(widget.fromKey, isLoadMore: true));
                        }
                        final wallet = walletList[index];

                        if (widget.fromKey == FromKey.swap) {
                          return SwapWalletItemView(
                              wallet: wallet,
                              onTap: () {
                                if (widget.onSelect != null) {
                                  hideKeyboard();
                                  widget.onSelect!(wallet);
                                  Get.back();
                                }
                              });
                        } else {
                          return SpotWalletItemView(
                            wallet: walletList[index],
                            isHide: gIsBalanceHide.value,
                            onTap: () {
                              hideKeyboard();
                              if (widget.fromKey == FromKey.buy && wallet.isDeposit == 1) {
                                if (wallet.currencyType == CurrencyType.crypto) {
                                  // navigationTo(context, sFull: WalletDepositScreen(wallet: wallet));
                                  navigationTo(context, sFull: WalletCryptoDepositScreen(wallet: wallet));
                                } else if (wallet.currencyType == CurrencyType.fiat) {
                                  navigationTo(context, sFull: WalletFiatDepositScreen(wallet: wallet));
                                }
                              } else if (widget.fromKey == FromKey.sell && wallet.isWithdrawal == 1) {
                                if (wallet.currencyType == CurrencyType.crypto) {
                                  navigationTo(context, sFull: WalletCryptoWithdrawScreen(wallet: wallet));
                                } else if (wallet.currencyType == CurrencyType.fiat) {
                                  navigationTo(context, sFull: WalletFiatWithdrawalScreen(wallet: wallet));
                                }
                              }
                            },
                          );
                        }
                      },
                    ),
                  );
          }),
        ],
      ),
    );
  }

  void onTextChanged(String text) {
    if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      if (widget.fromKey == FromKey.swap) {
        if (text.isEmpty) {
          walletList.value = widget.walletList ?? [];
        } else {
          text = text.toLowerCase();
          final list = (widget.walletList ?? []).where((element) => (element.coinType ?? "").toLowerCase().contains(text)).toList();
          walletList.value = list;
        }
      } else {
        getWalletList(widget.fromKey, isLoadMore: false);
      }
    });
  }

  Future<void> getWalletList(String fromKey, {bool isLoadMore = false}) async {
    if (gUserRx.value.id == 0) return;

    if (!isLoadMore) {
      listResponse = ListResponse();
      walletList.clear();
    }
    listResponse.currentPage = (listResponse.currentPage ?? 0) + 1;
    final search = searchController.text.trim();
    isLoadingWallets.value = true;
    APIRepository().getWalletList(listResponse.currentPage!, type: WalletViewType.spot, search: search).then((resp) {
      isLoadingWallets.value = false;
      if (resp.success) {
        final wallets = resp.data[APIKeyConstants.wallets];
        if (wallets != null) {
          listResponse = ListResponse.fromJson(wallets);
          if (listResponse.data != null) {
            List<Wallet> list = List<Wallet>.from(listResponse.data!.map((x) => Wallet.fromJson(x)));
            list = list.where((element) => fromKey == FromKey.buy ? element.isDeposit == 1 : element.isWithdrawal == 1).toList();
            walletList.addAll(list);
          }
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoadingWallets.value = false;
      showToast(err.toString());
    });
  }
}

class SwapWalletItemView extends StatelessWidget {
  const SwapWalletItemView({super.key, required this.wallet, required this.onTap});

  final Wallet wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge, vertical: Dimens.paddingMid),
      child: InkWell(
          onTap: onTap,
          child: Row(children: [
            WalletNameView(wallet: wallet, hideImage: true),
            Expanded(child: TextRobotoAutoBold(coinFormat(wallet.balance), textAlign: TextAlign.end))
          ])),
    );
  }
}
