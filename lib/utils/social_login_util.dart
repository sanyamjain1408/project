import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tradexpro_flutter/ui/features/auth/social_login_view.dart';
import 'common_utils.dart';

final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
bool isProcessGoing = false;

class SocialLoginUtil {
  ///https://pub.dev/packages/google_sign_in
  void google(Function(SocialLogin) onSuccess) async {
    if (isProcessGoing) return;
    try {
      isProcessGoing = true;

      ///googleSignIn.signOut();
      GoogleSignInAccount? googleAccount = googleSignIn.currentUser;
      googleAccount ??= await googleSignIn.signIn();
      if (googleAccount?.id != null && googleAccount!.id.isNotEmpty) {
        final sl = SocialLogin(socialId: googleAccount.id, name: googleAccount.displayName, email: googleAccount.email);
        onSuccess(sl);
        isProcessGoing = false;
      } else {
        isProcessGoing = false;
        showToast("Google account not found".tr);
        return;
      }
    } catch (e) {
      isProcessGoing = false;
      showToast(e.toString());
      printFunction("loginWithGoogle error ", e);
    }
  }

  void googleWithAccessToken(Function(SocialLogin) onSuccess) async {
    if (isProcessGoing) return;
    try {
      isProcessGoing = true;

      /// googleSignIn.signOut();
      GoogleSignInAccount? googleAccount = googleSignIn.currentUser;
      googleAccount ??= await googleSignIn.signIn();
      if (googleAccount != null) {
        final authData = await googleAccount.authentication;
        if (authData.accessToken != null && authData.accessToken!.isNotEmpty) {
          final sl =
              SocialLogin(socialId: googleAccount.id, name: googleAccount.displayName, email: googleAccount.email, token: authData.accessToken);
          onSuccess(sl);
        }
        isProcessGoing = false;
      } else {
        isProcessGoing = false;
        showToast("Google account not found".tr);
        return;
      }
    } catch (e) {
      isProcessGoing = false;
      showToast(e.toString());
      printFunction("loginWithGoogle error ", e);
    }
  }

  ///https://pub.dev/packages/flutter_facebook_auth
  void facebook(Function(SocialLogin) onSuccess) async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      switch (loginResult.status) {
        case LoginStatus.cancelled:
          return;
        case LoginStatus.failed:
          showToast(loginResult.message ?? 'Facebook account not found'.tr);
          return;
        case LoginStatus.operationInProgress:
          break;
        case LoginStatus.success:
          final userData = await FacebookAuth.instance.getUserData();
          final userId = userData['id'] as String? ?? '';
          if (userId.isNotEmpty) {
            final sl = SocialLogin(socialId: userId, name: userData['name'], email: userData['email']);
            onSuccess(sl);
          } else {
            showToast('Facebook account not found'.tr);
          }
          break;
      }
    } catch (e) {
      showToast(e.toString());
      debugPrint("facebook error $e");
    }
  }

  void facebookWithAccessToken(Function(SocialLogin) onSuccess) async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      switch (loginResult.status) {
        case LoginStatus.cancelled:
          return;
        case LoginStatus.failed:
          showToast(loginResult.message ?? 'Facebook account not found'.tr);
          return;
        case LoginStatus.operationInProgress:
          break;
        case LoginStatus.success:
          final AccessToken? accessToken = loginResult.accessToken;
          if (accessToken != null) {
            final userData = await FacebookAuth.instance.getUserData();
            final sl = SocialLogin(socialId: userData['id'], name: userData['name'], email: userData['email'], token: accessToken.tokenString);
            onSuccess(sl);
          } else {
            showToast('Facebook account not found'.tr);
          }
          break;
      }
    } catch (e) {
      showToast(e.toString());
      debugPrint("facebook error $e");
    }
  }

  bool isAppleSupported() {
    if (Platform.isIOS) {
      var versionStr = Platform.operatingSystemVersion.split(" ")[1];
      var version = int.parse(versionStr.split(".")[0]);
      if (version >= 13) return true;
    }
    return false;
  }

  ///https://pub.dev/packages/sign_in_with_apple
  void appleWithAccessToken(Function(SocialLogin) onSuccess) async {
    if (isProcessGoing) return;
    try {
      isProcessGoing = true;

      if (!SocialLoginUtil().isAppleSupported()) {
        showToast('unsupported_os_version'.tr);
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      final token = credential.identityToken;
      if (token != null && token.isNotEmpty) {
        final sl = SocialLogin(socialId: credential.userIdentifier, name: credential.givenName, email: credential.email, token: token);
        onSuccess(sl);
      } else {
        showToast("apple account not found".tr);
      }
      isProcessGoing = false;
    } catch (e) {
      isProcessGoing = false;
      printFunction("loginWithApple error ", e);
      if (e is SignInWithAppleAuthorizationException && [AuthorizationErrorCode.canceled, AuthorizationErrorCode.unknown].contains(e.code)) return;
      showToast(e.toString());
    }
  }

  void appleWithServiceId(Function(String, String) onSuccess) async {
    if (isProcessGoing) return;
    try {
      isProcessGoing = true;
      if (!SocialLoginUtil().isAppleSupported()) {
        showToast('unsupported_os_version'.tr);
        return;
      }
      WebAuthenticationOptions? webAuthenticationOptions;
      showLoadingDialog();
      final data = []; //await getSettingsBySlug([SettingsSlug.appleAuthServiceId, SettingsSlug.appleAuthRedirectUrl]);
      hideLoadingDialog();
      webAuthenticationOptions = WebAuthenticationOptions(clientId: data.first, redirectUri: Uri.parse(data.last));
      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], webAuthenticationOptions: webAuthenticationOptions);
      final userId = credential.userIdentifier; //Android did not get it
      final authorizationCode = credential.authorizationCode;
      authorizationCode.isNotEmpty ? onSuccess(userId ?? "", authorizationCode) : showToast("apple account not found".tr);
      isProcessGoing = false;
    } catch (e) {
      isProcessGoing = false;
      printFunction("loginWithApple error ", e);
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) return;
      showToast(e.toString());
    }
  }
}
