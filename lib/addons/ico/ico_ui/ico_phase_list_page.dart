import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ico_constants.dart';
import '../model/ico_phase.dart';
import '../../../utils/appbar_util.dart';
import '../../../utils/common_widgets.dart';
import '../../../utils/dimens.dart';
import 'ico_controller.dart';
import 'ico_widgets.dart';

class ICOPhaseListPage extends StatefulWidget {
  const ICOPhaseListPage({super.key, required this.type});

  final int type;

  @override
  State<ICOPhaseListPage> createState() => _ICOPhaseListPageState();
}

class _ICOPhaseListPageState extends State<ICOPhaseListPage> {
  final _controller = Get.find<IcoController>();
  List<IcoPhase> phaseList = <IcoPhase>[];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getPhaseActiveList(widget.type, (list) {
        phaseList = list;
        isLoading = false;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == IcoPhaseSortType.recent ? "Ongoing List".tr : "";
    return Scaffold(
      appBar: appBarBackWithActions(title: title),
      body: SafeArea(
          child: isLoading
              ? showLoading()
              : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(Dimens.paddingMid),
                itemCount: phaseList.length,
                itemBuilder: (context, index) => IcoPhaseItemView(phase: phaseList[index]),
              )),
    );
  }
}
