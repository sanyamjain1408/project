class P2pAPIURLConstants {
  ///End Urls : POST
  static const p2pAdsFilterChange = "/api/p2p/ads-filter-change";
  static const p2pOrderRate = "/api/p2p/get-p2p-order-rate";
  static const p2pAdsAvailableBalance = "/api/p2p/ads-available-balance";
  static const p2pPlaceP2pOrder = "/api/p2p/place-p2p-order";
  static const p2pPaymentMethod = "/api/p2p/payment-method";
  static const p2pTransferWalletBalance = "/api/p2p/transfer-wallet-balance";
  static const p2pUserAdsFilter = "/api/p2p/user-ads-filter";
  static const p2pAdsStatusChange = "/api/p2p/ads-status-change";
  static const p2pAdsDelete = "/api/p2p/ads-delete";
  static const p2pUserAdsEdit = "/api/p2p/ads-edit";
  static const p2pUserAdsSave = "/api/p2p/ads";
  static const p2pOrderDetails = "/api/p2p/get-p2p-order-details";
  static const p2pSendMessage = "/api/p2p/send-message";
  static const p2pOrderPayment = "/api/p2p/payment-p2p-order";
  static const p2pOrderRelease = "/api/p2p/release-p2p-order";
  static const p2pOrderFeedback = "/api/p2p/order-feedback";
  static const p2pOrderCancel = "/api/p2p/cancel-p2p-order";
  static const p2pOrderDispute = "/api/p2p/dispute-process";
  static const p2pGiftCardStoreAd = "/api/p2p/store-gift-card-adds";
  static const p2pGiftCardUpdateAd = "/api/p2p/update-gift-card-adds";
  static const p2pGiftCardDeleteAd = "/api/p2p/gift-card-delete";
  static const p2pGiftCardPlaceAd = "/api/p2p/place-gift-card-order";
  static const p2pGiftCardFeedbackUpdate = "/api/p2p/update-gift-card-order-feedback";
  static const p2pGiftCardOrderPayNow = "/api/p2p/pay-now-gift-card-order";
  static const p2pGiftCardOrderPaymentConfirm = "/api/p2p/payment-confirm-gift-card-order";
  static const p2pGiftCardOrderCancel = "/api/p2p/gift-card-order-cancel";
  static const p2pGiftCardOrderDispute = "/api/p2p/gift-card-order-dispute";
  static const p2pGiftCardSendMessage = "/api/p2p/send-message-gift";

  ///End Urls : GET
  static const getP2pAdsMarketSettings = "/api/p2p/ads-market-setting";
  static const getP2pUserProfile = "/api/p2p/user-profile";
  static const getP2pAdsDetails = "/api/p2p/ads-details";
  static const getP2pMyOrderListData = "/api/p2p/my-order-list-data";
  static const getP2pMyOrdersList = "/api/p2p/my-p2p-order";
  static const getP2pMyDisputeList = "/api/p2p/my-p2p-dispute";
  static const getP2pUserCenter = "/api/p2p/user-center";
  static const getP2pPaymentMethod = "/api/p2p/payment-method";
  static const getP2pAdminPaymentMethod = "/api/p2p/admin-payment-method";
  static const getP2pDetailsPaymentMethod = "/api/p2p/details-payment-method-";
  static const p2pPaymentMethodDelete = "/api/p2p/payment-method-delete-";
  static const getP2pWallets = "/api/p2p/wallets";
  static const getP2pAdsCreateSetting = "/api/p2p/ads-create-setting";
  static const getP2pAdsPrice = "/api/p2p/ads-price-get";
  static const getP2pGiftCardAdDetails = "/api/p2p/get-gift-card-ads-details-p2p";
  static const getP2pGiftCardPageData = "/api/p2p/get-gift-card-page-data";
  static const getP2pGiftCardAllAdList = "/api/p2p/all-gift-card-ads-list";
  static const getP2pGiftCardOrders = "/api/p2p/get-gift-card-orders";
  static const getP2pGiftCardList = "/api/p2p/get-gift-card-p2p";
  static const getP2pGiftCardUserAdList = "/api/p2p/user-gift-card-ads-list";
  static const getP2pGiftCardDetails = "/api/p2p/gift-card-details";
  static const getP2pGiftCardOrderDetails = "/api/p2p/get-gift-card-order";
}

class P2pAPIKeyConstants {
  static const coin = "coin";
  static const paymentMethod = "payment_method";
  static const paymentId = "payment_id";
  static const paymentUid = "payment_uid";
  static const country = "country";
  static const adsType = "ads_type";
  static const adsStatus = "ads_status";
  static const adsId = "ads_id";
  static const adsUid = "ads_uid";
  static const uid = "uid";
  static const coinType = "coin_type";
  static const balance = "balance";
  static const fromDate = "from_date";
  static const toDate = "to_date";
  static const username = "username";
  static const mobileAccountNumber = "mobile_account_number";
  static const cardNumber = "card_number";
  static const cardType = "card_type";
  static const bankName = "bank_name";
  static const bankAccountNumber = "bank_account_number";
  static const accountOpeningBranch = "account_opening_branch";
  static const transactionReference = "transaction_reference";
  static const delete = "delete";
  static const orderUid = "order_uid";
  static const order = "order";
  static const file = "file";
  static const tradeId = "trade_id";
  static const paymentSlip = "payment_slip";
  static const feedbackType = "feedback_type";
  static const feedback = "feedback";
  static const reason = "reason";
  static const reasonSubject = "reason_subject";
  static const reasonDetails = "reason_details";
  static const giftCardId = "gift_card_id";
  static const giftCardOrderId = "gift_card_order_id";
  static const paymentCurrencyType = "payment_currency_type";
  static const currencyType = "currency_type";
  static const paymentMethodUid = "payment_method_uid";
  static const slip = "slip";
}

class P2pTradeStatus {
  static const timeExpired = 0;
  static const escrow = 1;
  static const paymentDone = 2;
  static const transferDone = 3;
  static const canceled = 4;
  static const disputed = 5;
  static const refundedByAdmin = 6;
  static const releasedByAdmin = 7;
}

class P2pGiftCardStatus {
  static const deActive = 0;
  static const active = 1;
  static const success = 2;
  static const canceled = 3;
  static const onGoing = 4;
}

class P2pPaymentType {
  static const bank = 1;
  static const mobile = 2;
  static const card = 3;
}

class CardPaymentType {
  static const debit = 1;
  static const credit = 2;
}

class P2pPriceType {
  static const fixed = 1;
  static const floating = 2;
}

class TransactionType {
  static const buy = 1;
  static const sell = 2;
}

class PaymentCurrencyType {
  static const bank = 1;
  static const crypto = 2;
}