import 'dart:convert';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:pagination_tests/src/epub/js/xpub_js_api.dart';
import 'package:preload_page_view/preload_page_view.dart' as preload_pageview;
import 'package:webview_flutter/webview_flutter.dart';

import 'src/widgets/fling_page_scroll_physics.dart';
//import 'src/widgets/snapping_listview.dart';

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
  static const NB_CHAPTERS = 7;
  final _webviewKeys =
      List<GlobalKey>.generate(NB_CHAPTERS, (_) => GlobalKey());
  var _controller = [];
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
//      appBar: AppBar(
//        // Here we take the value from the MyHomePage object that was created by
//        // the App.build method, and use it to set our appbar title.
//        title: Text(widget.title),
//      ),

      body: Center(
        child: _chaptersListView(context),
//        child: PreloadPageView.builder(
//            preloadPagesCount: 3,
//            controller: PreloadPageController(),
//            itemCount: NB_CHAPTERS,
//            itemBuilder: (ctx, i) {
//              return PaginatingWebView(
//                i + 1,
//                key: _webviewKeys[i],
//              );
//            }),
      ),
    );
  }

  bool flingMode = false;
  Offset _offset = Offset(0.4, 0.7);

  Widget _chaptersListView(BuildContext context) {
    // return SnappingListView(
    // Nous pourrions utiliser soit la PageScroll en mode lecture, soit la FlingPageScroll dans un mode "overview" comme Google Play
    final scrollPhysics = flingMode ? FlingPageScrollPhysics(PageController()) : preload_pageview.PageScrollPhysics();
    return createListview(scrollPhysics);
  }

  ListView createListview(ScrollPhysics scrollPhysics) {
    return ListView(
    // itemExtent: MediaQuery.of(context).size.width,
    //itemExtent: MediaQuery.of(context).size.width * 3,
    scrollDirection: Axis.horizontal,
    physics: scrollPhysics,
    padding: EdgeInsets.all(0.0),
    children: <Widget>[
      PaginatingWebView(
        1,
        key: _webviewKeys[1],
      ),
//        PaginatingWebView(
//          2,
//          key: _webviewKeys[2],
//        ),
      PaginatingWebView(
        3,
        key: _webviewKeys[3],
      ),
      PaginatingWebView(
        4,
        key: _webviewKeys[4],
      ),
      PaginatingWebView(
        5,
        key: _webviewKeys[5],
      ),
      PaginatingWebView(
        6,
        key: _webviewKeys[6],
      ),
    ],
  );
  }

  ConstrainedBox createWebview(String initialUrl) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 920.0, maxHeight: 400.0),
      child: WebView(
        debuggingEnabled: true,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
          ),
        },
        initialUrl: initialUrl,
      ),
    );
  }

}
/*
GestureDetector(
      onVerticalDragStart: (dragDetails) {
        startVerticalDragDetails = dragDetails;
      },
      onVerticalDragUpdate: (dragDetails) {
        updateVerticalDragDetails = dragDetails;
      },
      onVerticalDragEnd: (endDetails) {
        double dx = updateVerticalDragDetails.globalPosition.dx -
            startVerticalDragDetails.globalPosition.dx;
        double dy = updateVerticalDragDetails.globalPosition.dy -
            startVerticalDragDetails.globalPosition.dy;
      },
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
    );
 */

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
    var webViewHorizontalGestureRecognizer =
    HorizontalDragGestureRecognizer();
        // WebViewHorizontalGestureRecognizer();
    contentWidth = MediaQuery.of(context).size.width * 3;
    Fimber.d("============= Device screen width: ${MediaQuery.of(context).size.width}");
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: contentWidth, maxWidth: contentWidth, maxHeight: 800.0),
      child: WebView(
        initialUrl: "https://www.google.com",
        debuggingEnabled: true,
        javascriptMode: JavascriptMode.unrestricted,
        //javascriptChannels: epubCallbacks.channels,
        javascriptChannels: Set.from([
          JavascriptChannel(
              name: 'setWebviewWidth',
              onMessageReceived: (JavascriptMessage message) {
                Fimber.d("================ setWebviewWidth: ${message.message}");
                setState(() {
                  contentWidth = double.parse(message.message);
                });
              }),
          JavascriptChannel(
              name: 'sendBeginningVisibile',
              onMessageReceived: (JavascriptMessage message) {
//                webViewHorizontalGestureRecognizer.setBeginningVisible(
//                    message, webViewHorizontalGestureRecognizer);
              }),
          JavascriptChannel(
              name: 'sendEndVisibile',
              onMessageReceived: (JavascriptMessage message) {
//                webViewHorizontalGestureRecognizer.setEndVisible(
//                    message, webViewHorizontalGestureRecognizer);
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
class WebViewHorizontalGestureRecognizer
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

  void setBeginningVisible(
      JavascriptMessage message,
      WebViewHorizontalGestureRecognizer
          platformViewHorizontalGestureRecognizer) {
    var value = message.message.toLowerCase() == 'true' ||
        message.message.toLowerCase() == '1';
    Fimber.d(
        ">>> setBeginningVisible, FROM JS: $value (message: ${message.message})");
    isBeginningVisible = value;
  }

  void setEndVisible(
      JavascriptMessage message,
      WebViewHorizontalGestureRecognizer
          platformViewHorizontalGestureRecognizer) {
    var value = message.message.toLowerCase() == 'true' ||
        message.message.toLowerCase() == '1';
    Fimber.d(
        ">>> setEndVisible, FROM JS: $value (message: ${message.message})");
    isEndVisible = value;
  }

  WebViewHorizontalGestureRecognizer({PointerDeviceKind kind})
      : super(kind: kind) {
    onUpdate = _onUpdate;
  }

  void _onUpdate(DragUpdateDetails details) {
    Fimber.d(">>> onUpdate: ${details.delta.direction}");
  }

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
  }

  @override
  void handleEvent(PointerEvent event) {
    Fimber.d(">>> handleEvent ==================================== ");
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
        if ((isEndVisible && isDraggingTowardsLeft(event)) ||
            (isBeginningVisible && isDraggingTowardsRight(event))) {
        } else {
          // horizontal drag - accept
          resolve(GestureDisposition.accepted);
          _dragDistance = Offset.zero;
        }
      }
    }
  }

  bool isDraggingTowardsRight(PointerEvent event) => event.delta.dx > 0;

  bool isDraggingTowardsLeft(PointerEvent event) => (event.delta.dx < 0);

  void askScrollPosToWebview() {
    Fimber.d(">>> askScrollPosToWebview");
    controller.evaluateJavascript(getScrollPosJSString);
  }
}

// Sample code from: https://stackoverflow.com/questions/57069716/scrolling-priority-when-combining-horizontal-scrolling-with-webview
// It seems that the rules of the arena have changed. Now the arena declares wins
// for gestures that have active receivers. That indeed increases the responsiveness
// of the gestures even more. However, as the native views do not claim the gestures
// and only consume them when no other active detector/receiver claims them, I suspect
// that the vertical drag doesn't even enter the arena as a gesture from the WebView.
// That is why any slight horizontal drag causes horizontal drag gesture to win - because
// simply no other widgets claim any gesture.
//
//You can extend VerticalDragGestureRecognizer, so it accepts gestures:

//class PlatformViewVerticalGestureRecognizer
//    extends VerticalDragGestureRecognizer {
//  PlatformViewVerticalGestureRecognizer({PointerDeviceKind kind})
//      : super(kind: kind);
//
//  Offset _dragDistance = Offset.zero;
//
//  @override
//  void addPointer(PointerEvent event) {
//    startTrackingPointer(event.pointer);
//  }
//
//  @override
//  void handleEvent(PointerEvent event) {
//    _dragDistance = _dragDistance + event.delta;
//    if (event is PointerMoveEvent) {
//      final double dy = _dragDistance.dy.abs();
//      final double dx = _dragDistance.dx.abs();
//
//      if (dy > dx && dy > kTouchSlop) {
//        // vertical drag - accept
//        resolve(GestureDisposition.accepted);
//        _dragDistance = Offset.zero;
//      } else if (dx > kTouchSlop && dx > dy) {
//        // horizontal drag - stop tracking
//        stopTrackingPointer(event.pointer);
//        _dragDistance = Offset.zero;
//      }
//    }
//  }
//
//  @override
//  String get debugDescription => 'horizontal drag (platform view)';
//
//  @override
//  void didStopTrackingLastPointer(int pointer) {}
//}
//
//After that, you can use the new class in gestureRecognizers:
//
//PageView.builder(
//  itemCount: 5,
//  itemBuilder: (context, index) {
//    return WebView(
//      initialUrl: 'https://flutter.dev/docs',
//      gestureRecognizers: [
//        Factory(() => PlatformViewVerticalGestureRecognizer()),
//      ].toSet(),
//    );
//  },
//);
