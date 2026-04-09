import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/chart_style.dart';
import 'package:k_chart_plus/depth_chart.dart';
import 'package:k_chart_plus/entity/depth_entity.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';

class ChartScreenDepth extends StatelessWidget {
  ChartScreenDepth({super.key, required this.buyOrders, required this.sellOrders, required this.fromModal});

  final List<ExchangeOrder> buyOrders;
  final List<ExchangeOrder> sellOrders;
  final bool fromModal;

  final List<DepthEntity> _bids = [], _asks = [];
  final ChartColors chartColors = ChartColors();

  @override
  Widget build(BuildContext context) {
    chartColors.depthBuyColor = gBuyColor;
    chartColors.depthSellColor = gSellColor;
    chartColors.defaultTextColor = Theme.of(context).primaryColor;
    chartColors.selectFillColor = Theme.of(context).secondaryHeaderColor;
    chartColors.selectBorderColor = Theme.of(context).primaryColor;
    chartColors.infoWindowTitleColor = Colors.grey;
    chartColors.infoWindowNormalColor = Theme.of(context).primaryColor;
    setData(buyOrders, sellOrders);

    final height = fromModal ? (context.width / 2) : (context.width / 1.5);
    return Container(
      decoration: boxDecorationTopRound(),
      height: height,
      clipBehavior: Clip.hardEdge,
      child: DepthChart(_bids, _asks, chartColors, baseUnit: tradeDecimal, quoteUnit: tradeDecimal),
    );
  }

  void setDemoData() {
    final List<DepthEntity> bids = getDemoData().map<DepthEntity>((item) => DepthEntity(item[0], item[1])).toList();
    final List<DepthEntity> asks = getDemoData().map<DepthEntity>((item) => DepthEntity(item[0], item[1])).toList();
    _initDepth(bids, asks);
  }

  void setData(List<ExchangeOrder> buyOrderList, List<ExchangeOrder> sellOrderList) {
    final List<DepthEntity> bids = buyOrderList.map<DepthEntity>((item) => DepthEntity(item.price ?? 0, item.amount ?? 0)).toList();
    final List<DepthEntity> asks = sellOrderList.map<DepthEntity>((item) => DepthEntity(item.price ?? 0, item.amount ?? 0)).toList();
    _bids.clear();
    _asks.clear();
    _initDepth(bids, asks);
  }

  void _initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;

    //Cumulative buy orders
    double cumulativeAmount = 0.0;
    bids.sort((left, right) => right.price.compareTo(left.price));
    for (var item in bids) {
      cumulativeAmount += item.vol;
      item.vol = cumulativeAmount;
      _bids.insert(0, item);
    }

    //Cumulative sell orders
    cumulativeAmount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    for (var item in asks) {
      cumulativeAmount += item.vol;
      item.vol = cumulativeAmount;
      _asks.add(item);
    }
  }
}

List<List<double>> getDemoData() => [
      [9620.130000000000000000, 0.000146000000000000],
      [9620.190000000000000000, 0.062830000000000000],
      [9620.330000000000000000, 0.002323000000000000],
      [9620.440000000000000000, 0.459942000000000000],
      [9620.600000000000000000, 0.005600000000000000],
      [9620.680000000000000000, 0.010000000000000000],
      [9620.830000000000000000, 0.002400000000000000],
      [9620.850000000000000000, 0.750000000000000000],
      [9621.050000000000000000, 0.001200000000000000],
      [9621.230000000000000000, 0.000900000000000000],
      [9621.240000000000000000, 0.004200000000000000],
      [9621.310000000000000000, 0.004100000000000000]
    ];
