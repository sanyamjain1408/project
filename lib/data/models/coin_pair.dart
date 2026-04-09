
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

class CoinPair {
  CoinPair({
    this.coinPairName,
    this.coinPair,
    this.coinPairId,
    this.parentCoinId,
    this.childCoinId,
    this.lastPrice,
    this.priceChange,
    this.childCoinName,
    this.icon,
    this.parentCoinName,
    this.userId,
    this.balance,
    this.estBalance,
    this.isFavorite,
    this.high,
    this.low,
    this.volume,
  });

  String? coinPairName;
  String? coinPair;
  int? coinPairId;
  int? parentCoinId;
  int? childCoinId;
  String? childCoinName;
  String? icon;
  String? parentCoinName;
  int? userId;

  String? estBalance;
  int? isFavorite;
  String? high;
  String? low;
  double? lastPrice;
  double? priceChange;
  double? balance;
  double? volume;

  factory CoinPair.fromJson(Map<String, dynamic> json) => CoinPair(
    coinPairName: json["coin_pair_name"],
    coinPair: json["coin_pair"],
    coinPairId: json["coin_pair_id"],
    parentCoinId: json["parent_coin_id"],
    childCoinId: json["child_coin_id"],
    lastPrice: makeDouble(json["last_price"]),
    priceChange: makeDouble(json["price_change"]),
    childCoinName: json["child_coin_name"],
    icon: json["icon"] ?? json["coin_icon"],
    parentCoinName: json["parent_coin_name"],
    userId: makeInt(json["user_id"]),
    balance: makeDouble(json["balance"]),
    estBalance: json["est_balance"],
    isFavorite: json["is_favorite"],
    high: json["high"],
    low: json["low"],
    volume: makeDouble(json["volume"]),
  );

  String getCoinPairName() => "${childCoinName ?? ""}/${parentCoinName ?? ""}";

  String getCoinPairKey() => parentCoinName.isValid ? "${childCoinName ?? ""}_${parentCoinName ?? ""}" : '';

  CoinPair setCoinPairKey(){
    if(!coinPair.isValid) coinPair = getCoinPairKey();
    if(!coinPairName.isValid) coinPairName = getCoinPairName();
    return this;
  }

  Map<String, dynamic> toJson() => {
    "coin_pair_id": coinPairId,
    "parent_coin_id": parentCoinId,
    "child_coin_id": childCoinId,
    "last_price": lastPrice,
    "balance": balance,
    "price_change": priceChange,
    "volume": volume,
    "high": high,
    "low": low,
    "child_coin_name": childCoinName,
    "parent_coin_name": parentCoinName,
    "is_favorite": isFavorite,
    "coin_pair": coinPair,
    "coin_icon": icon,
  };
}