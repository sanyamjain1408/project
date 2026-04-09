import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/blog_news.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/blog/blog_details_view.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'blog_controller.dart';
import 'blog_search_view.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  BlogScreenState createState() => BlogScreenState();
}

class BlogScreenState extends State<BlogScreen> {
  final _controller = Get.put(BlogController());
  late TextScaler textScaler;

  @override
  void initState() {
    super.initState();
    _controller.selectedCategory.value = -1;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getBlogSettings();
      _controller.getBlogListType(BlogNewsType.feature);
      _controller.getBlogCategories();
      _controller.getBlogListType(BlogNewsType.recent);
    });
  }

  @override
  Widget build(BuildContext context) {
    textScaler = MediaQuery.of(context).textScaler;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () {
                final actionList = _controller.blogSettings.value.blogSearchEnable == "1" ? [Icons.search] : <IconData>[];
                return appBarBackWithActions(
                    title: "Blog".tr,
                    actionIcons: actionList,
                    onPress: (index) => showBottomSheetFullScreen(context, const BlogSearchView(), title: "Search Your Blog".tr));
              },
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  Obx(() => _getBlogHeaderView(_controller.blogSettings.value)),
                  Obx(() => _getBlogFeatureView(_controller.blogSettings.value, _controller.featureBlogList)),
                  Obx(() => _getBlogCategoryView(_controller.blogCategories, _controller.selectedCategory.value)),
                  Obx(() {
                    return _controller.blogList.isEmpty
                        ? SliverFillRemaining(child: handleEmptyViewWithLoading(_controller.isLoading.value))
                        : SliverPadding(
                            padding: const EdgeInsets.all(Dimens.paddingMid),
                            sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                              childCount: _controller.blogList.length,
                              (context, index) {
                                if (_controller.selectedCategory.value != -1 &&
                                    _controller.hasMoreData &&
                                    index == (_controller.blogList.length - 1)) {
                                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getBlogListByCategory(true));
                                }
                                return BlogItemView(blog: _controller.blogList[index]);
                              },
                            )));
                  })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _getBlogHeaderView(BlogNewsSettings settings) {
    if (settings.blogFeatureHeading.isValid || settings.blogFeatureDescription.isValid) {
      final width = context.width - 20;
      final titleSize = getTextSize(settings.blogFeatureHeading ?? "", context.textTheme.labelMedium!.copyWith(fontSize: Dimens.titleFontSizeSmall),
          maxLine: 3, width: width, scale: textScaler);
      final subSize =
          getTextSize(settings.blogFeatureDescription ?? "", context.textTheme.displaySmall!, maxLine: 10, width: width, scale: textScaler);
      double height = titleSize.height + subSize.height + 20;
      return SliverAppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: height,
        flexibleSpace: Padding(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(settings.blogFeatureHeading ?? "",
                textAlign: TextAlign.start, style: context.textTheme.labelMedium!.copyWith(fontSize: Dimens.fontSizeMid), maxLines: 3),
            vSpacer5(),
            Text(settings.blogFeatureDescription ?? "", textAlign: TextAlign.start, maxLines: 10, style: context.textTheme.displaySmall)
          ]),
        ),
      );
    } else {
      return const SliverAppBar(backgroundColor: Colors.transparent, automaticallyImplyLeading: false, toolbarHeight: 0);
    }
  }

  SliverAppBar _getBlogFeatureView(BlogNewsSettings settings, List<Blog> fList) {
    if (settings.blogFeatureEnable == "1" && fList.isValid) {
      final height = context.width * 0.75;
      return SliverAppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: height,
        flexibleSpace: CarouselSlider.builder(
            itemCount: fList.length,
            itemBuilder: (context, index, realIndex) => BlogSliderView(blog: fList[index]),
            options: CarouselOptions(height: height, viewportFraction: 1, autoPlay: true, autoPlayInterval: const Duration(seconds: 3))),
      );
    } else {
      return const SliverAppBar(backgroundColor: Colors.transparent, automaticallyImplyLeading: false, toolbarHeight: 0);
    }
  }

  SliverAppBar _getBlogCategoryView(List<BNCategoryWithSub> cList, int selected) {
    if (cList.isValid) {
      return SliverAppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 50,
        pinned: true,
        flexibleSpace: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid, horizontal: Dimens.paddingMin),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final category = cList[index];
            final bgColor = selected == index ? context.theme.focusColor.withValues(alpha:0.5) : Colors.transparent;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMin),
              child: buttonText(category.title ?? "", bgColor: bgColor, textColor: context.theme.primaryColor, fontSize: Dimens.fontSizeMid,
                  onPress: () {
                _controller.selectedCategory.value = index;
                _controller.getBlogListByCategory(false);
              }),
            );
          },
          itemCount: cList.length,
        ),
      );
    } else {
      return const SliverAppBar(backgroundColor: Colors.transparent, automaticallyImplyLeading: false, toolbarHeight: 0);
    }
  }
}

class BlogItemView extends StatelessWidget {
  const BlogItemView({super.key, required this.blog});

  final Blog blog;

  @override
  Widget build(BuildContext context) {
    final width = (context.width - 20) / 3;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showBottomSheetFullScreen(context, BlogDetailsView(blog: blog), title: "Blog Details".tr),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.radiusCorner),
                  child: showImageNetwork(imagePath: blog.thumbnail, width: width, height: width, boxFit: BoxFit.cover)),
              hSpacer5(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextRobotoAutoBold(blog.title ?? "", maxLines: 3),
                    vSpacer5(),
                    TextRobotoAutoNormal(blog.description ?? "", maxLines: 3),
                    vSpacer5(),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextRobotoAutoNormal(formatDate(blog.publishAt, format: dateFormatMMMMDddYyy), color: context.theme.primaryColor)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BlogSliderView extends StatelessWidget {
  const BlogSliderView({super.key, required this.blog});

  final Blog blog;

  @override
  Widget build(BuildContext context) {
    final height = context.width * 0.45;
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showBottomSheetFullScreen(context, BlogDetailsView(blog: blog), title: "Blog Details".tr),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showImageNetwork(imagePath: blog.thumbnail, width: context.width - 20, height: height, boxFit: BoxFit.cover),
              vSpacer5(),
              TextRobotoAutoBold(blog.title ?? "", fontSize: Dimens.fontSizeLarge, maxLines: 2),
              vSpacer5(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                hSpacer5(),
                TextRobotoAutoNormal(formatDate(blog.publishAt, format: dateTimeFormatDdMMMMYyyyHhMm), textAlign: TextAlign.end)
              ])
            ],
          ),
        ),
      ),
    );
  }
}
