import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

class IcoDynamicForm {
  int? id;
  int? userId;
  int? uniqueId;
  int? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? tokenCreateStatus;
  List<FormDetail>? formDetails;

  IcoDynamicForm({
    this.id,
    this.userId,
    this.uniqueId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.tokenCreateStatus,
    this.formDetails,
  });

  factory IcoDynamicForm.fromJson(Map<String, dynamic> json) => IcoDynamicForm(
        id: json["id"],
        userId: json["user_id"],
        uniqueId: json["unique_id"],
        status: json["status"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        tokenCreateStatus: json["token_create_status"],
        formDetails: json["form_details"] == null ? null : List<FormDetail>.from(json["form_details"].map((x) => FormDetail.fromJson(x))),
      );
}

class FormDetail {
  int? id;
  int? uniqueId;
  String? question;
  String? answer;
  int? isInput;
  int? isOption;
  int? isFile;

  FormDetail({
    this.id,
    this.uniqueId,
    this.question,
    this.answer,
    this.isInput,
    this.isOption,
    this.isFile,
  });

  factory FormDetail.fromJson(Map<String, dynamic> json) => FormDetail(
        id: json["id"],
        uniqueId: json["unique_id"],
        question: json["question"],
        answer: json["answer"],
        isInput: json["is_input"],
        isOption: json["is_option"],
        isFile: json["is_file"],
      );
}

class IcoToken {
  int? id;
  int? userId;
  int? approvedId;
  int? approvedStatus;
  int? formId;
  String? baseCoin;
  String? coinType;
  String? tokenName;
  String? network;
  String? walletAddress;
  String? contractAddress;
  String? walletPrivateKey;
  String? chainId;
  String? chainLink;
  String? websiteLink;
  String? detailsRule;
  int? decimal;
  double? gasLimit;
  int? status;
  int? isUpdated;
  String? imageName;
  String? imagePath;
  DateTime? createdAt;
  DateTime? updatedAt;

  IcoToken({
    this.id,
    this.userId,
    this.approvedId,
    this.approvedStatus,
    this.formId,
    this.baseCoin,
    this.coinType,
    this.tokenName,
    this.network,
    this.walletAddress,
    this.contractAddress,
    this.walletPrivateKey,
    this.chainId,
    this.chainLink,
    this.websiteLink,
    this.detailsRule,
    this.decimal,
    this.gasLimit,
    this.status,
    this.isUpdated,
    this.imageName,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory IcoToken.fromJson(Map<String, dynamic> json) => IcoToken(
        id: json["id"],
        userId: json["user_id"],
        approvedId: json["approved_id"],
        approvedStatus: json["approved_status"],
        formId: json["form_id"],
        baseCoin: json["base_coin"],
        coinType: json["coin_type"],
        tokenName: json["token_name"],
        network: json["network"],
        walletAddress: json["wallet_address"],
        contractAddress: json["contract_address"],
        walletPrivateKey: json["wallet_private_key"],
        chainId: json["chain_id"],
        chainLink: json["chain_link"],
        websiteLink: json["website_link"],
        detailsRule: json["details_rule"],
        decimal: json["decimal"],
        gasLimit: makeDouble(json["gas_limit"]),
        status: json["status"],
        isUpdated: json["is_updated"],
        imageName: json["image_name"],
        imagePath: json["image_path"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      );

  Future<Map<String, dynamic>> toJson() async {
    final mapObj = <String, dynamic>{};
    if (id != null) mapObj["id"] = id;
    mapObj["network_id"] = network;
    mapObj["base_coin"] = baseCoin;
    mapObj["chain_link"] = chainLink;
    mapObj["contract_address"] = contractAddress;
    mapObj["wallet_address"] = walletAddress;
    if (walletPrivateKey.isValid) mapObj["wallet_private_key"] = walletPrivateKey;
    mapObj["gas_limit"] = gasLimit;
    mapObj["form_id"] = formId;
    mapObj["details_rule"] = detailsRule;
    mapObj["website_link"] = websiteLink;
    mapObj["decimal"] = decimal;
    mapObj["chain_id"] = chainId;
    mapObj["token_name"] = tokenName;
    mapObj["token_symbol"] = coinType;
    return mapObj;
  }
}

class IcoBuyToken {
  int? id;
  int? coinId;
  int? phaseId;
  int? tokenId;
  int? userId;
  double? amount;
  String? paymentMethod;
  int? walletId;
  dynamic payerWallet;
  String? trxId;
  int? bankId;
  dynamic payerCoin;
  String? bankRef;
  String? bankSlip;
  String? buyCurrency;
  double? payAmount;
  String? payCurrency;
  double? buyPrice;
  dynamic blockchainTx;
  dynamic usedGas;
  int? status;
  int? isAdminReceive;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? tokenName;

  IcoBuyToken({
    this.id,
    this.coinId,
    this.phaseId,
    this.tokenId,
    this.userId,
    this.amount,
    this.paymentMethod,
    this.walletId,
    this.payerWallet,
    this.trxId,
    this.bankId,
    this.payerCoin,
    this.bankRef,
    this.bankSlip,
    this.buyCurrency,
    this.payAmount,
    this.payCurrency,
    this.buyPrice,
    this.blockchainTx,
    this.usedGas,
    this.status,
    this.isAdminReceive,
    this.createdAt,
    this.updatedAt,
    this.tokenName,
  });

  factory IcoBuyToken.fromJson(Map<String, dynamic> json) => IcoBuyToken(
        id: json["id"],
        coinId: json["coin_id"],
        phaseId: json["phase_id"],
        tokenId: json["token_id"],
        userId: json["user_id"],
        amount: makeDouble(json["amount"]),
        paymentMethod: json["payment_method"],
        walletId: json["wallet_id"],
        payerWallet: json["payer_wallet"],
        trxId: json["trx_id"],
        bankId: json["bank_id"],
        payerCoin: json["payer_coin"],
        bankRef: json["bank_ref"],
        bankSlip: json["bank_slip"],
        buyCurrency: json["buy_currency"],
        payAmount: makeDouble(json["pay_amount"]),
        payCurrency: json["pay_currency"],
        buyPrice: makeDouble(json["buy_price"]),
        blockchainTx: json["blockchain_tx"],
        usedGas: json["used_gas"],
        status: json["status"],
        isAdminReceive: json["is_admin_receive"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
        tokenName: json["token_name"],
      );
}

class IcoMyToken {
  int? id;
  int? userId;
  String? name;
  int? coinId;
  dynamic key;
  int? type;
  String? coinType;
  int? status;
  int? isPrimary;
  double? balance;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? address;
  String? coinIcon;
  int? isWithdrawal;
  int? isDeposit;
  int? tradeStatus;
  String? imagePath;

  IcoMyToken({
    this.id,
    this.userId,
    this.name,
    this.coinId,
    this.key,
    this.type,
    this.coinType,
    this.status,
    this.isPrimary,
    this.balance,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.coinIcon,
    this.isWithdrawal,
    this.isDeposit,
    this.tradeStatus,
    this.imagePath,
  });

  factory IcoMyToken.fromJson(Map<String, dynamic> json) => IcoMyToken(
        id: json["id"],
        userId: json["user_id"],
        name: json["name"],
        coinId: json["coin_id"],
        key: json["key"],
        type: json["type"],
        coinType: json["coin_type"],
        status: json["status"],
        isPrimary: json["is_primary"],
        balance: makeDouble(json["balance"]),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        address: json["address"],
        coinIcon: json["coin_icon"],
        isWithdrawal: json["is_withdrawal"],
        isDeposit: json["is_deposit"],
        tradeStatus: json["trade_status"],
        imagePath: json["image_path"],
      );
}

class IcoWithdrawData {
  Earns? earns;
  Map<String, String>? currencyTypes;
  List<FiatCurrency>? currencies;
  List<IcoCoin>? coins;

  IcoWithdrawData({this.earns, this.currencyTypes, this.currencies, this.coins});

  factory IcoWithdrawData.fromJson(Map<String, dynamic> json) => IcoWithdrawData(
        earns: json["earns"] == null ? null : Earns.fromJson(json["earns"]),
        currencyTypes: json["currency_types"] == null ? null : Map.from(json["currency_types"]).map((k, v) => MapEntry<String, String>(k, v)),
        currencies: json["currencys"] == null ? null : List<FiatCurrency>.from(json["currencys"].map((x) => FiatCurrency.fromJson(x))),
        coins: json["coins"] == null ? null : List<IcoCoin>.from(json["coins"].map((x) => IcoCoin.fromJson(x))),
      );
}

class Earns {
  int? userId;
  double? earn;
  double? withdraw;
  double? available;
  String? currency;

  Earns({this.userId, this.earn, this.withdraw, this.available, this.currency});

  factory Earns.fromJson(Map<String, dynamic> json) => Earns(
        userId: json["user_id"],
        earn: makeDouble(json["earn"]),
        withdraw: makeDouble(json["withdraw"]),
        available: makeDouble(json["available"]),
        currency: json["currency"],
      );
}

class IcoCoin {
  int? id;
  String? coinType;

  IcoCoin({this.id, this.coinType});

  factory IcoCoin.fromJson(Map<String, dynamic> json) => IcoCoin(id: json["id"], coinType: json["coin_type"]);
}
