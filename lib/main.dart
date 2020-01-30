import 'dart:convert';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:pagination_tests/src/epub/js/xpub_js_api.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  if (kReleaseMode) {
    Fimber.plantTree(FimberTree());
  } else {
    Fimber.plantTree(DebugBufferTree());
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Pagination tests'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const NB_CHAPTERS = 6;
  final _webviewKeys =
      List<GlobalKey>.generate(NB_CHAPTERS, (_) => GlobalKey());
  var _controller = [];
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),

      body: Center(
        child: PreloadPageView.builder(
            preloadPagesCount: 3,
            controller: PreloadPageController(),
            itemCount: NB_CHAPTERS,
            itemBuilder: (ctx, i) {
              return PaginatingWebView(
                i + 1,
                key: _webviewKeys[i],
              );
            }),
      ),
    );
  }
}

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

  WebViewController _controller;
  JsApi jsApi;

  @override
  Widget build(BuildContext context) {
    var platformViewHorizontalGestureRecognizer =
        PlatformViewHorizontalGestureRecognizer();
    return WebView(
      initialUrl: "https://www.google.com",
      debuggingEnabled: true,
      javascriptMode: JavascriptMode.unrestricted,
      //javascriptChannels: epubCallbacks.channels,
      javascriptChannels: Set.from([
        JavascriptChannel(
            name: 'sendBeginningVisibile',
            onMessageReceived: (JavascriptMessage message) {
              platformViewHorizontalGestureRecognizer.setBeginningVisible(
                  message, platformViewHorizontalGestureRecognizer);
            }),
        JavascriptChannel(
            name: 'sendEndVisibile',
            onMessageReceived: (JavascriptMessage message) {
              platformViewHorizontalGestureRecognizer.setEndVisible(
                  message, platformViewHorizontalGestureRecognizer);
            }),
      ]),
      gestureRecognizers: [
        Factory(() => platformViewHorizontalGestureRecognizer),
      ].toSet(),
      onWebViewCreated: (WebViewController webViewController) {
        Fimber.d(">>> Webview CREATED");
        _controller = webViewController;
        platformViewHorizontalGestureRecognizer.controller = webViewController;
        jsApi = JsApi((js) => _controller.evaluateJavascript(js));
//                  epubCallbacks.jsApi = _jsApi;
        _loadHtmlFromAssets();
        //_injectCss();
        //_changeNbPages(kDefaultNbPages);
      },
    );
  }

  void setCurrentScrollInfos(
      JavascriptMessage message,
      PlatformViewHorizontalGestureRecognizer
          platformViewHorizontalGestureRecognizer) {
    Fimber.d(">>> FROM JS: ${message.message}");
    var values = message.message.split("/");
    platformViewHorizontalGestureRecognizer.webViewScrollX =
        double.parse(values[0]);
    platformViewHorizontalGestureRecognizer.webViewScrollWidth =
        double.parse(values[1]);
    platformViewHorizontalGestureRecognizer.webViewViewportWidth =
        double.parse(values[2]);
  }

  _loadHtmlFromAssets() async {
    String fileText =
        await rootBundle.loadString('assets/chap_${widget.chapNumber}.html');
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

/// Inspired by https://stackoverflow.com/questions/57069716/scrolling-priority-when-combining-pageview-with-webview-in-flutter-1-7-8/57150906#57150906
///
class PlatformViewHorizontalGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  WebViewController controller;
  PaginatingWebView _webView;

  double _webViewScrollX = -double.maxFinite;
  double _webViewScrollWidth = double.maxFinite;
  double _webViewViewportWidth = double.maxFinite;

  bool _isBeginningVisible = true;
  bool _isEndVisible = false;

  int _currentPointer;


  bool get isBeginningVisible => _isBeginningVisible;

  bool get isEndVisible => _isEndVisible;

  set isBeginningVisible(bool value) {
    Fimber.d(">>> SETTING isBeginningVisible to $value");
    _isBeginningVisible = value;
  }

  set isEndVisible(bool value) {
    Fimber.d(">>> SETTING isEndVisible to $value");
    _isEndVisible = value;
  }

  set webView(PaginatingWebView value) {
    _webView = value;
  }

  set webViewScrollX(double value) {
    _webViewScrollX = value;
    Fimber.d(
        ">>> _webViewCanScrollX --> $value, this: $hashCode, ${_webView.hashCode}");
  }

  set webViewScrollWidth(double value) {
    _webViewScrollWidth = value;
    Fimber.d(
        ">>> webViewScrollWidth --> $_webViewScrollWidth, this: $hashCode, ${_webView.hashCode}");
  }

  set webViewViewportWidth(double value) {
    _webViewViewportWidth = value;
    Fimber.d(
        ">>> webViewViewportWidth --> $_webViewViewportWidth, this: $hashCode, ${_webView.hashCode}");
  }

  void setBeginningVisible(JavascriptMessage message, PlatformViewHorizontalGestureRecognizer platformViewHorizontalGestureRecognizer) {
    var value = message.message.toLowerCase() == 'true' || message.message.toLowerCase() == '1';
    Fimber.d(">>> setBeginningVisible, FROM JS: $value (message: ${message.message})");
    isBeginningVisible = value;
  }

  void setEndVisible(JavascriptMessage message, PlatformViewHorizontalGestureRecognizer platformViewHorizontalGestureRecognizer) {
    var value = message.message.toLowerCase() == 'true' || message.message.toLowerCase() == '1';
    Fimber.d(">>> setEndVisible, FROM JS: $value (message: ${message.message})");
    isEndVisible = value;
  }


  PlatformViewHorizontalGestureRecognizer({PointerDeviceKind kind})
      : super(kind: kind);

  Offset _dragDistance = Offset.zero;

  @override
  void addPointer(PointerEvent event) {
    _currentPointer = event.pointer;
    startTrackingPointer(event.pointer);
    Fimber.d(">>> Pointer tracking STARTED, pointer: ${event.pointer}");
  }

  @override
  String get debugDescription => 'horizontal drag (platform view)';

  final getScrollPosJSString = """
PrintScrollPosition.postMessage(document.getElementById('container').scrollLeft + '/' + document.scrollingElement.scrollWidth + '/' +  Math.max(document.documentElement.clientWidth, document.documentElement.clientWidth /*window.innerWidth || 0*/ ));
""";

  @override
  void didStopTrackingLastPointer(int pointer) {
//    Fimber.d(">>> didStopTrackingLastPointer");
  }

  bool webviewCanScroll(double dx) {
    Fimber.d(">>> webviewCanScroll --> " + (_isEndVisible ? "false" : "true"));
    return !_isEndVisible;
    bool res = false;
    double wvScrollX = getNextScrollInfos();

    if (dx == 0 ||
        _webViewScrollWidth == double.maxFinite ||
        _webViewViewportWidth == double.maxFinite)
      res = true;
    else if (dx > 0)
      res = wvScrollX > 0;
//    res = wvScrollX - _webViewViewportWidth >= 0;

    else
      res = wvScrollX <= _webViewScrollWidth - 2 * _webViewViewportWidth;
    Fimber.d(
        ">>> CAN SCROLL? dx = $dx, scrollX: $wvScrollX, scrollWidth: $_webViewScrollWidth, vpwidth: $_webViewViewportWidth --> $res");
    return res;
  }

  double getNextScrollInfos() {
    double wvScrollX = double.maxFinite;
    // Horrible active polling, but found no better way for now to get the result from JS
    wvScrollX = _webViewScrollX;
//    while (wvScrollX == double.maxFinite) {
//      wvScrollX = _webViewScrollX;
//      sleep(const Duration(milliseconds:5));
//    }
    //_webViewScrollX = double.maxFinite;
    return wvScrollX;
  }

  @override
  void handleEvent(PointerEvent event) {
    _dragDistance = _dragDistance + event.delta;
    if (event is PointerMoveEvent) {
      final double dy = _dragDistance.dy.abs();
      final double dx = _dragDistance.dx.abs();

      if (dy > dx && dy > kTouchSlop) {
        // vertical drag - stop tracking
        stopTrackingPointer(event.pointer);
        _dragDistance = Offset.zero;
      } else if (dx > kTouchSlop && dx > dy) {
        // horizontal drag
        if ( (isEndVisible && isDraggingTowardsLeft(event))
            || (isBeginningVisible && isDraggingTowardsRight(event))) {

        } else {
          // horizontal drag - accept
          resolve(GestureDisposition.accepted);
          _dragDistance = Offset.zero;
        }
      }
    }
  }
  //@override
  void JMhandleEvent(PointerEvent event) {
    _dragDistance = _dragDistance + event.delta;
    // var wvCanScroll = webviewCanScroll(event.delta.dx);
    Fimber.d(
        ">>> handleEvent, dx: ${event.delta.dx}, isEndVisible: $isEndVisible, this: $hashCode, webview: ${_webView.hashCode}");
    if (!(event is PointerMoveEvent))
      return super.handleEvent(event);

//    if (isEndVisible) {
//      Fimber.d(">>> ============= END IS VISIBLE");
//      stopTrackingPointer(_currentPointer);
//      resolve(GestureDisposition.rejected);
//      super.handleEvent(event);
//      return;
//    }
    // When swiping from right to left dx is < 0 (to move forward in a LTR book)
    if ( (isDraggingTowardsLeft(event) && isEndVisible)
        || (isDraggingTowardsRight(event) && isBeginningVisible)) {
      Fimber.d(">>> REJECTING event");
      stopTrackingPointer(_currentPointer);
      //resolve(GestureDisposition.rejected);
    } else {
      Fimber.d(">>> ACCEPTING event");
      resolve(GestureDisposition.accepted);
    }
    return super.handleEvent(event);

//    Fimber.d(">>> handleEventnot NOT rejecting");
//
//    if (event is PointerMoveEvent) {
//      final double dy = _dragDistance.dy.abs();
//      final double dx = _dragDistance.dx.abs();
//      Fimber.d(">>> localPosition: ${event.localPosition.dx}");
//      if (!wvCanScroll || (dy > dx && dy > kTouchSlop)) {
//        // vertical drag - stop tracking
//        stopTrackingPointer(event.pointer);
//        Fimber.d(">>> Pointer tracking STOPPED");
//        controller.evaluateJavascript("console.log('STOP')");
//        _dragDistance = Offset.zero;
//      } else if (dx > kTouchSlop && dx > dy) {
//        // horizontal drag - accept if webview can scroll. Otherwise, the drag
//        // will be handled by the enclosing PageView
//        if (wvCanScroll) {
//          resolve(GestureDisposition.accepted);
//          Fimber.d(">>> DRAG accepted");
//          _dragDistance = Offset.zero;
//        }
//      }
//    }
  }

  bool isDraggingTowardsRight(PointerEvent event) => event.delta.dx > 0;

  bool isDraggingTowardsLeft(PointerEvent event) => (event.delta.dx < 0);

  void askScrollPosToWebview() {
    Fimber.d(">>> askScrollPosToWebview");
    controller.evaluateJavascript(getScrollPosJSString);
  }

}
