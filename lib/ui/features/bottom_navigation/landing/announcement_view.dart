import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';

import '../../../../data/models/settings.dart';
import '../../../../utils/alert_util.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/date_util.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';

class AnnouncementView extends StatelessWidget {
  const AnnouncementView({super.key, required this.announcementList});

  final List<Announcement> announcementList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
      child: CarouselSlider.builder(
        itemCount: announcementList.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
          final announcement = announcementList[itemIndex];
          return AnnouncementItemView(announcement: announcement);
        },
        options: CarouselOptions(
          scrollDirection: Axis.vertical,
          height: Dimens.btnHeightMid,
          viewportFraction: 1,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
        ),
      ),
    );
  }
}

class AnnouncementItemView extends StatelessWidget {
  const AnnouncementItemView({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showBottomSheetDynamic(context, AnnouncementDetailsView(announcement: announcement)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          showImageAsset(icon: Icons.campaign_outlined, iconSize: Dimens.iconSizeMid),
          hSpacer5(),
          Expanded(
            child: Text(
              announcement.title ?? "",
              style: context.textTheme.displaySmall?.copyWith(color: context.theme.primaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeBannerListView extends StatelessWidget {
  const HomeBannerListView({super.key, required this.bannerList, this.onTap});

  final List<Announcement> bannerList;
  final Function(Announcement)? onTap;

  @override
  Widget build(BuildContext context) {
    double height = context.width / 4;
    height = height + 30 + 50;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: CarouselSlider.builder(
        itemCount: bannerList.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
          return HomeBannerItemView(banner: bannerList[itemIndex], total: bannerList.length, current: itemIndex + 1);
        },
        options: CarouselOptions(
          viewportFraction: 1,
          height: height,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 10),
        ),
      ),
    );
  }
}

class HomeBannerItemView extends StatelessWidget {
  const HomeBannerItemView({super.key, required this.banner, required this.total, required this.current});

  final Announcement banner;
  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final imageSize = context.width / 4;
    // const text = "Experience the Future of Trading with Our Secure Exchange";
    final text = banner.title ?? '';
    final textList = text.split(" ").toList();

    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.symmetric(horizontal: Dimens.paddingMin),
      child: InkWell(
        onTap: () => showBottomSheetDynamic(context, AnnouncementDetailsView(announcement: banner)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textList.isEmpty
                    ? hSpacer10()
                    : Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: textList[0],
                            style: context.theme.textTheme.labelMedium?.copyWith(
                              fontSize: Dimens.titleFontSizeSmall,
                              color: context.theme.focusColor,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: text.substring(textList[0].length, text.length),
                                style: context.theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                          maxLines: 4,
                          textAlign: TextAlign.start,
                        ),
                      ),
                // ClipRRect(borderRadius: BorderRadius.circular(Dimens.radiusCorner), child: showCachedNetworkImage(banner.image ?? "", size: imageSize)),
                hSpacer5(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.radiusCorner),
                  child: showImageNetwork(
                    imagePath: banner.image ?? "",
                    width: imageSize,
                    height: imageSize,
                    boxFit: BoxFit.contain,
                    bgColor: Colors.transparent,
                  ),
                ),
              ],
            ),
            vSpacer10(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buttonOnlyIcon(
                  iconData: Icons.east,
                  visualDensity: VisualDensity.compact,
                  iconColor: context.theme.primaryColorLight,
                ),
                Container(
                  decoration: boxDecorationRoundBorder(radius: Dimens.radiusCornerLarge, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge, vertical: Dimens.paddingMin),
                  child: Text.rich(
                    TextSpan(
                      text: current.toString(),
                      style: Get.theme.textTheme.labelMedium!.copyWith(),
                      children: <TextSpan>[
                        TextSpan(
                          text: "/$total",
                          style: Get.theme.textTheme.labelMedium!.copyWith(color: context.theme.primaryColorLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementDetailsView extends StatelessWidget {
  const AnnouncementDetailsView({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final dateText =
        "${"Last revised".tr}: ${formatDate(announcement.updatedAt, format: dateTimeFormatDdMMMMYyyyHhMm)}";
    return Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        children: [
          vSpacer10(),
          TextRobotoAutoBold(announcement.title ?? "", maxLines: 5),
          vSpacer5(),
          TextRobotoAutoNormal(dateText),
          if (announcement.image.isValid)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
              child: showImageNetwork(
                imagePath: announcement.image,
                height: Get.width / 2,
                width: Get.width,
                boxFit: BoxFit.cover,
                padding: Dimens.paddingMin,
              ),
            ),
          vSpacer10(),
          Padding(
            padding: const EdgeInsets.all(Dimens.paddingMid),
            child: HtmlWidget(
              announcement.description ?? "",
              onLoadingBuilder: (context, element, loadingProgress) => showLoadingSmall(),
            ),
          ),
        ],
      ),
    );
  }
}
