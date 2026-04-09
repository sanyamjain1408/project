import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';

class FavoriteHelper {
  static List<CoinPair> getFavoriteList(String fromKey) {
    final objMap = GetStorage().read(fromKey == FromKey.future ? PreferenceKey.favoritesFuture : PreferenceKey.favoritesSpot);
    List<CoinPair> favList = <CoinPair>[];
    if (objMap != null) {
      try {
        if (objMap is List<CoinPair>) {
          favList = objMap as List<CoinPair>? ?? [];
        } else if (objMap is List<dynamic>) {
          favList = List<CoinPair>.from(objMap.map((element) => CoinPair.fromJson(element)));
        }
      } catch (error) {
        printFunction("updateFavorite error", "$error");
      }
    }
    return favList;
  }

  static void updateFavorite(CoinPair pair, String fromKey, Function(CoinPair) onUpdate) {
    List<CoinPair> favList = getFavoriteList(fromKey);
    if (pair.isFavorite == 1) {
      pair.isFavorite = 0;
      favList.remove(pair);
    } else {
      pair.isFavorite = 1;
      favList.add(pair);
    }
    writeFavList(fromKey, favList);
    onUpdate(pair);
  }

  static void checkFavorite(CoinPair pair, String fromKey, Function(CoinPair) onUpdate) {
    List<CoinPair> favList = getFavoriteList(fromKey);
    final hasPair = favList.indexWhere((element) => element.coinPair == pair.coinPair);
    if (hasPair != -1) {
      pair.isFavorite = 1;
      favList[hasPair] = pair;
      writeFavList(fromKey, favList);
    } else {
      pair.isFavorite = 0;
    }
    onUpdate(pair);
  }

  static void writeFavList(String fromKey, List<CoinPair> favList) {
    final key = fromKey == FromKey.future ? PreferenceKey.favoritesFuture : PreferenceKey.favoritesSpot;
    GetStorage().write(key, favList);
  }

  static Widget getFavoriteIcon(CoinPair pair, VoidCallback onTap) {
    return buttonOnlyIcon(
        onPress: onTap,
        iconData: pair.isFavorite == 1 ? Icons.star : Icons.star_border,
        size: Dimens.iconSizeMin,
        visualDensity: minimumVisualDensity,
        iconColor: pair.isFavorite == 1 ? Get.theme.focusColor : Get.theme.primaryColor);
  }

  static Future<void> showFavoritePopup(BuildContext context, Offset offset, CoinPair pair, String? fromKey, Function(String?)? onFavChange) async {
    if (pair.isFavorite == null) checkFavorite(pair, fromKey ?? '', (newPair) => pair = newPair);
    final title = pair.isFavorite == 1 ? "Remove Favorite".tr : "Add Favorite".tr;
    final Size? size = Overlay.of(context).context.findRenderObject()?.paintBounds.size;
    if (size == null) return;
    showMenu(
      context: context,
      color: context.theme.primaryColor,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy, 0, 0),
        Rect.fromLTWH(0, 0, size.width, size.height),
      ), // Adjust position as needed
      items: [
        PopupMenuItem(
          value: pair.isFavorite,
          height: Dimens.btnHeightMin,
          child: Text(title, style: context.textTheme.labelMedium?.copyWith(color: context.theme.scaffoldBackgroundColor)),
        ),
      ],
    ).then((value) {
      if (value != null) {
        updateFavorite(pair, fromKey ?? "", (updatedPair) {
          pair = updatedPair;
          if (onFavChange != null) {
            final message = pair.isFavorite == 1 ? "Added to favorite successfully".tr : "Removed from favorite successfully".tr;
            onFavChange(message);
          }
        });
      }
    });
  }
}
