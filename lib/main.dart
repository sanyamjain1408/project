import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/helper/data_process_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';
import 'package:tradexpro_flutter/utils/network_util.dart';
import 'package:tradexpro_flutter/utils/theme.dart';
import 'data/local/constants.dart';
import 'data/local/strings.dart';
import 'data/models/settings.dart';
import 'data/remote/api_provider.dart';
import 'data/remote/http_api_provider.dart';
import 'helper/app_helper.dart';
import 'ui/features/on_boarding/on_boarding_screen.dart';
import 'ui/features/root/root_screen.dart';
import 'ui/ui_helper/maintains_mood_widgets.dart';


void main() async {
  await dotenv.load(fileName: EnvKeyValue.kEnvFile);
  await GetStorage.init();
  await _setDefaultValues();
  WidgetsFlutterBinding.ensureInitialized();
  gIsDarkMode = ThemeService().loadThemeFromBox();
  Get.put(APIProvider());
  Get.put(SocketProvider());
  initBuySellColor();
  getCommonSettings();
}

Future<void> _setDefaultValues() async {
  GetStorage().writeIfNull(PreferenceKey.isDark, systemThemIsDark());
  GetStorage().writeIfNull(PreferenceKey.isLoggedIn, false);
  GetStorage().writeIfNull(PreferenceKey.isOnBoardingDone, false);
  GetStorage().writeIfNull(PreferenceKey.languageKey, LanguageUtil.defaultLangKey);
  GetStorage().writeIfNull(PreferenceKey.buySellColorIndex, 0);
  GetStorage().writeIfNull(PreferenceKey.buySellUpDown, 0);
}

Future<void> getCommonSettings() async {
  gUserAgent = await getUserAgent();
  final isOnline = await NetworkCheck.isOnline();
  if (isOnline) {
    final resp = await HttpAPIProvider().getRequest(
        APIURLConstants.baseUrl, APIURLConstants.getCommonSettingsWithLanding, isDynamic: true);
    if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
      Maintenance? maintenance = DataProcessHelper.checkMaintenanceMood(resp.data);
      if (maintenance == null) DataProcessHelper.commonSettingsProcess(resp.data);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) =>
          runApp(MyApp(maintenance: maintenance)));
    }
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key, this.maintenance});
  final Maintenance? maintenance;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: ThemeService().getBrightness()));
    final isOnBoarding = GetStorage().read(PreferenceKey.isOnBoardingDone);
    final screen = maintenance != null ? MaintainsMoodOnScreen(maintenance: maintenance!)
        : (isOnBoarding ? const RootScreen() : const OnBoardingScreen());

    return Directionality(
      textDirection: LanguageUtil.getTextDirection(),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        defaultTransition: Transition.rightToLeftWithFade,
        theme: Themes.light,
        darkTheme: Themes.dark,
        themeMode: ThemeService().theme,
        translations: Strings(),
        locale: LanguageUtil.getCurrentLocal(),
        fallbackLocale: LanguageUtil.locales.first.local,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          CountryLocalizations.delegate,
        ],
        initialRoute: "/",
        builder: (context, child) {
          final scale = MediaQuery.of(context).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.3);
          return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scale), child: child!);
        },
        home: screen,
      ),
    );
  }
}
