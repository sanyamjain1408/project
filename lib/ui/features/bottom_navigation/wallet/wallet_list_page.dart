import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../../side_navigation/activity/activity_screen.dart';
import 'wallet_controller.dart';
import 'wallet_widgets.dart';

class WalletListView extends StatefulWidget {
  const WalletListView({super.key, required this.fromType});

  final int fromType;

  @override
  State<WalletListView> createState() => _WalletListViewState();
}

class _WalletListViewState extends State<WalletListView> {
  final _controller = Get.find<WalletController>();
  final RxBool isLoading = false.obs;
  Timer? searchTimer;
  bool loadFromInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => initViewData());
  }

  @override
  void didUpdateWidget(covariant WalletListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => initViewData());
  }

  void initViewData({bool? keepSearch}) {
    if(keepSearch != true) _controller.searchController.text = '';
    if (widget.fromType == WalletViewType.spot) _controller.getWalletTotalValue();
    _getWalletListData();
  }

  Future<void> _getWalletListData() async {
    isLoading.value = true;
    _controller.getWalletList(widget.fromType, () => isLoading.value = false, isFromLoadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.fromType == WalletViewType.spot)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
            child: Column(
              children: [
                Obx(() {
                  final total = _controller.totalBalance.value;
                  return TotalBalanceViewSpot(gIsBalanceHide.value, total, onHistoryTap: () => Get.to(() => const ActivityScreen()), onHide: (value) => _controller.walletList.refresh());
                }),
                vSpacer10(),
                const WalletTopButtonsView(),
              ],
            ),
          ),
        vSpacer10(),
        Row(
          children: [
            textFieldSearch(
                controller: _controller.searchController,
                height: Dimens.btnHeightMid,
                width: context.width - 60,
                borderRadius: Dimens.radiusCornerMid,
                onTextChange: _onTextChanged,
                onSearch: () => _onTextChanged('')),
            buttonOnlyIcon(iconData: Icons.refresh, visualDensity: minimumVisualDensity, onPress: () {
              if(isLoading.value) return;
              initViewData(keepSearch: true);
            })
          ],
        ),
        Obx(() {
          return _controller.walletList.isEmpty
              ? handleEmptyViewWithLoading(isLoading.value, message: "Your wallets will listed here".tr)
              : Expanded(
                  child: ListView.builder(
                    itemCount: _controller.walletList.length,
                    itemBuilder: (context, index) {
                      if (_controller.hasMoreData && index == (_controller.walletList.length - 1)) {
                        _controller.getWalletList(widget.fromType, () {}, isFromLoadMore: true);
                      }

                      final item = _controller.walletList[index];
                      if (widget.fromType == WalletViewType.spot) {
                        return SpotWalletItemView(wallet: item, isHide: gIsBalanceHide.value);
                      } else if (widget.fromType == WalletViewType.future || widget.fromType == WalletViewType.p2p) {
                        return CommonWalletItemView(wallet: item, fromType: widget.fromType, isHide: gIsBalanceHide.value);
                      }
                      return vSpacer0();
                    },
                  ),
                );
        })
      ],
    );
  }

  void _onTextChanged(String text) {
    if (searchTimer?.isActive ?? false) searchTimer?.cancel();
    searchTimer = Timer(const Duration(seconds: 1), () => _getWalletListData());
  }
}

class TotalBalanceViewSpot extends StatelessWidget {
  const TotalBalanceViewSpot(this.isHide, this.total, {super.key, this.onHide, this.onHistoryTap});

  final bool isHide;
  final TotalBalance? total;
  final Function(bool)? onHide;
  final VoidCallback? onHistoryTap;

  @override
  Widget build(BuildContext context) {
    String currencyName = gUserRx.value.currency ?? total?.currency ?? DefaultValue.currency;
    final iconData = isHide ? Icons.visibility_off_outlined : Icons.visibility_outlined;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextRobotoAutoNormal('Total Balance'.tr),
                buttonOnlyIcon(
                    iconData: iconData,
                    visualDensity: minimumVisualDensity,
                    onPress: () {
                      GetStorage().write(PreferenceKey.isBalanceHide, !isHide);
                      gIsBalanceHide.value = !isHide;
                      if (onHide != null) onHide!(!isHide);
                    })
              ],
            ),
            isHide
                ? TextRobotoAutoNormal("Balance_hidden".tr)
                : TextRobotoAutoBold("${currencyFormat(total?.total)} $currencyName", fontSize: Dimens.fontSizeLarge),
          ],
        ),
        const Spacer(),
        if (onHistoryTap != null) buttonOnlyIcon(iconData: Icons.history, visualDensity: minimumVisualDensity, onPress: onHistoryTap)
      ],
    );
  }
}

// ignore_for_file: must_be_immutable
// class WalletListPage extends StatelessWidget {
//   WalletListPage({super.key, required this.fromType});
//
//   final int fromType;
//   final _controller = Get.find<WalletController>();
//   final _scrollController = ScrollController();
//   final refreshController = EasyRefreshController(controlFinishRefresh: true);
//
//   // Timer? _searchTimer;
//
//   void initViewData() {
//     _controller.searchController.text = '';
//     _controller.walletListFromType = fromType;
//     _controller.clearListView();
//     _controller.getWalletTotalValue();
//     _scrollController.addListener(() {
//       if (_scrollController.position.maxScrollExtent == _scrollController.offset) {
//         if (_controller.hasMoreData) _controller.getWalletList(isFromLoadMore: true);
//       }
//     });
//     // refreshController.finishRefresh();
//     refreshController.callRefresh(force: true);
//     // _controller.refreshController.callRefresh(force: true);
//     // print(">>>>> refreshController ${refreshController.hashCode}");
//   }
//
//   Future<void> _getWalletListData() async {
//     print(">>>>> _getWalletListData $fromType");
//     return _controller.getWalletList(isFromLoadMore: false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print(">>>>> fromType $fromType");
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) => initViewData());
//
//     return EasyRefresh(
//       controller: refreshController,
//       // controller: _controller.refreshController,
//       refreshOnStart: true,
//       onRefresh: _getWalletListData,
//       header: ClassicHeader(showText: false, iconTheme: const IconThemeData().copyWith(color: context.theme.focusColor)),
//       child: Obx(() {
//         final total = _controller.totalBalance.value;
//         return ListView(
//           padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
//           controller: _scrollController,
//           children: [
//             if (_controller.walletListFromType == WalletViewType.spot)
//               Column(
//                 children: [
//                   Obx(() => TotalBalanceViewSpot(gIsBalanceHide.value, total, onHistoryTap: () => Get.to(() => const ActivityScreen()))),
//                   vSpacer10(),
//                   const WalletTopButtonsView(),
//                 ],
//               ),
//             vSpacer10(),
//             textFieldSearch(
//                 controller: _controller.searchController,
//                 height: Dimens.btnHeightMid,
//                 margin: 0,
//                 borderRadius: Dimens.radiusCornerMid,
//                 onTextChange: _onTextChanged,
//                 onSearch: () => _onTextChanged('')),
//             _controller.walletList.isEmpty
//                 ? EmptyView(message: "Your wallets will listed here".tr, icon: Icons.wallet)
//                 : Container(
//                     decoration: boxDecorationRoundCorner(),
//                     margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
//                     child: Column(
//                         children: List.generate(_controller.walletList.length, (index) {
//                       final item = _controller.walletList[index];
//                       if (_controller.walletListFromType == WalletViewType.spot) {
//                         return SpotWalletItemView(wallet: item, isHide: gIsBalanceHide.value);
//                       } else if (_controller.walletListFromType == WalletViewType.future || _controller.walletListFromType == WalletViewType.p2p) {
//                         return CommonWalletItemView(wallet: item, fromType: _controller.walletListFromType, isHide: gIsBalanceHide.value);
//                       }
//                       return vSpacer0();
//                     }))),
//             vSpacer10()
//           ],
//         );
//       }),
//     );
//   }
//
//   void _onTextChanged(String text) {
//     // if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();
//     // // _searchTimer = Timer(const Duration(seconds: 1), () => _controller.refreshController.callRefresh());
//     // _searchTimer = Timer(const Duration(seconds: 1), () => refreshController.callRefresh());
//   }
// }
