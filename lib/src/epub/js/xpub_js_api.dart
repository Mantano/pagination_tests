import 'dart:convert';

import 'package:fimber/fimber.dart';

class JsApi {
  final Function _jsLoader;

  JsApi(this._jsLoader);

  void loadJS(String jScript) {
    Fimber.d("loadJS: $jScript");
    _jsLoader("javascript:(function(){$jScript})()");
  }

  void move(double offset) {
    loadJS("xpub.\$epubHtml.scrollLeft(xpub.\$epubBody.scrollLeft() + $offset)");
  }

  void refreshPage(bool moveToEnd) {
    if (moveToEnd) {
      loadJS("xpub.events.resetImpetus(xpub.\$epubBody[0].scrollWidth - xpub.paginationInfo.columnWidth, true)");
    } else {
      loadJS("xpub.events.resetImpetus(xpub.\$epubBody.scrollLeft())");
    }
  }

  void onDown(double dx, double dy) {
    loadJS("xpub.events.triggerEvent(xpub.\$epubBody, 'touchstart', ${dx.toInt()}, ${dy.toInt()})");
  }

  void onUp(double dx, double dy) {
    loadJS("xpub.events.triggerEvent(xpub.\$epubBody, 'touchend', ${dx.toInt()}, ${dy.toInt()})");
  }

  void onMove(double dx, double dy) {
    loadJS("xpub.events.triggerEvent(xpub.\$epubBody, 'touchmove', ${dx.toInt()}, ${dy.toInt()})");
  }

  void onCancel(double dx, double dy) {
    loadJS("xpub.events.triggerEvent(xpub.\$epubBody, 'touchcancel', ${dx.toInt()}, ${dy.toInt()})");
  }

}
