import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/blog_news.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/web_view.dart';
import 'news_controller.dart';
import 'news_screen.dart';

class NewsDetailsView extends StatefulWidget {
  const NewsDetailsView({super.key, required this.news});

  final News news;

  @override
  NewsDetailsViewState createState() => NewsDetailsViewState();
}

class NewsDetailsViewState extends State<NewsDetailsView> {
  final _controller = Get.find<NewsController>();
  Rx<NewsDetails> newsDetails = NewsDetails().obs;
  bool isLoading = true;

  @override
  void initState() {
    newsDetails.value.details = widget.news;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getNewsDetailsData(widget.news.slug ?? "", (details) {
        isLoading = false;
        if (details != null) newsDetails.value = details;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final news = newsDetails.value.details;
      List<News> relatedList = [];
      if (newsDetails.value.related?.data != null) {
        relatedList = List<News>.from(newsDetails.value.related!.data.map((x) => News.fromJson(x)));
      }
      return Expanded(
        child: ListView(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          children: [
            showImageNetwork(imagePath: news?.thumbnail, width: context.width - 20, boxFit: BoxFit.fitWidth),
            vSpacer10(),
            TextRobotoAutoBold(news?.title ?? "", fontSize: Dimens.fontSizeLarge, maxLines: 10),
            vSpacer5(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextRobotoAutoNormal(formatDate(news?.publishAt, format: dateTimeFormatDdMMMMYyyyHhMm)),
                buttonTextBordered("Share".tr, true,
                    visualDensity: minimumVisualDensity, onPress: () => shareText(URLConstants.blogShare + (news?.slug ?? "")))
              ],
            ),
            vSpacer20(),
            isLoading ? showLoadingSmall() : HtmlTextView(htmlText: news?.body ?? ""),
            vSpacer10(),
            if (relatedList.isNotEmpty) Align(alignment: Alignment.centerLeft, child: TextRobotoAutoBold("More News".tr)),
            if (relatedList.isNotEmpty) Column(children: List.generate(relatedList.length, (index) => NewsItemView(news: relatedList[index]))),
          ],
        ),
      );
    });
  }
}
