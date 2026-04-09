import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

import 'ico_dashboard_controller.dart';
import 'ico_dashboard_list_page.dart';
import 'ico_dashboard_withdraw_page.dart';

class ICODashboardScreen extends StatefulWidget {
  const ICODashboardScreen({super.key});

  @override
  State<ICODashboardScreen> createState() => _ICODashboardScreenState();
}

class _ICODashboardScreenState extends State<ICODashboardScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(IcoDashboardController());
  late TabController _tabController;

  final types = ["Applied Launchpad".tr, "ICO Tokens".tr, "Buy History".tr, "Token Wallet".tr, "Withdraw".tr, "Withdraw List".tr];

  @override
  void initState() {
    _tabController = TabController(length: types.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "ICO Dashboard".tr),
      body: SafeArea(
          child: Column(
        children: [
          tabBarUnderline(types, _tabController,
              isScrollable: true,
              fontSize: Dimens.fontSizeMid,
              indicatorColor: context.theme.focusColor,
              onTap: (index) => _controller.selectedType.value = index),
          Obx(() => _controller.selectedType.value == 4 ? const IcoDashboardWithdrawPage() : IcoDashboardListPage())
        ],
      )),
    );
  }
}
