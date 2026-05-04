import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/faq.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'faq_controller.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  FAQPageState createState() => FAQPageState();
}

class FAQPageState extends State<FAQPage> {
  final FAQController _controller = Get.put(FAQController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getFAQList(false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarBackWithActions(title: "FAQ".tr),
        body: Obx(() {
          return _controller.faqList.isEmpty
              ? handleEmptyViewWithLoading(_controller.isLoading)
              : ListView.builder(
            shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemCount: _controller.faqList.length,
                itemBuilder: (BuildContext context, int index) {
                  if (_controller.hasMoreData && index == (_controller.faqList.length - 1)) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getFAQList(true));
                  }
                  return FAQItemView(faq: _controller.faqList[index]);
                },
              );
        }));
  }
}

class FAQRelatedView extends StatelessWidget {
  const FAQRelatedView(this.faqList, {super.key});

  final List<FAQ> faqList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vSpacer20(),
        Text("FAQ".tr, 
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: "DMSans",
          height: 24/16
        ),),
        vSpacer10(),
        if (faqList.isEmpty)
          showEmptyView(message: "Related FAQ not found".tr)
        else
          for (final faq in faqList) FAQItemView(faq: faq, margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin))
      ],
    );
  }
}

class FAQItemView extends StatelessWidget {
  const FAQItemView({super.key, required this.faq, this.margin});

  final FAQ faq;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
      child: Theme(
        data: context.theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: TextRobotoAutoBold(faq.question ?? "", maxLines: 10),
          backgroundColor: Colors.transparent,
          collapsedIconColor: context.theme.primaryColor,
          iconColor: context.theme.primaryColor,
          children: <Widget>[
            dividerHorizontal(height: 1),
            Padding(
              padding: const EdgeInsets.all(Dimens.paddingMid),
              child: Text(faq.answer ?? "", style: context.textTheme.displaySmall?.copyWith(fontSize: Dimens.fontSizeMid)),
            )
          ],
        ),
      ),
    );
  }
}
