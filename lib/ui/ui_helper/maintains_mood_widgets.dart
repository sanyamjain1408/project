import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/helper/data_process_helper.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../data/local/api_constants.dart';
import '../../data/models/settings.dart';
import '../../data/remote/http_api_provider.dart';
import '../features/root/root_screen.dart';


class MaintainsMoodOnScreen extends StatelessWidget {
  const MaintainsMoodOnScreen({super.key, required this.maintenance});
  final Maintenance maintenance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(Dimens.paddingLarge),
            shrinkWrap: true,
            children: [
              showImageNetwork(imagePath: maintenance.maintenanceModeImg, boxFit: BoxFit.contain, bgColor: Colors.transparent),
              vSpacer20(),
              TextRobotoAutoBold(
                maintenance.maintenanceModeTitle ?? "Exchange is unavailable due to maintenance".tr,
                maxLines: 3,
                textAlign: TextAlign.center,
              ),
              vSpacer10(),
              TextRobotoAutoNormal(
                maintenance.maintenanceModeText ?? "maintenance_mood_message".tr,
                maxLines: 10,
                textAlign: TextAlign.center,
              ),
              vSpacer30(),
              buttonRoundedMain(text: "Check Again".tr, onPress: () => _checkAgainAction(context)),
              vSpacer30(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAgainAction(BuildContext context) async {
    showLoadingDialog();
    final resp = await HttpAPIProvider().getRequest(
        APIURLConstants.baseUrl, APIURLConstants.getCommonSettingsWithLanding, isDynamic: true);
    hideLoadingDialog();
    if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
      Maintenance? maintenance = DataProcessHelper.checkMaintenanceMood(resp.data);
      if (maintenance == null) {
        DataProcessHelper.commonSettingsProcess(resp.data);
        Get.offAll(()=> RootScreen());
      }else {
        showToast(maintenance.maintenanceModeTitle ?? "Exchange is unavailable due to maintenance".tr);
      }

    }
  }

}
