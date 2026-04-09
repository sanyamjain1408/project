import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../../ui/ui_helper/app_widgets.dart';
import '../../../models/p2p_gift_card.dart';
import '../../../p2p_common_utils.dart';
import '../p2p_gift_card_order_details/p2p_gift_order_details_screen.dart';
import 'p2p_gc_orders_controller.dart';

class P2PGCOrdersScreen extends StatefulWidget {
  const P2PGCOrdersScreen({super.key});

  @override
  State<P2PGCOrdersScreen> createState() => _P2PGCOrdersScreenState();
}

class _P2PGCOrdersScreenState extends State<P2PGCOrdersScreen> with TickerProviderStateMixin {
  final _controller = Get.put(P2pGCOrdersController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardOrders(false));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
          child: Row(
            children: [
              Expanded(flex: 4, child: TextRobotoAutoBold("${"Orders Status".tr}: ", color: context.theme.primaryColorLight)),
              hSpacer5(),
              Obx(() {
                return Expanded(
                  flex: 6,
                  child: dropDownListIndex(_controller.getOrderTypeMap().values.toList(), _controller.selectedOrderStatus.value, "",
                      hMargin: 0, height: 35, (index) {
                    _controller.selectedOrderStatus.value = index;
                    _controller.getP2pGiftCardOrders(false);
                  }),
                );
              }),
            ],
          ),
        ),
        Obx(() => _controller.gcOrderList.isEmpty
            ? handleEmptyViewWithLoading(_controller.isDataLoading.value)
            : Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  itemCount: _controller.gcOrderList.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (_controller.hasMoreData && index == (_controller.gcOrderList.length - 1)) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardOrders(true));
                    }
                    return P2pGCOrderItemView(_controller.gcOrderList[index]);
                  },
                ),
              ))
      ]),
    );
  }
}

class P2pGCOrderItemView extends StatelessWidget {
  const P2pGCOrderItemView(this.p2pGcOrder, {super.key});

  final P2PGiftCardOrder p2pGcOrder;

  @override
  Widget build(BuildContext context) {
    final status = getTradeTypeData(p2pGcOrder.status, isDispute: false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => P2pGiftOrderDetailsScreen(uid: p2pGcOrder.uid ?? "")),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
          color: Colors.grey.withValues(alpha: 0.1),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(Dimens.paddingMid),
            child: Column(
              children: [
                TwoTextSpaceFixed("${"Order Id".tr} : ", p2pGcOrder.orderId ?? ""),
                TwoTextSpaceFixed("${"Amount".tr} : ", "${coinFormat(p2pGcOrder.amount)} ${p2pGcOrder.pGiftCard?.giftCard?.coinType ?? ""}"),
                TwoTextSpaceFixed("${"Price".tr} : ", "${coinFormat(p2pGcOrder.price)} ${p2pGcOrder.currencyType ?? ""}"),
                TwoTextSpaceFixed("${"Status".tr} : ", status.first, subColor: status.last),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
