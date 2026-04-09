import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/blog_news.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/blog/blog_screen.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/web_view.dart';
import 'blog_controller.dart';

class BlogDetailsView extends StatefulWidget {
  const BlogDetailsView({super.key, required this.blog});

  final Blog blog;

  @override
  BlogDetailsViewState createState() => BlogDetailsViewState();
}

class BlogDetailsViewState extends State<BlogDetailsView> {
  final _controller = Get.isRegistered<BlogController>() ? Get.find<BlogController>() : Get.put(BlogController());
  Rx<BlogDetails> blogDetails = BlogDetails().obs;
  bool isLoading = true;

  @override
  void initState() {
    blogDetails.value.details = widget.blog;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getBlogDetailsData(widget.blog.slug ?? "", (details) {
        isLoading = false;
        if (details != null) blogDetails.value = details;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final blog = blogDetails.value.details;
      List<Blog> relatedList = [];
      if (blogDetails.value.related?.data != null) {
        relatedList = List<Blog>.from(blogDetails.value.related!.data.map((x) => Blog.fromJson(x)));
      }
      return Expanded(
        child: ListView(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          children: [
            showImageNetwork(imagePath: blog?.thumbnail, width: context.width - 20, boxFit: BoxFit.fitWidth),
            vSpacer10(),
            TextRobotoAutoBold(blog?.title ?? "", fontSize: Dimens.fontSizeLarge, maxLines: 3),
            vSpacer5(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextRobotoAutoNormal(formatDate(blog?.publishAt, format: dateTimeFormatDdMMMMYyyyHhMm)),
                buttonTextBordered("Share".tr, true,
                    visualDensity: minimumVisualDensity, onPress: () => shareText(URLConstants.blogShare + (blog?.slug ?? "")))
              ],
            ),
            vSpacer20(),
            isLoading ? showLoadingSmall() : HtmlTextView(htmlText: blog?.body ?? ""),
            vSpacer10(),
            TextRobotoAutoNormal("${"Updated At".tr}: ${formatDate(blog?.updatedAt, format: dateTimeFormatDdMMMMYyyyHhMm)}",
                textAlign: TextAlign.end),
            vSpacer10(),
            if (relatedList.isNotEmpty) Align(alignment: Alignment.centerLeft, child: TextRobotoAutoBold("More Blog".tr)),
            if (relatedList.isNotEmpty) Column(children: List.generate(relatedList.length, (index) => BlogItemView(blog: relatedList[index]))),
          ],
        ),
      );
    });
  }
}
