import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'chart_screen_depth.dart';
import 'charts_controller.dart';

class ChartsScreen extends StatefulWidget {
  final bool fromModal;
  final VoidCallback? onTapClose;

  const ChartsScreen({super.key, required this.fromModal, this.onTapClose});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final _controller = Get.find<ChartsController>();
  final ChartStyle chartStyle = ChartStyle();
  final ChartColors chartColors = ChartColors();
  final List<SecondaryState> _secondaryStateLi = [];

  @override
  void initState() {
    super.initState();
    chartColors.bgColor = Get.theme.secondaryHeaderColor;
    chartColors.upColor = gBuyColor;
    chartColors.dColor = gSellColor;
    chartColors.gridColor = Colors.transparent;
    chartColors.defaultTextColor = Get.theme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fromModal) _secondaryStateLi.add(SecondaryState.MACD);
    final height = widget.fromModal ? (Get.width / 2) : (Get.width * 0.75);
    double width = (context.width - (widget.fromModal ? 50 : 80));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => Row(
              children: [
                InkWell(
                    onTap: () => _controller.intervalIndex.value = -1,
                    child: TextRobotoAutoBold("Depth".tr, color: _controller.intervalIndex.value == -1 ? null : context.theme.primaryColorLight)),
                hSpacer10(),
                TimeSelectionView(
                    intervalMap: _controller.getIntervalMap(),
                    selected: _controller.intervalIndex.value,
                    width: width,
                    onSelected: (index) {
                      _controller.intervalIndex.value = index;
                      _controller.getChartData();
                    }),
                if (widget.fromModal) const Spacer(),
                if (widget.fromModal)
                  InkWell(
                      onTap: widget.onTapClose, child: Icon(Icons.arrow_drop_up, size: Dimens.iconSizeMin, color: context.theme.primaryColorLight))
              ],
            )),
        Obx(() {
          return _controller.intervalIndex.value == -1
              ? ChartScreenDepth(fromModal: widget.fromModal, buyOrders: _controller.buyOrders.toList(), sellOrders: _controller.sellOrders.toList())
              : Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    KChartWidget(
                      _controller.candles.toList(),
                      chartStyle,
                      chartColors,
                      mBaseHeight: height,
                      isTrendLine: false,
                      mainStateLi: {MainState.MA},
                      volHidden: widget.fromModal,
                      secondaryStateLi: _secondaryStateLi.toSet(),
                      fixedLength: tradeDecimal,
                      xFrontPadding: 50,
                      timeFormat: TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
                      verticalTextAlignment: VerticalTextAlignment.right,
                    ),
                    if (_controller.candles.isEmpty) handleEmptyViewWithLoading(_controller.isLoading.value),
                  ],
                );
        }),
      ],
    );
  }
}

class TimeSelectionView extends StatelessWidget {
  const TimeSelectionView({super.key, required this.intervalMap, required this.selected, required this.onSelected, required this.width});

  final Map<int, String> intervalMap;
  final int selected;
  final Function(int) onSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final list = intervalMap.values.toList();
    double rWidth = (35 * list.length) + (5 * (list.length - 1));
    rWidth = width >= rWidth ? rWidth : width;
    return Row(
      children: [
        SizedBox(
          width: rWidth,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                list.length,
                (index) {
                  final color = index == selected ? null : context.theme.primaryColorLight;
                  return InkWell(onTap: () => onSelected(index), child: TextRobotoAutoBold(list[index], color: color));
                },
              )),
        ),
      ],
    );
  }
}

