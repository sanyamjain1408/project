import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../data/local/constants.dart';
import '../../data/models/currency.dart';
import '../../utils/dimens.dart';
import '../../utils/spacers.dart';

class CurrencyItemView extends StatelessWidget {
  const CurrencyItemView(this.currency, {super.key, this.padding = Dimens.paddingMid, this.hideName = false});

  final Currency currency;
  final double padding;
  final bool hideName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: currency.coinType == DefaultValue.all
          ? TextRobotoAutoNormal("All".tr, color: Theme.of(context).primaryColor)
          : Row(
        children: [
          CurrencyIconView(currency: currency),
          hSpacer10(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextRobotoAutoBold(currency.coinType ?? ""),
              if (!hideName) TextRobotoAutoNormal(currency.name ?? ""),
            ],)

        ],
      ),
    );
  }
}

class CurrencyIconView extends StatelessWidget {
  const CurrencyIconView({super.key, this.currency, this.size});

  final Currency? currency;
  final double? size;


  @override
  Widget build(BuildContext context) {
    final sizeL = size ?? 40;
    return ClipOval(
        child: Container(
            alignment: Alignment.center,
            width: sizeL,
            height: sizeL,
            color: Theme.of(context).focusColor.withValues(alpha: 0.2),
            child: _imageView(context)));
  }

  Widget _imageView(BuildContext context){
    final iconPath = currency?.coinIcon ?? '';
    if (iconPath.isNotEmpty) {
      return iconPath.contains(".svg")
          ? SvgPicture.network(iconPath, fit: BoxFit.fill)
          : Image.network(iconPath, fit: BoxFit.fill);
    }else {
      String symbol = currency?.coinType ?? '';
      if(symbol.length > 4) symbol = symbol.substring(0, 4);

      if(symbol.isNotEmpty){
        return Padding(
          padding: const EdgeInsets.all(3),
          child: TextRobotoAutoNormal(symbol, fontSize: Dimens.fontSizeMin),
        );
      }else {
        return Image.asset(AssetConstants.icLogo, fit: BoxFit.cover);
      }
    }
  }
}