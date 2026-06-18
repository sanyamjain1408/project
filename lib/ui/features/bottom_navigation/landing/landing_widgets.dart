import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/local/constants.dart';
import '../../../../data/models/blog_news.dart';
import '../../../../data/models/settings.dart';
import '../../../../helper/app_helper.dart';
import '../../../../ui/features/notifications/notifications_page.dart';
import '../../../../ui/features/root/root_controller.dart';
import '../../../../utils/alert_util.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/date_util.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';
import '../../../../utils/web_view.dart';
import '../../../../ui/features/side_navigation/blog/blog_details_view.dart';
import '../../../../ui/features/bottom_navigation/landing/live_chat_screen.dart';
import '../../../../ui/features/auth/sign_in/sign_in_screen.dart';

const _bg        = Color(0xFF0A0B0D);
const _card      = Color(0xFF111318);
const _green     = Color(0xFFB5F000);
const _border    = Color(0xFF1E2128);
const _textDim   = Color(0xFF6B7280);
const _textMid   = Color(0xFFB0B8C1);

class AppBarHomeView extends StatelessWidget implements PreferredSizeWidget {
  const AppBarHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: kToolbarHeight,

      // ── LEFT: icon.png → drawer ──
      leading: GestureDetector(
        onTap: () => Scaffold.of(context).openDrawer(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/icon.png',
            width: 30,
            height: 30,
            errorBuilder: (ctx, err, st) =>
                const Icon(Icons.widgets, color: Colors.white, size: 26),
          ),
        ),
      ),

      // ── CENTER: nothing ──
      title: const SizedBox.shrink(),
      centerTitle: true,

      // ── RIGHT: headphone + bell ──
      actions: [
        // Headphone → LiveChat (always visible)
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LiveChatScreen()),
          ),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Image.asset(
              'assets/icons/help.png',
              width: 22,
              height: 22,
              errorBuilder: (ctx, err, st) =>
                  const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 22),
            ),
          ),
        ),

        // Bell → notifications (login check)
        GestureDetector(
          onTap: () {
            if (gUserRx.value.id > 0) {
              Get.to(() => const NotificationsPage());
            } else {
              Get.offAll(() => const SignInPage());
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/notification.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (ctx, err, st) =>
                      const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 22),
                ),
                Obx(() {
                  final count = Get.find<RootController>().notificationCount.value;
                  if (count <= 0) return const SizedBox();
                  return Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 16,
                      width: 16,
                      child: AutoSizeText(
                        count.toString(),
                        minFontSize: 5,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class LandingTopView extends StatelessWidget {
  const LandingTopView({super.key, this.lData});

  final LandingData? lData;

  @override
  Widget build(BuildContext context) {
    if (lData != null && lData!.landingFirstSectionStatus == 1) {
      return Padding(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            vSpacer10(),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.radiusCorner),
                  child: showImageNetwork(
                    imagePath: lData?.landingBannerImage,
                    width: Dimens.iconSizeLargeExtra,
                    height: Dimens.iconSizeLargeExtra,
                    boxFit: BoxFit.contain,
                  ),
                ),
                hSpacer10(),
                Expanded(child: TextRobotoAutoBold(lData?.landingTitle ?? "", maxLines: 3)),
              ],
            ),
            if (lData!.landingDescription.isValid) vSpacer5(),
            if (lData!.landingDescription.isValid) TextRobotoAutoNormal(lData?.landingDescription ?? "", maxLines: 15),
            vSpacer10(),
          ],
        ),
      );
    } else {
      return vSpacer0();
    }
  }
}

double exploreItemWidth = 0;

class ExploreItemView extends StatelessWidget {
  const ExploreItemView({super.key, required this.title, required this.icon, required this.onTap, this.maxLine});

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? maxLine;

  @override
  Widget build(BuildContext context) {
    if (exploreItemWidth == 0) {
      exploreItemWidth = (context.width - 40) / 4;
      exploreItemWidth = exploreItemWidth - 10;
    }
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: exploreItemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: Dimens.iconSizeMid, color: context.theme.focusColor),
            vSpacer5(),
            TextRobotoAutoBold(
              title,
              maxLines: maxLine ?? 2,
              fontSize: Dimens.fontSizeMidExtra,
              color: context.theme.primaryColorLight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LatestBlogItemView extends StatelessWidget {
  const LatestBlogItemView({super.key, required this.blog});

  final Blog blog;

  @override
  Widget build(BuildContext context) {
    final imageSize = context.width / 4;
    return InkWell(
      onTap: () => showBottomSheetFullScreen(context, BlogDetailsView(blog: blog), title: "Blog Details".tr),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded( // <--- FIXED: 'Extent' se 'Expanded' kar diya gaya
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextRobotoAutoBold(blog.title ?? '', maxLines: 2),
                    vSpacer20(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextRobotoAutoNormal(blog.category ?? ''),
                        TextRobotoAutoNormal(formatDateForInbox(blog.publishAt)),
                      ],
                    ),
                  ],
                ),
              ),
              if (blog.thumbnail.isValid) hSpacer10(),
              if (blog.thumbnail.isValid)
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.radiusCorner),
                  child: showImageNetwork(
                    imagePath: blog.thumbnail,
                    width: imageSize,
                    height: imageSize - 20,
                    boxFit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          dividerHorizontal(height: Dimens.paddingLargeDouble),
        ],
      ),
    );
  }
}

class ExploreItemViewLarge extends StatelessWidget {
  const ExploreItemViewLarge({
    super.key,
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subTitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            hSpacer10(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TextRobotoAutoBold(title, maxLines: 1), TextRobotoAutoNormal(subTitle, maxLines: 2)],
              ),
            ),
            showImageAsset(icon: icon, iconSize: Dimens.iconSizeLarge, color: context.theme.primaryColor),
          ],
        ),
      ),
    );
  }
}

class LatestFeatureItemView extends StatelessWidget {
  const LatestFeatureItemView({super.key, required this.feature});

  final LandingFeature feature;

  @override
  Widget build(BuildContext context) {
    final cSize = (context.width - 50) / 2;
    return InkWell(
      onTap: () {
        if (feature.featureUrl.isValid) Get.to(() => WebViewPage(url: feature.featureUrl!));
      },
      child: Container(
        decoration: boxDecorationRoundBorder(),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        width: cSize,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radiusCornerSmall),
              child: showImageNetwork(
                imagePath: feature.featureIcon,
                height: Dimens.iconSizeLarge,
                width: Dimens.iconSizeLarge,
                boxFit: BoxFit.cover,
              ),
            ),
            TextRobotoAutoBold(feature.featureTitle ?? '', maxLines: 1),
            TextRobotoAutoNormal(feature.description ?? '', maxLines: 3, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}