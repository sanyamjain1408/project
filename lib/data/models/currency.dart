
import 'package:decimal/decimal.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';

class Currency {
  int? id;
  String? name;
  String? coinType;
  String? label;
  String? value;
  String? coinIcon;
  int? network;
  String? networkName;
  String? coinPrice;

  Currency({
    this.id,
    this.name,
    this.coinType,
    this.label,
    this.value,
    this.coinIcon,
    this.network,
    this.networkName,
    this.coinPrice,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    id: json["id"],
    name: json["name"],
    coinType: json["coin_type"],
    label: json["label"],
    value: json["value"],
    coinIcon: json["coin_icon"],
    network: json["network"],
    networkName: json["network_name"],
    coinPrice: json["coin_price"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "coin_type": coinType,
    "label": label,
    "value": value,
    "coin_icon": coinIcon,
    "network": network,
    "network_name": networkName,
    "coin_price": coinPrice,
  };
}

class CurrencyNetworks {
  List<Network>? networks;
  List<Network>? coinPaymentNetworks;
  Wallet? wallet;

  CurrencyNetworks({
    this.networks,
    this.coinPaymentNetworks,
    this.wallet,
  });

  factory CurrencyNetworks.fromJson(Map<String, dynamic> json) => CurrencyNetworks(
    wallet:  json["wallet"] == null ? null : Wallet.fromJson(json["wallet"]),
    networks: json["networks"] == null ? [] : List<Network>.from(json["networks"]!.map((x) => Network.fromJson(x))),
    coinPaymentNetworks: json["coin_payment_networks"] == null ? [] : List<Network>.from(json["coin_payment_networks"]!.map((x) => Network.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "networks": networks == null ? [] : List<Network>.from(networks!.map((x) => x)),
    "coin_payment_networks": coinPaymentNetworks == null ? [] : List<Network>.from(coinPaymentNetworks!.map((x) => x)),
  };
}

class WithdrawalCreate {
  int? coinId;
  int? networkId;
  Decimal? amount;
  String? address;
  String? networkType;
  String? memo;
  String? verifyCode;
  String? coinType;

  WithdrawalCreate({
    this.coinId,
    this.networkId,
    this.address,
    this.amount,
    this.networkType,
    this.verifyCode,
    this.memo,
    this.coinType,
  });

}
