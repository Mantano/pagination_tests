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
    super.build(context);
    contentWidth = MediaQuery.of(context).size.width * 3;
    Fimber.d(
        "============= Device screen width: ${MediaQuery.of(context).size.width}");
    return ConstrainedBox(
      constraints: BoxConstraints(
          minWidth: contentWidth, maxWidth: contentWidth, maxHeight: 800.0),
      child: WebView(
        // initialUrl:
        //     Uri.encodeFull("https://www.google.com?q=${widget.chapNumber}"),
        debuggingEnabled: true,
        // javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          Fimber.d(">>> Webview CREATED");
          _controller = webViewController;
          _loadHtmlFromAssets();
        },
        onPageFinished: _onPageFinished,
      ),
    );
  }

  _loadHtmlFromAssets() async {
    Fimber.d("============= Loading: " +
        'assets/chap_${widget.chapNumber + 1}.html');
    String fileText = await rootBundle
        .loadString('assets/chap_${widget.chapNumber + 1}.html');
    _controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }

  void _onPageFinished(String url) {
    Fimber.d("============== _onPageFinished[${widget.chapNumber}]");
    try {
      // jsApi?.initPagination();
    } catch (e, stacktrace) {
      Fimber.d("_onPageFinished ERROR", ex: e, stacktrace: stacktrace);
    }
  }
}
