import 'package:decimal/decimal.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

class Wallet {
  Wallet(
      {required this.id,
      this.userId,
      this.name,
      this.childfullname,
      this.coinId,
      this.key,
      this.type,
      this.coinType,
      this.status,
      this.isPrimary,
      this.isDeposit,
      this.isWithdrawal,
      this.tradeStatus,
      this.balance,
      this.createdAt,
      this.updatedAt,
      this.coinIcon,
      this.onOrder,
      this.availableBalance,
      this.total,
      this.onOrderUsd,
      this.availableBalanceUsd,
      this.totalBalanceUsd,
      this.network,
      this.networkName,
      this.minimumWithdrawal,
      this.maximumWithdrawal,
      this.withdrawalFees,
      this.withdrawalFeesType,
      this.encryptId,
      this.currencyType,
        this.decimal,
      this.networkId});

  int id;
  int? userId;
  String? encryptId;
  String? name;
  String? childfullname;
  int? coinId;
  dynamic key;
  int? type;
  String? coinType;
  int? status;
  int? isPrimary;
  int? isDeposit;
  int? isWithdrawal;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? coinIcon;
  int? network;
  String? networkName;
  int? tradeStatus;
  int? currencyType;
  int? networkId;
  double? balance;
  double? onOrder;
  double? availableBalance;
  double? total;
  double? onOrderUsd;
  double? availableBalanceUsd;
  double? totalBalanceUsd;
  Decimal? minimumWithdrawal;
  double? maximumWithdrawal;
  double? withdrawalFees;
  int? withdrawalFeesType;
  int? decimal;

  factory Wallet.fromJson(Map<String?, dynamic> json) {
  final coinPairs = json["coin_pairs"];
  final firstPair = (coinPairs != null && coinPairs is List && coinPairs.isNotEmpty)
      ? coinPairs[0] as Map<String, dynamic>
      : null;

  return Wallet(
    id: json["id"] ?? 0,
    userId: json["user_id"],
    encryptId: json["encryptId"],
    name: json["name"] ?? json["wallet_name"],
    childfullname: json["child_full_name"]
        ?? json["wallet_child_full_name"]
        ?? firstPair?["child_full_name"]
        ?? json["coin_type"],
    coinId: json["coin_id"],
    key: json["key"],
    type: json["type"],
    coinType: json["coin_type"],
    status: json["status"],
    currencyType: json["currency_type"],
    isPrimary: json["is_primary"],
    isDeposit: json["is_deposit"],
    isWithdrawal: json["is_withdrawal"],
    tradeStatus: json["trade_status"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    coinIcon: json["coin_icon"],
    balance: makeDouble(json["balance"]),
    onOrder: makeDouble(json["on_order"]),
    availableBalance: makeDouble(json["available_balance"]),
    total: makeDouble(json["total"]),
    onOrderUsd: makeDouble(json["on_order_usd"]),
    availableBalanceUsd: makeDouble(json["available_balance_usd"]),
    totalBalanceUsd: makeDouble(json["total_balance_usd"]),
    network: json["network"],
    networkName: json["network_name"],
    networkId: makeInt(json["network_id"]),
    minimumWithdrawal: makeDecimal(json["minimum_withdrawal"]),
    maximumWithdrawal: makeDouble(json["maximum_withdrawal"]),
    withdrawalFees: makeDouble(json["withdrawal_fees"]),
    withdrawalFeesType: makeInt(json["withdrawal_fees_type"]),
    decimal: json["decimal"],
  );
}
}

class Network {
  Network({
    this.id,
    this.walletId,
    this.coinId,
    this.baseType,
    this.address,
    this.networkType,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.networkName,
  });

  int? id;
  int? walletId;
  int? coinId;
  int? baseType;
  String? address;
  String? networkType;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? networkName;

  factory Network.fromJson(Map<String, dynamic> json) => Network(
        id: json["id"],
        walletId: json["wallet_id"],
        coinId: json["coin_id"],
        baseType: json["base_type"],
        address: json["address"],
        networkType: json["network_type"] ?? json["type"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        networkName: json["network_name"] ?? json["name"],
      );
}

class WalletDeposit {
  Wallet? coin;
  List<Network>? networks;

  WalletDeposit({
    this.coin,
    this.networks,
  });

  factory WalletDeposit.fromJson(Map<String, dynamic> json) => WalletDeposit(
    coin: json["coin"] == null ? null : Wallet.fromJson(json["coin"]),
    networks: json["networks"] == null ? [] : List<Network>.from(json["networks"]!.map((x) => Network.fromJson(x))),
  );
}

class WalletAddress {
  String? address;
  String? memo;
  String? tokenAddress;
  Network? network;
  List<Network>? coinPaymentNetworks;
  DateTime? rentedTill;
  DateTime? currentTime;
  Wallet? wallet;

  WalletAddress({
    this.coinPaymentNetworks,
    this.network,
    this.address,
    this.memo,
    this.tokenAddress,
    this.rentedTill,
    this.currentTime,
    this.wallet,
  });

  factory WalletAddress.fromJson(Map<String, dynamic> json) => WalletAddress(
    address: json["address"],
    memo: json["memo"],
    tokenAddress: json["token_address"],
    network: json["network"] == null ? null : Network.fromJson(json["network"]),
    coinPaymentNetworks: json["coin_payment_networks"] == null ? null : List<Network>.from(json["coin_payment_networks"]!.map((x) => Network.fromJson(x))),
    rentedTill: json["rented_till"] == null ? null : DateTime.parse(json["rented_till"]),
    currentTime: json["current_time"] == null ? null : DateTime.parse(json["current_time"]),
    wallet: json["wallet"] == null ? null : Wallet.fromJson(json["wallet"]),

  );
}

class PreWithdraw {
  String? coinType;
  double? fees;
  double? amount;
  double? feesPercentage;
  int? feesType;
  Decimal? min;
  Decimal? max;

  PreWithdraw({
    this.coinType,
    this.fees,
    this.amount,
    this.feesPercentage,
    this.feesType,
    this.min,
    this.max
  });

  factory PreWithdraw.fromJson(Map<String, dynamic> json) => PreWithdraw(
        coinType: json["coin_type"],
        fees: makeDouble(json["fees"]),
        amount: makeDouble(json["amount"]),
        feesPercentage: makeDouble(json["fees_percentage"]),
        feesType: json["fees_type"],
         min: makeDecimal(json["min"]),
          max: makeDecimal(json["max"]),
      );
}

class WalletOverview {
  double? spotWallet;
  double? spotWalletUsd;
  double? futureWallet;
  double? futureWalletUsd;
  double? p2PWallet;
  double? p2PWalletUsd;
  double? total;
  double? totalUsd;
  List<String>? coins;
  String? selectedCoin;
  String? banner;
  List<History>? withdraw;
  List<History>? deposit;

  WalletOverview({
    this.spotWallet,
    this.spotWalletUsd,
    this.futureWallet,
    this.futureWalletUsd,
    this.p2PWallet,
    this.p2PWalletUsd,
    this.total,
    this.totalUsd,
    this.coins,
    this.selectedCoin,
    this.banner,
    this.withdraw,
    this.deposit,
  });

  factory WalletOverview.fromJson(Map<String, dynamic> json) => WalletOverview(
        spotWallet: makeDouble(json["spot_wallet"]),
        spotWalletUsd: makeDouble(json["spot_wallet_usd"]),
        futureWallet: makeDouble(json["future_wallet"]),
        futureWalletUsd: makeDouble(json["future_wallet_usd"]),
        p2PWallet: makeDouble(json["p2p_wallet"]),
        p2PWalletUsd: makeDouble(json["p2p_wallet_usd"]),
        total: makeDouble(json["total"]),
        totalUsd: makeDouble(json["total_usd"]),
        selectedCoin: json["selected_coin"],
        banner: json["banner"],
        coins: json["coins"] == null ? null : List<String>.from(json["coins"].map((x) => x)),
        withdraw: json["withdraw"] == null ? null : List<History>.from(json["withdraw"].map((x) => History.fromJson(x))),
        deposit: json["deposit"] == null ? null : List<History>.from(json["deposit"].map((x) => History.fromJson(x))),
      );
}

class TotalBalance {
  String? currency;
  double? total;

  TotalBalance({this.currency, this.total});

  factory TotalBalance.fromJson(Map<String, dynamic> json) => TotalBalance(currency: json["currency"], total: makeDouble(json["total"]));
}

class NetworkAddress {
  int? networkId;
  int? walletId;
  String? address;
  String? tokenAddress;

  NetworkAddress({this.networkId, this.address, this.tokenAddress, this.walletId});

  factory NetworkAddress.fromJson(Map<String, dynamic> json) =>
      NetworkAddress(networkId: json["network_id"], address: json["address"], tokenAddress: json["token_address"], walletId: json["wallet_id"]);
}

class CheckDeposit {
  String? coinType;
  String? txId;
  int? confirmations;
  double? amount;
  String? address;
  String? fromAddress;
  int? coinId;
  int? networkId;
  String? network;
  String? message;

  CheckDeposit({
    this.coinType,
    this.txId,
    this.confirmations,
    this.amount,
    this.address,
    this.fromAddress,
    this.coinId,
    this.networkId,
    this.network,
    this.message,
  });

  factory CheckDeposit.fromJson(Map<String, dynamic> json) => CheckDeposit(
        coinType: json["coin_type"],
        txId: json["txId"],
        confirmations: json["confirmations"],
        amount: makeDouble(json["amount"]),
        address: json["address"],
        fromAddress: json["from_address"],
        coinId: json["coin_id"],
        networkId: json["network_id"],
        network: json["network"],
      );
}
