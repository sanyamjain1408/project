import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/user.dart';


const _bg        = Color(0xFF0A0B0D);
const _card      = Color(0xFF111318);
const _green     = Color(0xFFB5F000);
const _border    = Color(0xFF1E2128);
const _textDim   = Color(0xFF6B7280);
const _textMid   = Color(0xFFB0B8C1);

Rx<User> gUserRx = User(id: 0).obs;
bool gIsDarkMode = false;
bool gIsLandingScreenShowed = false;
String gUserAgent = "";
Color gBuyColor = _green;
Color gSellColor = Color(0xD73C3C);
BuildContext? currentContext;
RxBool gIsBalanceHide = false.obs;
int tradeDecimal = DefaultValue.decimal;

class TemporaryData {
  static CoinPair? selectedCurrencyPair;
  static String? activityType;
  static int? changingPageId;
}

enum IdVerificationType { none, nid, passport, driving, voter }

enum PhotoType { front, back, selfie }

class AssetConstants {
  //ICONS
  static const basePathIcons = "assets/icons/";
  static const blogo = "${basePathIcons}blogo.png";
  static const icEmail = "${basePathIcons}ic_email.svg";
  static const icFingerprintScan = "${basePathIcons}ic_fingerprint_scan.svg";
  static const icKey = "${basePathIcons}ic_key.svg";
  static const icDelete = "${basePathIcons}ic_delete.svg";
  static const icSmartphone = "${basePathIcons}ic_smartphone.svg";
  static const icUpload = "${basePathIcons}ic_upload.svg";
  static const icRibbon = "${basePathIcons}ic_ribbon.png";
  static const icGift = "${basePathIcons}ic_gift.png";
  static const icGoogle = "${basePathIcons}ic_google.png";
  static const icArrowDropDown = "${basePathIcons}ic_arrow_drop_down.svg";
  static const icArrowDropUp = "${basePathIcons}ic_arrow_drop_up.svg";
  static const icArrowLeft = "${basePathIcons}ic_arrow_left.svg";
  static const icCloseBox = "${basePathIcons}ic_close_box.svg";
  static const icPasswordHide = "${basePathIcons}ic_password_hide.svg";
  static const icPasswordShow = "${basePathIcons}ic_password_show.svg";
  static const icTickLarge = "${basePathIcons}icTickLarge.svg";
  static const icBoxFilterAll = "${basePathIcons}icBoxFilterAll.svg";
  static const icSearch = "${basePathIcons}icSearch.svg";
  static const icCross = "${basePathIcons}icCross.svg";
  static const icCopy = "${basePathIcons}icCopy.svg";
  static const icEditRoundBg = "${basePathIcons}icEditRoundBg.png";
  static const icTwitter = "${basePathIcons}ic_twitter.svg";
  static const icLinkedin = "${basePathIcons}ic_linkedin.svg";


  ///IMAGES
  static const basePathImages = "assets/images/";
  static const imgDrivingLicense = "${basePathImages}img_driving_license.png";
  static const imgNID = "${basePathImages}img_nid.png";
  static const imgPassport = "${basePathImages}img_passport.png";
  static const imgVoterCard = "${basePathImages}img_voter_card.png";
  static const onBoarding0 = "${basePathImages}onBoarding0.png";
  static const onBoarding1 = "${basePathImages}onBoarding1.png";
  static const onBoarding2 = "${basePathImages}onBoarding2.png";
  static const imgGoogleAuthenticator = "${basePathImages}img_google_authenticator.png";
  static const imgIcoMiddle = "${basePathImages}img_ico_middle.png";

  ///OTHERS
  static const pathTempImageFolder = "/tmpImages/";

}

class FromKey {
  static const up = "up";
  static const down = "down";
  static const buy = "buy";
  static const sell = "sell";
  static const all = "all";
  static const buySell = "buy_sell";
  static const trade = "trade";
  static const dashboard = "dashboard";
  static const check = "check";
  static const home = "home";
  static const future = "future";
  static const open = "open";
  static const close = "close";
  static const swap = "swap";
  static const wallet = "wallet";
}

class HistoryType {
  static const deposit = "deposit";
  static const withdraw = "withdraw";
  static const stopLimit = "stop_limit";
  static const swap = "swap";
  static const buyOrder = "buy_order";
  static const sellOrder = "sell_order";
  static const transaction = "transaction";
  static const fiatDeposit = "fiat_deposit";
  static const fiatWithdrawal = "fiat_withdrawal";
  static const refEarningWithdrawal = "ref_earning_withdrawal";
  static const refEarningTrade = "ref_earning_trade";
}

class PreferenceKey {
  static const isDark = 'is_dark';
  static const languageKey = "language_key";
  static const isOnBoardingDone = 'is_on_boarding_done';
  static const isLoggedIn = "is_logged_in";
  static const accessToken = "access_token";
  static const accessTokenEvm = "evm_access_token";
  static const accessType = "access_type";
  static const userObject = "user_object";
  static const settingsObject = "settings_object";
  static const mediaList = "media_list";
  static const buySellColorIndex = "buy_sell_color_index";
  static const buySellUpDown = "buy_sell_up_down";
  static const isBalanceHide = "is_balance_hide";
  static const favoritesSpot = "favorites_spot";
  static const favoritesFuture = "favorites_future";
}

class DefaultValue {
  static const int kPasswordLength = 6;
  static const int codeLength = 6;
  static const String currency = "USD";
  static const String currencySymbol = "\$";
  static const String crispKey = "encrypt";
  static const String all = "all";

  static const int listLimitLarge = 20;
  static const int listLimitMedium = 10;
  static const int listLimitShort = 5;
  static const int listLimitOrderBook = 14;

  static const int fiatDecimal = 2;
  static const int cryptoDecimal = 4;
  static const int decimal = 8;

  static const bool showLanding = true;

  static const String randomImage = "https://picsum.photos/200";
      // "https://media.istockphoto.com/photos/high-angle-view-of-a-lake-and-forest-picture-id1337232523"; //"https://picsum.photos/200";
}

class ListConstants {
  static const List<String> percents = ['25', '50', '75', '100'];
  static const List<int> leverages = [1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  static const List<String> coinType = ["BTC", "LTCT", "ETH", "LTC", "DOGE", "BCH", "DASH", "ETC", "USDT"];
  static const kCategoryColorList = [Color(0xff1F78FC), Color(0xffE30261), Color(0xffD200A4), Color(0xffFFA800)];
}

class EnvKeyValue {
  static const kStripKey = "stripKey";
  static const kEnvFile = ".env";
  static const kModePaypal = "modePaypal";
  static const kClientIdPaypal = "clientIdPaypal";
  static const kSecretPaypal = "secretPaypal";
  static const kApiSecret = "apiSecret";
}

class IdVerificationStatus {
  static const notSubmitted = "Not Submitted";
  static const pending = "Pending";
  static const accepted = "Approved";
  static const rejected = "Rejected";
}

class UserStatus {
  static const pending = 0;
  static const accepted = 1;
  static const rejected = 2;
  static const suspended = 4;
  static const deleted = 5;
}

class RegistrationType {
  static const facebook = 1;
  static const google = 2;
  static const twitter = 3;
  static const apple = 4;
}

class PaymentMethodType {
  static const paypal = 3;
  static const bank = 4;
  static const card = 5;
  static const wallet = 6;
  static const crypto = 8;
  static const payStack = 9;
}

class FAQType {
  static const main = 1;
  static const deposit = 2;
  static const withdraw = 3;
  static const buy = 4;
  static const sell = 5;
  static const coin = 6;
  static const wallet = 7;
  static const trade = 8;
}

class StakingInvestmentStatus {
  static const running = 1;
  static const canceled = 2;
  static const unpaid = 3;
  static const paid = 4;
  static const success = 5;
}

class StakingTermsType {
  static const strict = 1;
  static const flexible = 2;
}

class StakingRenewType {
  static const manual = 1;
  static const auto = 2;
}

class GiftCardStatus {
  static const active = 1;
  static const redeemed = 2;
  static const transferred = 3;
  static const trading = 4;
  static const locked = 5;
}

class GiftCardCheckStatus {
  static const redeem = 1;
  static const add = 2;
  static const check = 3;
}

class GiftCardSendType {
  static const email = 1;
  static const phone = 2;
}

class WalletType {
  static const spot = 1;
  static const p2p = 2;
}

class FutureMarketKey {
  static const assets = "assets";
  static const hour = "hour";
  static const new_ = "new";
}

class FTTransactionType {
  static const transfer = 1;
  static const commission = 2;
  static const fundingFee = 3;
  static const realizedPnl = 4;
}

class WalletFiatHistoryStatus {
  static const pending = 0;
  static const accepted = 1;
  static const rejected = 2;
}

class WalletCryptoHistoryStatus {
  static const pending = 0;
  static const success = 1;
  static const rejected = 2;
  static const failed = 3;
  static const initial = 4;
  static const processing = 5;
  static const expire = 99;
}

class FutureTradeType {
  static const open = 1;
  static const close = 2;
  static const takeProfitClose = 3;
  static const stopLossClose = 4;
}

class TradeType {
  static const buy = 1;
  static const sell = 2;
}

class OrderType {
  static const limit = 1;
  static const market = 2;
  static const stopLimit = 3;
  static const stopMarket = 4;
}

class MarginMode {
  static const isolate = 1;
  static const cross = 2;
}

class CurrencyType {
  static const crypto = 1;
  static const fiat = 2;
}

class WalletViewType {
  static const overview = 0;
  static const spot = 1;
  static const future = 2;
  static const p2p = 3;
  static const checkDeposit = 4;
}

/// # trc20Token, evmBaseCoin => network list; # coinPayment && USDT => network list(coin payment)
class NetworkType {
  static const coinPayment = 1;
  static const bitcoinApi = 2;
  static const bitGoApi = 3;
  static const trc20Token = 6;
  static const evmBaseCoin = 8;
  static const evmSolana = 10;
}

class BlogNewsType {
  static const recent = 1;
  static const popular = 2;
  static const feature = 3;
}

class AppBottomNavKey {
  static const home = 1;
  static const market = 2;
  static const trade = 3;
  static const future = 4;
  static const wallet = 5;
}

class SortKey {
  static const pair = 1;
  static const volume = 2;
  static const price = 3;
  static const change = 4;
  static const capital = 5;
}

class TransferType {
  static const deposit = 1;
  static const withdraw = 2;
}

class BankAccessType {
  static const user = 1;
  static const admin = 2;
  static const ico = 3;
  static const p2p = 4;
}

class ActionType {
  static const edit = 1;
  static const delete = 2;
}

class DynamicFieldTypes {
  static const text = "text";
  static const email = 'email';
  static const number = 'number';
}

