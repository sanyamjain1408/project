import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'my_profile_controller.dart';

class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key, required this.registrationId});

  final String registrationId;

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  TextEditingController codeEditController = TextEditingController();
  final _controller = Get.put(MyProfileController());
  Timer? resendTimer;
  RxBool resendActive = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      startTimer();
    });
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subTitle = "${'Enter verification code which sent phone'.tr} ${widget.registrationId}";
    return Scaffold(
      appBar: appBarBackWithActions(title: "Verify Phone".tr),
      body: SafeArea(
        child: Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Dimens.paddingMid),
            children: [
              vSpacer10(),
              TextRobotoAutoBold(subTitle, color: context.theme.primaryColorLight, maxLines: 3),
              vSpacer20(),
              pinCodeView(controller: codeEditController),
              vSpacer20(),
              buttonRoundedMain(text: "Verify".tr, onPress: () => checkInputData()),
              vSpacer20(),
              Obx(() => textSpanWithAction('Did not receive code'.tr, "Resend".tr.toUpperCase(), onTap: () {
                    if (resendActive.value) {
                      _controller.sendSMS(widget.registrationId, true);
                      startTimer();
                    }
                  }, textAlign: TextAlign.end, subColor: resendActive.value ? null : context.theme.dividerColor))
            ],
          ),
        ),
      ),
    );
  }

  void startTimer() {
    resendActive.value = false;
    int second = 0;
    resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      second++;
      if (second == 45) {
        resendTimer?.cancel();
        resendActive.value = true;
      }
    });
  }

  void checkInputData() {
    if (codeEditController.text.length < DefaultValue.codeLength) {
      showToast("code_invalid_message".trParams({"count": DefaultValue.codeLength.toString()}));
      return;
    }
    hideKeyboard(context: context);
    _controller.verifyPhone(codeEditController.text);
  }
}
