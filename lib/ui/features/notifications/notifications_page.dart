import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/timeline_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'notifications_controller.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final _controller = Get.put(NotificationsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Notifications".tr),
      body: SafeArea(
        child: Obx(() => gUserRx.value.id == 0
            ? signInNeedView()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                      child: buttonTextBordered("Clear all".tr, true, visualDensity: minimumVisualDensity, onPress: () => clearAction())),
                  _timeLine()
                ],
              )),
      ),
    );
  }

  Widget _timeLine() {
    return Obx(() => _controller.notificationList.isEmpty
        ? handleEmptyViewWithLoading(_controller.isDataLoading.value, message: "empty_message_notifications_list".tr)
        : Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
              shrinkWrap: true,
              itemCount: _controller.notificationList.length,
              itemBuilder: (BuildContext context, int index) {
                final item = _controller.notificationList[index];
                return TimeLine().buildTimelineTile(
                    startText: formatDate(item.createdAt, format: dateTimeFormatYyyyMMDdHhMm),
                    title: item.title ?? "",
                    subtitle: item.notificationBody ?? "",
                    isFirst: index == 0,
                    isLast: _controller.notificationList.last == item);
              },
            ),
          ));
  }

  void clearAction() {
    alertForAction(context,
        title: "Clear All Notifications".tr, subTitle: "Are you want to clear all current notifications".tr, buttonTitle: "YES".tr, onOkAction: () {
      Get.back();
      _controller.updateNotificationStatus();
    });
  }
}
