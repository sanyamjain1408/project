import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';

// ── COLORS ────────────────────────────────────────────────────────────────────
const futureBg = Color(0xFF0D0D0D);
const futureCard = Color(0xFF121212);
const futureCard2 = Color(0xFF1C1C1C);
const futureInputBg = Color(0xFF171717);
const futureGreen = Color(0xFF0ECB81);
const futureGreenLight = Color(0x260ECB81);
const futureRed = Color(0xFFF6465D);
const futureRedLight = Color(0x26F6465D);
const futureTextWhite = Color(0xFFFFFFFF);
const futureMuted = Color(0x73FFFFFF);
const futureBorder = Color(0x14FFFFFF);
const futureYellow = Color(0xFFD4F000);
const futureDmSans = 'DMSans';

// ── DATA MODELS ───────────────────────────────────────────────────────────────
class FuturePair {
  final int id;
  final String symbol;
  final String baseCurrency;
  final String quoteCurrency;
  final double currentPrice;
  final double priceChange24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final int pricePrecision;
  final int quantityPrecision;
  final double fundingRate;
  final double takerFee;
  final int leverageMin;

  FuturePair({
    required this.id,
    required this.symbol,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.currentPrice,
    required this.priceChange24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.pricePrecision,
    required this.quantityPrecision,
    required this.fundingRate,
    required this.takerFee,
    required this.leverageMin,
  });

  factory FuturePair.fromJson(Map<String, dynamic> j) => FuturePair(
    id: j['id'] ?? 0,
    symbol: j['symbol'] ?? '',
    baseCurrency: j['base_currency'] ?? '',
    quoteCurrency: j['quote_currency'] ?? '',
    currentPrice: double.tryParse(j['current_price']?.toString() ?? '0') ?? 0,
    priceChange24h: double.tryParse(j['price_change_24h']?.toString() ?? '0') ?? 0,
    high24h: double.tryParse(j['high_24h']?.toString() ?? '0') ?? 0,
    low24h: double.tryParse(j['low_24h']?.toString() ?? '0') ?? 0,
    volume24h: double.tryParse(j['volume_24h']?.toString() ?? '0') ?? 0,
    pricePrecision: j['price_precision'] ?? 2,
    quantityPrecision: j['quantity_precision'] ?? 4,
    fundingRate: double.tryParse(j['funding_rate']?.toString() ?? '0.0001') ?? 0.0001,
    takerFee: double.tryParse(j['taker_fee']?.toString() ?? '0.05') ?? 0.05,
    leverageMin: j['leverage_min'] ?? 1,
  );
}

class FuturePosition {
  final int id;
  final String symbol;
  final String side;
  final double entryPrice;
  final double quantity;
  final double margin;
  final double fee;
  final double liquidationPrice;
  final double? takeProfit;
  final double? stopLoss;
  final int leverage;
  final String status;

  FuturePosition({
    required this.id,
    required this.symbol,
    required this.side,
    required this.entryPrice,
    required this.quantity,
    required this.margin,
    required this.fee,
    required this.liquidationPrice,
    this.takeProfit,
    this.stopLoss,
    required this.leverage,
    required this.status,
  });

  factory FuturePosition.fromJson(Map<String, dynamic> j) => FuturePosition(
    id: j['id'] ?? 0,
    symbol: j['symbol'] ?? '',
    side: j['side'] ?? 'long',
    entryPrice: double.tryParse(j['entry_price']?.toString() ?? '0') ?? 0,
    quantity: double.tryParse(j['quantity']?.toString() ?? '0') ?? 0,
    margin: double.tryParse(j['margin']?.toString() ?? '0') ?? 0,
    fee: double.tryParse(j['fee']?.toString() ?? '0') ?? 0,
    liquidationPrice: double.tryParse(j['liquidation_price']?.toString() ?? '0') ?? 0,
    takeProfit: j['take_profit'] != null ? double.tryParse(j['take_profit'].toString()) : null,
    stopLoss: j['stop_loss'] != null ? double.tryParse(j['stop_loss'].toString()) : null,
    leverage: j['leverage'] ?? 1,
    status: j['status'] ?? 'open',
  );
}

class FutureOrder {
  final int id;
  final String symbol;
  final String side;
  final String orderType;
  final double price;
  final double quantity;
  final double margin;
  final double fee;
  final String status;
  final String createdAt;

  FutureOrder({
    required this.id,
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.price,
    required this.quantity,
    required this.margin,
    required this.fee,
    required this.status,
    required this.createdAt,
  });

  factory FutureOrder.fromJson(Map<String, dynamic> j) => FutureOrder(
    id: j['id'] ?? 0,
    symbol: j['symbol'] ?? '',
    side: j['side'] ?? 'long',
    orderType: j['order_type'] ?? 'limit',
    price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
    quantity: double.tryParse(j['quantity']?.toString() ?? '0') ?? 0,
    margin: double.tryParse(j['margin']?.toString() ?? '0') ?? 0,
    fee: double.tryParse(j['fee']?.toString() ?? '0') ?? 0,
    status: j['status'] ?? 'pending',
    createdAt: j['created_at'] ?? '',
  );
}

// ── HELPER FUNCTIONS ──────────────────────────────────────────────────────────
String formatFutureVolume(double vol) {
  if (vol >= 1.0e9) return '\$${(vol / 1.0e9).toStringAsFixed(2)}B';
  if (vol >= 1.0e6) return '\$${(vol / 1.0e6).toStringAsFixed(2)}M';
  if (vol >= 1.0e3) return '\$${(vol / 1.0e3).toStringAsFixed(2)}K';
  return '\$${vol.toStringAsFixed(2)}';
}

double futureRng(int seed, int n, double lo, double hi) {
  final x = (math.sin(seed * 127.1 + n * 311.7) * 43758.5453).abs();
  return lo + (x - x.floor()) * (hi - lo);
}

Map<String, List<List<String>>> buildFutureOrderBook(
  double price,
  int pp,
  int ap,
  int seed,
  int rowCount,
) {
  if (price == 0) return {'asks': [], 'bids': []};
  final tick = math.pow(10, -pp).toDouble();
  final asks = <List<String>>[];
  final bids = <List<String>>[];
  for (int i = 1; i <= rowCount; i++) {
    final spread = 0.000006 * i * (1 + futureRng(seed, i * 2, -0.05, 0.05));
    final targetUsdt = (i == 4 || i == 10)
        ? futureRng(seed, i + 100, 5000, 30000)
        : (i <= 5 ? futureRng(seed, i, 500, 8000) : futureRng(seed, i, 50, 2000));
    final baseAmt = targetUsdt / price;
    final askAmt = baseAmt * (1 + futureRng(seed, i * 3, -0.2, 0.2));
    final bidAmt = baseAmt * (1 + futureRng(seed, i * 5, -0.2, 0.2));
    final askPrice = ((price * (1 + spread)) / tick).ceil() * tick;
    final bidPrice = ((price * (1 - spread)) / tick).floor() * tick;
    asks.add([askPrice.toStringAsFixed(pp), askAmt.toStringAsFixed(ap)]);
    bids.add([bidPrice.toStringAsFixed(pp), bidAmt.toStringAsFixed(ap)]);
  }
  asks.sort((a, b) => double.parse(a[0]).compareTo(double.parse(b[0])));
  bids.sort((a, b) => double.parse(b[0]).compareTo(double.parse(a[0])));
  return {
    'asks': asks.take(rowCount).toList(),
    'bids': bids.take(rowCount).toList(),
  };
}

String getFutureToken() {
  try {
    final box = GetStorage();
    return box.read(PreferenceKey.accessToken) ?? '';
  } catch (_) {
    return '';
  }
}
