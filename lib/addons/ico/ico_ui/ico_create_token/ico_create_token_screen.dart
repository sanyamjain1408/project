import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dashboard.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../ui/ui_helper/app_widgets.dart';
import 'ico_create_token_controller.dart';

class IcoCreateTokenScreen extends StatefulWidget {
  const IcoCreateTokenScreen({super.key, this.preToken, this.fromId});

  final IcoToken? preToken;
  final int? fromId;

  @override
  State<IcoCreateTokenScreen> createState() => _IcoCreateTokenScreenState();
}

class _IcoCreateTokenScreenState extends State<IcoCreateTokenScreen> {
  final _controller = Get.put(IcoCreateTokenController());
  final _focusLink = FocusNode();
  final _focusContract = FocusNode();
  final linkEditController = TextEditingController();
  final contractEditController = TextEditingController();
  final decimalEditController = TextEditingController();
  final walletEditController = TextEditingController();
  final privateEditController = TextEditingController();
  final gasEditController = TextEditingController();
  final websiteEditController = TextEditingController();
  final rulesEditController = TextEditingController();
  bool isEvm = false;

  @override
  void initState() {
    isEvm = getSettingsLocal()?.isEvmWallet == true;
    _controller.selectedNetwork.value = -1;
    _controller.preToken = widget.preToken;
    _setPreData();
    super.initState();
    _focusLink.addListener(_onFocusChange);
    _focusContract.addListener(_onFocusChange);
    if (isEvm) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller.getIcoCreateTokenDetails(widget.preToken?.id, (token) {
          _controller.preToken = token;
          _setPreData();
        });
      });
    } else {
      _controller.networkList.value = _controller.networkListStatic;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _focusLink.dispose();
    _focusContract.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.preToken == null ? "Add New ICO Token".tr : "Edit ICO Token".tr;
    final btnTitle = widget.preToken == null ? "Create Token".tr : "Edit Token".tr;

    return Scaffold(
      appBar: appBarBackWithActions(title: title),
      body: SafeArea(
          child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          vSpacer5(),
          TextRobotoAutoBold("Network".tr),
          Obx(() {
            final list = _controller.networkList.map((e) => e.networkName ?? "").toList();
            return dropDownListIndex(list, _controller.selectedNetwork.value, "Select".tr, (index) {
              _controller.selectedNetwork.value = index;
              _onFocusChange();
            }, hMargin: 0, bgColor: Colors.transparent);
          }),
          if (!isEvm)
            Column(
              children: [
                vSpacer5(),
                Obx(() {
                  final subText =
                      _controller.selectedNetwork.value == -1 ? "N/A".tr : _controller.networkList[_controller.selectedNetwork.value].networkType;
                  return TwoTextSpaceFixed("Base Coin".tr, subText ?? "");
                }),
                dividerHorizontal(),
              ],
            ),
          if (!isEvm) vSpacer10(),
          if (!isEvm)
            textFieldWithSuffixIcon(controller: linkEditController, hint: "Enter RPC Url".tr, labelText: "Chain Link".tr, focusNode: _focusLink),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: contractEditController, hint: "Enter contract address".tr, labelText: "Contract Address".tr, focusNode: _focusContract),
          Obx(() {
            final contract = _controller.contract.value;
            if (contract.chainId.isValid) {
              return Column(
                children: [
                  vSpacer10(),
                  TwoTextSpaceFixed("Token Symbol".tr, contract.symbol ?? ""),
                  TwoTextSpaceFixed("Token Name".tr, contract.name ?? ""),
                  TwoTextSpaceFixed("Chain Id".tr, contract.chainId ?? ""),
                  if (isEvm) TwoTextSpaceFixed("Decimal".tr, (contract.tokenDecimal ?? 0).toString()),
                  vSpacer10(),
                ],
              );
            } else {
              return _controller.contractError.value.isValid
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [vSpacer2(), TextRobotoAutoNormal(_controller.contractError.value, maxLines: 3, color: Colors.amber), vSpacer5()],
                    )
                  : vSpacer0();
            }
          }),
          if (!isEvm) vSpacer10(),
          if (!isEvm)
            textFieldWithSuffixIcon(controller: decimalEditController, hint: "Enter decimal".tr, type: TextInputType.number, labelText: "Decimal".tr),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: walletEditController, hint: "Enter wallet address".tr, labelText: "Wallet Address".tr),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: privateEditController, hint: "Enter private key".tr, labelText: "Wallet Private Key".tr, isObscure: true),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: gasEditController,
              hint: "Enter gas limit".tr,
              labelText: "Gas Limit".tr,
              type: const TextInputType.numberWithOptions(decimal: true)),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: websiteEditController, hint: "Enter website Link".tr, labelText: "Website Link".tr),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: rulesEditController,
              hint: "Enter your rules".tr,
              labelText: "Details Rules".tr,
              maxLines: 3,
              height: isTextScaleGetterThanOne(context) ? 100 : 80),
          vSpacer10(),
          if (widget.preToken?.imagePath.isValid ?? false)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextRobotoAutoBold("Selected Image".tr),
              showImageNetwork(imagePath: widget.preToken?.imagePath, height: Dimens.iconSizeLogo, width: Dimens.iconSizeLogo)
            ]),
          _documentView(),
          vSpacer10(),
          buttonRoundedMain(text: btnTitle, onPress: () => _checkAndCreateToken()),
          vSpacer10(),
        ],
      )),
    );
  }

  Row _documentView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buttonText("Select image".tr,
            visualDensity: VisualDensity.compact,
            onPress: () => showImageChooser(context, (chooseFile, isGallery) => _controller.selectedFile.value = chooseFile, isCrop: false)),
        Obx(() {
          final text = _controller.selectedFile.value.path.isEmpty ? "No image selected".tr : _controller.selectedFile.value.name;
          return Expanded(child: TextRobotoAutoNormal(text, maxLines: 2, textAlign: TextAlign.center));
        })
      ],
    );
  }

  void _setPreData() {
    if (_controller.preToken != null) {
      final index = _controller.networkList.indexWhere((element) => element.id.toString() == _controller.preToken?.network);
      if (index != -1) _controller.selectedNetwork.value = index;
      contractEditController.text = _controller.preToken?.contractAddress ?? "";
      walletEditController.text = _controller.preToken?.walletAddress ?? "";
      // privateEditController.text = _controller.preToken?.walletPrivateKey ?? "";
      gasEditController.text = (_controller.preToken?.gasLimit ?? "").toString();
      websiteEditController.text = _controller.preToken?.websiteLink ?? "";
      rulesEditController.text = _controller.preToken?.detailsRule ?? "";
      final contract = Contract();
      contract.chainId = _controller.preToken?.chainId;
      contract.name = _controller.preToken?.tokenName;
      contract.symbol = _controller.preToken?.coinType;
      if (isEvm) {
        contract.tokenDecimal = _controller.preToken?.decimal ?? 0;
      } else {
        decimalEditController.text = (_controller.preToken?.decimal ?? "").toString();
        linkEditController.text = _controller.preToken?.chainLink ?? "";
      }
      _controller.contract.value = contract;
    }
  }

  void _onFocusChange() {
    if (!_focusLink.hasFocus && !_focusContract.hasFocus) {
      final address = contractEditController.text.trim();
      if (address.isNotEmpty) {
        if (isEvm) {
          if (_controller.selectedNetwork.value != -1) {
            final network = _controller.networkList[_controller.selectedNetwork.value].id;
            _controller.icoGetContractAddressDetails(address, network: network);
          } else {
            showToast("Select_network_type");
          }
        } else {
          final link = linkEditController.text.trim();
          if (link.isNotEmpty) {
            _controller.icoGetContractAddressDetails(address, chainLink: link);
          }
        }
      } else {
        _controller.contractError.value = "";
      }
    }
  }

  Future<void> _checkAndCreateToken() async {
    final token = widget.preToken ?? IcoToken();
    if (_controller.selectedNetwork.value == -1) {
      showToast("Select_network_type".tr);
      return;
    }
    final net = _controller.networkList[_controller.selectedNetwork.value];
    token.network = net.id.toString();
    token.baseCoin = net.networkType;

    if (!isEvm) {
      token.chainLink = linkEditController.text.trim();
      if (!token.chainLink.isValid) {
        showToast("Enter_rpc_link".tr);
        return;
      }
    }

    token.contractAddress = contractEditController.text.trim();
    if (!token.contractAddress.isValid) {
      showToast("Enter_contract_Address".tr);
      return;
    }
    token.walletAddress = walletEditController.text.trim();
    if (!token.walletAddress.isValid) {
      showToast("Enter_wallet_Address".tr);
      return;
    }
    token.walletPrivateKey = privateEditController.text.trim();
    if (_controller.preToken == null && !token.walletPrivateKey.isValid) {
      showToast("Enter_wallet_private_key".tr);
      return;
    }
    token.gasLimit = makeDouble(gasEditController.text.trim());
    if (token.gasLimit! <= 0) {
      showToast("gas_limit_must_greater_than_0".tr);
      return;
    }
    if (_controller.contractError.isNotEmpty) {
      showToast(_controller.contractError.value);
      return;
    }
    final contract = _controller.contract.value;
    if (contract.chainId.isValid) {
      token.chainId = contract.chainId;
      token.tokenName = contract.name;
      token.coinType = contract.symbol;
    }
    if (isEvm) {
      token.decimal = contract.tokenDecimal;
    } else {
      token.decimal = makeInt(decimalEditController.text.trim());
    }

    token.formId = widget.fromId;
    token.websiteLink = websiteEditController.text.trim();
    token.detailsRule = rulesEditController.text.trim();
    hideKeyboard();
    _controller.icoCreateUpdateToken(token, _controller.selectedFile.value);
  }
}
