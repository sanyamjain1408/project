import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'check_deposit/check_deposit_page.dart';
import 'wallet_controller.dart';
import 'wallet_list_page.dart';
import 'wallet_overview_page.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(WalletController());

  @override
  void initState() {
    _controller.tabController = TabController(length: _controller.getTypeMap().length, vsync: this);
    if (TemporaryData.changingPageId != null) {
      _controller.selectedTypeIndex.value = TemporaryData.changingPageId!;
      TemporaryData.changingPageId = null;
      _controller.tabController?.animateTo(_controller.selectedTypeIndex.value);
    }

    super.initState();
  }
@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── TOP TABBAR HATAO — Overview nahi dikhana ──
      // TabBarPlain hata diya

      Expanded(
        child: Obx(() => gUserRx.value.id == 0 
          ? signInNeedView() 
          : const WalletOverviewPage()),
      ),
    ],
  );
}

  
}
