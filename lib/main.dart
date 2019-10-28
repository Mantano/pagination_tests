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
  static const NB_CHAPTERS = 8;
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
//      body: Center(
//        // Center is a layout widget. It takes a single child and positions it
//        // in the middle of the parent.
//        child: Column(
//          // Column is also a layout widget. It takes a list of children and
//          // arranges them vertically. By default, it sizes itself to fit its
//          // children horizontally, and tries to be as tall as its parent.
//          //
//          // Invoke "debug painting" (press "p" in the console, choose the
//          // "Toggle Debug Paint" action from the Flutter Inspector in Android
//          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//          // to see the wireframe for each widget.
//          //
//          // Column has various properties to control how it sizes itself and
//          // how it positions its children. Here we use mainAxisAlignment to
//          // center the children vertically; the main axis here is the vertical
//          // axis because Columns are vertical (the cross axis would be
//          // horizontal).
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            Text(
//              'You have pushed the button this many times:',
//            ),
//            Text(
//              '$_counter',
//              style: Theme.of(context).textTheme.display1,
//            ),
//          ],
//        ),
//      ),

      // TOD0 JM:
      //  - Injecter dans les pag sun JS qui signale quand on atteint le limite de scroll à G ou à D,
      // - Dans le callback Flutter ainsi appelé, positionner un booléen "pageViewMustHandleDrag", et
      // faire en sorte que le PlatformViewHorizontalGestureRecognizer fasse stopTrackingPointer et se "désactive"
      // Code JS: Plusieurs solutions sur https://stackoverflow.com/questions/3962558/javascript-detect-scroll-end
      // Par exemple: if (($(window).innerHeight() + $(window).scrollTop()) >= $("body").height()) {
      //    //do stuff
      //}
      // ALTERNATIVE: placer la webview dans une ListView do
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
            name: 'PrintScrollPosition',
            onMessageReceived: (JavascriptMessage message) {
              //This is where you receive message from
              //javascript code and handle in Flutter/Dart
              //like here, the message is just being printed
              //in Run/LogCat window of android studio
              Fimber.d(">>> FROM JS: ${message.message}");
              var values = message.message.split("/");
              platformViewHorizontalGestureRecognizer.webViewScrollX =
                  double.parse(values[0]);
              platformViewHorizontalGestureRecognizer.webViewScrollWidth =
                  double.parse(values[1]);
              platformViewHorizontalGestureRecognizer.webViewViewportWidth =
                  double.parse(values[2]);
            })
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

double _webViewScrollX = 0;
double _webViewScrollWidth = double.maxFinite;
double _webViewViewportWidth = double.maxFinite;

/// Inspired by https://stackoverflow.com/questions/57069716/scrolling-priority-when-combining-pageview-with-webview-in-flutter-1-7-8/57150906#57150906
///
class PlatformViewHorizontalGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  WebViewController controller;
  PaginatingWebView _webView;

  set webView(PaginatingWebView value) {
    _webView = value;
  }

  set webViewScrollX(double value) {
    _webViewScrollX = value;
    Fimber.d(
        ">>> _webViewCanScrollX --> $_webViewScrollX, this: $hashCode, ${_webView.hashCode}");
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

  PlatformViewHorizontalGestureRecognizer({PointerDeviceKind kind})
      : super(kind: kind);

  Offset _dragDistance = Offset.zero;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    askScrollPosToWebview();
    Fimber.d(">>> Pointer tracking STARTED");
  }

  @override
  String get debugDescription => 'horizontal drag (platform view)';

  final getScrollPosJSString = """
PrintScrollPosition.postMessage(document.getElementById('container').scrollLeft + '/' + document.getElementById('container').scrollWidth + '/' +  Math.max(document.documentElement.clientWidth, document.documentElement.clientWidth /*window.innerWidth || 0*/));
""";

  @override
  void didStopTrackingLastPointer(int pointer) {
    Fimber.d(">>> didStopTrackingLastPointer");
    askScrollPosToWebview();
  }

  bool webviewCanScroll(double dx) {
    bool res = false;
    if (dx == 0 || _webViewScrollWidth == double.maxFinite ||  _webViewViewportWidth == double.maxFinite)
      res = true;
    else if (dx > 0)
      res = _webViewScrollX > 0;
//    res = _webViewScrollX - _webViewViewportWidth >= 0;

    else
      res = _webViewScrollX <= _webViewScrollWidth - _webViewViewportWidth + 2*4;
    Fimber.d(
        ">>> CAN SCROLL? dx = $dx, scrollX: $_webViewScrollX, scrollWidth: $_webViewScrollWidth, vpwidth: $_webViewViewportWidth --> $res");
    return res;
  }

  @override
  void handleEvent(PointerEvent event) {
    _dragDistance = _dragDistance + event.delta;
    // askScrollPosToWebview();
    Fimber.d(
        ">>> handleEvent, webViewCanScroll: ${webviewCanScroll(event.delta.dx)}, this: $hashCode, ${_webView.hashCode}");
    if (!webviewCanScroll(event.delta.dx)) {
      Fimber.d(">>> REJECTING event");
      resolve(GestureDisposition.rejected);
      return;
    }
    Fimber.d(">>> handleEventnot NOT rejecting");

    if (event is PointerMoveEvent) {
      final double dy = _dragDistance.dy.abs();
      final double dx = _dragDistance.dx.abs();
      Fimber.d(">>> localPosition: ${event.localPosition.dx}");
      if (!webviewCanScroll(event.delta.dx) || (dy > dx && dy > kTouchSlop)) {
        // vertical drag - stop tracking
        stopTrackingPointer(event.pointer);
        Fimber.d(">>> Pointer tracking STOPPED");
        controller.evaluateJavascript("console.log('STOP')");
        _dragDistance = Offset.zero;
      } else if (dx > kTouchSlop && dx > dy) {
        // horizontal drag - accept if webview can scroll. Otherwise, the drag
        // will be handled by the enclosing PageView
        if (webviewCanScroll(event.delta.dx)) {
          resolve(GestureDisposition.accepted);
          Fimber.d(">>> DRAG accepted");
          _dragDistance = Offset.zero;
        }
      }
    }
  }

  void askScrollPosToWebview() {
    controller.evaluateJavascript(getScrollPosJSString);
  }
}
