class IcoAPIURLConstants {
  ///End Urls : POST
  static const icoTokenBuyNew = "/ico-launchpad/api/token-buy-ico-new";
  static const icoTokenWithdrawPrice = "/ico-launchpad/api/token-withdraw-price";
  static const icoTokenWithdrawRequest = "/ico-launchpad/api/token-withdraw-request";
  static const icoChatConversationStore = "/ico-launchpad/api/ico-chat-conversation-store";
  static const icoSavePhaseStatus = "/ico-launchpad/api/save-ico-phase-status";
  static const icoGetContractAddressDetails = "/ico-launchpad/api/get-contract-address-details";
  static const icoCreateUpdateToken = "/ico-launchpad/api/create-update-ico-token";
  static const icoCreateUpdateTokenPhase = "/ico-launchpad/api/create-update-ico-token-phase";
  static const icoDynamicFormSubmit = "/ico-launchpad/api/dynamic-form-submit";
  static const icoCreateUpdateTokenPhaseAdditional = "/ico-launchpad/api/create-update-ico-token-phase-additional";

  ///End Urls : GET
  static const getIcoLaunchpadSettings = "/ico-launchpad/api/launchpad-settings";
  static const getIcoPhaseActiveList = "/ico-launchpad/api/ico-phase-active-list";
  static const getIcoActivePhaseDetails = "/ico-launchpad/api/active-ico-phase-details";
  static const getIcoTokenBuyPage = "/ico-launchpad/api/token-buy-page";
  static const getIcoTokenPriceInfo = "/ico-launchpad/api/token-price-info";
  static const getIcoSubmittedDynamicFormList = "/ico-launchpad/api/submitted-dynamic-form-list";
  static const getIcoTokenListUser = "/ico-launchpad/api/ico-list-user";
  static const getIcoTokenBuyHistory = "/ico-launchpad/api/token-buy-history";
  static const getIcoMyTokenBalance = "/ico-launchpad/api/my-token-balance";
  static const getIcoTokenEarns = "/ico-launchpad/api/token-earns";
  static const getIcoChatDetails = "/ico-launchpad/api/ico-chat-details";
  static const getIcoTokenPhaseList = "/ico-launchpad/api/ico-token-phase-list";
  static const getIcoDynamicForm = "/ico-launchpad/api/dynamic-form";
  static const getIcoTokenPhaseAdditionalDetails = "/ico-launchpad/api/ico-token-phase-additional-details";
  static const getIcoCreateTokenDetails = "/ico-launchpad/api/ico-details";
  static const getIcoTokenWithdrawList = "/ico-launchpad/api/token-withdraw-list";

  /// Main App
  static const getIcoCoinList = "/api/get-coin-list";
}

class IcoPhaseSortType {
  static const expired = 1;
  static const featured = 2;
  static const recent = 3;
  static const future = 4;
}

class IcoSocialKeyInt {
  static const facebook = 1;
  static const twitter = 2;
  static const linkedIn = 3;
}

class DynamicFormType {
  static const inputText = 1;
  static const dropdown = 2;
  static const radio = 3;
  static const checkbox = 4;
  static const textArea = 5;
  static const file = 6;
}

class IcoSocialKeyString {
  static const facebook = "Facebook";
  static const twitter = "Twitter";
  static const linkedIn = "Linkedin";
}

class IcoFromKey {
  static const details = "details";
  static const buyToken = "buyToken";
}

class IcoCurrencyType {
  static const fiat = 1;
  static const crypto = 2;
}
