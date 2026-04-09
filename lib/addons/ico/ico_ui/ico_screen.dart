import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/constants.dart';
import '../../../helper/app_helper.dart';
import '../../../utils/appbar_util.dart';
import '../../../utils/button_util.dart';
import '../../../utils/common_utils.dart';
import '../../../utils/common_widgets.dart';
import '../../../utils/decorations.dart';
import '../../../utils/dimens.dart';
import '../../../utils/image_util.dart';
import '../../../utils/spacers.dart';
import '../../../utils/text_util.dart';
import '../../../utils/extensions.dart';
import '../ico_constants.dart';
import '../model/ico_phase.dart';
import '../model/ico_settings.dart';
import 'ico_controller.dart';
import 'ico_dashboard/ico_dashboard_screen.dart';
import 'ico_launch_token/ico_launch_token_screen.dart';
import 'ico_phase_list_page.dart';
import 'ico_widgets.dart';

class ICOScreen extends StatefulWidget {
  const ICOScreen({super.key});

  @override
  State<ICOScreen> createState() => _ICOScreenState();
}

class _ICOScreenState extends State<ICOScreen> {
  final _controller = Get.put(IcoController());
  RxString appName = ''.obs;

  @override
  void initState() {
    super.initState();
    _getTextAppName();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getIcoLaunchpadSettings(() => setState(() {}));
      _controller.getIcoPhaseActiveList(IcoPhaseSortType.featured);
      _controller.getIcoPhaseActiveList(IcoPhaseSortType.recent);
      _controller.getIcoPhaseActiveList(IcoPhaseSortType.future);
    });

  }

  @override
  Widget build(BuildContext context) {
    final lPad = _controller.launchpad;
    return Scaffold(
      appBar: appBarBackWithActions(title: "ICO".tr),
      body: SafeArea(
          child: _controller.isDataLoading
              ? showLoading()
              : ListView(
            shrinkWrap: true,
            children: [
              Obx(() => IcoHomeFirstSectionView(launchpad: lPad, appName: appName.value)),
              vSpacer15(),
              AllTotalView(lPad: lPad),
              vSpacer15(),
              IcoHomeSecondSectionView(launchpad: lPad),
              Obx(() => _listView(_controller.featuredList, "Featured Items".tr, IcoPhaseSortType.featured)),
              Obx(() => _listView(_controller.ongoingList, "Ongoing List".tr, IcoPhaseSortType.recent, isAll: true)),
              Obx(() => _listView(_controller.futureList, "Future Items".tr, IcoPhaseSortType.future)),
              vSpacer15(),
              if (lPad.featureList.isValid)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                    child: TextRobotoAutoBold(lPad.launchpadWhyChooseUsText ?? "")),
              if (lPad.featureList.isValid)
                for (final wcu in lPad.featureList!) FeaturedItemView(feature: wcu)
            ],
          )),
    );
  }

  Widget _listView(List<IcoPhase> list, String title, int type, {bool? isAll}) {
    return list.isValid
        ? Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vSpacer15(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextRobotoAutoBold(title),
            if (isAll == true)
              buttonTextBordered("View All".tr, false,
                  visualDensity: minimumVisualDensity, onPress: () => Get.to(() => ICOPhaseListPage(type: type)))
          ]),
          vSpacer5(),
          for (final phase in list) IcoPhaseItemView(phase: phase)
        ],
      ),
    )
        : vSpacer0();
  }

  Future<void> _getTextAppName() async => appName.value = await getAppName();
}

class IcoHomeFirstSectionView extends StatelessWidget {
  const IcoHomeFirstSectionView({super.key, required this.launchpad, required this.appName});

  final IcoLaunchpad launchpad;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(
          color: context.theme.dialogTheme.backgroundColor),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextRobotoAutoBold(launchpad.launchpadFirstTitle ?? "$appName ${"Token Launch Platform".tr}", fontSize: Dimens.fontSizeLarge, maxLines: 3),
            vSpacer5(),
            TextRobotoAutoNormal(launchpad.launchpadFirstDescription ?? "${"Buy Or Earn New Tokens Directly On".tr} $appName", maxLines: 50),
            vSpacer10(),
            buttonTextBordered("Launchpad Dashboard".tr, true,
                onPress: () => checkLoggedInStatus(context, () => Get.to(() => const ICODashboardScreen()))),
          ],
        ));
  }
}

class AllTotalView extends StatelessWidget {
  const AllTotalView({super.key, required this.lPad});

  final IcoLaunchpad lPad;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TotalView(value: lPad.currentFundsLocked, title: "Total Supplied Token".tr, icon: Icons.monetization_on_outlined)),
            hSpacer10(),
            Expanded(child: TotalView(value: lPad.totalFundsRaised, title: "Total Sold Raised".tr, icon: Icons.shopping_cart_checkout_outlined)),
          ],
        ),
        vSpacer10(),
        Row(
          children: [
            Expanded(child: TotalView(value: lPad.projectLaunchpad, title: "Projects Launched".tr, icon: Icons.space_dashboard_outlined)),
            hSpacer10(),
            Expanded(child: TotalView(value: lPad.allTimeUniqueParticipants, title: "Total Participants".tr, icon: Icons.people_outline)),
          ],
        ),
      ],
    );
  }
}

class IcoHomeSecondSectionView extends StatelessWidget {
  const IcoHomeSecondSectionView({super.key, required this.launchpad});

  final IcoLaunchpad launchpad;

  @override
  Widget build(BuildContext context) {
    final image = launchpad.launchpadMainImage;
    return Container(
      decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRobotoAutoBold(launchpad.launchpadSecondTitle ?? "Apply to launch your own token".tr, maxLines: 3),
                      vSpacer5(),
                      buttonText("Apply To Launch Token".tr,
                          visualDensity: VisualDensity.compact,
                          onPress: () => checkLoggedInStatus(context, () => Get.to(() => const IcoLaunchTokenScreen()))),
                    ],
                  )),
              if (image.isValid) showImageNetwork(imagePath: image, width: context.width / 4, boxFit: BoxFit.scaleDown, bgColor: Colors.transparent)
              else showImageAsset(imagePath: AssetConstants.imgIcoMiddle,width: context.width / 4, boxFit: BoxFit.scaleDown)
            ],
          ),
          vSpacer5(),
          TextRobotoAutoNormal(launchpad.launchpadSecondDescription ?? "ico_default_description_middle".tr, maxLines: 50),
        ],
      ),
    );
  }
}

class FeaturedItemView extends StatelessWidget {
  const FeaturedItemView({super.key, required this.feature});

  final IcoFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: boxDecorationRoundCorner(),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin, horizontal: Dimens.paddingMid),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          showImageNetwork(imagePath: feature.image, width: Dimens.iconSizeLargeExtra, height: Dimens.iconSizeLargeExtra, boxFit: BoxFit.cover),
          hSpacer10(),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TextRobotoAutoBold(feature.title ?? "", maxLines: 2), TextRobotoAutoNormal(feature.description ?? "", maxLines: 10)]),
          )
        ]));
  }
}

