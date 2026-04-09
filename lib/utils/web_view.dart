import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'button_util.dart';
import 'common_utils.dart';
import 'common_widgets.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  WebViewPageState createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true, mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{});
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => showLoadingDialog(isDismissible: true),
          onPageFinished: (String url) => hideLoadingDialog(),
          onWebResourceError: (WebResourceError error) => printFunction("onWebResourceError", error.description),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: Get.height,
          width: Get.width,
          child: WebViewWidget(controller: _controller),
        ),
      ),
      floatingActionButton: buttonOnlyIcon(
          onPress: () {
            Get.back();
          },
          iconPath: AssetConstants.icArrowLeft),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class HtmlTextView extends StatelessWidget {
  const HtmlTextView({super.key, required this.htmlText});

  final String htmlText;

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      htmlText,
      onLoadingBuilder: (context, element, loadingProgress) => showLoadingSmall(),
      textStyle: TextStyle(color: context.theme.primaryColor),
    );
  }
}
