import 'dart:convert';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pagination_tests/src/epub/js/xpub_js_api.dart';
import 'package:pagination_tests/src/listeners/web_view_horizontal_gesture_recognizer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaginatingWebView extends StatefulWidget {
  final int chapNumber;

  PaginatingWebView(
    this.chapNumber, {
    Key key,
  }) : super(key: key);

  @override
  _PaginatingWebViewState createState() => _PaginatingWebViewState();
}

class _PaginatingWebViewState extends State<PaginatingWebView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final kDefaultNbPages = 3;
  double contentWidth = 920.0;

  WebViewController _controller;
  JsApi jsApi;

  @override
  Widget build(BuildContext context) {
    // var webViewHorizontalGestureRecognizer = HorizontalDragGestureRecognizer();
    var webViewHorizontalGestureRecognizer =
        WebViewHorizontalGestureRecognizer(
          chapNumber: widget.chapNumber,
          webView: widget,
        );
    contentWidth = MediaQuery.of(context).size.width * 3;
    Fimber.d(
        "============= Device screen width: ${MediaQuery.of(context).size.width}");
    return ConstrainedBox(
      constraints: BoxConstraints(
          minWidth: contentWidth, maxWidth: contentWidth, maxHeight: 800.0),
      child: WebView(
        initialUrl: "https://www.google.com",
        debuggingEnabled: true,
        javascriptMode: JavascriptMode.unrestricted,
        //javascriptChannels: epubCallbacks.channels,
        javascriptChannels: Set.from([
          JavascriptChannel(
              name: 'setWebviewWidth',
              onMessageReceived: (JavascriptMessage message) {
                Fimber.d(
                    "================ setWebviewWidth: ${message.message}");
                setState(() {
                  contentWidth = double.parse(message.message);
                });
              }),
          JavascriptChannel(
              name: 'sendBeginningVisibile',
              onMessageReceived: (JavascriptMessage message) {
                webViewHorizontalGestureRecognizer.setBeginningVisible(
                    message, webViewHorizontalGestureRecognizer);
              }),
          JavascriptChannel(
              name: 'sendEndVisibile',
              onMessageReceived: (JavascriptMessage message) {
                webViewHorizontalGestureRecognizer.setEndVisible(
                    message, webViewHorizontalGestureRecognizer);
              }),
        ]),
        gestureRecognizers: [
          Factory(() => webViewHorizontalGestureRecognizer),
        ].toSet(),
        onWebViewCreated: (WebViewController webViewController) {
          Fimber.d(">>> Webview CREATED");
          _controller = webViewController;
          //webViewHorizontalGestureRecognizer.controller = webViewController;
          jsApi = JsApi((js) => _controller.evaluateJavascript(js));
//                  epubCallbacks.jsApi = _jsApi;
          _loadHtmlFromAssets();
          //_injectCss();
          //_changeNbPages(kDefaultNbPages);
        },
      ),
    );
  }

  _loadHtmlFromAssets() async {
    String fileText = await rootBundle
        .loadString('assets/debug_snap_${widget.chapNumber}.html');
    _controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }

  _injectCss() async {
    Fimber.d(">>> Loading CSS...");
    // String cssText = await rootBundle.loadString('assets/css/pagination.css');
    String cssText = "#container {width: 60%}";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    var cssText64 = stringToBase64.encode(cssText);
    Fimber.d(">>> Injecting CSS: ${cssText.replaceAll("\n", " ")}");
    var js = """
var parent = document.getElementsByTagName('head').item(0);
var style = document.createElement('style');
style.type = 'text/css';
style.innerHTML = window.atob('$cssText64');
parent.appendChild(style);
""";
    Fimber.d(">>> JS: ${js.replaceAll("\n", " ")}");

    _controller.loadUrl(js);
  }

  _changeNbPages(nbPages) {
    String js = "document.documentElement.style.setProperty('nb-pages', " +
        nbPages +
        ");";
    _controller.evaluateJavascript(js);
  }

  void loadJS(String jScript) {
    Fimber.d("loadJS: $jScript");
    _controller.evaluateJavascript("javascript:(function(){$jScript})()");
  }
}
