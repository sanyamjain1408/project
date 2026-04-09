import 'package:get_storage/get_storage.dart';

import '../data/local/api_constants.dart';
import '../data/local/constants.dart';
import '../data/models/settings.dart';
import '../utils/common_utils.dart';

class DataProcessHelper {
  static Maintenance? checkMaintenanceMood(Map<String, dynamic> data) {
    final isMaintenance = data[APIKeyConstants.maintenance] as int? ?? 0;
    if (isMaintenance == 1) {
      showToast(data[APIKeyConstants.message]);
      return Maintenance.fromJson(data[APIKeyConstants.data]);
    }
    return null;
  }

  static void commonSettingsProcess(Map<String, dynamic> data, {Function(LandingData? landingSettings)? onSettings}) {
    final settings = data[APIKeyConstants.commonSettings];
    if (settings != null && settings is Map<String, dynamic>) {
      GetStorage().write(PreferenceKey.settingsObject, settings);
    }
    LandingData? landingData;
    final landing = data[APIKeyConstants.landingSettings];
    if (landing != null && landing is Map<String, dynamic>) {
      final media = landing["media_list"];
      if (media != null && media is List) GetStorage().write(PreferenceKey.mediaList, media);
      landingData = LandingData.fromJson(landing);
    }
    if (onSettings != null) onSettings(landingData);
  }
}
