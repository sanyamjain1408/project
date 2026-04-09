import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'appbar_util.dart';

class QRScannerPage extends StatefulWidget {
  final Function(String) onData;

  const QRScannerPage({super.key, required this.onData});

  @override
  State<StatefulWidget> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Scan QR-Code".tr),
      body: Column(
        children: <Widget>[
          Expanded(child: _buildQrView(context)),
          textWithBackground("Place QR code with the frame to scan".tr, bgColor: Colors.transparent, textAlign: TextAlign.center)
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated:(controller) => _onQRViewCreated(controller, context),
      overlay: QrScannerOverlayShape(
          borderColor: Theme.of(context).focusColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: MediaQuery.of(context).size.width / 2),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller, BuildContext context) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.format == BarcodeFormat.qrcode) {
        if (scanData.code.isValid) widget.onData(scanData.code!);
        this.controller?.pauseCamera();
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) showToast("Need camera permission".tr);
  }

}
