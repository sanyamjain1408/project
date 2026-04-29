import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'earn_controller.dart';
import 'earn_home_screen.dart';
import 'earn_positions_screen.dart';
import 'earn_history_screen.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final RxInt selectedTabIndex = 0.obs;
  final tabList = ['Products'.tr, 'My Positions'.tr, 'History'.tr];

  @override
  void initState() {
    super.initState();
    Get.put(EarnController());
    _tabController = TabController(vsync: this, length: 3);
    Get.find<EarnController>().fetchProducts();
    Get.find<EarnController>().fetchBalances();
    if (gUserRx.value.id > 0) {
      Get.find<EarnController>().fetchPositions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      appBar: appBarBackWithActions(title: 'Easy Earn'.tr),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            const Divider(height: 0, color: Color(0xFF1E2128)),
            Expanded(child: _buildTabBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0A0B0D),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: const Color(0xFFB5F000),
        indicatorWeight: 2,
        labelColor: const Color(0xFFB5F000),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        onTap: (index) => selectedTabIndex.value = index,
        tabs: tabList.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildTabBody() {
    return Obx(() {
      switch (selectedTabIndex.value) {
        case 0:
          return const EarnHomeScreen();
        case 1:
          return const EarnPositionsScreen();
        case 2:
          return const EarnHistoryScreen();
        default:
          return const SizedBox();
      }
    });
  }
}