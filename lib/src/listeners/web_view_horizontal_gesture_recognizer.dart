import 'package:fimber/fimber.dart';
import 'package:flutter/gestures.dart';
import 'package:pagination_tests/src/widgets/pagination_web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Inspired by https://stackoverflow.com/questions/57069716/scrolling-priority-when-combining-pageview-with-webview-in-flutter-1-7-8/57150906#57150906
///
class WebViewHorizontalGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  final int chapNumber;
  final PaginatingWebView webView;
  WebViewController controller;

  double _webViewScrollX = -double.maxFinite;
  double _webViewScrollWidth = double.maxFinite;
  double _webViewViewportWidth = double.maxFinite;

  bool _isBeginningVisible = true;
  bool _isEndVisible = false;

  int _currentPointer;

  bool get isBeginningVisible => _isBeginningVisible;

  bool get isEndVisible => _isEndVisible;

  set isBeginningVisible(bool value) {
    Fimber.d(">>> SETTING isBeginningVisible[$chapNumber] to $value");
    _isBeginningVisible = value;
  }

  set isEndVisible(bool value) {
    Fimber.d(">>> SETTING isEndVisible[$chapNumber] to $value");
    _isEndVisible = value;
  }

  set webViewScrollX(double value) {
    _webViewScrollX = value;
    Fimber.d(
        ">>> _webViewCanScrollX[$chapNumber] --> $value, this: $hashCode, ${webView.hashCode}");
  }

  set webViewScrollWidth(double value) {
    _webViewScrollWidth = value;
    Fimber.d(
        ">>> webViewScrollWidth[$chapNumber] --> $_webViewScrollWidth, this: $hashCode, ${webView.hashCode}");
  }

  set webViewViewportWidth(double value) {
    _webViewViewportWidth = value;
    Fimber.d(
        ">>> webViewViewportWidth[$chapNumber] --> $_webViewViewportWidth, this: $hashCode, ${webView.hashCode}");
  }

  void setBeginningVisible(
      JavascriptMessage message,
      WebViewHorizontalGestureRecognizer
          platformViewHorizontalGestureRecognizer) {
    var value = message.message.toLowerCase() == 'true' ||
        message.message.toLowerCase() == '1';
    Fimber.d(
        ">>> setBeginningVisible[$chapNumber], FROM JS: $value (message: ${message.message})");
    isBeginningVisible = value;
  }

  void setEndVisible(
      JavascriptMessage message,
      WebViewHorizontalGestureRecognizer
          platformViewHorizontalGestureRecognizer) {
    var value = message.message.toLowerCase() == 'true' ||
        message.message.toLowerCase() == '1';
    Fimber.d(
        ">>> setEndVisible[$chapNumber], FROM JS: $value (message: ${message.message})");
    isEndVisible = value;
  }

  WebViewHorizontalGestureRecognizer({
    this.chapNumber,
    this.webView,
    PointerDeviceKind kind,
  }) : super(kind: kind) {
    onUpdate = _onUpdate;
  }

  void _onUpdate(DragUpdateDetails details) {
    Fimber.d(">>> onUpdate[$chapNumber]: ${details.delta.direction}");
  }

  Offset _dragDistance = Offset.zero;

  @override
  void addPointer(PointerEvent event) {
    _currentPointer = event.pointer;
    startTrackingPointer(event.pointer);
    Fimber.d(
        ">>> Pointer tracking STARTED, pointer[$chapNumber]: ${event.pointer}");
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
    Fimber.d(">>> webviewCanScroll[$chapNumber] --> " +
        (_isEndVisible ? "false" : "true"));
    return !_isEndVisible;
  }

  @override
  void handleEvent(PointerEvent event) {
    // Fimber.d(">>> handleEvent ==================================== ");
    _dragDistance = _dragDistance + event.delta;
    if (event is PointerMoveEvent) {
      final double dy = _dragDistance.dy.abs();
      final double dx = _dragDistance.dx.abs();

      if (isVerticalDrag(dy, dx)) {
        // vertical drag - stop tracking
        stopTrackingPointer(event.pointer);
        _dragDistance = Offset.zero;
      } else if (dx > kTouchSlop && dx > dy) {
        // horizontal drag
        if ((isEndVisible && isDraggingTowardsLeft(event)) ||
            (isBeginningVisible && isDraggingTowardsRight(event))) {
          // The enclosing PageView must handle the drag since the webview cannot scroll anymore
          stopTrackingPointer(event.pointer);
        } else {
          // horizontal drag - accept
          resolve(GestureDisposition.accepted);
          _dragDistance = Offset.zero;
        }
      }
    }
  }

  bool isVerticalDrag(double dy, double dx) => dy > dx && dy > kTouchSlop;

  bool isDraggingTowardsRight(PointerEvent event) => event.delta.dx > 0;

  bool isDraggingTowardsLeft(PointerEvent event) => (event.delta.dx < 0);

  void askScrollPosToWebview() {
    Fimber.d(">>> askScrollPosToWebvie[$chapNumber]");
    controller.evaluateJavascript(getScrollPosJSString);
  }
}
