import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/social_login_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

class SocialLoginView extends StatelessWidget {
  const SocialLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getSettingsLocal();
    final isApple = settings?.socialLoginAppleEnable == 1 &&  SocialLoginUtil().isAppleSupported();

    return settings?.socialLoginEnable == 1
        ? Column(
            children: [
              vSpacer20(),
              Row(children: [
                Expanded(child: dividerHorizontal(indent: Dimens.paddingLarge)),
                TextRobotoAutoNormal("Or_continue_with".tr),
                Expanded(child: dividerHorizontal(indent: Dimens.paddingLarge))
              ],),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (settings?.socialLoginGoogleEnable == 1)
                    buttonOnlyIcon(
                        iconPath: AssetConstants.icGoogle,
                        size: Dimens.iconSizeLarge,
                        onPress: () => SocialLoginUtil().googleWithAccessToken((loginInfo) => loginWithSocialAccount(RegistrationType.google, loginInfo))),
                  if (settings?.socialLoginFacebookEnable == 1) hSpacer10(),
                  if (settings?.socialLoginFacebookEnable == 1)
                    buttonOnlyIcon(
                        iconData: Icons.facebook,
                        iconColor: Colors.blue,
                        size: Dimens.iconSizeLarge,
                        onPress: () =>
                            SocialLoginUtil().facebookWithAccessToken((loginInfo) => loginWithSocialAccount(RegistrationType.facebook, loginInfo))),
                  if (isApple) hSpacer10(),
                  if (isApple)
                    buttonOnlyIcon(
                        iconData: Icons.apple,
                        size: Dimens.iconSizeLarge,
                        onPress: () => SocialLoginUtil().appleWithAccessToken((loginInfo) => loginWithSocialAccount(RegistrationType.apple, loginInfo))),
                ],
              ),
              vSpacer20(),
            ],
          )
        : Container();
  }

  void loginWithSocialAccount(int type, SocialLogin loginInfo) {
    loginInfo.type = type;
    showLoadingDialog();
    APIRepository().registerSocialAccount(loginInfo).then((resp) {
      hideLoadingDialog();
      if (resp.success && resp.data != null) {
        handleLoginSuccess(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString(), isError: true);
    });
  }
}

class SocialLogin {
  SocialLogin({
    this.type,
    this.socialId,
    this.name,
    this.email,
    this.token,
  });

  int? type;
  String? socialId;
  String? name;
  String? email;
  String? token;

  void toPrint() => printFunction("SocialLogin >>>>> ", "socialId: $socialId, name: $name, email: $email, type: $type, token: $token");
}
