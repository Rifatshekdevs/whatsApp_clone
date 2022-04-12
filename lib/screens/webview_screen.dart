import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../colors.dart';

class WebViewScreen extends StatefulWidget {
  final String? url, name;

  const WebViewScreen({Key? key, this.url, this.name}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  late ContextMenu contextMenu;
  double progress = 0;

  @override
  void initState() {
    super.initState();

    if (widget.name == "About") {
      if (Common.aboutUrl == "") {
        Common.aboutUrl = widget.url!;
      }
    } else {
      if (Common.helpUrl == "") {
        Common.helpUrl = widget.url!;
      }
    }

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: AppColors.primaryColor),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        centerTitle: false,
        automaticallyImplyLeading: true,
        title: textUtils.bold20(widget.name, AppColors.whiteColor, TextAlign.center),
        elevation: 0.0,
      ),
      body: Stack(children: [
        InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(url: Uri.parse(widget.url!)),
          initialUserScripts: UnmodifiableListView<UserScript>([]),
          initialOptions: options,
          pullToRefreshController: pullToRefreshController,
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              if (widget.name == "About") {
                Common.aboutUrl = url.toString();
              } else {
                Common.helpUrl = url.toString();
              }
            });
          },
          androidOnPermissionRequest: (controller, origin, resources) async {
            return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;

            if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
              String url = "";
              if (widget.name == "About") {
                url = Common.aboutUrl;
              } else {
                url = Common.helpUrl;
              }

              if (await canLaunch(url)) {
                // Launch the App
                await launch(url);
                // and cancel the request
                return NavigationActionPolicy.CANCEL;
              }
            }

            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (controller, url) async {
            pullToRefreshController.endRefreshing();
            setState(() {
              if (widget.name == "About") {
                Common.aboutUrl = url.toString();
              } else {
                Common.helpUrl = url.toString();
              }
            });
          },
          onLoadError: (controller, url, code, message) {
            pullToRefreshController.endRefreshing();
          },
          onProgressChanged: (controller, progress) {
            if (progress == 100) {
              pullToRefreshController.endRefreshing();
            }
            setState(() {
              this.progress = progress / 100;
            });
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) {
            setState(() {
              if (widget.name == "About") {
                Common.aboutUrl = url.toString();
              } else {
                Common.helpUrl = url.toString();
              }
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint(consoleMessage.message);
          },
        ),
        progress < 1.0 ? LinearProgressIndicator(value: progress) : Container(),
      ]),
    );
  }
}
