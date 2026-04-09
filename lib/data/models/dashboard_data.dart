import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import 'coin_pair.dart';

class DashboardData {
  DashboardData({
    this.title,
    this.coinPairs,
    this.orderData,
    this.feesSettings,
    this.lastPriceData,
    this.broadcastPort,
    this.appKey,
    this.cluster,
  });

  String? title;
  List<CoinPair>? coinPairs;
  OrderData? orderData;
  Fees? feesSettings;
  List<PriceData>? lastPriceData;
  String? broadcastPort;
  String? appKey;
  String? cluster;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        title: json["title"],
        broadcastPort: json["broadcast_port"],
        appKey: json["app_key"],
        cluster: json["cluster"],
        coinPairs: json["pairs"] == null ? null : List<CoinPair>.from(json["pairs"].map((x) => CoinPair.fromJson(x))),
        orderData: json["order_data"] is Map<String, dynamic> ? OrderData.fromJson(json["order_data"]) : null,
        feesSettings: json["fees_settings"] is Map<String, dynamic> ? Fees.fromJson(json["fees_settings"]) : null,
        lastPriceData: json["last_price_data"] == null ? null : List<PriceData>.from(json["last_price_data"].map((x) => PriceData.fromJson(x))),
      );
}

class Fees {
  Fees({
    this.makerFees,
    this.takerFees,
    this.thirtyDayVolume,
  });

  double? makerFees;
  double? takerFees;
  String? thirtyDayVolume;

  factory Fees.fromJson(Map<String, dynamic> json) => Fees(
        makerFees: makeDouble(json["maker_fees"]),
        takerFees: makeDouble(json["taker_fees"]),
        thirtyDayVolume: json["thirtyDayVolume"],
      );

  Map<String, dynamic> toJson() => {
        "maker_fees": makerFees,
        "taker_fees": takerFees,
        "thirtyDayVolume": thirtyDayVolume,
      };
}

class PriceData {
  PriceData({
    this.amount,
    this.price,
    this.lastPrice,
    this.priceOrderType,
    this.total,
    this.time,
  });

  double? amount;
  double? price;
  double? lastPrice;
  double? total;

  String? priceOrderType;
  String? time;

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
        amount: makeDouble(json["amount"]),
        price: makeDouble(json["price"]),
        lastPrice: makeDouble(json["last_price"]),
        priceOrderType: json["price_order_type"],
        total: makeDouble(json["total"]),
        time: json["time"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "price": price,
        "last_price": lastPrice,
        "price_order_type": priceOrderType,
        "total": total,
        "time": time,
      };
}

class OrderData {
  OrderData({
    this.baseCoinId,
    this.tradeCoinId,
    this.total,
    this.fees,
    this.onOrder,
    this.sellPrice,
    this.buyPrice,
    this.baseCoin,
    this.tradeCoin,
    this.exchangePair,
    this.exchangeCoinPair,
  });

  int? baseCoinId;
  int? tradeCoinId;
  Total? total;
  Fees? fees;
  OnOrder? onOrder;
  double? sellPrice;
  double? buyPrice;
  String? baseCoin;
  String? tradeCoin;
  String? exchangePair;
  String? exchangeCoinPair;

  factory OrderData.fromJson(Map<String, dynamic> json) => OrderData(
        baseCoinId: json["base_coin_id"],
        tradeCoinId: json["trade_coin_id"],
        total: Total.fromJson(json["total"]),
        fees: json["fees"] is Map<String, dynamic> ? Fees.fromJson(json["fees"]) : null,
        onOrder: json["on_order"] == null ? null : OnOrder.fromJson(json["on_order"]),
        sellPrice: makeDouble(json["sell_price"]),
        buyPrice: makeDouble(json["buy_price"]),
        baseCoin: json["base_coin"],
        tradeCoin: json["trade_coin"],
        exchangePair: json["exchange_pair"],
        exchangeCoinPair: json["exchange_coin_pair"],
      );
}

class OnOrder {
  OnOrder({
    this.tradeWallet,
    this.tradeWalletTotal,
    this.baseWallet,
    this.baseWalletTotal,
  });

  double? tradeWallet;
  double? tradeWalletTotal;
  double? baseWallet;
  double? baseWalletTotal;

  factory OnOrder.fromJson(Map<String, dynamic> json) => OnOrder(
        tradeWallet: makeDouble(json["trade_wallet"]),
        tradeWalletTotal: makeDouble(json["trade_wallet_total"]),
        baseWallet: makeDouble(json["base_wallet"]),
        baseWalletTotal: makeDouble(json["base_wallet_total"]),
      );
}

class Total {
  Total({
    this.tradeWallet,
    this.baseWallet,
  });

  TradeWallet? tradeWallet;
  TradeWallet? baseWallet;

  factory Total.fromJson(Map<String, dynamic> json) => Total(
        tradeWallet: TradeWallet.fromJson(json["trade_wallet"]),
        baseWallet: TradeWallet.fromJson(json["base_wallet"]),
      );

}

class TradeWallet {
  TradeWallet({
    this.balance,
    this.coinType,
    this.fullName,
    this.high,
    this.low,
    this.volume,
    this.lastPrice,
    this.priceChange,
    this.walletId,
    this.pairDecimal,
  });

  double? balance;
  String? coinType;
  String? fullName;
  double? high;
  double? low;
  double? volume;
  double? lastPrice;
  double? priceChange;
  int? walletId;
  int? pairDecimal;

  factory TradeWallet.fromJson(Map<String, dynamic> json) => TradeWallet(
        balance: makeDouble(json["balance"]),
        coinType: json["coin_type"],
        fullName: json["full_name"],
        high: makeDouble(json["high"]),
        low: makeDouble(json["low"]),
        volume: makeDouble(json["volume"]),
        lastPrice: makeDouble(json["last_price"]),
        priceChange: makeDouble(json["price_change"]),
        walletId: makeInt(json["wallet_id"]),
        pairDecimal: makeInt(json["pair_decimal"]),
      );

  Wallet createWallet() {
    return Wallet(id: walletId ?? 0, coinType: coinType, name: fullName, balance: balance);
  }

}


class SelfBalance {
  SelfBalance({
    this.total,
    this.sellPrice,
    this.buyPrice,
    // this.baseWalletTotal,
    this.baseWallet,
    // this.tradeWalletTotal,
    this.tradeWallet,
  });

  Total? total;
  double? sellPrice;
  double? buyPrice;
  // double? baseWalletTotal;
  double? baseWallet;
  // double? tradeWalletTotal;
  double? tradeWallet;
}

class TradeTolerance {
  double? lowTolerance;
  double? highTolerance;

  TradeTolerance({
    this.lowTolerance,
    this.highTolerance,
  });

  factory TradeTolerance.fromJson(Map<String, dynamic> json) => TradeTolerance(
    lowTolerance: makeDouble(json["low_tolerence"]),
    highTolerance: makeDouble(json["high_tolerence"]),
  );

}