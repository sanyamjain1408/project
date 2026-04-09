import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/gift_card.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/gift_cards/gift_cards_widgets.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

import '../faq/faq_page.dart';

class GiftCardsFAQScreen extends StatelessWidget {
  const GiftCardsFAQScreen({super.key, required this.gcData});

  final GiftCardsData gcData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Gift Card Info".tr),
      body: SafeArea(
        child: Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Dimens.paddingMid),
            children: [
              GiftCardTitleView(image: gcData.secondBanner, title: gcData.secondHeader, subTitle: gcData.secondDescription),
              FAQRelatedView(gcData.faq ?? []),
            ],
          ),
        ),
      ),
    );
  }
}
