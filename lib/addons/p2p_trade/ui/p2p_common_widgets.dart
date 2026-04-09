import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:get/get.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../../../data/local/constants.dart';
import '../../../data/models/user.dart';
import '../../../helper/app_helper.dart';
import '../../../utils/button_util.dart';
import '../../../utils/common_utils.dart';
import '../../../utils/date_util.dart';
import '../../../utils/decorations.dart';
import '../../../utils/dimens.dart';
import '../../../utils/extensions.dart';
import '../../../utils/image_util.dart';
import '../../../utils/number_util.dart';
import '../../../utils/spacers.dart';
import '../../../utils/text_field_util.dart';
import '../../../utils/text_util.dart';
import '../models/p2p_profile_details.dart';
import 'p2p_profile/p2p_profile_screen.dart';

class P2pUserView extends StatelessWidget {
  const P2pUserView({super.key, this.user, this.isActiveOnTap = true, this.name, this.image, this.withName = false});
  final User? user;
  final bool isActiveOnTap;
  final bool withName;
  final String? name;
  final String? image;

  @override
  Widget build(BuildContext context) {
    var nameL = name;
    if (user != null) nameL = user?.nickName ?? user?.firstName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isActiveOnTap && user != null) ? () => Get.to(() => P2pProfileScreen(userId: user?.id ?? 0)) : null,
        child: Row(
          children: [
            ClipOval(
                child: Container(
                    color: Colors.grey,
                    height: Dimens.iconSizeMid,
                    width: Dimens.iconSizeMid,
                    padding: const EdgeInsets.all(2),
                    child: showCircleAvatar(user?.photo ?? image))),
            hSpacer5(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextRobotoAutoBold(nameL ?? ""),
                if (withName && user != null) TextRobotoAutoNormal(getName(user?.firstName, user?.lastName)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Container titleAndDescView(String title, String description) {
  return Container(
    width: Get.width,
    decoration: boxDecorationRoundCorner(),
    padding: const EdgeInsets.all(Dimens.paddingMid),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextRobotoAutoBold(title, color: Get.theme.primaryColorLight),
        vSpacer10(),
        TextRobotoAutoNormal(description,
            fontSize: Dimens.fontSizeMid, maxLines: 50, color: Get.theme.primaryColor),
        vSpacer10(),
      ],
    ),
  );
}

class FeedBackItemView extends StatelessWidget {
  const FeedBackItemView({super.key, required this.feedback});
  final P2pFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final btnTitle = feedback.feedbackType == 1 ? "Positive".tr : "Negative".tr;
    return Container(
      decoration: boxDecorationRoundCorner(),
      margin: const EdgeInsets.all(Dimens.paddingMin),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        title: TextRobotoAutoBold(feedback.feedback ?? ""),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: Dimens.paddingMin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              P2pUserView(isActiveOnTap: false, name: feedback.userName, image: feedback.userImg),
              buttonText(btnTitle, bgColor: feedback.feedbackType == 1 ? Colors.green : Colors.redAccent, visualDensity: minimumVisualDensity, textColor: Colors.white)
            ],
          ),
        ),
      ),
    );
  }
}

class SegmentedControlView extends StatelessWidget {
  const SegmentedControlView(this.list, this.selected, {super.key, this.onChange, this.selectedColor});
  final int selected;
  final Function(int)? onChange;
  final List<String> list;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final fontSize = isTextScaleGetterThanOne(context) ? Dimens.fontSizeSmall : Dimens.fontSizeMid;
    final Map<int, Widget> segmentValues = <int, Widget>{
      1: Text(list.first,
          style: context.theme.textTheme.labelMedium!.copyWith(fontSize: fontSize, color: selected == 1 ? Colors.white : context.theme.primaryColor),
          textAlign: TextAlign.center),
      2: Text(list.last,
          style: context.theme.textTheme.labelMedium!.copyWith(fontSize: fontSize, color: selected == 2 ? Colors.white : context.theme.primaryColor),
          textAlign: TextAlign.center)
    };

    return CupertinoSlidingSegmentedControl(
        groupValue: selected,
        children: segmentValues,
        thumbColor: selectedColor ?? context.theme.focusColor,
        backgroundColor: context.theme.dialogTheme.backgroundColor!,
        padding: const EdgeInsets.all(Dimens.paddingMin),
        onValueChanged: (i) {
          if (onChange != null) onChange!(i as int);
        });
  }
}

class NumberIncrementView extends StatelessWidget {
  const NumberIncrementView({super.key, required this.controller, this.onTextChange});
  final TextEditingController controller;
  final Function(String)? onTextChange;

  @override
  Widget build(BuildContext context) {
    return textFieldWithWidget(prefixWidget: _buttonView(false), controller: controller, suffixWidget: _buttonView(true), type: TextInputType.number);
  }

  InkWell _buttonView(bool isIncrement) {
    final icon = isIncrement ? Icons.add : Icons.remove;
    return InkWell(onTap: () => _buttonAction(isIncrement), child: Icon(icon, size: Dimens.iconSizeMin, color: Get.theme.primaryColor));
  }

  void _buttonAction(bool isIncrement) {
    var amount = makeDouble(controller.text.trim());
    if (isIncrement) {
      amount = amount + 1;
    } else {
      amount = amount - 1;
      if (amount < 0) return;
    }
    controller.text = amount.toString();
  }
}

class DocumentUploadView extends StatelessWidget {
  const DocumentUploadView({super.key, this.documentImage, required this.selectedImage});
  final File? documentImage;
  final Function(File) selectedImage;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: context.width / 3,
        width: context.width,
        decoration: boxDecorationRoundBorder(color: context.theme.scaffoldBackgroundColor),
        child: (documentImage?.path.isValid ?? false)
            ? showImageLocal(documentImage!)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonOnlyIcon(iconPath: AssetConstants.icUpload, size: Dimens.iconSizeMid),
                  vSpacer10(),
                  TextRobotoAutoNormal("Tap to upload photo".tr),
                ],
              ),
      ),
      onTap: () {
        showImageChooser(context, (chooseFile, isGallery) {
          if (isGallery) {
            selectedImage(chooseFile);
          } else {
            saveFileOnTempPath(chooseFile, onNewFile: (newFile) {
              selectedImage(newFile);
            });
          }
        });
      },
    );
  }
}

class TagSelectionViewString extends StatelessWidget {
  const TagSelectionViewString(
      {super.key, required this.tagList, required this.tagController, required this.initialSelection, required this.onTagSelected});
  final List<String> tagList;
  final Function(List<String>) onTagSelected;
  final StringTagController tagController;
  final List<String> initialSelection;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            elevation: 4.0,
            color: context.theme.dialogTheme.backgroundColor,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final dynamic option = options.elementAt(index);
                return TextButton(
                  onPressed: () {
                    if (!(tagController.getTags ?? []).contains(option)) onSelected(option);
                  },
                  child: Align(alignment: Alignment.centerLeft, child: Text('$option', textAlign: TextAlign.left, style: context.textTheme.labelMedium)),
                );
              },
            ),
          ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return tagList;
        }
        return tagList.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selectedTag) {
        tagController.onTagSubmitted(selectedTag);
        onTagSelected(tagController.getTags ?? []);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) => onTagSelected(tagController.getTags ?? []));
        return TextFieldTags<String>(
          textEditingController: textEditingController,
          focusNode: focusNode,
          textfieldTagsController: tagController,
          initialTags: initialSelection,
          textSeparators: const [' ', ','],
          letterCase: LetterCase.normal,
          inputFieldBuilder: (context, inputValues) {
            return TextField(
              controller: inputValues.textEditingController,
              focusNode: inputValues.focusNode,
              style: context.theme.textTheme.displaySmall,
              cursorColor: context.theme.primaryColor,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(Dimens.paddingLarge),
                disabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(15)), borderSide: BorderSide(width: 1, color: Get.theme.dividerColor)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(15)), borderSide: BorderSide(width: 1, color: Get.theme.dividerColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(15)), borderSide: BorderSide(width: 1, color: Get.theme.focusColor)),
                hintText: inputValues.tags.isNotEmpty ? '' : "Select".tr,
                prefixIconConstraints: BoxConstraints(maxWidth: Get.width - 40),
                errorText: inputValues.error,
                prefixIcon: inputValues.tags.isNotEmpty
                    ? SingleChildScrollView(
                        controller: inputValues.tagScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: inputValues.tags.map((String tag) {
                          return Container(
                            decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(20.0)), color: context.theme.focusColor.withValues(alpha: 0.25)),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tag, style: context.textTheme.displaySmall!.copyWith(color: context.theme.primaryColor)),
                                const SizedBox(width: 5.0),
                                InkWell(
                                  child: Icon(Icons.cancel, size: Dimens.iconSizeMin, color: context.theme.primaryColor),
                                  onTap: () {
                                    inputValues.onTagRemoved(tag);
                                    onTagSelected(tagController.getTags ?? []);
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList()),
                      )
                    : null,
              ),
              onChanged: inputValues.onTagChanged,
              onSubmitted: inputValues.onTagSubmitted,
            );
          },
        );
      },
    );
  }
}

class CountDownView extends StatelessWidget {
  const CountDownView({super.key, required this.endTime, this.onEnd});

  final DateTime endTime;
  final Function()? onEnd;

  @override
  Widget build(BuildContext context) {
    int endTimeMilli = endTime.millisecondsSinceEpoch;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: CountdownTimer(
        endTime: endTimeMilli,
        widgetBuilder: (_, CurrentRemainingTime? time) {
          var text = "${twoDigitInt(time?.days)} : ${twoDigitInt(time?.hours)} : ${twoDigitInt(time?.min)} : ${twoDigitInt(time?.sec)}";
          return Text(text, style: Get.textTheme.labelMedium?.copyWith(color: context.theme.focusColor));
        },
        onEnd: onEnd,
      ),
    );
  }
}

class CancelView extends StatelessWidget {
  CancelView({super.key, this.onCancel});

  final Function(String)? onCancel;
  final reasonEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        vSpacer10(),
        TextRobotoAutoBold("Cancel Order".tr),
        vSpacer20(),
        Align(alignment: Alignment.centerLeft, child: TextRobotoAutoNormal("Reason to cancel the order".tr)),
        vSpacer5(),
        textFieldWithSuffixIcon(controller: reasonEditController, hint: "Write Your Reason".tr, maxLines: 3, height: 100),
        vSpacer15(),
        buttonRoundedMain(
            text: "Confirm".tr,
            onPress: () {
              final reason = reasonEditController.text.trim();
              if (reason.isEmpty) {
                showToast("reason for the cancellation".tr);
                return;
              }
              hideKeyboard();
              if (onCancel != null) onCancel!(reason);
            }),
        vSpacer10(),
      ],
    );
  }
}

class P2pIconWithTap extends StatelessWidget {
  const P2pIconWithTap({super.key, required this.icon, this.onTap, this.iconColor});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.all(Dimens.paddingMin),
      child: Icon(icon, size: Dimens.iconSizeMin, color: iconColor ?? context.theme.primaryColor),
    ));
  }
}


class P2pProfileTopInfoView extends StatelessWidget {
  const P2pProfileTopInfoView({super.key, this.user, this.userRegisterDays});
  final  User? user;
  final int? userRegisterDays;

  @override
  Widget build(BuildContext context) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: P2pUserView(user: user, isActiveOnTap: false, withName: true)),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextRobotoAutoNormal("Registered at".tr),
              TextRobotoAutoBold("${formatTotalDays(userRegisterDays)} ${"ago".tr}"),
            ],
          ),
        ),
      ],
    );
  }
}

