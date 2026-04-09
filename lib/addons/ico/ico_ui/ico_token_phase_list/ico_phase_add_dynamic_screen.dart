import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'ico_token_phase_list_controller.dart';

class IcoPhaseAddInfoScreen extends StatefulWidget {
  const IcoPhaseAddInfoScreen({super.key, required this.prePhase});

  final IcoPhase prePhase;

  @override
  State<IcoPhaseAddInfoScreen> createState() => _IcoPhaseAddInfoScreenState();
}

class _IcoPhaseAddInfoScreenState extends State<IcoPhaseAddInfoScreen> {
  final _controller = Get.find<IcoTokenPhaseListController>();
  RxBool isEdit = false.obs;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _getData());
  }

  @override
  void dispose() {
    _controller.additionalList.clear();
    super.dispose();
  }

  void _getData() async {
    _controller.getIcoTokenPhaseAdditionalDetails(widget.prePhase, (data) {
      isLoading = false;
      isEdit.value = data.isNotEmpty;
      _controller.additionalList.value = data;
      if (!isEdit.value) _addNewInfoInList();
    });
  }

  void _addNewInfoInList() {
    _controller.additionalList.add(PhaseAdditionalInfo(icoPhaseId: widget.prePhase.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(top: Dimens.paddingMainViewTop),
              child: Obx(() {
                final title = isEdit.value ? "Edit Additional Info".tr : "Add Additional Info".tr;
                return Column(
                  children: [
                    appBarBackWithActions(title: title, fontSize: Dimens.fontSizeMid),
                    isLoading
                        ? showLoading()
                        : Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(Dimens.paddingMid),
                        children: [
                          Column(
                              children:
                              List.generate(_controller.additionalList.length, (index) => PhaseAdditionalInfoItemView(index: index))),
                          vSpacer10(),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Expanded(child: buttonRoundedMain(text: "Save Data".tr, onPress: () => _checkAndSaveInfo(context))),
                            hSpacer10(),
                            Expanded(child: buttonRoundedMain(text: "Add Field".tr, onPress: () => _addNewInfoInList())),
                          ]),
                          vSpacer10(),
                        ],
                      ),
                    )
                  ],
                );
              }))),
    );
  }

  void _checkAndSaveInfo(BuildContext context) async {
    final dyList = _controller.additionalList;
    final mapObj = <String, dynamic>{};
    if (dyList.isNotEmpty) {
      for (int i = 0; i < dyList.length; i++) {
        final form = dyList[i];
        if (!form.title.isValid) {
          showToast("Title can not be empty".tr);
          return;
        }
        if (!form.value.isValid) {
          showToast("Value can not be empty".tr);
          return;
        }
        if (form.id != null) mapObj["ids[$i]"] = form.id;
        mapObj["titles[$i]"] = form.title;
        mapObj["values[$i]"] = form.value;
        if (form.localFile != null && form.localFile!.path.isNotEmpty) {
          mapObj["file_values[$i]"] = await APIRepository().makeMultipartFile(form.localFile!);
        }
      }
      mapObj["ico_phase_id"] = widget.prePhase.id;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => hideKeyboard(context: context));
      _controller.icoCreateUpdateTokenPhaseAdditional(mapObj, () => _getData());
    }
  }
}

class PhaseAdditionalInfoItemView extends StatelessWidget {
  PhaseAdditionalInfoItemView({super.key, required this.index});

  final int index;
  final _controller = Get.find<IcoTokenPhaseListController>();

  @override
  Widget build(BuildContext context) {
    final info = _controller.additionalList[index];
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(children: [
        textFieldWithSuffixIcon(
            controller: TextEditingController(text: info.title ?? ""),
            labelText: "Title".tr,
            hint: "Enter Title".tr,
            onTextChange: (text) {
              _controller.additionalList[index].title = text;
            }),
        vSpacer10(),
        textFieldWithSuffixIcon(
            controller: TextEditingController(text: info.value ?? ""),
            labelText: "Value".tr,
            hint: "Enter Value".tr,
            onTextChange: (text) {
              _controller.additionalList[index].value = text;
            }),
        vSpacer5(),
        _documentView(context, info)
      ]),
    );
  }

  Column _documentView(BuildContext context, PhaseAdditionalInfo info) {
    final text = (info.localFile == null || info.localFile!.path.isEmpty) ? "No image selected".tr : info.localFile.name;
    return Column(
      children: [
        if (info.file.isValid)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextRobotoAutoBold("Selected Image".tr),
            showImageNetwork(
                imagePath: info.file,
                height: Dimens.iconSizeLarge,
                width: Dimens.iconSizeLarge,
                boxFit: BoxFit.cover,
                onPressCallback: () => openUrlInBrowser(info.file ?? ""))
          ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
                width: 150,
                child: buttonText("Select Image".tr, onPress: () {
                  showImageChooser(context, (chooseFile, isGallery) {
                    _controller.additionalList[index].localFile = chooseFile;
                    _controller.additionalList.refresh();
                  }, isCrop: false);
                })),
            Expanded(child: TextRobotoAutoNormal(text, maxLines: 2))
          ],
        ),
      ],
    );
  }
}
