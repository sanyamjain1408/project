import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PayStackData {
  String? authorizationUrl;
  String? reference;
  String? trxId;

  PayStackData({this.authorizationUrl, this.reference, this.trxId});

  factory PayStackData.fromJson(Map<String, dynamic> json) => PayStackData(
        authorizationUrl: json["authorization_url"],
        reference: json["reference"],
      );
}

class PayStackPaymentPage extends StatefulWidget {
  final Function(PayStackData) onFinish;
  final PayStackData paystackData;

  const PayStackPaymentPage({super.key, required this.onFinish, required this.paystackData});

  @override
  State<StatefulWidget> createState() => PayStackPaymentPageState();
}

class PayStackPaymentPageState extends State<PayStackPaymentPage> {
  String returnURL = '';
  String cancelURL = 'https://standard.paystack.co/close';
  late final WebViewController _controller;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    initWebview();
    super.initState();
    returnURL = "verify-paystack";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:  TextRobotoAutoBold("Paystack".tr),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: GestureDetector(child: Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor), onTap: () => Navigator.pop(context)),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  void initWebview() {
    final color = gIsDarkMode ? Colors.black : Colors.white;
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true, mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{});
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Flutter;Webview')
      ..setBackgroundColor(color)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            printFunction("NavigationDelegate start", url);
          },
          onPageFinished: (String url) {
            printFunction("NavigationDelegate finish", url);
          },
          onWebResourceError: (WebResourceError error) => printFunction("NavigationDelegate error", error.description),
          onUrlChange: (change) {
            printFunction("NavigationDelegate change", change.url);
          },
          onNavigationRequest: (NavigationRequest request) {
            printFunction("NavigationDelegate request", request.url);
            if (request.url.contains(returnURL)) {
              final uri = Uri.parse(request.url);
              final payerID = uri.queryParameters['trxref'];
              widget.paystackData.trxId = payerID;
              Navigator.of(context).pop();
              widget.onFinish(widget.paystackData);
              return NavigationDecision.prevent;
            } else if (request.url.contains(cancelURL)) {
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paystackData.authorizationUrl ?? ""));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }
}
