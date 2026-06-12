import 'package:tradexpro_flutter/utils/number_util.dart';

class SpotPair {
  final int? id;
  final String? symbol;
  final String? baseCurrency;
  final String? quoteCurrency;
  final double? currentPrice;
  final double? priceChange24h;
  final double? high24h;
  final double? low24h;
  final double? volume24h;
  final int pricePrecision;
  final int amountPrecision;
  final double? makerFee;
  final double? takerFee;
  final double? minOrderAmount;
  final int? baseCoinId;
  final int? quoteCoinId;
  final String? icon;

  SpotPair({
    this.id, this.symbol, this.baseCurrency, this.quoteCurrency,
    this.currentPrice, this.priceChange24h, this.high24h, this.low24h,
    this.volume24h, this.pricePrecision = 2, this.amountPrecision = 6,
    this.makerFee, this.takerFee, this.minOrderAmount,
    this.baseCoinId, this.quoteCoinId, this.icon,
  });

  factory SpotPair.fromJson(Map<String, dynamic> j) => SpotPair(
    id: j['id'],
    symbol: j['symbol'],
    baseCurrency: j['base_currency'],
    quoteCurrency: j['quote_currency'],
    currentPrice: makeDouble(j['current_price']),
    priceChange24h: makeDouble(j['price_change_24h']),
    high24h: makeDouble(j['high_24h']),
    low24h: makeDouble(j['low_24h']),
    volume24h: makeDouble(j['volume_24h']),
    pricePrecision: makeInt(j['price_precision']),
    amountPrecision: makeInt(j['amount_precision']),
    makerFee: makeDouble(j['maker_fee']),
    takerFee: makeDouble(j['taker_fee']),
    minOrderAmount: makeDouble(j['min_order_amount']),
    baseCoinId: makeInt(j['base_coin_id'] ?? j['base_currency_id']),
    quoteCoinId: makeInt(j['quote_coin_id'] ?? j['quote_currency_id']),
    icon: j['icon'] as String?,
  );

  String get coinPairName => '${baseCurrency ?? ""}/${quoteCurrency ?? ""}';
}

class SpotTicker {
  final double price;
  final double priceChange24h;
  final double high24h;
  final double low24h;
  final double volume24h;

  const SpotTicker({
    this.price = 0, this.priceChange24h = 0,
    this.high24h = 0, this.low24h = 0, this.volume24h = 0,
  });

  factory SpotTicker.fromJson(Map<String, dynamic> j) => SpotTicker(
    price: makeDouble(j['price'] ?? j['last_price'] ?? j['current_price']),
    priceChange24h: makeDouble(j['price_change_24h'] ?? j['change_24h'] ?? j['change']),
    high24h: makeDouble(j['high_24h'] ?? j['high']),
    low24h: makeDouble(j['low_24h'] ?? j['low']),
    volume24h: makeDouble(j['volume_24h'] ?? j['volume']),
  );
}

class SpotOrderBook {
  final List<List<double>> bids;
  final List<List<double>> asks;

  const SpotOrderBook({required this.bids, required this.asks});

  factory SpotOrderBook.fromJson(Map<String, dynamic> j) {
    List<List<double>> parse(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) {
        final row = e as List;
        return [makeDouble(row[0]), makeDouble(row[1])];
      }).toList();
    }
    return SpotOrderBook(bids: parse(j['bids']), asks: parse(j['asks']));
  }

  static const SpotOrderBook empty = SpotOrderBook(bids: [], asks: []);
}

class SpotTrade {
  final double price;
  final double amount;
  final String side;
  final String? time;

  const SpotTrade({this.price = 0, this.amount = 0, this.side = 'buy', this.time});

  factory SpotTrade.fromJson(Map<String, dynamic> j) => SpotTrade(
    price: makeDouble(j['price']),
    amount: makeDouble(j['amount']),
    side: j['side'] ?? j['type'] ?? 'buy',
    time: j['time_str'] ?? j['time'],
  );

  bool get isBuy => side.toLowerCase() == 'buy';
}

class SpotBalance {
  final double available;
  final double locked;

  const SpotBalance({this.available = 0, this.locked = 0});

  factory SpotBalance.fromJson(Map<String, dynamic> j) => SpotBalance(
    available: makeDouble(j['available'] ?? j['free']),
    locked: makeDouble(j['locked'] ?? j['freeze']),
  );
}
