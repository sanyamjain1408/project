import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'button_util.dart';
import 'common_utils.dart';
import 'common_widgets.dart';

const pathTempProfileImageName = "_profileImage_id_verify.jpeg";
const pathTempFrontImageName = "_frontImage_id_verify.jpeg";
const pathTempBackImageName = "_backImage_id_verify.jpeg";

Widget showCircleAvatar(String? url, {double size = 90}) {
  return ClipOval(
    child: CachedNetworkImage(
      imageUrl: url ?? "",
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => const AppLogo(),
      errorWidget: (context, url, error) => const AppLogo(),
    ),
  );
}

ColorFilter? getColorFilter(Color? color) => color == null ? null : ColorFilter.mode(color, BlendMode.srcIn);

Widget showCachedNetworkImage(String url, {double size = 90}) {
  return CachedNetworkImage(
    imageUrl: url,
    width: size,
    height: size,
    fit: BoxFit.cover,
    placeholder: (context, url) => const AppLogo(),
    errorWidget: (context, url, error) => const AppLogo(),
  );
}

Widget showImageAsset(
    {IconData? icon,
    String? imagePath = "assets/icons/blogo.png",
    double? width,
    double? height,
    VoidCallback? onPressCallback,
    Color? color,
    BoxFit? boxFit = BoxFit.contain,
    double? iconSize}) {
  return InkWell(
    onTap: onPressCallback,
    child: imagePath!.isNotEmpty
        ? imagePath.contains(".svg")
            ? SvgPicture.asset(imagePath, fit: boxFit!, width: width, height: height, colorFilter: getColorFilter(color))
            : Image.asset(imagePath, fit: boxFit!, width: width, height: height, color: color)
        : Icon(icon!, size: iconSize, color: color),
  );
}

Widget showImageNetwork(
    {String? imagePath,
      double? width,
      double? height,
      VoidCallback? onPressCallback,
      Color? iconColor,
      BoxFit boxFit = BoxFit.contain,
      Color? bgColor,
      double? iconSize,
      double? padding,
      bool hideDefaultImage = false}) {
  return InkWell(
      onTap: onPressCallback,
      child: Container(
        height: height,
        width: width,
        color: bgColor ?? Colors.grey.withValues(alpha: 0.25),
        padding: EdgeInsets.all(padding ?? 0),
        child: imagePath.isValid
            ? imagePath!.contains(".svg")
            ? SvgPicture.network(imagePath, fit: boxFit, colorFilter: getColorFilter(iconColor))
            : Image.network(imagePath,
            fit: boxFit, errorBuilder: (context, error, stackTrace) => hideDefaultImage ? const SizedBox() : const AppLogo())
            : (hideDefaultImage ? const SizedBox() : const AppLogo()),
      ));
}

Widget showImageLocal(File file, {double size = 90}) {
  return Container(padding: const EdgeInsets.all(5), child: Image.file(file, width: size, height: size, fit: BoxFit.cover));
}

Widget showCircleAvatarLocal(File file, {double size = 90}) {
  return ClipOval(child: Image.file(file, width: size, height: size, fit: BoxFit.cover));
}

void showImageChooser(BuildContext context, Function(File, bool) onChoose, {bool isCamera = true, bool isGallery = true, bool isCrop = true}) {
  hideKeyboard(context: context);
  choosePhotoModalBottomSheet(
      onTakePic: isCamera
          ? () {
              Get.back();
              getImage(false, onChoose, isCrop);
            }
          : null,
      onChoosePic: isGallery
          ? () {
              Get.back();
              getImage(true, onChoose, isCrop);
            }
          : null,
      width: Get.width * 0.85);
}

void choosePhotoModalBottomSheet({VoidCallback? onTakePic, VoidCallback? onChoosePic, double width = 0}) => Get.bottomSheet(
      Container(
          alignment: Alignment.bottomCenter,
          //height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onTakePic != null)
                buttonRoundedMain(
                    text: "Take a picture".tr, onPress: onTakePic, width: width, textColor: Colors.black, bgColor: Colors.white),
              if (onTakePic != null) dividerHorizontal(height: 10, indent: Get.width - width),
              if (onChoosePic != null)
                buttonRoundedMain(
                    text: "Choose a picture".tr, onPress: onChoosePic, width: width, textColor: Colors.black, bgColor: Colors.white),
              if (onChoosePic != null) dividerHorizontal(height: 10, indent: Get.width - width),
              buttonRoundedMain(text: "Cancel".tr, onPress: () => Get.back(), width: width, textColor: Colors.black, bgColor: Colors.grey),
              const SizedBox(height: 10)
            ],
          )),
      isDismissible: true,
    );

Future getImage(bool isGallery, Function(File, bool) onChoose, bool isCrop) async {
  XFile? res;
  if (isGallery) {
    res = await ImagePicker().pickImage(source: ImageSource.gallery);
  } else {
    res = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
  }
  if (res != null) {
    if (isCrop) {
      cropImage(isGallery, res, onChoose);
    } else {
      onChoose(File(res.path), isGallery);
    }
  }
}

Future cropImage(bool isGallery, XFile file, Function(File, bool) onChoose) async {
  final   aspectRatioPresets = [
    CropAspectRatioPreset.square,
    CropAspectRatioPreset.ratio3x2,
    CropAspectRatioPreset.original,
    CropAspectRatioPreset.ratio4x3,
    CropAspectRatioPreset.ratio16x9
  ];
  CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: file.path,
    uiSettings: [
      AndroidUiSettings(initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: true, aspectRatioPresets: aspectRatioPresets),
      IOSUiSettings(aspectRatioLockEnabled: true, aspectRatioPresets: aspectRatioPresets),
    ],
  );

  if (croppedFile != null) {
    var file = File(croppedFile.path);
    onChoose(file, isGallery);
  }
}

void saveFileOnTempPath(File chooseFile, {String? imgName, Function(File)? onNewFile}) async {
  imgName = imgName ?? pathTempProfileImageName;

  getImageDirectoryPath(imgName).then((tempPath) {
    ///Delete previous file if exists
    final checkFile = File(tempPath);
    if (checkFile.existsSync()) checkFile.deleteSync();

    ///Create new file
    File(tempPath).createSync(recursive: true);
    File newFile = chooseFile.copySync(tempPath);
    chooseFile.deleteSync();
    if (onNewFile != null) onNewFile(newFile);
  });
}

Future<String> getImageDirectoryPath(String path) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  return "${appDocDir.path}${AssetConstants.pathTempImageFolder}${DateTime.now().millisecondsSinceEpoch}$path";
}
//palette_generator or material_color_utilities
// Future<Color> getOppositeColorFromImage(String? path) async {
//   if (path.isValid) {
//     final image = NetworkImage(path!);
//     final imageSize = Size(Get.width, Get.width / 2);
//     final region = Offset.zero & imageSize;
//     final paletteGenerator = await PaletteGenerator.fromImageProvider(image, size: imageSize, region: region, maximumColorCount: 3);
//     final imageColor = paletteGenerator.dominantColor?.color ??
//         paletteGenerator.mutedColor?.color ??
//         paletteGenerator.dominantColor?.color ??
//         paletteGenerator.vibrantColor?.color;
//
//     if (imageColor != null) {
//       return imageColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
//     }
//   }
//   return Colors.transparent;
// }