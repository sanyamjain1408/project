import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'colors.dart';

class Themes {
  static final light = ThemeData.light().copyWith(
    textTheme: lightTextTheme,
    colorScheme: ThemeData.light().colorScheme.copyWith( primary: const Color(0xFFCCFF00),),
    primaryColor: darkBG,
    primaryColorLight: lightTextSecondary,
    scaffoldBackgroundColor: lightBG,
    secondaryHeaderColor: lightSecondaryBG,
    dialogTheme: const DialogThemeData(backgroundColor: lightBGDark),
    dividerColor: lightDivider,
    focusColor: focus,
    iconTheme: const IconThemeData(color: darkBG, size: Dimens.iconSizeMin),
  );

  static final lightTextTheme = TextTheme(
    labelMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: darkBG, fontSize: Dimens.fontSizeMid),
    displaySmall: GoogleFonts.roboto(fontWeight: FontWeight.normal, color: lightTextSecondary, fontSize: Dimens.fontSizeMidExtra),
  );

  static final dark = ThemeData.dark().copyWith(
    textTheme: darkTextTheme,
    colorScheme: ThemeData.light().colorScheme.copyWith(primary: const Color(0xFFCCFF00) ),
    primaryColor: darkTextPrimary,
    primaryColorLight: darkTextSecondary,
    scaffoldBackgroundColor: darkBG,
    secondaryHeaderColor: darkSecondaryBG,
    dialogTheme: const DialogThemeData(backgroundColor: darkBGLight),
    dividerColor: darkDivider,
    focusColor: focus,

    iconTheme: const IconThemeData(color: darkTextPrimary, size: Dimens.iconSizeMid),
  );

  static final darkTextTheme = TextTheme(
    labelMedium: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: darkTextPrimary, fontSize: Dimens.fontSizeMid),
    displaySmall: GoogleFonts.roboto(fontWeight: FontWeight.normal, color: darkTextSecondary, fontSize: Dimens.fontSizeMidExtra),
  );
}

/// *** NOTE: get the view main colors by context (like background) *** ///
class ThemeService {
  ThemeMode get theme => loadThemeFromBox() ? ThemeMode.dark : ThemeMode.light;

  bool loadThemeFromBox() => GetStorage().read(PreferenceKey.isDark) ?? false;

  void _saveThemeToBox(bool isDarkMode) => GetStorage().write(PreferenceKey.isDark, isDarkMode);

  Brightness getBrightness() => loadThemeFromBox() ? Brightness.light : Brightness.dark;

  void switchTheme() {
    var isDark = loadThemeFromBox();
    gIsDarkMode = !gIsDarkMode;
    Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
    _saveThemeToBox(!isDark);
  }
}
