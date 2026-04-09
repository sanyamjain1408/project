import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_constants.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../ui/ui_helper/app_widgets.dart';
import 'ico_buy_token/ico_buy_token_screen.dart';
import 'ico_controller.dart';
import 'ico_widgets.dart';

class ICOPhaseDetailsPage extends StatefulWidget {
  const ICOPhaseDetailsPage({super.key, required this.phase});

  final IcoPhase phase;

  @override
  State<ICOPhaseDetailsPage> createState() => _ICOPhaseDetailsPageState();
}

class _ICOPhaseDetailsPageState extends State<ICOPhaseDetailsPage> {
  final _controller = Get.find<IcoController>();
  late IcoPhase phase;

  @override
  void initState() {
    phase = widget.phase;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getIcoActivePhaseDetails(phase.id ?? 0, (ph) {
        phase = ph;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "ICO Phase Details".tr),
      body: SafeArea(
          child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          showImageNetwork(imagePath: phase.image, width: context.width, height: context.width / 2, boxFit: BoxFit.cover),
          vSpacer10(),
          Row(
            children: [
              TextRobotoAutoBold(phase.tokenName ?? "", fontSize: Dimens.fontSizeLarge),
              hSpacer5(),
              Icon(Icons.check_circle, size: Dimens.iconSizeMin, color: context.theme.primaryColor)
            ],
          ),
          Row(
            children: [
              if (phase.websiteLink.isValid) LinkView(title: "Website".tr, link: phase.websiteLink),
              if (phase.videoLink.isValid) LinkView(title: "Video Link".tr, link: phase.videoLink),
              const Spacer(),
              buttonText("Buy Now".tr,
                  visualDensity: VisualDensity.compact,
                  onPress: () => checkLoggedInStatus(context, () => Get.off(() => IcoBuyTokenScreen(phase: phase))))
            ],
          ),
          vSpacer10(),
          IcoPhaseInfoView(phase: phase, fromPage: IcoFromKey.details, flex: 4),
          vSpacer20(),
          TextRobotoAutoBold(phase.phaseTitle ?? "N/A".tr, maxLines: 3),
          vSpacer2(),
          TextRobotoAutoNormal(phase.description ?? "N/A".tr, maxLines: 50),
          vSpacer20(),
          TextRobotoAutoBold("Details Rule".tr),
          vSpacer2(),
          TextRobotoAutoNormal(phase.detailsRule ?? "N/A".tr, maxLines: 50),
          _additionalInfoView(),
          SocialLinksView(linkText: phase.socialLink)
        ],
      )),
    );
  }

  Widget _additionalInfoView() {
    return phase.icoPhaseAdditionalDetails.isValid
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            vSpacer20(),
            TextRobotoAutoBold("Additional information".tr),
            vSpacer2(),
            Column(
                children: List.generate(phase.icoPhaseAdditionalDetails!.length, (index) {
              final info = phase.icoPhaseAdditionalDetails![index];
              return TwoTextSpaceFixed("${info.title ?? ""}: ", info.value ?? "", flex: 5, maxLine: 3, subMaxLine: 3);
            }))
          ])
        : vSpacer0();
  }
}

class LinkView extends StatelessWidget {
  const LinkView({super.key, this.link, this.icon, required this.title});

  final String title;
  final String? link;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Dimens.paddingMid),
      child: InkWell(
        onTap: () => openUrlInBrowser(link ?? ""),
        child: Row(
          children: [
            Icon(icon ?? Icons.link_outlined, size: Dimens.iconSizeMin, color: context.theme.primaryColor),
            TextRobotoAutoNormal(title, color: context.theme.primaryColor)
          ],
        ),
      ),
    );
  }
}

class SocialLinksView extends StatelessWidget {
  const SocialLinksView({super.key, this.linkText});

  final String? linkText;

  @override
  Widget build(BuildContext context) {
    if (linkText.isValid) {
      final linkMap = json.decode(linkText!);
      // final linkMap = json.decode("{\"Facebook\":\"https://www.facebook.com\",\"Twitter\":null,\"Linkedin\":null}");
      if (linkMap is Map<String, dynamic> && linkMap.isNotEmpty) {
        final fb = linkMap[IcoSocialKeyString.facebook] as String?;
        final twitter = linkMap[IcoSocialKeyString.twitter] as String?;
        final linkedin = linkMap[IcoSocialKeyString.linkedIn] as String?;
        final isAnyValid = fb.isValid || twitter.isValid || linkedin.isValid;
        return isAnyValid
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                vSpacer20(),
                TextRobotoAutoBold("Social Channels".tr),
                vSpacer10(),
                Wrap(
                  runSpacing: Dimens.paddingMid,
                  spacing: Dimens.paddingMid,
                  children: [
                    if (fb.isValid) _socialIconView(fb!, icon: Icons.facebook),
                    if (twitter.isValid) _socialIconView(twitter!, assetIcon: AssetConstants.icTwitter),
                    if (linkedin.isValid) _socialIconView(linkedin!, assetIcon: AssetConstants.icLinkedin)
                  ],
                )
              ])
            : vSpacer0();
      }
    }

    return vSpacer0();
  }

  InkWell _socialIconView(String link, {IconData? icon, String? assetIcon}) {
    return InkWell(
      onTap: () => openUrlInBrowser(link),
      child: showImageAsset(
          imagePath: assetIcon ?? "",
          icon: icon,
          iconSize: Dimens.iconSizeMid,
          width: Dimens.iconSizeMid,
          height: Dimens.iconSizeMid,
          color: Get.theme.primaryColor),
    );
  }
}
